--[[
	Jest Test Script v0.1.0
	Author: Great_Bird
	Date: 2025-02-17
	Last edited: 2025-02-17

	Run `lune run test help` for usage instructions.

	Script which runs tests in Roblox Studio using Jest (link: https://github.com/jsdotlua/jest-lua)
	Requires the Jest Roblox library to be installed.

	You will need some tools installed to use this script. They can be found here:
	* Lune: https://github.com/lune-org/lune
	* Wally: https://github.com/UpliftGames/wally
	* wally-package-types: https://github.com/JohnnyMorganz/wally-package-types/blob/master/Cargo.toml
	* Rojo: https://github.com/rojo-rbx/rojo
	* run-in-roblox: https://github.com/rojo-rbx/run-in-roblox
	Place this file into a `.lune` directory in the root of your project to use it.
	
	This script is very project-specific, so you may need to modify it to fit your project's needs.
	Constant variables are provided for easy configuration; see `config.luau`.

	Changelog:
	v0.1.1 (2025-02-17)
	- Changes:
		- Added file info, docs, and help message
		- Added `test` option to install the test packages as well
	v0.1.0 (2025-02-12)
	- Notes: Release
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local Config = require("config")
local DevSetupTasks = require("modules/dev-setup-tasks")
local ProcessUtil = require("modules/process-util")

local c = stdio.color
local s = stdio.style

local BUILD_FILE_PATH = Config.testBuildFilePath
local TEST_PROJECT_PATH = Config.testProjectFilePath
local TEST_SCRIPT_PATH = "test/run-tests.luau"

if table.find(process.args, "help") then
	print("Runs tests in Roblox Studio")
	print()
	print(`{s("bold")}Instructions:{s("reset")}`)
	print("First, run this script with both the 'import' flag to import the main place, and the 'serve' flag to serve the test project with Rojo.")
	print("Then, open the build file in Roblox Studio and connect with the Rojo plugin.")
	print("Once you're ready, run this script again without arguments to run the tests.")
	print()
	print(`{s("bold")}{c("yellow")}Note:{c("reset")}\
If this script fails to run Jest, you may need to enable the FFlagEnableLoadModule feature in Roblox Studio.\
To do this, run Roblox Studio Mod Manager (GitHub: https://github.com/MaximumADHD/Roblox-Studio-Mod-Manager),\
set the FFlag, then run Roblox Studio before running the script again.`)
	print()
	print(`{s("bold")}Usage: {c("yellow")}lune{c("reset")} run{s("reset")} test [help] [import] [serve]`)
	print()
	print(`{s("bold")}Options:`)
	print(`  {s("bold")}help{s("reset")}    Display this help message and exit`)
	print(`  {s("bold")}import{s("reset")}  Overwrite {BUILD_FILE_PATH} with the latest version of the main place`)
	print(`  {s("bold")}serve{s("reset")}   Serve {TEST_PROJECT_PATH} using Rojo.`)

	process.exit(0)
end


if table.find(process.args, "import") then
	DevSetupTasks.fetchTypeDefinitions()
	DevSetupTasks.installPackages()
	DevSetupTasks.createSourcemap(TEST_PROJECT_PATH)
	DevSetupTasks.fetchPlace(BUILD_FILE_PATH)
end

if table.find(process.args, "serve") then
	ProcessUtil.printAllCompleted()

	print("The test project has been set up!")
	if not fs.isFile(BUILD_FILE_PATH) then
		print(`{s("bold")}{c("yellow")}Warning: {c("reset")}{s("reset")}{BUILD_FILE_PATH} does not exist. It's recommended to run with the 'import' flag to ensure the latest version of the main place is imported.`)
	else
		print(`Open {BUILD_FILE_PATH} in Roblox Studio and connect with the Rojo plugin to start testing.`)
		print(`Once you're ready, run 'lune run test' to run the tests.`)
	end

	DevSetupTasks.serveProject(TEST_PROJECT_PATH)
else
	-- If run-in-roblox can't run Jest because FFlagEnableLoadModule is not enabled, you'll need to set the FFlag using Roblox
	-- Studio Mod Manager (https://github.com/MaximumADHD/Roblox-Studio-Mod-Manager) and then run a Roblox Studio instance
	-- before running the script
	ProcessUtil.spawnProcess(
		"run-in-roblox",
		{ "--place", BUILD_FILE_PATH, "--script", TEST_SCRIPT_PATH },
		{ shell = true, stdio = "inherit" },
		"Ran tests",
		"Failed to run tests"
	)
	ProcessUtil.printAllCompleted()
end
