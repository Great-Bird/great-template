local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CharacterService = require(script.Character.CharacterService)
local Loader = require(ReplicatedStorage.Shared.Util.Loader)
local SchedulesServer = require(script.Schedules.SchedulesServer)

Loader.loadTopLevelModules(script)

SchedulesServer.initialize.startNoYield()
SchedulesServer.start.startNoYield()

RunService.Heartbeat:Connect(SchedulesServer.heartbeat.startNoYield)
RunService.Stepped:Connect(function(_, dt)
	SchedulesServer.stepped.startNoYield(dt)
end)
RunService.PreSimulation:Connect(SchedulesServer.preSimulation.startNoYield)
RunService.PostSimulation:Connect(SchedulesServer.postSimulation.startNoYield)

local function onPlayerAdded(player: Player)
	CharacterService.onPlayerAdded(player)
	SchedulesServer.loadPlayer.startNoYield(player)
end

local function onPlayerRemoving(player: Player)
	CharacterService.onPlayerRemoving(player)
	SchedulesServer.unloadPlayer.startNoYield(player)
end

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

CharacterService.characterLoaded:Connect(SchedulesServer.loadCharacter.startNoYield)
CharacterService.characterUnloading:Connect(SchedulesServer.unloadCharacter.startNoYield)
