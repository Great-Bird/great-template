--[[
	Weighted v0.1.0
	Author: Great_Bird
	Date: 2025-02-12
	Last updated: 2025-02-12

	Library for weighted random choice systems.
	
	Usage:
	```lua
	local Weighted = require(path.to.Weighted)
	
	local list = Weighted.list {
		Weighted.item(1000, "Common"),
		Weighted.item(100, "Uncommon"),
		Weighted.item(50, "Rare"),
		Weighted.item(10, "Epic"),
		Weighted.item(5, "Legendary"),
		Weighted.item(1, "Mythic"),
	}
	local randomItem = Weighted.choice(list)
	print(randomItem) -- will probably print "Common"
	```

	Changelog:
	v0.1.0
	- Notes: Release
]]

export type Item<T> = { data: T, weight: number }
export type List<T> = { maxWeight: number, items: { Item<T> } }

local module = {}

--[=[
	Returns whether the first item is rarer than the second item.
]=]
local function isRarer<T>(comparedItem: Item<T>, compareTo: Item<T>): boolean
	return comparedItem.weight < compareTo.weight
end
module.isRarer = isRarer

--[=[
	Creates a weighted item with a given weight.
]=]
local function createWeightedItem<T>(weight: number, data: T): Item<T>
	assert(weight % 1 == 0, "Weight must be an integer, got " .. weight)
	return {
		data = data,
		weight = weight,
	}
end
module.item = createWeightedItem

local function parseItem<T>(item: Item<T> | any): Item<T>?
	return if typeof(item) == "table" and item.data ~= nil and typeof(item.weight) == "number" then item else nil
end

local function list<T>(items: { [any]: Item<T> | T }): List<T>
	local itemList = {}
	local maxWeight = 0
	for _, weightedItem in items do
		local item = parseItem(weightedItem) :: Item<T>
		if not item then
			item = createWeightedItem(1, weightedItem :: T)
		end
		table.insert(itemList, item)
		maxWeight += item.weight
	end
	table.sort(itemList, isRarer)
	return {
		items = itemList,
		maxWeight = maxWeight,
	}
end
module.list = list

local function getRandom(
	min: number,
	max: number,
	randomInteger: nil | Random | (min: number, max: number) -> number
): number
	local randomFn: (number, number) -> number = if typeof(randomInteger) == "function"
		then randomInteger
		elseif typeof(randomInteger) == "Random" then function(min: number, max: number): number
			return randomInteger:NextInteger(min, max)
		end
		else math.random
	local rolledNumber = randomFn(min, max)
	assert(
		rolledNumber >= min and rolledNumber <= max,
		"Random function returned a number outside of the specified range"
	)
	assert(rolledNumber % 1 == 0, "Random function returned a non-integer")
	return rolledNumber
end

--[=[
	Chooses a weighted item from the list based on the weight of each item. Higher weights are more likely to be rolled.
	Takes either a Random object, or a random function which should return a random integer between the passed minimum and maximum.
]=]
local function choice<T>(list: List<T>, randomInteger: nil | Random | (min: number, max: number) -> number): T
	local randomWeight = getRandom(0, list.maxWeight, randomInteger)

	local accumulatedWeight = 0
	for _, item in list.items do
		accumulatedWeight += item.weight
		if accumulatedWeight >= randomWeight then
			return item.data
		end
	end

	error("Failed to choose a weighted item")
end
module.choice = choice

return module
