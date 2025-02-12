local ProcessUtil = require("process-util")
local DevSetupTasks = require("dev-setup-tasks")

DevSetupTasks.installPackages()
DevSetupTasks.createMissingPackageDirectories()
DevSetupTasks.createSourcemap()
DevSetupTasks.reexportPackageTypes()
ProcessUtil.printAllCompleted()
