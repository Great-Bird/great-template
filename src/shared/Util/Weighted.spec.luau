local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

describe("Weighted", function()
	local Weighted
	local mockData
	local mockWeightedData
	beforeEach(function()
		jest.resetModules()
		Weighted = require(script.Parent.Weighted)

		mockData = {
			highWeight = 3,
			lowWeight = 1,
			mediumWeight = 2,
		}
		mockWeightedData = Weighted.list {
			Weighted.item(mockData.highWeight, mockData.highWeight),
			Weighted.item(mockData.lowWeight, mockData.lowWeight),
			Weighted.item(mockData.mediumWeight, mockData.mediumWeight),
		}
	end)

	describe(".item", function()
		it("creates a weighted item", function()
			local weightedItem = Weighted.item(1, 2)
			expect(weightedItem).toEqual { weight = 1, data = 2 }
		end)

		it("throws if weight is not an integer", function()
			expect(function()
				Weighted.item(1.5, 2)
			end).toThrow()
		end)
	end)

	describe(".isRarer", function()
		it("returns whether the first item is rarer than the second", function()
			local item1 = Weighted.item(1, 1)
			local item2 = Weighted.item(2, 2)
			expect(Weighted.isRarer(item1, item2)).toBe(true)
		end)
	end)

	describe(".list", function()
		it("creates a sorted list of weighted items", function()
			expect(mockWeightedData).toEqual {
				items = { { weight = 1, data = 1 }, { weight = 2, data = 2 }, { weight = 3, data = 3 } },
				maxWeight = 6,
			}
		end)

		it("creates a list of weighted items with default weight of 1", function()
			local weightedData = Weighted.list { 1, 2, Weighted.item(2, 3) }
			expect(weightedData).toEqual {
				items = { { weight = 1, data = 1 }, { weight = 1, data = 2 }, { weight = 2, data = 3 } },
				maxWeight = 4,
			}
		end)

		it("allows dictionaries as inputs", function()
			local weightedData = Weighted.list(mockData :: { [any]: number })
			expect(weightedData).toMatchObject({
				items = expect.any("table"),
				maxWeight = 3,
			})
		end)
	end)

	describe(".choice", function()
		local randomMock, randomInteger = jest.fn(function()
			return 3
		end)
		beforeEach(function()
			randomMock.mockClear()
		end)

		it("chooses an item at random given no random function", function()
			local chosenItem = Weighted.choice(mockWeightedData)
			expect(chosenItem).toBeDefined()
		end)

		it("chooses an item given a random function", function()
			local rolledCoin = Weighted.choice(mockWeightedData, randomInteger)
			expect(randomMock).toHaveBeenCalledWith(0, mockWeightedData.maxWeight)
			expect(rolledCoin).toBe(mockData.mediumWeight)
		end)

		it("throws if the random function returns a number higher than the max weight", function()
			randomMock.mockReturnValueOnce(7)
			expect(function()
				Weighted.choice(mockWeightedData, randomInteger)
			end).toThrow()
		end)

		it("throws if the random function returns a non-integer", function()
			randomMock.mockReturnValueOnce(1.5)
			expect(function()
				Weighted.choice(mockWeightedData, randomInteger)
			end).toThrow()
		end)
	end)
end)
