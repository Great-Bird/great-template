local ProcessUtil = require("modules/process-util")
local DevSetupTasks = require("modules/dev-setup-tasks")

DevSetupTasks.installPackages()
DevSetupTasks.createMissingPackageDirectories()
DevSetupTasks.createSourcemap()
DevSetupTasks.reexportPackageTypes()
ProcessUtil.printAllCompleted()
