--[[
	ReactiveValue v0.3.0
	Author: Great_Bird
	Date: 2024-09-28
	Last updated: 2025-07-16

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

	The `checkChanged` parameter is run to determine if the value has changed. It should return true if the value has changed, false otherwise.
	By default, it checks for deep equality of tables, and always returns true for frozen tables (even if nested).
	You can use a simpler check if you don't need deep equality:
	```lua
		local function simpleCheckChanged(new, current)
			return new ~= current
		end

		local function logChange(new, old)
			print("Value changed from", old, "to", new)
		end

		local tableA = table.freeze {}
		local tableB = table.freeze {}
		local unfrozenTable = {}

		-- You can also find a function like this at ReactiveValue.checkChangedSimple
		local valueSimple = ReactiveValue.new(tableA, nil, simpleCheckChanged)
		valueSimple.changed:Connect(logChange)
		valueSimple.set(tableB) -- Value changed from {} to {}

		local value = ReactiveValue.new(tableA, nil, ReactiveValue.checkChanged) -- This is the default checkChanged function
		value.changed:Connect(logChange)
		-- This does not result in the `changed` signal being fired
		value.set(tableB)
		-- But this does, because the table is unfrozen and could change later
		value.set(unfrozenTable) -- Value changed from {} to {}
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
	v0.3.0 (2025-07-16)
	- Breaking:
		- Renamed the `check` property of ReactiveValue to `checkValue`.
		- ReactiveValue now uses the `checkValue` property instead of the function passed to the constructor.
	- Added:
		- checkChanged function that checks for deep equality of tables, and always returns true for frozen tables.
		- checkChangedSimple function that checks for simple equality using `~=` operator.
	- Changes:
		- Allowed the user to pass checkChanged as a parameter to constructors.
		- Added checkChanged as a property of ReactiveValue and DerivedReactiveValue.
	v0.2.0 (2025-02-12)
	- Changes:
		- Moved documentation to top of file.
	v0.1.0 (2024-09-28)
		- Notes: Release
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local function equal(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= type(b) then
		return false
	end
	if type(a) == "table" then
		-- Non-frozen tables can change later, which would make them unequal.
		if not table.isfrozen(a) or not table.isfrozen(b) then
			return false
		end

		for key, value in a do
			if not equal(b[key], value) then
				return false
			end
		end

		for key, value in b do
			if not equal(a[key], value) then
				return false
			end
		end

		return true
	end
	return false
end

local DEFAULT_CHECK_VALUE_FUNCTION: CheckValueFunction<any> = function(value: any)
	return value
end
local DEFAULT_CHECK_CHANGED_FUNCTION: CheckChangedFunction<any> = function(new: any, current: any): boolean
	return not equal(new, current)
end

type CheckValueFunction<T> = (new: T, current: T, old: T) -> T
type CheckChangedFunction<T> = (new: T, current: T) -> boolean
export type ReactiveValue<T> = {
	changed: Signal.Signal<T, T>,
	checkValue: CheckValueFunction<T>,
	checkChanged: CheckChangedFunction<T>,
	set: (new: T) -> T,
	get: () -> (T, T),
	getCurrent: () -> T,
	observe: (callback: (new: T, old: T) -> ()) -> Signal.Connection,
	destroy: () -> (),
}
export type DerivedReactiveValue<T> = {
	changed: Signal.Signal<T, T>,
	checkChanged: CheckChangedFunction<T>,
	get: () -> (T, T),
	getCurrent: () -> T,
	observe: (callback: (new: T, old: T) -> ()) -> Signal.Connection,
	destroy: () -> (),
}

local module = {}

--[=[
	@param new : `T` The new value being set.
	@param current : `T` The current value before the change.
	@return boolean

	A function that returns a boolean representing whether the new value is
	different from the current value.
	
	Will check for deep equality of tables, so it can be used to determine if
	the value has changed. Will always return true for unfrozen tables (even if
	nested), as they can change later.
]=]
module.checkChanged = DEFAULT_CHECK_CHANGED_FUNCTION

--[=[
	@param new : `T` The new value being set.
	@param current : `T` The current value before the change.
	@return boolean

	A simple function that returns a boolean representing whether the new value is
	different from the current value, just using the `~=` operator.

	Use this if you don't have the resources to check for deep equality of tables.
]=]
function module.checkChangedSimple<T>(new: T, current: T): boolean
	return new ~= current
end

--[=[
	@param initialValue : `T` The initial value of the ReactiveValue.
	@param checkValueFn : `(new: T, current: T, old: T) -> T` A function that is called when the value is set. Must return the new value. Will not be called for the initial value.
	@param checkChangedFn : `(new: T, current: T, old: T) -> boolean` A function that is called to determine if the value has changed. Must return true if the value has changed, false otherwise.
	@return `ReactiveValue<T>`

	A ReactiveValue is a value that can be observed for changes. When the value changes, the `changed` signal is fired with the new and old values.
]=]
function module.new<T>(initialValue: T, checkValueFn: CheckValueFunction<T>?, checkChangedFn: CheckChangedFunction<T>?): ReactiveValue<T>
	local checkValue: CheckValueFunction<T> = checkValueFn or DEFAULT_CHECK_VALUE_FUNCTION
	local checkChanged: CheckChangedFunction<T> = checkChangedFn or DEFAULT_CHECK_CHANGED_FUNCTION

	local reactiveValue = {
		changed = Signal.new() :: Signal.Signal<T, T>,
		checkValue = checkValue,
		checkChanged = checkChanged,
	}
	local current: T = initialValue
	local old: T = initialValue
	local setting = false

	function reactiveValue.set(new: T): T
		if setting then
			error("Cannot set ReactiveValue while processing a set call")
		end
		setting = true

		new = reactiveValue.checkValue(new, current, old)
		if not reactiveValue.checkChanged(new, current) then
			setting = false
			return current
		end
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
function module.derive<T, D>(sourceValue: DerivedReactiveValue<T>, derive: (current: T, old: T) -> D, checkChangedFn: CheckChangedFunction<D>?): DerivedReactiveValue<D>
	local checkChanged: CheckChangedFunction<D> = checkChangedFn or DEFAULT_CHECK_CHANGED_FUNCTION

	local derivedReactiveValue = {
		changed = Signal.new() :: Signal.Signal<D, D>,
		checkChanged = checkChanged,
	}
	local current: D = derive(sourceValue.get())
	local old: D = current

	local changedConnection = sourceValue.changed:Connect(function(sourceNew, sourceOld)
		old = current
		current = derive(sourceNew, sourceOld)
		if not derivedReactiveValue.checkChanged(current, old) then
			return
		end
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
