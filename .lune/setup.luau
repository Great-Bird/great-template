--[[
	Setup Script v0.1.0
	Author: Great_Bird
	Run `lune run setup help` for usage instructions.

	Script which sets up the development environment for the project.
	You will some tools installed to use this script. They can be found here:
	* Lune: https://github.com/lune-org/lune
	Place this file into a `.lune` directory in the root of your project to use it.
	
	This script is very project-specific, so you may need to modify it to fit your project's needs.
	Constant variables are provided for easy configuration.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")
local Config = require("config")

local c = stdio.color
local s = stdio.style

if table.find(process.args, "help") then
	print("Sets up the development environment for the project.")
	print()
	print(`{s("bold")}Usage: {c("yellow")}lune{c("reset")} run{s("reset")} setup [help] [import]`)
	print()
	print(`{s("bold")}Options:`)
	print(`  {s("bold")}help{s("reset")}  Display this help message and exit`)
	print(`  {s("bold")}import{s("reset")}  Overwrite {Config.buildFilePath} with the latest version of the main place. Will run by default if {Config.buildFilePath} does not exist.`)
	print(`  {s("bold")}test{s("reset")}  Serve the test project instead of the main project`)

	process.exit(0)
end

local DevSetupTasks = require("dev-setup-tasks")
local ProcessUtil = require("process-util")

DevSetupTasks.fetchTypeDefinitions()
DevSetupTasks.installPackages()
if table.find(process.args, "import") or not fs.isFile(Config.buildFilePath) then
	DevSetupTasks.fetchPlace()
end
ProcessUtil.printAllCompleted()

print(`The development environment has been set up!`)
print(`Open {Config.projectFilePath} in Roblox Studio and connect with the Rojo plugin to start developing.`)
DevSetupTasks.serveProject()
