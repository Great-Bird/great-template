local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local peek = Fusion.peek

return function<T>(scope: Fusion.Scope, source: Fusion.StateObject<T>, isFrozen: Fusion.UsedAs<boolean>)
	local lastValue = peek(source)
	return scope:Computed(function(use, scope)
		if use(isFrozen) then
			return lastValue
		else
			lastValue = use(source :: any)
			return lastValue
		end
	end)
end
