-- ROBLOX upstream: https://github.com/facebook/jest/blob/v28.0.0/packages/jest-diff/src/constants.ts
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  */

local NO_DIFF_MESSAGE = "Compared values have no visual difference."

local SIMILAR_MESSAGE = [[Compared values serialize to the same structure.
Printing internal object structure without calling `toJSON` instead.]]

return {
	NO_DIFF_MESSAGE = NO_DIFF_MESSAGE,
	SIMILAR_MESSAGE = SIMILAR_MESSAGE,
}
