local Config = require("../config")
local ProcessUtil = require("process-util")
local Remodel = require("remodel")
local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")

local module = {}

function module.fetchPlace(overwritePath: string?)
	local path = overwritePath or Config.buildFilePath

	local dataModel: Remodel.LuneDataModel = Remodel.readPlaceAsset(Config.placeId)
	Remodel.writePlaceFile(path, dataModel)
	ProcessUtil.printTaskCompleted(`Saved place file to {path}`)
	return dataModel
end

function module.serveProject(projectFilePath: string?)
	ProcessUtil.printTaskInProgress("Changes are syncing. Press Ctrl+C to stop.")
	ProcessUtil.spawnProcess(
		"rojo",
		{ "serve", projectFilePath or Config.projectFilePath },
		{ shell = true },
		nil,
		"Failed to start server"
	)
end

function module.fetchTypeDefinitions()
	local result = net.request {
		url = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau",
		method = "GET",
	}
	if result.ok then
		fs.writeFile("globalTypes.d.luau", result.body)
		ProcessUtil.printTaskCompleted("Downloaded global type definitions")
	else
		ProcessUtil.printTaskFailed(
			"Failed to download global type definitions",
			result.statusCode .. result.statusMessage
		)
		process.exit(1)
	end
end

function module.installPackages(--[[projectDirectoryPath: string?]])
	ProcessUtil.spawnProcess("pesde", { "install" }, nil, "Installed packages", "Failed to install packages")
end

function module.createSourcemap(projectFilePath: string?, watch: boolean?)
	local args = {
		"sourcemap",
		projectFilePath or Config.projectFilePath,
		"--include-non-scripts",
		"--output",
		Config.sourcemapFilePath,
	}
	if watch then
		table.insert(args, "--watch")
	end
	ProcessUtil.spawnProcess("rojo", args, nil, "Created sourcemap", "Failed to create sourcemap")
end

return module
