local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local MockRBXScriptConnection = require(script.Parent.MockRBXScriptConnection)

local jest = JestGlobals.jest

local module = {}

function module.Connect<T...>(
	self: MockRBXScriptSignal<T...>,
	callback: (T...) -> ()
): MockRBXScriptConnection.MockRBXScriptConnection<T...>
	local connection: MockRBXScriptConnection.MockRBXScriptConnection<T...>
	connection = MockRBXScriptConnection.new(callback, function()
		table.remove(self._connections, table.find(self._connections, connection))
	end)
	table.insert(self._connections, connection)
	return connection
end

function module.Once<T...>(
	self: MockRBXScriptSignal<T...>,
	callback: (T...) -> ()
): MockRBXScriptConnection.MockRBXScriptConnection<T...>
	local connection = module.Connect(self, callback)
	connection._once = true
	return connection
end

function module.Wait<T...>(self: MockRBXScriptSignal<T...>): T...
	local running = coroutine.running()
	module.Once(self, function(...)
		if coroutine.status(running) == "suspended" then
			coroutine.resume(running, ...)
		end
	end)
	return coroutine.yield()
end

function module._fire<T...>(self: MockRBXScriptSignal<T...>, ...: T...)
	for _, connection in self._connections do
		connection:_receiveEvent(...)
	end
end

function module._disconnectAll<T...>(self: MockRBXScriptSignal<T...>)
	for _, connection in self._connections do
		connection:Disconnect()
	end
end

function module.new<T...>(): MockRBXScriptSignal<T...>
	local self = {
		_connections = {} :: { MockRBXScriptConnection.MockRBXScriptConnection<T...> },
	}

	self._connect, self.Connect = jest.fn(module.Connect)
	self._once, self.Once = jest.fn(module.Once)
	self._wait, self.Wait = jest.fn(module.Wait)

	self._fire = module._fire
	self._disconnectAll = module._disconnectAll

	return self
end

export type MockRBXScriptSignal<T...> = {
	Connect: (
		self: MockRBXScriptSignal<T...>,
		callback: (T...) -> ()
	) -> MockRBXScriptConnection.MockRBXScriptConnection<T...>,
	Once: (
		self: MockRBXScriptSignal<T...>,
		callback: (T...) -> ()
	) -> MockRBXScriptConnection.MockRBXScriptConnection<T...>,
	Wait: (self: MockRBXScriptSignal<T...>) -> T...,

	_connections: { MockRBXScriptConnection.MockRBXScriptConnection<T...> },

	_fire: (self: MockRBXScriptSignal<T...>, T...) -> (),
	_disconnectAll: (self: MockRBXScriptSignal<T...>) -> (),
}

return module
