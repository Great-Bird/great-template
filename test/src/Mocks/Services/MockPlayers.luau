local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local MockPlayer = require(ReplicatedStorage.Testing.Mocks.Instances.MockPlayer)

local jest = JestGlobals.jest

local module = {}

function module.new()
	return {
		GetPlayers = jest.fn(function()
			local players = {}
			for i = 1, 3 do
				players[i] = MockPlayer.new(i)
			end
			return players
		end),
	}
end

return module
