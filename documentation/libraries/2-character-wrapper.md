CharacterService, CharacterController, and CharacterShared serve as a single point
where commonly used character instances are accessed, and then made easily available
through an interface. They also fire character-related game schedules such as
`loadCharacter`.

The character wrapper aims to eliminate the tired patterns that appear in code
which handles character instances. Here's an example of how those patterns tend
to manifest:

```lua
-- Give each player an anti-gravity force when they spawn

local Players = game:GetService("Players")

local function onCharacterAdded(character: Model)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local rootAttachment = humanoidRootPart:WaitForChild("RootAttachment")

    local force = path.to.AntigravityForce:Clone()
    force.Attachment0 = rootAttachment
    force.Parent = humanoidRootPart
end

local function onPlayerAdded(player: Player)
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
```

Now let's look at how that same code looks using the character wrapper and schedules:
```lua
-- Give each player an anti-gravity force when they spawn

local SchedulesServer = require(path.to.SchedulesServer)

SchedulesServer.loadCharacter.job(function(instances, player)
    local force = path.to.AntigravityForce:Clone()
    force.Attachment0 = instances.rootPart.RootAttachment
    force.Parent = instances.rootPart
end)
```

The second is obviously much more concise. Using some sort of character wrapper
is a no-brainer. Another benefit of this approach is that if we start commonly
using another character instance which we didn't add to the `instances` table,
we can just modify the character wrapper to include it as well!

Imagine if we were using patterns akin to the first example
throughout the whole game! Unfortunately, that reality is quite common in many
codebases.