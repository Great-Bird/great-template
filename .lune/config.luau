return {
	-- Project-specific options. These are required to be set.
	placeId = 0, -- The place ID of the game to download on `lune run setup import`

	-- File path options. It's fine to leave these at their defaults.
	buildFilePath = "build.rbxlx", -- The path to the build file to write to on `lune run setup import`
	projectFilePath = "default.project.json", -- The path to the project file to serve on `lune run setup`

	testBuildFilePath = "test.rbxlx", -- The path to the test build file to write to on `lune run setup import test`
	testProjectFilePath = "test.project.json", -- The path to the test project file to serve on `lune run setup test`

	sourceCodeDirectoryPath = "src", -- The path to the source code directory
	sourcemapFilePath = "sourcemap.json", -- The path to the rojo sourcemap file
	typeDefinitionsFilePath = "globalTypes.d.luau", -- The path to write the global type definitions file from https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
}
