# great-template
A great template to use for Roblox projects.

TODO: Table of contents

## Guide

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
in the VSCode terminal. This should install every needed
tool for using this project template.

## List of Tools

### Toolchain
- [`rojo`](https://rojo.space/docs/v7/): Syncs project source code to Roblox Studio, enabling the use of VSCode, Git, and other tools
- [`luau-lsp`](https://github.com/JohnnyMorganz/luau-lsp): CLI for Luau LSP, a language server for Luau. Mainly useful for setting FFlags and displaying type errors.
- [`lune`](https://lune-org.github.io/docs): CLI for running Luau scripts in the terminal. This is required for many of the tools this project template provides. 
- [`wally`](https://github.com/UpliftGames/wally): Package manager which makes it easy to automatically update Roblox packages and libraries used as dependencies of the project. We may decide to replace Wally with [Pesde](https://pesde.dev) in the future when it is more stable.
- [`wally-package-types`](https://github.com/JohnnyMorganz/wally-package-types): Re-exports type definitions provided in Wally packages to linker files.
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
TODO: Install some libraries by default: Signal, ReactiveValue, SFXUtil, VFXUtil, Schedule, CharacterWrapper, Spring, Tagged, AssertInstance

TODO: Recommend libraries that aren't installed by default: DocumentService, Blink

TODO: My libraries

## Style Guide
TODO: Style guide
