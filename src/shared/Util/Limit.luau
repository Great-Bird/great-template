--!strict

export type Throttle<T> = {
	invoke: (key: T, throttleTime: number) -> number?,
	getTimeLeft: (key: T, throttleTime: number) -> number,
	state: { [T]: { timestamp: number, thread: thread }? }
}
export type Rate<T> = {
	invoke: (key: T) -> boolean,
	isExceeded: (key: T) -> boolean,
	uses: { [T]: number }
}

local Module = {}

--[=[
	Returns an object that represents a rate limiter.
	
	The `invoke` function returns true if it has been called with the passed key
	more than `maxRate` times per `interval` seconds.
	```lua
	local rateLimit = Limit.rateLimit(5, 2) :: Limit.Rate<Player>
	
	local function sendMessage(player: Player)
		-- Only allow this function to run 5 times every 2 seconds
		if rateLimit.invoke(player) then
			return
		end
		print(player.Name)
	end

	-- This will only print the local player 5 times every 2 seconds
	while task.wait() do
		sendMessage(game:GetService("Players").LocalPlayer)
	end
	```
	
	The `isExceeded` function returns whether the key has hit the rate limit
	without invoking the limit.
	
	The `uses` table stores uses within the last interval.
]=]
function Module.rate<T>(maxRate: number, interval: number?): Rate<T>
	interval = interval or 1
	assert(maxRate > 0 and maxRate % 1 == 0, "maxRate must be an integer greater than 0")
	assert(interval > 0, "interval must be greater than 0")

	local uses: { [T]: number } = {}
	
	local function isExceeded(key: T): boolean
		return uses[key] and uses[key] >= maxRate
	end
	
	local function invoke(key: T): boolean
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

	return { invoke = invoke, isExceeded = isExceeded, uses = uses }
end

--[=[
	Returns an object that represents a leading-edge throttle.
	
	The `invoke` function returns nil if it has not been called with the passed
	key in the past `throttleTime` seconds, else it returns the number of
	seconds left until the throttle ends.
	```lua
	local throttle = Limit.throttle() :: Limit.Throttle<Player>
	
	local function sendMessage(player: Player)
		-- Only allow this function to run once per second
		if throttle.invoke(player, 1) then
			return
		end
		print(player.Name)
	end

	-- This will only print the local player once every second
	while task.wait() do
		sendMessage(game:GetService("Players").LocalPlayer)
	end
	```

	The `getTimeLeft` function returns how much longer the passed key will be
	throttled for without invoking the throttle.

	The `state` table stores the throttle state.
]=]
function Module.throttle<T>(): Throttle<T>
	local throttleState: { [T]: { timestamp: number, thread: thread }? } = {}
	
	local function getTimeLeft(key: T, throttleTime: number): number
		local entry = throttleState[key]
		return if entry then throttleTime - (os.clock() - entry.timestamp) else 0
	end
	
	local function invoke(key: T, throttleTime: number): number?
		local entry = throttleState[key]
		if not entry then
			throttleState[key] = {
				timestamp = os.clock(),
				thread = task.delay(throttleTime, function()
					throttleState[key] = nil
				end)
			}
		else
			local now = os.clock()
			local timePassed = now - entry.timestamp
			if timePassed < throttleTime then
				return throttleTime - timePassed
			end
			task.cancel(entry.thread)
			entry.timestamp = now
			entry.thread = task.delay(throttleTime, function()
				throttleState[key] = nil
			end)
		end
		return nil
	end

	return { invoke = invoke, getTimeLeft = getTimeLeft, state = throttleState }
end

return Module
