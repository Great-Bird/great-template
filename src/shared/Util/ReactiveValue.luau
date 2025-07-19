--[[
	ReactiveValue v0.4.0
	Author: Great_Bird
	Date: 2024-09-28
	Last updated: 2025-07-19

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

	You can also derive a new ReactiveValue from an existing one.
	The derived value will update whenever the source value has changed.
	```lua
	local value = ReactiveValue.new(0)
	local derivedValue = ReactiveValue.derive(function(use)
		-- Note that within the `derive` function, you must use the `use` function to access ReactiveValues.
		-- Do not call `get()` on ReactiveValues directly, as this will not register dependencies correctly.
		return use(value) * 2
	end)
	local connection = derivedValue.changed:Connect(function(new, old)
		print("Derived value changed from", old, "to", new)
	end)
	value.set(1) -- Derived value changed from 0 to 2
	value.set(2) -- Derived value changed from 2 to 4
	```

	Changelog:
	v0.4.0 (2025-07-19)
	- Breaking:
		- Changed ReactiveValue.derive to take a function that registers dependencies with a `use` function.
			- This allows for dependency tracking and the ability to derive from multiple ReactiveValues.
	v0.3.0 (2025-07-16)
	- Breaking:
		- Renamed the `check` property of ReactiveValue to `checkValue`.
		- ReactiveValue now uses the `checkValue` property instead of the function passed to the constructor.
		- ReactiveValue and DerivedReactiveValue are no longer frozen tables.
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

export type CheckValueFunction<T> = (new: T, current: T, old: T) -> T
export type CheckChangedFunction<T> = (new: T, current: T) -> boolean

export type Use = <V>(value: ReactiveValue<V>) -> V
export type DerivedReactiveValue<T> = {
	changed: Signal.Signal<T, T>,
	checkChanged: CheckChangedFunction<T>,
	get: () -> (T, T),
	getCurrent: () -> T,
	observe: (callback: (new: T, old: T) -> ()) -> Signal.Connection,
	destroy: () -> (),
}
export type ReactiveValue<T> = DerivedReactiveValue<T> & {
	checkValue: CheckValueFunction<T>,
	set: (new: T) -> T,
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
function module.new<T>(
	initialValue: T,
	checkValueFn: CheckValueFunction<T>?,
	checkChangedFn: CheckChangedFunction<T>?
): ReactiveValue<T>
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

	return reactiveValue
end

--[=[
	@param derive : `(use: Use) -> T` A function that takes a `Use` function and returns the derived value. Must use the `use` function instead of using `get()` on ReactiveValues.
	@param checkChangedFn : `(new: T, current: T) -> boolean` A function that is called to determine if the value has changed. Must return true if the value has changed, false otherwise.
	@return `DerivedReactiveValue<T>`

	Creates a new ReactiveValue derived from existing ones. The derived value will be updated whenever the source value(s) change.

	Warning: You must use the `use` function to access ReactiveValues within the `derive` function. Do not call `get()` on ReactiveValues directly, as this will not register dependencies correctly.
]=]
function module.derive<T>(
	derive: (use: Use) -> T,
	checkChangedFn: CheckChangedFunction<T>?
): DerivedReactiveValue<T>
	local checkChanged: CheckChangedFunction<T> = checkChangedFn or DEFAULT_CHECK_CHANGED_FUNCTION

	local dependencies: { ReactiveValue<any> } = {}

	local derivedReactiveValue = {
		changed = Signal.new() :: Signal.Signal<T, T>,
		checkChanged = checkChanged,
	}
	local current: T = derive(function(value: ReactiveValue<any>)
		if not table.find(dependencies, value) then
			table.insert(dependencies, value)
		end
		return value.getCurrent()
	end)
	local old: T = current
	local pendingCalculate = false
	local calculating = false

	local function use<V>(value: ReactiveValue<V>): V
		return value.getCurrent()
	end

	local function recalculate()
		if calculating then
			error(`Cannot recalculate DerivedReactiveValue while already calculating. This is likely a circular dependency issue.`)
		end
		calculating = true

		local new = derive(use)
		if not checkChanged(new, current) then
			return
		end
		old = current
		current = new
		pendingCalculate = false
		calculating = false

		derivedReactiveValue.changed:Fire(new, old)
	end

	local function consumeChange()
		if pendingCalculate then
			recalculate()
		end
	end

	local function registerChange()
		if not pendingCalculate then
			task.defer(consumeChange) -- Defer to allow all changes to be registered before recalculating
		end
		pendingCalculate = true
	end

	local changedConnections: { [ReactiveValue<T>]: Signal.Connection } = {}
	for _, dependency in dependencies do
		changedConnections[dependency] = dependency.changed:Connect(registerChange)
	end

	local function get()
		if pendingCalculate then
			recalculate()
		end
		return current, old
	end

	function derivedReactiveValue.getCurrent(): T
		return (get())
	end

	derivedReactiveValue.get = get

	function derivedReactiveValue.observe(callback: (new: T, old: T) -> ()): Signal.Connection
		callback(get())
		return derivedReactiveValue.changed:Connect(callback)
	end

	function derivedReactiveValue.destroy()
		for _, connection in changedConnections do
			connection:Disconnect()
		end
		table.clear(changedConnections)
		derivedReactiveValue.changed:Destroy()
	end

	return derivedReactiveValue
end

return module
