local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local Signal = require(ReplicatedStorage.Packages.Signal)

local jest = JestGlobals.jest

local module = {}

function module.new(): Signal.Connection
	local connection = {
		Connected = true,
	}

	connection.Disconnect = jest.fn(function(self)
		self.Connected = false
	end)
	connection.Destroy = connection.Disconnect

	return connection
end

return module
