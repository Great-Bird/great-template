local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local Config = require("../config")
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

function module.installPackages(projectDirectoryPath: string?)
	local args = { "install" }
	if projectDirectoryPath then
		table.insert(args, "--project-path")
		table.insert(args, projectDirectoryPath)
	end
	ProcessUtil.spawnProcess("wally", args, nil, "Installed packages", "Failed to install packages")
end

--[=[
	This function is a workaround for wally not creating directories for empty categories.

	This function is used to avoid having to edit the project file when no
	packages exist in a category (e.g. `Packages`, `ServerPackages`, `DevPackages`).
]=]
function module.createMissingPackageDirectories()
	if not fs.isDir("Packages") then
		fs.writeDir("Packages")
		ProcessUtil.printTaskCompleted("Added Packages folder")
	end
	if not fs.isDir("ServerPackages") then
		fs.writeDir("ServerPackages")
		ProcessUtil.printTaskCompleted("Added ServerPackages folder")
	end
	if not fs.isDir("test/DevPackages") then
		fs.writeDir("test/DevPackages")
		ProcessUtil.printTaskCompleted("Added test/DevPackages folder")
	end
end

function module.createSourcemap(projectFilePath: string?)
	ProcessUtil.spawnProcess(
		"rojo",
		{ "sourcemap", projectFilePath or Config.projectFilePath, "--include-non-scripts", "--output", Config.sourcemapFilePath },
		nil,
		"Created sourcemap",
		"Failed to create sourcemap"
	)
end

function module.reexportPackageTypes(reexportDevPackageTypes: boolean?)
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

	if reexportDevPackageTypes then
		ProcessUtil.spawnProcess(
			"wally-package-types",
			{ "--sourcemap", Config.sourcemapFilePath, "test/DevPackages" },
			nil,
			"Re-exported dev package types",
			"Failed to re-export dev package types"
		)
	end
end

return module
