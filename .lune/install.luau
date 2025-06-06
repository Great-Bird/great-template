--[[
	Install Script v0.2.0
	Author: Great_Bird
	Date: 2025-02-12
	Last edited: 2025-06-01

	Run `lune run install help` for usage instructions.

	Script which installs packages using pesde.

	You will need some tools installed to use this script. They can be found here:
	* Lune: https://github.com/lune-org/lune
	* Pesde: https://github.com/pesde-pkg/pesde
	* Rojo: https://github.com/rojo-rbx/rojo
	Place this file into a `.lune` directory in the root of your project to use it.
	
	This script is very project-specific, so you may need to modify it to fit your project's needs.
	Constant variables are provided for easy configuration; see `config.luau`.

	Changelog:
	v0.2.0 (2025-06-01)
	- Changes:
		- Updated to use pesde for package management instead of wally
	- Removed:
		- `test` option, as it is no longer needed.
	v0.1.1 (2025-02-17)
	- Changes:
		- Added file info, docs, and help message
		- Added `test` option to install the test packages as well
	v0.1.0 (2025-02-12)
	- Notes: Release
]]

local process = require("@lune/process")
local stdio = require("@lune/stdio")
local Config = require("config")
local ProcessUtil = require("modules/process-util")
local DevSetupTasks = require("modules/dev-setup-tasks")

local c = stdio.color
local s = stdio.style

if table.find(process.args, "help") then
	print("Installs packages using pesde.")
	print()
	print(`{s("bold")}Usage: {c("yellow")}lune{c("reset")} run{s("reset")} install [help]`)
	print()
	print(`{s("bold")}Options:`)
	print(`  {s("bold")}help{s("reset")}  Display this help message and exit`)

	process.exit(0)
end

DevSetupTasks.installPackages()
DevSetupTasks.createSourcemap(Config.projectFilePath)
ProcessUtil.printAllCompleted()
