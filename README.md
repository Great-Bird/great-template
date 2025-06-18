# great-template
A great template to use for Roblox projects.

## Table of Contents

- [great-template](#great-template)
  - [Table of Contents](#table-of-contents)
  - [Quick Start](#quick-start)
    - [Tools](#tools)
    - [Configuration](#configuration)
    - [Dependencies](#dependencies)
      - [Tools](#tools-1)
      - [Roblox Packages](#roblox-packages)
    - [Final Setup](#final-setup)
  - [List of Tools Used](#list-of-tools-used)
    - [Toolchain](#toolchain)
    - [Recommended VSCode Extensions](#recommended-vscode-extensions)
    - [Roblox Libraries](#roblox-libraries)
      - [Game Schedules](#game-schedules)
      - [Character Wrapper](#character-wrapper)
      - [List of utility libraries](#list-of-utility-libraries)
      - [List of Roblox packages](#list-of-roblox-packages)
  - [Style Guide](#style-guide)
  - [Understanding](#understanding)
    - [What does each file do?](#what-does-each-file-do)

## Quick Start

### Tools

To begin, you will need to install [Rokit](https://github.com/rojo-rbx/rokit/releases),
the toolchain manager used for this project template. Rokit is a newer alternative to
Aftman/Foreman which does not require manually typing out manifests for tools.
See https://github.com/rojo-rbx/rokit for documentation and installation instructions.

After you've installed Rokit, if you haven't already, run
```bash
rokit self-update
```
to get the latest version of Rokit. Next, run
```bash
rokit install
```
in the VSCode terminal, and press Y to trust each tool when prompted. This should
install every needed tool for using this project template.

Note: If confused while using CLI tools, you should be able to run them with the
`--help` flag (e.g. `rokit --help`) to view usage instructions. Here are some example
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

You may have a few tools or packages in mind which you would like to use in this
project.

#### Tools
Let's say you want to install [Blink](https://github.com/1Axen/blink), a CLI tool
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
down the data you're sending to your clients even further. To do this, you can
open `pesde.toml`, and under the `[dependencies]` section, add
```toml
Squash = { wally = "data-oriented-house/squash", version = "VERSION" }
```
where `VERSION` is the latest version of Squash (example: 2.5.0). After running
```bash
lune run install
```
Squash will be downloaded to the `roblox_packages` folder, and now you're ready
to blow the world away by building your crazy efficient networked multiplayer
game!

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
✅ Created sourcemap
All tasks completed!
The development environment has been set up!
Warning: build.rbxlx does not exist. It's recommended to run with the 'import' flag to ensure the latest version of the main place is imported.
🔄 Changes are syncing. Press Ctrl+C to stop.
```
Follow the instructions, and now you're ready to make your game!

Whenever you open this project in VSCode, make sure to run `lune run setup`.
Passing the `import` flag is only necessary if there were changes made in the
main place which you would like to edit with.

Note: The main place (i.e. the one you specified the place ID of in `config.luau`) holds
the source copy of the game's DataModel. Changes to Instances in a local file
(such as `build.rbxlx`) will not automatically update the main place. If you want
to make changes to the game's Instances, make your changes in the main place, and
run `lune run setup import` and re-open the build file.

If you're curious about what each part of this project structure does, see
[Understanding](#understanding).

## List of Tools Used

### Toolchain
- [`rokit`](https://github.com/rojo-rbx/rokit): Toolchain manager which allows for quickly downloading and updating tools.
- [`rojo`](https://rojo.space/docs/v7/): Syncs project source code to Roblox Studio, enabling the use of VSCode, Git, and other tools.
- [`luau-lsp`](https://github.com/JohnnyMorganz/luau-lsp): CLI for Luau LSP, a language server for Luau. Mainly useful for setting FFlags and displaying type errors.
- [`lune`](https://lune-org.github.io/docs): CLI for running Luau scripts in the terminal. This is required for many of the tools this project template provides. 
- [`pesde`](https://github.com/pesde-pkg/pesde): Package manager which makes it easy to automatically update Roblox packages and libraries used as dependencies of the project.
- [`stylua`](https://github.com/JohnnyMorganz/StyLua): A CLI code formatter for Lua and Luau. This removes the need to format files manually.
- [`selene`](https://kampfkarren.github.io/selene/selene.html): A linter for Lua and Luau. Displays warnings in code when you make common mistakes.

### Recommended VSCode Extensions
- [Rojo](https://marketplace.visualstudio.com/items?itemName=evaera.vscode-rojo): Extension which makes it easy to sync using Rojo without needing the command line. Also helps manage and automatically update the Roblox Studio plugin for Rojo, which is required for it to work.
- [Luau LSP](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.luau-lsp): Support for the Luau language in VSCode. Makes your life easier with great features like autocomplete, type errors, and more.
  - Luau LSP comes with a [companion plugin](https://create.roblox.com/store/asset/10913122509/Luau-Language-Server-Companion) for Roblox Studio which provides autocomplete for Roblox Instances in VSCode. It is recommended to install this. Once installed, make sure to set `luau-lsp.plugin.enabled` to `true` in settings.
  - See the [recommended settings for this extension](#recommended-settings-for-luau-lsp)
- [StyLua](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.stylua): Extension for StyLua which makes it easy to set up VSCode to format your code at the press of a keyboard shortcut.
- [Indenticator](https://marketplace.visualstudio.com/items?itemName=SirTori.indenticator) (optional): Highlights your current indent level. If you're the kind of programmer who lives on the edge (of your text editor, because you have code which uses 15 indents), then you'll find this useful.
- [Incredibly In Your Face](https://marketplace.visualstudio.com/items?itemName=VirejDasani.incredibly-in-your-face) (optional): Mr. Incredible will become more and more uncanny as you write more errors in your code. Very effective at motivating you to write less errors.

### Roblox Libraries
Some utility libraries which are helpful for Roblox development are installed
by default. You can delete these at your preference, but note that some of them,
such as Schedule and Signal, are used in the project template code.

#### Game Schedules
See [the page on Game Schedules](documentation/libraries/1-game-schedules.md).

#### Character Wrapper
See [the page on the Character Wrapper](documentation/libraries/2-character-wrapper.md).

#### List of utility libraries
More detailed documentation for each of these can be found in their respective
modules in `src/shared/Util`. Short descriptions of each library are provided
below:
- AssertInstance: Validate that an Instance has the correct state, or display
  automatically-written, high-quality error messages in the output. Useful for
  using Roblox Studio as a level editor.
- FusionUtil: Utility objects for Fusion.
- Loader: Bootloader for modules. Supports match and ignore globs.
- NumberUtil: Extra math functions and utilities for formatting numbers.
- RandomPoint: Get uniformly random points inside of primitive parts.
- ReactiveValue: Simple reactive state management through Value Instance-like
  objects (e.g. StringValue, NumberValue).
- Schedule: Create routines in which game code runs in a defined sequence.
- SFXUtil: Easily play sounds and cross-fade music without needing to write
  configuration code for common use cases like deleting a sound after it has
  finished playing.
- Spring: Continuous, configurable spring-like motion for use in UI and 2D and
  3D animations.
- State: Table-driven, flexible state machine implementation. Easy to mentally
  convert from a state graph to code or vice versa.
- TableUtil: Extra table functions.
- Tagged: CollectionService utility library enabling high-performance code which
  interacts with tagged Instances by using cached collections. Provides
  shorthands for many common use cases, such as observing tagged Instances under
  an ancestor Instance.
- VFXUtil: Easily play visual effects and tween model pivots and scales.
- Weighted: Library for weighted random choice systems.

#### List of Roblox packages
- [howmanysmall/Janitor](https://howmanysmall.github.io/Janitor/): Garbage
  collection made easy and ergonomic.
- [sleitnick/Signal](https://sleitnick.github.io/RbxUtil/api/Signal/):
  Create your own events using an API that mirrors RBXScriptSignal.
- [elttob/Fusion](https://elttob.uk/Fusion/0.3/): Luau companion library which
  makes implementing UI, reacting to state changes, and creating animations a
  breeze.
- [pepeeltoro41/ui-labs](https://github.com/PepeElToro41/ui-labs): Allows you to
  prototype UI with mock-up data in a controlled environment, and see UI code
  and functionality updates in real time.

## Style Guide
See [the page on the style guide](documentation/style-guide.md).

## Understanding

### What does each file do?
See [the page on what each file does](documentation/understanding/what-does-each-file-do.md).
