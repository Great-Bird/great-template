local process = require("@lune/process")

local Config = require("config")
local ProcessUtil = require("modules/process-util")
local DevSetupTasks = require("modules/dev-setup-tasks")

local testing = table.find(process.args, "test") ~= nil
local projectFilePath = if testing then Config.testProjectFilePath else Config.projectFilePath

local watch = table.find(process.args, "watch") ~= nil

ProcessUtil.printTaskInProgress("Watching for changes! Feel free to edit your scripts and open up a new terminal while this runs...")
DevSetupTasks.createSourcemap(projectFilePath, watch)
ProcessUtil.printAllCompleted()
