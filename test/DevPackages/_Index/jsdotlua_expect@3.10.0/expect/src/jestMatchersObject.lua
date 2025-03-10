-- ROBLOX upstream: https://github.com/facebook/jest/blob/v28.0.0/packages/expect/src/jestMatchersObject.ts
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  */

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Symbol = LuauPolyfill.Symbol
local Object = LuauPolyfill.Object
local Error = LuauPolyfill.Error
type Partial<T> = any

local getType = require(script.Parent.Parent:WaitForChild('jest-get-type')).getType
local AsymmetricMatcher = require(script.Parent:WaitForChild('asymmetricMatchers')).AsymmetricMatcher

local Types = require(script.Parent:WaitForChild('types'))
type Expect = Types.Expect
type MatcherState = Types.MatcherState
type MatchersObject = Types.MatchersObject

local jestMatchersObject_extracted = require(script.Parent:WaitForChild('jestMatchersObject_extracted'))-- Global matchers object holds the list of available matchers and
-- the state, that can hold matcher specific values that change over time.
-- ROBLOX deviation: extracted JEST_MATCHERS_OBJECT to jestMatchersObject_extracted to avoid circular dependency

local JEST_MATCHERS_OBJECT = jestMatchersObject_extracted.JEST_MATCHERS_OBJECT

-- Notes a built-in/internal Jest matcher.
-- Jest may override the stack trace of Errors thrown by internal matchers.
local INTERNAL_MATCHER_FLAG = Symbol.for_("$$jest-internal-matcher")

-- ROBLOX deviation START: add type alias to reduce deviations
local TypeError = Error
-- ROBLOX deviation END

if not _G[JEST_MATCHERS_OBJECT] then
	local defaultState = {
		assertionCalls = 0,
		expectedAssertionsNumber = nil, -- doesn't have significance in Lua but kept for translation
		isExpectingAssertions = false,
		suppressedErrors = {},
	}

	_G[JEST_MATCHERS_OBJECT] = {
		matchers = {},
		state = defaultState,
	}
end

-- ROBLOX deviation: extracted getState to jestMatchersObject_extracted to avoid circular dependency
local getState = jestMatchersObject_extracted.getState

--[[
	ROBLOX TODO: add default generic param when possible
	original code:
	export const setState = <State extends MatcherState = MatcherState>(
]]
local function setState<State>(state: Partial<State>): ()
	Object.assign(_G[JEST_MATCHERS_OBJECT].state, state)
end

--[[
	ROBLOX TODO: add default generic param when possible
	original code:
	export const getMatchers = <
	  State extends MatcherState = MatcherState,
	>(): MatchersObject<State> => (global as any)[JEST_MATCHERS_OBJECT].matchers;
]]
local function getMatchers(): MatchersObject
	return _G[JEST_MATCHERS_OBJECT].matchers
end

-- ROBLOX deviation: matchers does not have MatchersObject type annotation and expect
-- does not have Expect type annotation
--[[
	ROBLOX TODO: add default generic param when possible
	original code:
	export const setMatchers = <State extends MatcherState = MatcherState>(
]]
local function setMatchers(matchers: MatchersObject, isInternal: boolean, expect: Expect): ()
	for key, matcher in pairs(matchers) do
		-- ROBLOX TODO: assign INTERNAL_MATCHER_FLAG to matchers
		if not isInternal then
			if typeof(matcher) ~= "function" then
				error(
					TypeError.new(
						('expect.extend: `%s` is not a valid matcher. Must be a function, is "%s"'):format(
							tostring(key),
							tostring(getType(matcher))
						)
					)
				)
			end

			local CustomMatcher = {}
			CustomMatcher.__index = CustomMatcher
			setmetatable(CustomMatcher, AsymmetricMatcher)

			CustomMatcher.new = function(inverse: boolean?, ...)
				inverse = if inverse ~= nil then inverse else false
				local self = AsymmetricMatcher.new({ ... }, inverse)
				setmetatable(self, CustomMatcher)
				return self
			end

			CustomMatcher.asymmetricMatch = function(self, other: any)
				local pass = matcher(self:getMatcherContext(), other, unpack(self.sample)).pass

				return if self.inverse then not pass else pass
			end

			CustomMatcher.toString = function(self)
				if self.inverse then
					return string.format("never.%s", key)
				end
				return tostring(key)
			end

			CustomMatcher.getExpectedType = function(self)
				return "any"
			end

			CustomMatcher.toAsymmetricMatcher = function(self)
				local sample = self.sample
				local i = 1
				local printval = ""
				while i < #sample do
					printval = printval .. tostring(sample[i]) .. ", "
					i += 1
				end
				printval = printval .. tostring(sample[i])
				return string.format("%s<%s>", self:toString(), printval)
			end;

			-- ROBLOX deviation start: there is not Object.defineProperty equivalent in Lua
			(expect :: any)[key] = function(...)
				return CustomMatcher.new(false, ...)
			end
			if not expect.never then
				expect.never = {} :: any
			end
			expect.never[key] = function(...)
				return CustomMatcher.new(true, ...)
			end
			-- ROBLOX deviation end
		end
	end

	Object.assign(_G[JEST_MATCHERS_OBJECT].matchers, matchers)
end

return {
	INTERNAL_MATCHER_FLAG = INTERNAL_MATCHER_FLAG,
	getState = getState,
	setState = setState,
	getMatchers = getMatchers,
	setMatchers = setMatchers,
}
