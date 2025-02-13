# Game Schedules

Schedules for commonly used events are provided in [SchedulesServer](/src/server/Schedules/SchedulesServer.luau) and [SchedulesClient](/src/client/Schedules/SchedulesClient.luau).
For any schedule, you can create a job, which is code specified to run as part of
the schedule. What is useful about them is that you can specify a job to occur
after other jobs.
As such, Schedules differ from Signals in that they define a consistent order for
callbacks.

The `initialize` and `start` schedules are used in module loading. If you've used
[Knit](https://sleitnick.github.io/Knit/) or something similar before, you may be
familiar with these names. Knit is an old Roblox game framework which has
[a few problems](https://medium.com/@sleitnick/knit-its-history-and-how-to-build-it-better-3100da97b36),
but it also had a few useful ideas. Here, we adapt one of them. Each
___top-level game system___ is given a lifecycle to implement:
1. a bootloading step, where the system is required by the entry point of the game
   (the main server or client script)
2. an `initialize` step, where the system can prepare itself to be used by
   other systems
3. a `start` step, where the system can run any game logic it is concerned with,
   using other systems as needed

Systems that implement these schedules are conventionally called ___services___ if on
the server, and ___controllers___ if on the client. Not every module in the game will
be a service or controller; in general, systems each control one feature, or one
aspect of the game.

Here is an example of the `initialize` schedule being used in two services:

```lua
local SchedulesServer = require(path.to.SchedulesServer)

local PartColorService = {}

PartColorService.initializeJob = SchedulesServer.start.job(function()
    -- Set all parts in workspace to a random color
    for _, instance in workspace:GetDescendants() do
        if instance:IsA("BasePart") then
            instance.BrickColor = BrickColor.random()
        end
    end
end)

return PartColorService
```

```lua
local PartColorService = require(path.to.PartColorService)
local SchedulesServer = require(path.to.SchedulesServer)

local KillbrickService = {}

KillbrickService.initializeJob = SchedulesServer.start.job(function()
    -- Make all parts that match a randomly selected color kill players on touch
    local killbrickColor = BrickColor.random()
    for _, instance in workspace:GetDescendants() do
        if instance:IsA("BasePart") and instance.BrickColor == killbrickColor then
            instance.Touched:Connect(function(hitPart)
                print("Pretend I killed whoever", hitPart, "belongs to")
            end)
        end
    end
    
    -- By passing another job connected to the same schedule, we specify that
    -- this job should run after the other job
end, PartColorService.initializeJob)

return KillbrickService
```