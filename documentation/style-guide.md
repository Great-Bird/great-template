# Style Guide

In addition to using StyLua as a code formatter, here are some extra guidelines
to follow to keep your code looking clean and easy to read.

## Casing
Generally, you can follow these guidelines for casing:
1. Dependencies and imports (services, libraries, static Instance paths, shorthands) use the same case as the name of the dependency or import.
2. Configuration constants use SCREAMING_SNAKE_CASE.
3. Type definitions use PascalCase.
4. Exports (the return values from modules) use PascalCase if the value is a namespace (i.e. a table), or camelCase otherwise.
5. Everything else uses camelCase.

## Script Structure
Below is a code block demonstrating the sections files in this project template
are usually organized into.
Note that the comments marking sections (e.g. `-- Documentation`) are purely for
example, and it is preferable not to write them.
```lua
-- Documentation (if needed to explain the file, such as for reusable libraries)
-- Dates are in ISO format
--[[
    MyLibrary v1.2.1
    Author: Great_Bird
    Date: 2025-02-12
    Last updated: 2025-02-12
  
    Cool stuff goes in this library.
  
    Usage:
    print(MyLibrary.thumbsups) --> 2
    MyLibrary.giveCompliment() --> "you are super cool"
    MyLibrary.spawnMonsters(5)
  
    Changelog:
    v1.2.1
    - Changes:
        - The default value for `MyLibrary.thumbsups` is now anatomically correctly set to 2, down from 3.
    v1.2.0
    - Additions:
        - Added `MyLibrary.thumbsups` field.
    v1.1.0
    - Fixes:
        - `MyLibrary.giveCompliment` now compliments the user instead of telling them they have bad hair
    v1.0.0
    - Notes: Release
]]

-- Comment directives
--!strict
--!optimize 2

-- Services (PascalCase)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies (same casing as the way the dependencies are named)
-- Should be alphabetically sorted. StyLua can be configured to do this for you.
local MonsterRegistry = require(ReplicatedStorage.Shared.MonsterRegistry)
local Tagged = require(ReplicatedStorage.Util.Tagged)
local TagRegistry = require(ReplicatedStorage.Shared.TagRegistry)

-- Imports and shorthands (same casing as the way the imports are named)
local monsterTags = TagRegistry.monsterTags
local getTagged = Tagged.get

-- Configuration constants (SCREAMING_SNAKE_CASE).
-- Constants should never be set after they are defined. Additionally, they should
-- provide some sort of clarification on what they control.
local MAX_MONSTERS = 10  -- Max number of spawned monsters

-- Type definitions (PascalCase)
export type MonsterState = {
    model: Model,
    damage: number,
    health: number,
}

-- Variables and state (camelCase)
local monsters: { MonsterState } = {}

-- Independent functions (camelCase names and parameters)
local function outputWarn(message: string)
    warn(`[MyLibrary]: {message}`)
end

-- File code and exports
-- Return value is simply called "module" instead of reflecting the name of the file.
-- If you want to name it after the file name, use the same casing as the file name.
local module = {
    thumbsups = 2, -- Exported property (camelCase)
}

-- Exported functions (camelCase names and parameters)

-- Moonwave documentation comments should be put before each function. Luau LSP
-- can display this documentation when the user hovers over a reference to the function
--[=[
    Spawns random monsters. Does not spawn any more than MAX_MONSTERS.

    @param monsterCount (number) The number of monsters to spawn.
]=]
function module.spawnMonsters(monsterCount: number)
    if #monsters == MAX_MONSTERS then
        outputWarn("Could not spawn any monsters because the maximum monsters has been reached")
        return
    end

    for i = #monsters + 1, math.min(MAX_MONSTERS, monsterCount) do
        local monsterTag = monsterTags[math.random(1, #monsterTags)]

        local model = MonsterRegistry.getModelForMonsterTag(monsterTag):Clone()
        model.Parent = workspace
        model:AddTag(monsterTag)

        table.insert(monsters, {
            model = model,
            health = math.random(80, 120),
            damage = math.random(10, 16),
        })
    end
end

--[=[
    Outputs a compliment for the user.
]=]
function module.giveCompliment()
    print("you are super cool")
end

-- Module return
return module
```
