--[[
	TableUtil v0.1.0
	Author: Great_Bird
	Date: 2025-02-12
	Last updated: 2025-02-12

	Table utilities for Luau.
	For performance reasons, this library generally does not treat tables as immutable.
	If you need immutability, consider using `table.clone`, `table.freeze`, and `TableUtil.deepCopy`.

	Changelog:
	v0.1.0 (2025-02-12)
	- Notes: Release
]]

--!strict
--!native
--!optimize 2

export type RandomFn = (min: number, max: number) -> number

local getRandom: RandomFn
do
	local random = Random.new()
	getRandom = function(min, max)
		return random:NextInteger(min, max)
	end
end

local module = {}

--[=[
	Compares two strings, returning true if a < b, according to shortlex order.
	For example, "Part1" < "Part2" < "Part10".
	Intended to be used in `table.sort`.
	https://en.wikipedia.org/wiki/Lexicographic_order#Definition
]=]
local function compareLexic(a: string, b: string)
	local aLength, bLength = string.len(a), string.len(b)
	if aLength ~= bLength then
		return aLength < bLength
	end
	for index = 1, math.max(aLength, bLength) do
		local aByte = string.byte(string.sub(a, index, index))
		local bByte = string.byte(string.sub(b, index, index))
		if aByte ~= bByte then
			return aByte < bByte
		end
	end
	return true
end
module.compareLexic = compareLexic

--[=[
	Maps each element of the array to `fn`.
]=]
local function mapArray<T, U>(tbl: { T }, fn: (value: T, index: number) -> U): { U }
	local mapped = table.create(#tbl)
	for i, v in tbl do
		table.insert(mapped, fn(v, i))
	end
	return mapped
end
module.mapArray = mapArray

--[=[
	Calls `fn` with `accumulator` for every element of the array, and then returns `accumulator`. 
]=]
local function reduceArray<T, U>(tbl: { T }, accumulator: U, fn: (accumulator: U, value: T, index: number) -> U): U
	for i, v in tbl do
		accumulator = fn(accumulator, v, i)
	end
	return accumulator
end
module.reduceArray = reduceArray

--[=[
	Returns a new array which does not include any elements that `predicate` returns false for. 
]=]
local function filterArray<T>(tbl: { T }, predicate: (value: T, index: number) -> boolean): { T }
	local filtered = table.create(#tbl)
	for i, v in tbl do
		if predicate(v, i) then
			table.insert(filtered, i, v)
		end
	end
	return filtered
end
module.filterArray = filterArray

--[=[
	Randomly shuffles the table using https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
]=]
local function shuffleArray<T>(tbl: { T }, randomFn: RandomFn?): { T }
	local random: RandomFn = randomFn or getRandom
	for i = 1, #tbl - 1 do
		local randomIndex = random(i + 1, #tbl)
		tbl[i], tbl[randomIndex] = tbl[randomIndex], tbl[i]
	end
	return tbl
end
module.shuffleArray = shuffleArray

--[=[
	Gets the values of `tbl` as an array.
]=]
local function values<T>(tbl: { [any]: T }): { T }
	local valueList = table.create(#tbl)
	for _, value in tbl do
		table.insert(valueList, value)
	end
	return valueList
end
module.values = values

--[=[
	Gets the keys of `tbl` as an array.
]=]
local function keys<T>(tbl: { [T]: any }): { T }
	local keysList = table.create(#tbl)
	for key in tbl do
		table.insert(keysList, key)
	end
	return keysList
end
module.keys = keys

--[=[
	Returns a new table with the keys and values of `tbl` swapped.
]=]
local function invert<K, T>(tbl: { [K]: T }): { [T]: K }
	local inverted = {}
	for k, v in tbl do
		inverted[v] = k
	end
	return inverted
end
module.invert = invert

--[=[
	Returns a subarray of `tbl`.
]=]
local function sliceArray<T>(tbl: { T }, startIndex: number, endIndex: number): { T }
	return table.move(tbl, startIndex, endIndex, 1, table.create(endIndex - startIndex + 1))
end
module.sliceArray = sliceArray

--[=[
	Clones the table, and recursively clones nested tables.
]=]
local function deepCopy<T>(tbl: T & { [any]: any }): T
	local copy: any = table.clone(tbl)
	for k, v in copy do
		copy[k] = if type(v) == "table" then deepCopy(v) else v
	end
	return copy :: T
end
module.deepCopy = deepCopy

--[=[
	Freezes the table, and recursively freezes nested tables.
]=]
local function deepFreeze<T>(tbl: T & { [any]: any }): T
	table.freeze(tbl)
	for _, v in tbl :: { [any]: any } do
		if type(v) == "table" then
			deepFreeze(v)
		end
	end
	return tbl
end
module.deepFreeze = deepFreeze

--[=[
	Returns whether all of `tbl`'s fields and values are contained identically in `source`. Compares nested tables by reference.
	Returns true for improper subsets where the tables have equal contents.
]=]
local function isSubsetShallow(tbl: { [any]: any }, source: { [any]: any }): boolean
	for k, v in tbl do
		if source[k] ~= v then
			return false
		end
	end
	return true
end
module.isSubsetShallow = isSubsetShallow

--[=[
	Returns whether all of `tbl`'s fields and values are contained identically in `source`, recursing for nested tables.
	Returns true for improper subsets where the tables have equal contents.
]=]
local function isSubsetDeep(tbl: { [any]: any }, source: { [any]: any }): boolean
	for k, v1 in tbl do
		local v2 = source[k]
		if v1 ~= v2 then
			if type(v1) == "table" and type(v2) == "table" then
				if not isSubsetDeep(v1, v2) then
					return false
				end
			else
				return false
			end
		end
	end
	return true
end
module.isSubsetDeep = isSubsetDeep

--[=[
	Returns a new table containing the fields and values that are present in both `tbl1` and `tbl2`.
]=]
local function intersect(tbl1: { [any]: any }, tbl2: { [any]: any }): { [any]: any }
	local result = {}
	for k, v in tbl1 do
		if tbl2[k] == v then
			result[k] = v
		end
	end
	return result
end
module.intersect = intersect

--[=[
	Returns a new array containing the elements that are present in both `tbl1` and `tbl2`.
]=]
local function intersectArrays(tbl1: { any }, tbl2: { any }): { any }
	local result = {}
	for _, v in tbl1 do
		if table.find(tbl2, v) then
			table.insert(result, v)
		end
	end
	return result
end
module.intersectArrays = intersectArrays

--[=[
	Returns whether the two tables have the same fields and values. Compares nested tables by reference.
]=]
local function equalsShallow(tbl1: { [any]: any }, tbl2: { [any]: any }): boolean
	return isSubsetShallow(tbl1, tbl2) and isSubsetShallow(tbl2, tbl1)
end
module.equalsShallow = equalsShallow

--[=[
	Returns whether the two tables have the same fields and values, recursing for nested tables.
]=]
local function equalsDeep(tbl1: { [any]: any }, tbl2: { [any]: any }): boolean
	return isSubsetDeep(tbl1, tbl2) and isSubsetDeep(tbl2, tbl1)
end
module.equalsDeep = equalsDeep

--[=[
	Returns a new array containing every element of the passed arrays, in order of the arguments.
]=]
local function mergeArrays<T>(...: { T }): { T }
	local arrays = { ... }

	-- Calculate the size of the merged array first so it can be passed to `table.create`
	local mergedArraySize = 0
	for _, array in arrays do
		mergedArraySize += #array
	end

	local result = table.create(mergedArraySize)
	for _, array in arrays do
		table.move(array, 1, #array, #result + 1, result)
	end
	return result
end
module.mergeArrays = mergeArrays

--[=[
	Applies each entry in each passed table to a new table, in the order they were passed.
]=]
local function mergeTables(...: { [any]: any }): { [any]: any }
	local result = {}
	for _, tbl in { ... } do
		for k, v in tbl do
			result[k] = v
		end
	end
	return result
end
module.merge = mergeTables

--[=[
	Returns a random value from the array.
]=]
local function pickArray<T>(tbl: { T }, randomFn: RandomFn?): T
	local random = randomFn or getRandom
	return tbl[random(1, #tbl)]
end
module.pickArray = pickArray

--[=[
	Returns a random value from the dictionary.
]=]
local function pickDict(tbl: { [any]: any }, randomFn: RandomFn?)
	local random = randomFn or getRandom
	local keys = {}
	for key, _ in tbl do
		table.insert(keys, key)
	end
	return tbl[keys[random(1, #keys)]]
end
module.pickDict = pickDict

--[=[
	Returns `count` random values from the array.
	The resulting array size will not exceed the size of `tbl`.
]=]
local function sampleArray<T>(tbl: { T }, count: number, randomFn: RandomFn?): { T }
	local sample: { T } = table.create(count)
	local shuffled = shuffleArray(table.clone(tbl))
	for i = 1, count do
		table.insert(sample, table.remove(shuffled) :: any)
	end
	return sample
end
module.sampleArray = sampleArray

--[=[
	Returns the first key of the dictionary that has the passed value, or nil if none are found.
]=]
local function findDict(tbl: { [any]: any }, value: any): any
	for k, v in tbl do
		if v == value then
			return k
		end
	end
	return nil
end
module.findDict = findDict

--[=[
	Returns the value of the first entry with the passed key.
	This function searches recursively.
]=]
local function findKeyDeep(tbl: { [any]: any }, key: any): any
	for k, v in tbl do
		if k == key then
			return v
		elseif type(v) == "table" then
			local result = findKeyDeep(v, key)
			if result then
				return result
			end
		end
	end
	return nil
end
module.findKeyDeep = findKeyDeep

--[=[
	Reverses the order of the passed array, so last elements come first, and vice versa.
]=]
local function reverseArray<T>(tbl: { T }): { T }
	for i = 1, math.floor(#tbl / 2) do
		local j = #tbl - i + 1
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end
module.reverseArray = reverseArray

--[=[
	Fills in the fields missing in `tbl` with the fields in `template`.
]=]
local function reconcile<T, U>(tbl: T, template: U): T & U
	assert(type(tbl) == "table", "tbl must be a table")
	assert(type(template) == "table", "template must be a table")
	for k, v in template do
		if not tbl[k] then
			tbl[k] = v
		end
	end
	return tbl
end
module.reconcile = reconcile

--[=[
	Returns a new table which has the values of `tbl` as keys and `true` as values.
]=]
local function toSet<T>(tbl: { T }): { [T]: boolean }
	local set = {}
	for _, v in tbl do
		set[v] = true
	end
	return set
end
module.toSet = toSet

--[=[
	Flattens an array of arrays into a single array.
]=]
local function flattenArray<T>(tbl: { { T } }): { T }
	local flattened = {}
	for _, v in tbl do
		if type(v) == "table" then
			for _, v2 in v do
				table.insert(flattened, v2)
			end
		else
			table.insert(flattened, v)
		end
	end
	return flattened
end
module.flattenArray = flattenArray

--[=[
	Maps each element of the array to `fn`, and then flattens the resulting arrays into a single array.
]=]
local function flatMapArray<T, U>(tbl: { T }, fn: (value: T, index: number) -> { U }): { U }
	return flattenArray(mapArray(tbl, fn))
end
module.flatMapArray = flatMapArray

-- stylua: ignore
local zipTables:
	& <K, T1>({[K]: T1}) -> () -> (K, T1)
	& <K, T1, T2>({[K]: T1}, {[K]: T2}) -> () -> (K, T1, T2)
	& <K, T1, T2, T3>({[K]: T1}, {[K]: T2}, {[K]: T3}) -> () -> (K, T1, T2, T3)
	& <K, T1, T2, T3, T4>({[K]: T1}, {[K]: T2}, {[K]: T3}, {[K]: T4}) -> () -> (K, T1, T2, T3, T4)
	& <K, T1, T2, T3, T4, T5>({[K]: T1}, {[K]: T2}, {[K]: T3}, {[K]: T4}, {[K]: T5}) -> () -> (K, T1, T2, T3, T4, T5)
	& <K, T1, T2, T3, T4, T5, T6>({[K]: T1}, {[K]: T2}, {[K]: T3}, {[K]: T4}, {[K]: T5}, {[K]: T6}) -> () -> (K, T1, T2, T3, T4, T5, T6)
	& <K, T1, T2, T3, T4, T5, T6, T7>({[K]: T1}, {[K]: T2}, {[K]: T3}, {[K]: T4}, {[K]: T5}, {[K]: T6}, {[K]: T7}) -> () -> (K, T1, T2, T3, T4, T5, T6, T7)
	& <K, T1, T2, T3, T4, T5, T6, T7, T8>({[K]: T1}, {[K]: T2}, {[K]: T3}, {[K]: T4}, {[K]: T5}, {[K]: T6}, {[K]: T7}, {[K]: T8}) -> () -> (K, T1, T2, T3, T4, T5, T6, T7, T8)
	& <K, T1, T2, T3, T4, T5, T6, T7, T8, T9>({[K]: T1}, {[K]: T2}, {[K]: T3}, {[K]: T4}, {[K]: T5}, {[K]: T6}, {[K]: T7}, {[K]: T8}, {[K]: T9}) -> () -> (K, T1, T2, T3, T4, T5, T6, T7, T8, T9)
	& <K, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10>({[K]: T1}, {[K]: T2}, {[K]: T3}, {[K]: T4}, {[K]: T5}, {[K]: T6}, {[K]: T7}, {[K]: T8}, {[K]: T9}, {[K]: T10}) -> () -> (K, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10)
zipTables = function(...: { [any]: any }): () -> (any, ...any)
	assert(select("#", ...) > 0, "Must pass at least one table")

	local firstTable = select(1, ...)
	local numTables = select("#", ...)
	local otherTables = { select(2, ...) }
	local currentKey = nil
	return function()
		local firstValue
		currentKey, firstValue = next(firstTable, currentKey)
		while currentKey ~= nil do
			local values = { firstValue }

			for i, otherTable in otherTables do
				local currentValue = otherTable[currentKey]
				if currentValue == nil then
					break
				end
				values[i] = currentValue
			end

			if #values == numTables then
				return currentKey, table.unpack(values)
			end

			currentKey, firstValue = next(firstTable, currentKey)
		end
		return nil
	end
end :: any
--[=[
	Returns an iterator function which returns the values of each shared key in the passed tables.
]=]
module.zipTables = zipTables

return module
