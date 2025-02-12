--[[
	Analyze Script v0.1.0
	Author: Great_Bird
	Run `lune run analyze help` for usage instructions.

	Script which runs the luau-lsp analyze command. Displays all type errors and warnings in the console.
	You will some tools installed to use this script. They can be found here:
	* Lune: https://github.com/lune-org/lune
	* Luau LSP: https://github.com/JohnnyMorganz/luau-lsp
	Place this file into a `.lune` directory in the root of your project to use it.
	
	This script is very project-specific, so you may need to modify it to fit your project's needs.
	Constant variables are provided for easy configuration.
]]

local process = require("@lune/process")
local fs = require("@lune/fs")
local stdio = require("@lune/stdio")
local ProcessUtil = require("process-util")
local Config = require("config")

local DEFINITIONS_PATH: string = Config.typeDefinitionsFilePath -- Global type definition file
local IGNORE_PATHS: { string }? = {
	"**/_Index/**", -- Ignore packages
}
local LUAU_RC_PATH: string? = ".luaurc" -- Optional luaurc file
local SETTINGS_PATH: string? = ".vscode/settings.json" -- Optional VSCode settings file
local SOURCEMAP_PATH: string = Config.sourcemapFilePath -- Sourcemap file as returned by `rojo sourcemap`
local SOURCE_PATH: string = Config.sourceCodeDirectoryPath -- Project source code directory

local c = stdio.color
local s = stdio.style

if table.find(process.args, "help") then
	print("Runs all necessary initialization commands in one go")
	print()
	print(`{s("bold")}Usage: {c("yellow")}lune{c("reset")} run{s("reset")} analyze [DIRECTORY] [no-strict-dm-types] [help]`)
	print()
	print(`{s("bold")}Options:`)
	print(`  {s("bold")}DIRECTORY{s("reset")}  The directory to analyze (default: "{SOURCE_PATH}")`)
	print(`  {s("bold")}no-strict-dm-types{s("reset")}  Pass the --no-strict-dm-types flag to luau-lsp, disabling strict type checking for DataModel objects`)
	print(`  {s("bold")}help{s("reset")}  Display this help message and exit`)

	process.exit(0)
end

local args = {}

local function addArgument(commandOrName: string, value: string?)
	table.insert(args, commandOrName)
	if value then
		table.insert(args, value)
	end
end

addArgument("analyze")
addArgument("--platform", "roblox")
if LUAU_RC_PATH and fs.isFile(LUAU_RC_PATH) then
	addArgument("--base-luaurc", LUAU_RC_PATH)
end
addArgument("--sourcemap", SOURCEMAP_PATH)
addArgument("--definitions", DEFINITIONS_PATH)
if SETTINGS_PATH and fs.isFile(SETTINGS_PATH) then
	addArgument("--settings", SETTINGS_PATH)
end
if IGNORE_PATHS then
	for _, ignorePath in IGNORE_PATHS do
		addArgument("--ignore", ignorePath)
	end
end
local processArgs = table.clone(process.args)
local noStrictTypesIndex = table.find(processArgs, "no-strict-dm-types")
if noStrictTypesIndex then
	addArgument("--no-strict-dm-types")
	table.remove(processArgs, noStrictTypesIndex)
end
if processArgs[1] then
	-- Override source path with specified directory
	addArgument(processArgs[1])
else
	addArgument(SOURCE_PATH)
end

ProcessUtil.printTaskInProgress("Analyzing project...")
process.spawn("luau-lsp", args, {
	shell = true,
	stdio = "inherit",
})
ProcessUtil.printAllCompleted()
