local ProcessUtil = require("process-util")
local DevSetupTasks = require("dev-setup-tasks")

DevSetupTasks.serveProject()
ProcessUtil.printAllCompleted()
