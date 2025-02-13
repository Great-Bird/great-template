# great-template
A great template to use for Roblox projects.

TODO: Table of contents

## Quick Start

### Tools

To begin, you will need to install [Rokit](https://github.com/rojo-rbx/rokit/releases),
the toolchain manager used for this project template. Rokit is a newer alternative to
Aftman/Foreman which does not require manually typing out manifests for tools.
See https://github.com/rojo-rbx/rokit for documentation and installation instructions.

After you've installed Rokit, if you haven't already, run
```bash
rokit self-install
```
to get the latest version of Rokit. Next, run
```bash
rokit install
```
in the VSCode terminal, and press Y to trust each tool when prompted. This should
install every needed tool for using this project template.

Note: If confused while using CLI tools, you should be able to run them with the
`--help` flag (e.g `rokit --help`) to view usage instructions. Here are some example
usage instructions for Rokit (run in a Git Bash terminal):
```bash
great@Birdnest MINGW64 ~/Documents/GitHub/great-template (main)
$ rokit --help
Next-generation toolchain manager for Roblox projects

Usage: rokit.exe [OPTIONS] [COMMAND]

Commands:
  add           Adds a new tool to Rokit and installs it
  authenticate  Authenticate with an artifact provider, such as GitHub
  init          Initializes a new Rokit project in the current directory
  install       Adds a new tool using Rokit and installs it
  list          Lists all existing tools managed by Rokit
  self-install  Installs / re-installs Rokit, and updates all tool links
  self-update   Updates Rokit to the latest version
  system-info   Prints out information about the current system and installed tools
  trust         Mark the given tool(s) as being trusted
  update        Updates all tools, or specific tools, to the latest version
  help          Print this message or the help of the given subcommand(s)

Options:
  -v, --verbose...
  -h, --help        Print help
  -V, --version     Print version
```

### Configuration

There is a bit of project-specific configuration to do. First, run
```bash
code .lune/config.luau
```
to open up the configuration script (alternatively, you can open it up using the
file explorer). It might look something like this:
```lua
return {
    -- Project-specific options. These are required to be set.
    placeId = 0, -- The place ID of the game to download on `lune run setup import`

    -- File path options. It's fine to leave these at their defaults.
    buildFilePath = "build.rbxlx", -- The path to the build file to write to on `lune run setup import`
    projectFilePath = "default.project.json", -- The path to the project file to serve on `lune run setup`
    sourceCodeDirectoryPath = "src", -- The path to the source code directory
    sourcemapFilePath = "sourcemap.json", -- The path to the rojo sourcemap file
    typeDefinitionsFilePath = "globalTypes.d.luau", -- The path to write the global type definitions file from https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
}
```
Change `placeId` to your game's Roblox place ID. Optionally, change any of the
file paths according to your preference.

### Dependencies

You may have a few tools or packages you'd like to use with this project in mind.

#### Tools
Let's say you want to install [Blink](https://github.com/1Axen/blink), a tool
which automatically generates high-performance Roblox networking code from a file
describing your RemoteEvents. To do this, you can run
```bash
rokit add 1Axen/Blink
```
which will add Blink to your `rokit.toml` and install the tool. Now you're able
to use it in your project!

#### Roblox Packages
Now let's say you're actually something of a performant network code fanatic, and
you want to use [Squash](https://data-oriented-house.github.io/Squash/) to compress
down the data you're sending to your clients even further. To do this, you can add
```toml
Squash = "data-oriented-house/squash@VERSION"
```
to the `[dependencies]` section within `wally.toml`, where `VERSION` is the
latest version of Squash (example: 2.5.0). After running
```lua
lune run install
```
Squash will be downloaded to the `Packages` folder, and now you're ready to blow
the world away by building your crazy efficient networked multiplayer game!

### Final Setup

Now that you hopefully have everything installed, run
```bash
lune run setup import
```
to set everything else up as needed. You should see something like this appear in
the output:
```bash
great@Birdnest MINGW64 ~/Documents/GitHub/great-template (main)
$ lune run setup
✅ Downloaded global type definitions
✅ Installed packages
✅ Added ServerPackages folder
✅ Added DevPackages folder
✅ Created sourcemap
✅ Re-exported package types
✅ Re-exported server package types
✅ Re-exported dev package types
All tasks completed!
The development environment has been set up!
Open build.rbxlx in Roblox Studio and connect with the Rojo plugin to start developing.
🔄 Changes are syncing. Press Ctrl+C to stop.
```
Follow the instructions, and now you're ready to make your game!

Whenever you open this project in VSCode, make sure to run `lune run setup`.
Passing the `import` flag is only necessary if there were changes made in the
main place which you would like to edit with.

Note: The main place (i.e. the one you specified the place ID of in `config.luau`) holds
the source copy of the game's DataModel. Changes to instances in a local file
(such as `build.rbxlx`) will not automatically update the main place. If you want
to make changes to the game's instances, make your changes in the main place, and
run `lune run setup import` and re-open the build file.

If you're curious about what each part of this project structure does, see
[Understanding](#understanding).

## List of Tools Used

### Toolchain
- [`rojo`](https://rojo.space/docs/v7/): Syncs project source code to Roblox Studio, enabling the use of VSCode, Git, and other tools
- [`luau-lsp`](https://github.com/JohnnyMorganz/luau-lsp): CLI for Luau LSP, a language server for Luau. Mainly useful for setting FFlags and displaying type errors.
- [`lune`](https://lune-org.github.io/docs): CLI for running Luau scripts in the terminal. This is required for many of the tools this project template provides. 
- [`wally`](https://github.com/UpliftGames/wally): Package manager which makes it easy to automatically update Roblox packages and libraries used as dependencies of the project. We may decide to replace Wally with [Pesde](https://pesde.dev) in the future when it is more stable.
- [`wally-package-types`](https://github.com/JohnnyMorganz/wally-package-types): Re-exports type definitions provided by Wally packages in linker files. This is helpful for using strict Luau typing.
- [`stylua`](https://github.com/JohnnyMorganz/StyLua): A CLI code formatter for Lua and Luau. This removes the need to format files manually.
- [`selene`](https://kampfkarren.github.io/selene/selene.html): A linter for Lua and Luau. Displays warnings in code when you make common mistakes.

### Recommended VSCode Extensions
- [Rojo](https://marketplace.visualstudio.com/items?itemName=evaera.vscode-rojo): Extension which makes it easy to sync using Rojo without needing the command line. Also helps manage and automatically update the Roblox Studio plugin for Rojo, which is required for it to work.
- [Luau LSP](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.luau-lsp): Support for the Luau language in VSCode. Makes your life easier with great features like autocomplete, type errors, and more.
  - Luau LSP comes with a [companion plugin](https://create.roblox.com/store/asset/10913122509/Luau-Language-Server-Companion) for Roblox Studio which provides autocomplete for Roblox instances in VSCode. It is recommended to install this. Once installed, make sure to set `luau-lsp.plugin.enabled` to `true` in settings.
  - See the [recommended settings for this extension](#recommended-settings-for-luau-lsp)
- [StyLua](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.stylua): Extension for StyLua which makes it easy to set up VSCode to format your code at the press of a keyboard shortcut.
- [Indenticator](https://marketplace.visualstudio.com/items?itemName=SirTori.indenticator) (optional): Highlights your current indent level. If you're the kind of programmer who lives on the edge (of your text editor, because you have code which uses 15 indents), then you'll find this useful.
- [Incredibly In Your Face](https://marketplace.visualstudio.com/items?itemName=VirejDasani.incredibly-in-your-face) (optional): Mr. Incredible will become more and more uncanny as you write more errors in your code. Very effective at motivating you to write less errors.

#### Recommended settings for Luau LSP
The extension for Luau LSP comes with many settings. Without too much commentary, here are some recommended settings to paste into your `settings.json` (which can be opened by typing "Open User Settings (JSON)" in the command palette):
```json
"luau-lsp.completion.autocompleteEnd": true,
"luau-lsp.completion.imports.enabled": true,
"luau-lsp.completion.imports.separateGroupsWithLine": true,
"luau-lsp.hover.multilineFunctionDefinitions": true,
"luau-lsp.inlayHints.typeHintMaxLength": 5000,
"luau-lsp.fflags.override": {
    "LuauAutocompleteDynamicLimits": "false",
    "LuauAutocompleteTableKeysNoInitialCharacter": "true",
    "LuauSolverV2": "false",
    "LuauTarjanChildLimit": "150000",
},
"luau-lsp.inlayHints.functionReturnTypes": true,
"luau-lsp.inlayHints.parameterTypes": true,
"luau-lsp.inlayHints.variableTypes": true,
"luau-lsp.plugin.maximumRequestBodySize": "10mb",
"luau-lsp.ignoreGlobs": [
    "**/_Index/**",
    "**/_Index/../**",
    "*.d.lua",
    "*.d.luau"
],
"luau-lsp.fflags.enableByDefault": true,
"luau-lsp.hover.showTableKinds": true,
"luau-lsp.diagnostics.strictDatamodelTypes": true,
"luau-lsp.plugin.enabled": true,
```

### Roblox Libraries
Some utility libraries which are helpful for Roblox development are installed by default.
You can delete these at your preference, but note that some of them, such as Schedule and Signal, are used in the project template.

#### Game Schedules
TODO: Improve this section

Schedules for commonly used events are provided in SchedulesServer and SchedulesClient.
You can create a job, or code specified to run as part of a schedule. What's useful
is that you can specify a job to occur after other jobs. As such, Schedules differ
from Signals in that they define a consistent order for running code.

The `initialize` and `start` schedules are used in module loading. If you've used
[Knit](https://sleitnick.github.io/Knit/) before, you may be familiar with these
names. Knit is an old Roblox game framework which has [a few problems](https://medium.com/@sleitnick/knit-its-history-and-how-to-build-it-better-3100da97b36).
Here we're adapting one of its useful ideas: modules are given an `initialize`
step, where they can prepare themselves to be required; and then a `start` step,
where they can run any game logic they are concerned with. Modules that implement
these schedules are conventionally called Services (on the server) and Controllers
(on the client).

Here is an example of how schedules simplify code by allowing more assumptions
to be made:

```lua
local SchedulesServer = require(path.to.SchedulesServer)

local ImportantPartService = {}

ImportantPartService.initializeJob = SchedulesServer.start.job(function()
    local importantPart = Instance.new("Part")
    importantPart.Name = "Very important part"
    importantPart.Parent = workspace
end)

return ImportantPartService
```

```lua
local ImportantPartService = require(path.to.ImportantPartService)
local SchedulesServer = require(path.to.SchedulesServer)

local PartPrintingService = {}

PartPrintingService.initializeJob = SchedulesServer.start.job(function()
    print(workspace.ImportantPart) --> "Very important part"
end, ImportantPartService.initializeJob) -- Here we specify that this should run after the part is created by ImportantPartService

return PartPrintingService
```

#### Character Wrapper
CharacterService, CharacterController, and CharacterShared serve as a single point
where commonly used character instances are accessed, and then made easily available
through an interface. They also fire character-related game schedules such as
`loadCharacter`.

The character wrapper aims to eliminate the tired patterns that appear in code
which handles character instances. Here's an example of how those patterns tend
to manifest:

```lua
-- Give each player an anti-gravity force when they spawn

local Players = game:GetService("Players")

local function onCharacterAdded(character: Model)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local rootAttachment = humanoidRootPart:WaitForChild("RootAttachment")

    local force = path.to.AntigravityForce:Clone()
    force.Attachment0 = rootAttachment
    force.Parent = humanoidRootPart
end

local function onPlayerAdded(player: Player)
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
```

Now let's look at how that same code looks using the character wrapper and schedules:
```lua
-- Give each player an anti-gravity force when they spawn

local SchedulesServer = require(path.to.SchedulesServer)

SchedulesServer.loadCharacter.job(function(instances, player)
    local force = path.to.AntigravityForce:Clone()
    force.Attachment0 = instances.rootPart.RootAttachment
    force.Parent = instances.rootPart
end)
```

The second is obviously much more concise. Using some sort of character wrapper
is a no-brainer. Another benefit of this approach is that if we start commonly
using another character instance which we didn't add to the `instances` table,
we can just modify the character wrapper to include it as well!

Imagine if we were using patterns akin to the first example
throughout the whole game! Unfortunately, that reality is quite common in many
codebases.

#### List of utility libraries
- AssertInstance: Makes it easy to validate that an instance has the correct state. Writes high-quality error messages for you.
- Loader: Bootloader for modules. Supports match and ignore globs.
- NumberUtil: Extra math functions and utilities for formatting numbers.
- RandomPoint: Get uniformly random points inside of primitive parts.
- ReactiveValue: Simple reactive state management through Value Instance-like objects.
- Schedule: Define routines in which game code runs in a defined sequence.
- SFXUtil: Easily play sounds and cross-fade music without needing to write configuration code for common use cases.
- Spring: Continuous, configurable spring-like motion for use in UI and 2D and 3D animations.
- State: Table-driven, flexible state machine implementation. Makes it easy to convert from a state graph to code or vice versa.
- TableUtil: Extra table functions.
- Tagged: CollectionService utility library enabling high-performance code which interacts with tagged instances by using cached collections. Provides shorthands for many common use cases.
- VFXUtil: Easily play visual effects and tween model pivots and scales.
- Weighted: Library for weighted random choice systems.

#### List of Roblox packages
- howmanysmall/Janitor: Garbage collection made easy and ergonomic.
- sleitnick/Signal: Create your own events using an API that mirrors RBXScriptSignal.

## Style Guide

In addition to using StyLua as a code formatter, here are some extra guidelines
to follow to keep your code looking clean and easy to read.

### Casing
Generally, you can follow these guidelines for casing:
1. Dependencies and imports (services, libraries, static instance paths, shorthands) use the same case as the name of the dependency or import.
2. Configuration constants use SCREAMING_SNAKE_CASE.
3. Type definitions use PascalCase.
4. Exports (the return values from modules) use PascalCase if the value is a namespace (i.e. a table), or camelCase otherwise.
5. Everything else uses camelCase.

### Script Structure
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

## Understanding
TODO

### What does each file do?
TODO