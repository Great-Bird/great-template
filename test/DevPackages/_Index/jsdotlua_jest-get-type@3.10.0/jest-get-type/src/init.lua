-- ROBLOX upstream: https://github.com/facebook/jest/blob/v28.0.0/packages/jest-get-type/src/index.ts
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  */

local LuauPolyfill = require(script.Parent:WaitForChild('luau-polyfill'))
local Error = LuauPolyfill.Error
local instanceof = LuauPolyfill.instanceof
local RegExp
local Set = LuauPolyfill.Set
local Map = LuauPolyfill.Map

--[[
	ROBLOX deviation: checks for Roblox builtin data types
	https://developer.roblox.com/en-us/api-reference/data-types
]]
local function isRobloxBuiltin(value: any): boolean
	return type(value) ~= typeof(value)
end

local function getType(value: any): string
	--[[
		ROBLOX deviation: code omitted because lua has no primitive undefined type
		lua makes no distinction between null and undefined so we just return nil
	]]
	if value == nil then
		return "nil"
	end
	if typeof(value) == "boolean" then
		return "boolean"
	end
	if typeof(value) == "function" then
		return "function"
	end
	if typeof(value) == "number" then
		return "number"
	end
	if typeof(value) == "string" then
		return "string"
	end
	if typeof(value) == "DateTime" then
		return "DateTime"
	end
	if typeof(value) == "userdata" and tostring(value):match("Symbol%(.*%)") then
		return "symbol"
	end
	if typeof(value) == "table" then
		local ok, hasRegExpShape = pcall(function()
			return typeof(value.test) == "function" and typeof(value.exec) == "function"
		end)
		if ok and hasRegExpShape then
			RegExp = require(script.Parent:WaitForChild('luau-regexp'))
			
if instanceof(value, RegExp) then
				return "regexp"
			end
		end
	end
	if instanceof(value, Error) then
		return "error"
	end
	if instanceof(value, Map) then
		return "map"
	end
	if instanceof(value, Set) then
		return "set"
	end
	--[[
		ROBLOX deviation: lua makes no distinction between tables, arrays, and objects
		we always return table here and consumers are expected to perform the check
	]]
	if typeof(value) == "table" then
		return "table"
	end

	--[[
		ROBLOX deviation: returns name of Roblox datatype
		https://developer.roblox.com/en-us/api-reference/data-types
	]]
	if isRobloxBuiltin(value) then
		return typeof(value)
	end

	-- ROBLOX deviation: added luau types for userdata and thread
	if type(value) == "userdata" then
		return "userdata"
	end
	if typeof(value) == "thread" then
		return "thread"
	end
	-- ROBLOX deviation: code omitted because lua has no primitive bigint type
	-- ROBLOX deviation: code omitted because lua makes no distinction between tables, arrays, and objects

	-- ROBLOX deviation: include the type in the error message
	error(string.format("value of unknown type: %s (%s)", typeof(value), tostring(value)))
end

local function isPrimitive(value: any): boolean
	-- ROBLOX deviation: explicitly define objects and functions and Instances as non primitives
	return typeof(value) ~= "table" and typeof(value) ~= "function" and not isRobloxBuiltin(value)
end

return {
	getType = getType,
	isPrimitive = isPrimitive,
	isRobloxBuiltin = isRobloxBuiltin,
}
