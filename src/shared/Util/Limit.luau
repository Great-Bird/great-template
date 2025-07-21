--!strict

export type Debounce<T> = {
	timeLeft: (key: T, debounceTime: number) -> number?,
	state: { [T]: { timestamp: number, thread: thread }? }
}
export type Rate<T> = {
	exceeded: (key: T) -> boolean,
	uses: { [T]: number }
}

local Module = {}

--[=[
	Returns an object with an `exceeded` function that returns true if it has
	been called with the passed key more than `maxRate` times per `interval`
	seconds.
	The `uses` table in the object stores uses within the last interval.
]=]
function Module.rate<T>(maxRate: number, interval: number?): Rate<T>
	interval = interval or 1
	assert(maxRate > 0 and maxRate % 1 == 0, "maxRate must be an integer greater than 0")
	assert(interval > 0, "interval must be greater than 0")

	local uses: { [T]: number } = {}

	local function exceeded(key: T)
		if not uses[key] then
			uses[key] = 0
			task.delay(interval, function()
				uses[key] = nil
			end)
		end
		if uses[key] >= maxRate then
			return true
		else
			uses[key] += 1
			return false
		end
	end
	
	return { exceeded = exceeded, uses = uses }
end

--[=[
	Returns an object with a `timeLeft` function that returns 0 if it has not
	been called with the passed key in the past `debounceTime` seconds, else the
	number of seconds before the debounce for the key is over.
	The `state` table in the object stores the debounce state.
]=]
function Module.debounce<T>(): Debounce<T>
	local debounceState: { [T]: { timestamp: number, thread: thread }? } = {}

	local function timeLeft(key: T, debounceTime: number): number
		local entry = debounceState[key]
		if not entry then
			debounceState[key] = {
				timestamp = os.clock(),
				thread = task.delay(debounceTime, function()
					debounceState[key] = nil
				end)
			}
		else
			local now = os.clock()
			local timePassed = now - entry.timestamp
			if timePassed < debounceTime then
				return debounceTime - timePassed
			end
			task.cancel(entry.thread)
			entry.timestamp = now
			entry.thread = task.delay(debounceTime, function()
				debounceState[key] = nil
			end)
		end
		return 0
	end

	return { timeLeft = timeLeft, state = debounceState }
end

return Module
