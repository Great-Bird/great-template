local process = require("@lune/process")

local Config = require("config")
local ProcessUtil = require("modules/process-util")
local DevSetupTasks = require("modules/dev-setup-tasks")

local testing = table.find(process.args, "test") ~= nil
local projectFilePath = if testing then Config.testProjectFilePath else Config.projectFilePath

DevSetupTasks.createSourcemap(projectFilePath)
ProcessUtil.printAllCompleted()
