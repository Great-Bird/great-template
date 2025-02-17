local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local ReactiveValue = require(ReplicatedStorage.Shared.Util.ReactiveValue)

local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

jest.useFakeTimers()

describe("ReactiveValue.new(value)", function()
	local value: ReactiveValue.ReactiveValue<number>
	beforeEach(function()
		value = ReactiveValue.new(0)
	end)

	it("returns a table", function()
		expect(type(value)).toBe("table")
	end)

	describe(".set", function()
		it("sets the value", function()
			value.set(1)
			expect(value.getCurrent()).toBe(1)
		end)
		it("returns the set value", function()
			expect(value.set(1)).toBe(1)
		end)
	end)

	describe(".get", function()
		it("starts with the initial value", function()
			local current, old = value.get()
			expect(current).toBe(0)
			expect(old).toBe(0)
		end)
		it("returns the current and old values", function()
			expect(value.getCurrent()).toBe(0)
			value.set(1)
			local current, old = value.get()
			expect(current).toBe(1)
			expect(old).toBe(0)
		end)
	end)

	describe(".getCurrent", function()
		it("returns the current value", function()
			value.set(1)
			expect(value.getCurrent()).toBe(1)
		end)
	end)

	describe(".destroy", function()
		it("disconnects all connections", function()
			local mockFn = jest.fn()
			value.changed:Connect(mockFn)
			value.destroy()
			value.set(1)
			expect(mockFn).never.toHaveBeenCalled()
		end)
	end)

	describe(".changed", function()
		afterEach(function()
			value.destroy()
		end)

		it("fires once when the value changes", function()
			local mockFn = jest.fn()
			value.changed:Connect(mockFn)
			value.set(1)
			expect(mockFn).toHaveBeenCalledTimes(1)
		end)

		it("fires with the current and old values", function()
			local mockFn = jest.fn()
			value.changed:Connect(mockFn)
			value.set(1)
			expect(mockFn).toHaveBeenLastCalledWith(1, 0)
		end)

		it("does not fire when the value is set to the same value", function()
			local mockFn = jest.fn()
			value.changed:Connect(mockFn)
			value.set(0)
			expect(mockFn).never.toHaveBeenCalled()
		end)
	end)

	describe(".observe", function()
		local mockFn = jest.fn()
		local observeCallback = function(...)
			return mockFn(...)
		end
		beforeEach(function()
			mockFn.mockClear()
		end)

		it("calls the callback with the current and old value once immediately", function()
			value.set(1)
			value.observe(observeCallback)
			expect(mockFn).toHaveBeenLastCalledWith(1, 0)

			value.destroy()
		end)

		it("calls the callback in a new thread", function()
			local thread
			mockFn.mockImplementationOnce(function()
				thread = coroutine.running()
			end)
			value.observe(observeCallback)
			expect(type(thread)).toBe("thread")
			expect(thread).never.toBe(coroutine.running())
		end)

		it("calls the callback with the current and old value when the value changes", function()
			value.observe(observeCallback)
			value.set(1)
			expect(mockFn).toHaveBeenCalledTimes(2)
			expect(mockFn).toHaveBeenLastCalledWith(1, 0)

			value.destroy()
		end)

		it("returns a connection", function()
			local connection = value.observe(observeCallback)
			connection:Disconnect()
			value.set(1)
			expect(mockFn).toHaveBeenCalledTimes(1)

			value.destroy()
		end)
	end)
end)

describe("ReactiveValue.new(value, checkFn)", function()
	it("passes the new, current, and old values to the check function", function()
		local mockFn = jest.fn(function(new: number, current: number, old: number): number
			return new
		end)
		local value = ReactiveValue.new(0, mockFn)

		value.set(1)
		expect(mockFn).toHaveBeenLastCalledWith(1, 0, 0)

		value.set(2)
		expect(mockFn).toHaveBeenLastCalledWith(2, 1, 0)
		expect(mockFn).toHaveBeenCalledTimes(2)
	end)

	it("uses the check function to validate the new value", function()
		local mockIncreaseCheck = jest.fn(function(new: number, current: number, old: number): number
			assert(new > current)
			return new
		end)
		local onlyIncreasingValue = ReactiveValue.new(0, mockIncreaseCheck)
		expect(function()
			onlyIncreasingValue.set(1)
		end).never.toThrow()
		expect(function()
			onlyIncreasingValue.set(0)
		end).toThrow()
	end)
end)

describe("ReactiveValue.derive(reactiveValue, deriveFn)", function()
	local mockDeriveFn = jest.fn(function(current: number, old: number): string
		return tostring(current)
	end)
	local value: ReactiveValue.ReactiveValue<number>
	local derivedValue: ReactiveValue.DerivedReactiveValue<string>
	beforeEach(function()
		mockDeriveFn.mockClear()
		value = ReactiveValue.new(0)
		derivedValue = ReactiveValue.derive(value, mockDeriveFn)
	end)
	afterEach(function()
		value.destroy()
		derivedValue.destroy()
	end)

	it("returns a table", function()
		expect(type(derivedValue)).toBe("table")
	end)
	it("deriveFn is called for the current value once immediately", function()
		expect(mockDeriveFn).toHaveBeenCalledTimes(1)
		expect(derivedValue.getCurrent()).toBe("0")
	end)
	it("deriveFn is called with the current and old values", function()
		value.set(1)
		expect(mockDeriveFn).toHaveBeenLastCalledWith(1, 0)
		expect(derivedValue.getCurrent()).toBe("1")
	end)
	it("derived value updates when source value changes", function()
		value.set(1)
		expect(derivedValue.getCurrent()).toBe("1")
		value.set(2)
		expect(derivedValue.getCurrent()).toBe("2")
	end)
	it("can derive from another derived value", function()
		local doubleDerivedValue = ReactiveValue.derive(derivedValue, function(current: string, old: string): number
			return tonumber(current) :: number
		end)
		value.set(1)
		expect(doubleDerivedValue.getCurrent()).toBe(1)
	end)

	describe(".set", function()
		it("does not exist", function()
			expect(derivedValue).never.toHaveProperty("set")
		end)
	end)
end)
