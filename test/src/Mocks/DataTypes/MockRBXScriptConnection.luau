local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local jest = JestGlobals.jest

local module = {}

function module.Disconnect<T...>(self: MockRBXScriptConnection<T...>)
	self.Connected = false
	if self._onDisconnect then
		self._onDisconnect()
	end
end

function module._receiveEvent(self: MockRBXScriptConnection<...any>, ...: any)
	if not self.Connected then
		return
	end

	if self._callback then
		self._callback(...)
	end

	if self._once then
		module.Disconnect(self)
	end
end

function module.new<T...>(callback: (T...) -> ()?, onDisconnect: () -> ()?, once: boolean?): MockRBXScriptConnection<T...>
	local self = {
		Disconnect = jest.fn(),
		Connected = true,

		_callback = callback,
		_onDisconnect = onDisconnect,
		_once = once,
	}

	self._disconnect, self.Disconnect = jest.fn(module.Disconnect)
	self._receiveEvent = module._receiveEvent

	return self
end

export type MockRBXScriptConnection<T...> = {
	Disconnect: (self: MockRBXScriptConnection<T...>) -> (),
	_disconnect: any,
	Connected: boolean,

	_once: boolean?,
	_callback: (T...) -> ()?,
	_onDisconnect: () -> ()?,
	_receiveEvent: (self: MockRBXScriptConnection<T...>, T...) -> (),
}

return module
