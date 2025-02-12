--[[
	Schedule v0.1.0
	Authors: SOLARSCUFFLE_BOT, Great_Bird
	Date: 2025-02-12
	Last updated: 2025-02-12

	Task scheduling library forked from https://github.com/Data-Oriented-House/Sandwich

	MIT License

	Copyright (c) 2023 Sona

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

	Changelog:
	v0.1.0
	- Notes: Release
]]

local NOOP = function() end
local ROOT: Job<...any> = function() end

local function visit<T...>(schedule: Schedule<T...>, visited: { [Job<T...>]: true }, job: Job<T...>)
	if visited[job] then
		return
	end

	visited[job] = true

	for _, dependency in schedule.graph[job] do
		visit(schedule, visited, dependency)
	end

	if job ~= ROOT then
		table.insert(schedule.jobs, 1, job)
	end
end

local function topologicalSort<T...>(schedule: Schedule<T...>)
	local visited = {}
	table.clear(schedule.jobs)

	visit(schedule, visited, ROOT)
end

--[=[
	@param callback The function to call.
	@param ... The arguments to pass to the function.
	@return { success: true, yielded: boolean } | { success: false, error: string }	

	Detects if a function yielded when called.
]=]
local function callNoYield<A...>(
	callback: (A...) -> (),
	...: A...
): { success: true, yielded: boolean } | { success: false, error: string }
	local thread = coroutine.create(callback)
	local success, err = coroutine.resume(thread, ...)
	local yielded = coroutine.status(thread) == "suspended"
	coroutine.close(thread) -- Stop the thread from running if it has yielded
	if not success then
		return { success = success, error = err }
	end
	return { success = success, yielded = yielded }
end

local Schedule = {}

--[=[
	Creates a new schedule that can be used to create jobs. Optionally takes in a `before` and `after` callback that will be called before and after each job is executed.
]=]
function Schedule.new<T...>(parameters: {
	before: (Job<T...>, T...) -> ()?,
	after: (Job<T...>, T...) -> ()?,
}?): Schedule<T...>
	--[=[
		Schedules are used to create jobs that can be executed at a later time.
	]=]
	local schedule = {
		graph = { [ROOT] = {} },
		jobs = {},
		before = (if parameters and parameters.before then parameters.before else NOOP) :: (Job<T...>, T...) -> (),
		after = (if parameters and parameters.after then parameters.after else NOOP) :: (Job<T...>, T...) -> (),
	}

	--[=[
		Creates a new job that can be executed later by calling `Schedule.start`. Takes in other jobs as dependencies, which must be executed before this job is executed.

		```lua
		local schedule = Schedule.schedule()

		local a = schedule.job(function(...) print("a", ...) end)
		local b = schedule.job(function(...) print("b", ...) end)
		local c = schedule.job(function(...) print("c", ...) end, a)
		local d = schedule.job(function(...) print("d", ...) end, a, b)
		local e = schedule.job(function(...) print("e", ...) end, c, d)
		local f = schedule.job(function(...) print("f", ...) end, a, e, b, c)
		```
	]=]
	function schedule.job(jobTask: Job<T...>, ...: Job<T...>): Job<T...>
		local job = jobTask
		schedule.graph[job] = {}

		local dependencies = { ... }
		if #dependencies == 0 then
			table.insert(schedule.graph[ROOT], job)
		else
			for _, dependency in dependencies do
				local nextJobs = schedule.graph[dependency]
				assert(
					nextJobs,
					"A dependency does not exist! You are passing in a job that was not created by this schedule, or you are not passing in a job at all."
				)
				table.insert(nextJobs, job)
			end
		end

		topologicalSort(schedule)

		return job
	end

	--[=[
		Executes the schedule's tasks in topological order.

		```lua
		schedule.start("Hello, world!")

		-- b	Hello, world!
		-- a	Hello, world!
		-- d	Hello, world!
		-- c	Hello, world!
		-- e	Hello, world!
		-- f	Hello, world!
		```
	]=]
	function schedule.start(...: T...)
		for _, job in schedule.jobs do
			schedule.before(job, ...)
			job(...)
			schedule.after(job, ...)
		end
	end

	--[=[
		Runs the schedule, erroring if any function in the schedule yields.
	]=]
	function schedule.startNoYield(...: T...)
		for _, job in schedule.jobs do
			schedule.before(job, ...)

			local result = callNoYield(job, ...)
			if not result.success then
				local scriptName, line = debug.info(job, "sl")
				error(`Failed to run scheduled function defined in {scriptName}:{line}: {result.error}`)
			elseif result.yielded then
				local scriptName, line = debug.info(job, "sl")
				error(`Failed to run scheduled function defined in {scriptName}:{line}: Job yielded`)
			end

			schedule.after(job, ...)
		end
	end

	return schedule
end

--[=[
	Returns a new schedule that runs each job in parallel. This is useful when you want to run multiple yielding jobs at the same time and be notified when they all finish.
]=]
function Schedule.parallel<T...>(parameters: {
	before: (Job<T...>, T...) -> ()?,
	after: (Job<T...>, T...) -> ()?,
}?): ParallelSchedule<T...>
	local schedule = {
		jobs = {},
		dependencies = {},
		before = (if parameters and parameters.before then parameters.before else NOOP) :: (Job<T...>, T...) -> (),
		after = (if parameters and parameters.after then parameters.after else NOOP) :: (Job<T...>, T...) -> (),
	}

	--[=[
		Creates a new job that can be executed later by calling `Schedule.start`. Takes in other jobs as dependencies, which must be executed before this job is executed.
	]=]
	function schedule.job(jobTask: Job<T...>, ...: Job<T...>): Job<T...>
		table.insert(schedule.jobs, jobTask)

		local dependencies = { ... }
		for _, dependency in dependencies do
			if not schedule.dependencies[dependency] then
				error(
					"A dependency does not exist! You are passing in a job that was not created by this schedule, or you are not passing in a job at all."
				)
			end
		end
		schedule.dependencies[jobTask] = dependencies

		return jobTask
	end

	local function startSchedule(disallowYield: boolean, ...: T...)
		local unfinishedJobCount = #schedule.jobs
		local currentThread = coroutine.running()
		local finishedDependencies: { [Job<T...>]: true } = {}
		local yieldingThreads: { [thread]: true } = {}

		local function runJob(job: Job<T...>, ...: T...)
			local jobThread = coroutine.running()
			yieldingThreads[jobThread] = true
			local dependencies = schedule.dependencies[job]
			repeat
				local doneYielding = true
				for _, dependency in dependencies do
					if not finishedDependencies[dependency] then
						doneYielding = false
						break
					end
				end
				if not doneYielding then
					coroutine.yield()
				end
			until doneYielding
			yieldingThreads[jobThread] = nil

			schedule.before(job, ...)

			local result = callNoYield(job, ...)
			if not result.success then
				local scriptName, line = debug.info(job, "sl")
				error(`Failed to run scheduled function defined in {scriptName}:{line}: {result.error}`)
			elseif result.yielded then
				local scriptName, line = debug.info(job, "sl")
				error(`Failed to run scheduled function defined in {scriptName}:{line}: Job yielded`)
			end

			schedule.after(job, ...)

			finishedDependencies[job] = true
			unfinishedJobCount -= 1
			if unfinishedJobCount == 0 then
				if coroutine.status(currentThread) == "suspended" then
					task.spawn(currentThread)
				end
			else
				for thread in yieldingThreads do
					if coroutine.status(thread) == "suspended" then
						coroutine.resume(thread)
					end
				end
			end
		end

		for _, job in schedule.jobs do
			local coro = coroutine.create(runJob)
			local success, err = coroutine.resume(coro, job, ...)
			if not success then
				error(`Failed to run scheduled function: {err}`)
			end
		end

		if unfinishedJobCount > 0 then
			coroutine.yield()
		end
	end

	--[=[
		Executes the schedule's tasks in parallel. Yields until all jobs are finished.
	]=]
	function schedule.start(...: T...)
		startSchedule(false, ...)
	end

	--[=[
		Runs the schedule, erroring if any function in the schedule yields.
	]=]
	function schedule.startNoYield(...: T...)
		startSchedule(true, ...)
	end

	return schedule
end

--[=[
	Creates a new thread that will execute a callback every given number of seconds. If the callback returns true, the thread will stop executing.

	```lua
	-- Run this every 300 seconds
	local gameThread = Schedule.interval(300, function()
		print("A special boss has appeared!")
	end)
	```
]=]
function Schedule.interval<T...>(period: number, callback: (T...) -> boolean?, ...: T...)
	return task.spawn(function(...: T...)
		repeat
			task.wait(period)
		until callback(...) == true
	end, ...)
end

--[=[
	Connects a callback to an event but will only fire the callback at the given frequency.

	```lua
	-- Run this 3 times a second on Heartbeat
	Schedule.tick(RunService.Heartbeat, 3, function(deltaTime)
		local result = expensiveCalculation(deltaTime)
		expensiveOperation(result)
	end)
	```
]=]
function Schedule.tick<T...>(event: RBXScriptSignal<T...>, frequency: number, callback: (T...) -> ()): RBXScriptConnection
	local period = 1 / frequency
	local last = os.clock()
	return event:Connect(function(...)
		local now = os.clock()
		local delta = now - last
		if delta > period then
			callback(...)
			last = now - delta % period
		end
	end)
end

export type Schedule<T...> = {
	job: (jobTask: (T...) -> (), ...Job<T...>) -> Job<T...>,
	start: (T...) -> (),
	startNoYield: (T...) -> (),
	before: (job: Job<T...>, T...) -> (),
	after: (job: Job<T...>, T...) -> (),
	graph: { [Job<T...>]: { Job<T...> } },
	jobs: { Job<T...> },
}
export type ParallelSchedule<T...> = {
	job: (jobTask: (T...) -> (), ...Job<T...>) -> Job<T...>,
	start: (T...) -> (),
	startNoYield: (T...) -> (),
	before: (job: Job<T...>, T...) -> (),
	after: (job: Job<T...>, T...) -> (),
	dependencies: { [Job<T...>]: { Job<T...> } },
	jobs: { Job<T...> },
}
export type Job<T...> = (T...) -> ()

return Schedule
