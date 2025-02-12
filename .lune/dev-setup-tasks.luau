local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local Config = require("config")
local ProcessUtil = require("process-util")
local Remodel = require("remodel")

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
	ProcessUtil.spawnProcess("rojo", { "serve", projectFilePath or Config.projectFilePath }, { shell = true }, nil, "Failed to start server")
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

function module.installPackages()
	ProcessUtil.spawnProcess("wally", { "install" }, nil, "Installed packages", "Failed to install packages")
end

function module.createMissingPackageDirectories()
	if not fs.isDir("Packages") then
		fs.writeDir("Packages")
		ProcessUtil.printTaskCompleted("Added Packages folder")
	end
	if not fs.isDir("ServerPackages") then
		fs.writeDir("ServerPackages")
		ProcessUtil.printTaskCompleted("Added ServerPackages folder")
	end
	if not fs.isDir("DevPackages") then
		fs.writeDir("DevPackages")
		ProcessUtil.printTaskCompleted("Added DevPackages folder")
	end
end

function module.createSourcemap()
	ProcessUtil.spawnProcess(
		"rojo",
		{ "sourcemap", Config.projectFilePath, "--include-non-scripts", "--output", Config.sourcemapFilePath },
		nil,
		"Created sourcemap",
		"Failed to create sourcemap"
	)
end

function module.reexportPackageTypes()
	ProcessUtil.spawnProcess(
		"wally-package-types",
		{ "--sourcemap", Config.sourcemapFilePath, "Packages" },
		nil,
		"Re-exported package types",
		"Failed to re-export package types"
	)

	ProcessUtil.spawnProcess(
		"wally-package-types",
		{ "--sourcemap", Config.sourcemapFilePath, "ServerPackages" },
		nil,
		"Re-exported server package types",
		"Failed to re-export server package types"
	)

	ProcessUtil.spawnProcess(
		"wally-package-types",
		{ "--sourcemap", Config.sourcemapFilePath, "DevPackages" },
		nil,
		"Re-exported dev package types",
		"Failed to re-export dev package types"
	)
end

return module
