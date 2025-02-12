--[[
	NumberUtil v0.1.0
	Author: Great_Bird
	Date: 2025-02-12
	Last updated: 2025-02-12

	Utilities for working with numbers.

	Changelog:
	v0.1.0 (2025-02-12)
	- Notes: Release
]]

--!native
--!optimize 2

local EPSILON = 1e-10

-- stylua: ignore
local abbreviations = {
	"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dd", "Ud", "Dd", "Td", "Qad", "Qid", 
	"Sxd", "Spd", "Ocd", "Nod", "Vg", "Uvg", "Dvg", "Tvg", "Qavg", "Qivg", "Sxvg", "Spvg", "Ocvg",
}
local powers = {}
for i = 1, #abbreviations do
	powers[i] = 1000 ^ i
end

local module = {}

--[=[
	Rounds a number to a specified number of decimal places.
]=]
local function round(x: number, numDecimals: number?): number
	if not numDecimals then
		return math.round(x)
	end
	local multiplier = 10 ^ numDecimals
	return math.round(x * multiplier) / multiplier
end
module.round = round

--[=[
	Truncates (i.e. floors) a number to a specified number of decimal places.
]=]
local function truncate(x: number, numDecimals: number?): number
	local multiplier = 10 ^ (numDecimals or 0)
	return math.floor(x * multiplier + EPSILON) / multiplier -- add EPSILON to avoid floating point errors
end
module.truncate = truncate

--[=[
	Returns a number formatted as a string with a specified number of decimal places. Leaves off padding zeros.
]=]
local function formatDecimals(x: number, numPreserveDecimals: number): string
	local format = string.format("%." .. numPreserveDecimals .. "f", truncate(x, numPreserveDecimals))
	local truncated = string.gsub(format, "(%..-)0+$", function(match)
		return if #match > 1 then match else ""
	end)
	return truncated
end
module.formatDecimals = formatDecimals

--[=[
	Abbreviates a number to a string with a suffix representing the power of 1000 it is closest to.
]=]
local function abbreviate(x: number): string
	local abs = math.abs(x)
	if abs < 1000 then
		return formatDecimals(x, 3)
	end
	local powerIndex = math.min(math.floor(math.log10(abs) / 3), #abbreviations)
	local rounded = math.floor(abs * 1000) / 1000 / powers[powerIndex] * math.sign(x)
	return formatDecimals(rounded, 3) .. abbreviations[powerIndex]
end
module.abbreviate = abbreviate

return module
