local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local peek = Fusion.peek

export type TimerValue = {
	start: number,
	elapsed: number,
	deltaTime: number,
}
export type Timer = Fusion.Computed<TimerValue>

return function(scope: Fusion.Scope, elapsedTime: Fusion.StateObject<number>?)
	local elapsedTime_: Fusion.StateObject<number>
	if not elapsedTime then
		local newElapsedTime = scope:Value(0)
		elapsedTime_ = newElapsedTime

		table.insert(scope, RunService.PreRender:Connect(function(dt)
			newElapsedTime:set(peek(newElapsedTime) + dt)
		end))
	else
		elapsedTime_ = elapsedTime
	end
	
	local startTime = os.clock()
	local timer: Timer
	local lastValue: TimerValue? = nil
	timer = scope:Computed(function(use, scope)
		local elapsed = use(elapsedTime_) :: number
		local currentValue = table.freeze {
			start = startTime,
			elapsed = elapsed,
			deltaTime = if lastValue then elapsed - lastValue.elapsed else 0,
		}
		lastValue = currentValue
		return currentValue
	end)
	return timer
end
