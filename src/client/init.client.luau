local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CharacterController = require(script.Character.CharacterController)
local Loader = require(ReplicatedStorage.Shared.Util.Loader)
local SchedulesClient = require(script.Schedules.SchedulesClient)

local localPlayer = Players.LocalPlayer

Loader.loadTopLevelModules(script)

SchedulesClient.initialize.start()
SchedulesClient.start.startNoYield()

RunService.PreRender:Connect(SchedulesClient.preRender.startNoYield)
RunService.PreAnimation:Connect(SchedulesClient.preAnimation.startNoYield)
RunService.Heartbeat:Connect(SchedulesClient.heartbeat.startNoYield)
RunService.Stepped:Connect(function(_, dt)
	SchedulesClient.stepped.startNoYield(dt)
end)
RunService.PreSimulation:Connect(SchedulesClient.preSimulation.startNoYield)
RunService.PostSimulation:Connect(SchedulesClient.postSimulation.startNoYield)

local function onPlayerAdded(player)
	CharacterController.onPlayerAdded(player)
	SchedulesClient.loadPlayer.startNoYield(player)
	if player == localPlayer then
		SchedulesClient.loadLocalPlayer.startNoYield(player)
	end
end

local function onPlayerRemoving(player)
	CharacterController.onPlayerRemoving(player)
	SchedulesClient.unloadPlayer.startNoYield(player)
	if player == localPlayer then
		SchedulesClient.unloadLocalPlayer.startNoYield(player)
	end
end

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

CharacterController.characterLoaded:Connect(SchedulesClient.loadCharacter.startNoYield)
CharacterController.characterUnloading:Connect(SchedulesClient.unloadCharacter.startNoYield)
CharacterController.localCharacterLoaded:Connect(SchedulesClient.loadLocalCharacter.startNoYield)
CharacterController.localCharacterUnloading:Connect(SchedulesClient.unloadLocalCharacter.startNoYield)
