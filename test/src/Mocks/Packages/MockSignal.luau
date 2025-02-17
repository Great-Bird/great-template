local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MockSignalConnection = require(script.Parent.MockSignalConnection)
local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local Signal = require(ReplicatedStorage.Packages.Signal)

local jest = JestGlobals.jest

local module = {}

function module.new(): Signal.Signal<...any>
	local signal = {}

	-- TODO implement this stub
	signal.Connect = jest.fn(function() return MockSignalConnection.new() end)
	signal.Wait = jest.fn()
	signal.Once = jest.fn()
	signal.Destroy = jest.fn()
	signal.DisconnectAll = jest.fn()
	signal.Fire = jest.fn()
	signal.FireDeferred = jest.fn()
	signal.GetConnections = jest.fn()

	return signal
end

return module
