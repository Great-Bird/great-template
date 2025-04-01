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

for _, player in Players:GetPlayers() do
	SchedulesServer.loadPlayer.startNoYield(player)
end
Players.PlayerAdded:Connect(SchedulesServer.loadPlayer.startNoYield)
Players.PlayerRemoving:Connect(SchedulesServer.unloadPlayer.startNoYield)

CharacterService.characterLoaded:Connect(SchedulesServer.loadCharacter.startNoYield)
CharacterService.characterUnloading:Connect(SchedulesServer.unloadCharacter.startNoYield)
