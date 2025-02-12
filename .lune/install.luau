local ProcessUtil = require("process-util")
local DevSetupTasks = require("dev-setup-tasks")

DevSetupTasks.installPackages()
ProcessUtil.printAllCompleted()
