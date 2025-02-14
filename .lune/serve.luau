local ProcessUtil = require("modules/process-util")
local DevSetupTasks = require("modules/dev-setup-tasks")

DevSetupTasks.serveProject()
ProcessUtil.printAllCompleted()
