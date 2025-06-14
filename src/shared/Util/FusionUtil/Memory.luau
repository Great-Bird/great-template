local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local TableUtil = require(ReplicatedStorage.Shared.Util.TableUtil)

local peek = Fusion.peek

return function<T>(scope: Fusion.Scope<typeof(Fusion)>, source: Fusion.StateObject<T>, maxHistory: Fusion.UsedAs<number>?)
	maxHistory = maxHistory or 2

	-- The problem to solve here is that we need to add the source value to the
	-- history whenever the source value changes, but we also need to reallocate
	-- the history array whenever the maxHistory value changes. So, we need two
	-- observers that do different things.

	local history = scope:Value(table.freeze {})
	scope:Observer(source):onBind(function()
		history:set(TableUtil.immutInsertArray(peek(history), 1, peek(source)))
	end)
	scope:Observer(maxHistory):onBind(function()
		local valueList = peek(history)
		local maxHistoryValue = peek(maxHistory)

		if #valueList > maxHistoryValue then
			history:set(TableUtil.immutSliceArray(valueList, 1, maxHistoryValue))
		end
	end)
	return scope:Computed(function(use, scope)
		local valueHistory = use(history)
		return table.freeze {
			current = valueHistory[1],
			last = valueHistory[2],
			history = valueHistory,
		}
	end)
end
