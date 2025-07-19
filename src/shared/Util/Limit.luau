--!strict

local Limit = {}

--[=[
	Returns a function that returns true if it has been called more than
	`maxRate` times per `interval` seconds, and a table which stores uses within
	the last interval.
]=]
function Limit.rate(maxRate: number, interval: number?)
	interval = interval or 1
	assert(maxRate > 0 and maxRate % 1 == 0, "maxRate must be an integer greater than 0")
	assert(interval > 0, "interval must be greater than 0")

	local uses: { [any]: number } = {}

	local function limitExceeded(key: any)
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
	
	return limitExceeded, uses
end

--[=[
	Returns a function that returns nil if it has not been called in the past
	`debounceTime` seconds, else a number representing the amount of time in
	seconds before the debounce for the key is over. Also returns a table
	storing the debounce state.
]=]
function Limit.debounce()
	local debounceState: { [any]: { timestamp: number, thread: thread }? } = {}

	local function onDebounce(key: any, debounceTime: number): number?
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
		return
	end

	return onDebounce, debounceState
end

return Limit
