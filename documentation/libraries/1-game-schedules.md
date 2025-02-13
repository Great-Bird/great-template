Schedules for commonly used events are provided in SchedulesServer and SchedulesClient.
For any schedule, you can create a job, which is code specified to run as part of
the schedule. What's useful is that you can specify a job to occur after other jobs.
As such, Schedules differ from Signals in that they define a consistent order for
callbacks.

The `initialize` and `start` schedules are used in module loading. If you've used
[Knit](https://sleitnick.github.io/Knit/) before, you may be familiar with these
names. Knit is an old Roblox game framework which has [a few problems](https://medium.com/@sleitnick/knit-its-history-and-how-to-build-it-better-3100da97b36), but it had a few useful
ideas. Here we're adapting one of them: each top-level game systems are given a
lifecycle to implement:
1. a bootloading step, where the module is required by the entrypoint of the system
2. an `initialize` step, where the module can prepare itself to be required
3. a `start` step, where the module can run any game logic it is are concerned with

Modules that implement these schedules are conventionally called ___services___ if on
the server, and ___controllers___ if on the client. Not every module in the game will
be a service or controller; in general, top-level game systems each control one
feature, or one aspect of the game.

Here is an example of how schedules simplify code by allowing more assumptions
to be made:

```lua
local SchedulesServer = require(path.to.SchedulesServer)

local ImportantPartService = {}

ImportantPartService.initializeJob = SchedulesServer.start.job(function()
    local importantPart = Instance.new("Part")
    importantPart.Name = "Very important part"
    importantPart.Parent = workspace
end)

return ImportantPartService
```

```lua
local ImportantPartService = require(path.to.ImportantPartService)
local SchedulesServer = require(path.to.SchedulesServer)

local PartPrintingService = {}

PartPrintingService.initializeJob = SchedulesServer.start.job(function()
    print(workspace.ImportantPart) --> "Very important part"
end, ImportantPartService.initializeJob) -- Here we specify that this should run after the part is created by ImportantPartService

return PartPrintingService
```