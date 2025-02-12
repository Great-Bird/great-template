--[[
	ReactiveValue v0.1.0
	Author: Great_Bird
	Date: 2024-09-28
	Last updated: 2025-02-12

	Note: Requires Signal as a dependency. https://sleitnick.github.io/RbxUtil/api/Signal/

	A ReactiveValue stores a value and provides utilities for reacting to changes
	to the stored value. They're useful for state management, and running systems
	only when necessary.

	ReactiveValues can be used in place of Roblox ValueObjects to provide more
	flexibility and control, as well as performance benefits.

	Usage:
	```lua
	local value = ReactiveValue.new(0)

	local connection = value.changed:Connect(function(new, old)
		print("Value changed from", old, "to", new)
	end)

	value.set(1) -- Value changed from 0 to 1

	connection:Disconnect()

	value.set(2) -- No output

	-- The `get` method returns the current and previous value
	print(value.get()) -- 2, 1

	-- Call destroy to clean up the signal when the value is no longer needed
	value.destroy()
	```

	The `checkValue` parameter is run for all values that are set. The function should return the new value.
	It's useful for running extra validations or processing. For example, you can constrain a number to a range:
	```lua
	local value = ReactiveValue.new(0, function(value, current, old)
		return math.clamp(value, 0, 10)
	end)

	-- The `set` method returns the actual value that was set
	local actualValue = value.set(5)
	print(actualValue == value.get()) -- true

	actualValue = value.set(20)
	print(actualValue == value.get()) -- false
	```

	The `observe` method is shorthand for connecting to the `changed` signal and immediately calling the callback with the current and previous value:
	```lua
	local value = ReactiveValue.new("hello")

	value.observe(print) -- hello

	value.set("world") -- world
	```

	You can also derive a new ReactiveValue from an existing one. The derived value will update whenever the source value changes:
	```lua
	local sourceValue = ReactiveValue.new(0)
	local derivedValue = ReactiveValue.derive(sourceValue, function(current, old)
		return current * 2
	end)

	local connection = derivedValue.changed:Connect(function(new, old)
		print(`Derived value changed from {old} to {new}`)
	end)

	sourceValue.set(1) -- Derived value changed from 0 to 2
	```

	Changelog:
	v0.2.0 (2025-02-12)
	- Changes:
		- Moved documentation to top of file.
	v0.1.0 (2024-09-28)
		- Notes: Release
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local DEFAULT_CHECK_VALUE_FUNCTION: CheckValueFunction<any> = function(value: any)
	return value
end

type CheckValueFunction<T> = (new: T, current: T, old: T) -> T
export type ReactiveValue<T> = {
	changed: Signal.Signal<T, T>,
	check: CheckValueFunction<T>,
	set: (new: T) -> T,
	get: () -> (T, T),
	getCurrent: () -> T,
	observe: (callback: (new: T, old: T) -> ()) -> Signal.Connection,
	destroy: () -> (),
}
export type DerivedReactiveValue<T> = {
	changed: Signal.Signal<T, T>,
	get: () -> (T, T),
	getCurrent: () -> T,
	observe: (callback: (new: T, old: T) -> ()) -> Signal.Connection,
	destroy: () -> (),
}

local module = {}

--[=[
	@param initialValue : `T` The initial value of the ReactiveValue.
	@param checkValue : `(new: T, current: T, old: T) -> T` A function that is called when the value is set. Must return the new value. Will not be called for the initial value.
	@return `ReactiveValue<T>`

	A ReactiveValue is a value that can be observed for changes. When the value changes, the `changed` signal is fired with the new and old values.
]=]
function module.new<T>(initialValue: T, checkValue: ((new: T, current: T, old: T) -> T)?): ReactiveValue<T>
	local check: CheckValueFunction<T> = checkValue or DEFAULT_CHECK_VALUE_FUNCTION

	local reactiveValue = {
		changed = Signal.new() :: Signal.Signal<T, T>,
		check = check,
	}
	local current: T = initialValue
	local old: T = initialValue
	local setting = false

	function reactiveValue.set(new: T): T
		if setting then
			error("Cannot set ReactiveValue while processing a set call")
		end
		setting = true

		new = check(new, current, old)
		old = current
		current = new

		setting = false
		reactiveValue.changed:Fire(new, old)

		return new
	end

	function reactiveValue.getCurrent(): T
		return current
	end

	function reactiveValue.get(): (T, T)
		return current, old
	end

	function reactiveValue.observe(callback: (new: T, old: T) -> ()): Signal.Connection
		callback(current, old)
		return reactiveValue.changed:Connect(callback)
	end

	function reactiveValue.destroy()
		reactiveValue.changed:Destroy()
	end

	return table.freeze(reactiveValue)
end

--[=[
	@param sourceValue : `DerivedReactiveValue<T>` The ReactiveValue to derive from. Can be a ReactiveValue or another derived ReactiveValue.
	@param derive : `(current: T, old: T) -> D` A function that takes the current value and the old value and returns the derived value.
	@return `DerivedReactiveValue<D>`

	Creates a new ReactiveValue dependent on an existing ReactiveValue. The derived value will be updated whenever the source value changes.
	Derived ReactiveValues are similar to ReactiveValues, but they have a limited set of methods. They can be observed and destroyed, but they cannot be set.
]=]
function module.derive<T, D>(sourceValue: DerivedReactiveValue<T>, derive: (current: T, old: T) -> D): DerivedReactiveValue<D>
	local derivedReactiveValue = {
		changed = Signal.new() :: Signal.Signal<D, D>,
	}
	local current: D = derive(sourceValue.get())
	local old: D = current

	local changedConnection = sourceValue.changed:Connect(function(sourceNew, sourceOld)
		old = current
		current = derive(sourceNew, sourceOld)
		derivedReactiveValue.changed:Fire(current, old)
	end)

	function derivedReactiveValue.getCurrent(): D
		return current
	end

	function derivedReactiveValue.get(): (D, D)
		return current, old
	end

	function derivedReactiveValue.observe(callback: (new: D, old: D) -> ()): Signal.Connection
		callback(current, old)
		return derivedReactiveValue.changed:Connect(callback)
	end

	function derivedReactiveValue.destroy()
		changedConnection:Disconnect()
		derivedReactiveValue.changed:Destroy()
	end

	return table.freeze(derivedReactiveValue)
end

return module
