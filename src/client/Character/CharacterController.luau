local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterShared = require(ReplicatedStorage.Shared.Character.CharacterShared)
local Signal = require(ReplicatedStorage.Packages.Signal)

local localPlayer = Players.LocalPlayer

local playersToInstances: { [Player]: CharacterShared.Instances } = {}
local playerConnections = {}

local module = {
	characterLoaded = Signal.new() :: Signal.Signal<CharacterShared.Instances, Player>,
	localCharacterLoaded = Signal.new() :: Signal.Signal<CharacterShared.Instances, Player>,
	characterUnloading = Signal.new() :: Signal.Signal<CharacterShared.Instances, Player>,
	localCharacterUnloading = Signal.new() :: Signal.Signal<CharacterShared.Instances, Player>,
}

local function waitForInstances(character: Model, player: Player): CharacterShared.Instances
	local rootPart = character:WaitForChild("HumanoidRootPart")
	assert(rootPart:IsA("Part"), "Character must have a HumanoidRootPart")
	local humanoid = character:WaitForChild("Humanoid")
	assert(humanoid:IsA("Humanoid"), "Character must have a Humanoid")
	local animator = humanoid:WaitForChild("Animator")
	assert(animator:IsA("Animator"), "Character must have an Animator")
	local head = character:WaitForChild("Head")
	assert(head:IsA("Part"), "Character must have a Head Part")

	return {
		animator = animator,
		character = character,
		head = head,
		humanoid = humanoid,
		player = player,
		rootPart = rootPart,
	}
end

function module.observeCharacter(
	player: Player,
	onCharacterLoaded: (instances: CharacterShared.Instances, player: Player) -> ()?,
	onCharacterUnloading: (instances: CharacterShared.Instances, player: Player) -> ()?
): (Signal.Connection?, Signal.Connection?)
	local loadedConnection = nil :: Signal.Connection?
	if onCharacterLoaded then
		local instances = playersToInstances[player]
		if instances then
			onCharacterLoaded(instances, player)
		end
		loadedConnection = module.characterLoaded:Connect(function(instances, loadedPlayer)
			if loadedPlayer == player then
				onCharacterLoaded(instances, player)
			end
		end)
	end

	local unloadingConnection = nil :: Signal.Connection?
	if onCharacterUnloading then
		unloadingConnection = module.characterUnloading:Connect(function(instances, unloadingPlayer)
			if unloadingPlayer == player then
				onCharacterUnloading(instances, player)
			end
		end)
	end

	return loadedConnection, unloadingConnection
end

function module.observeLocalCharacter(
	onCharacterLoaded: (instances: CharacterShared.Instances, player: Player) -> ()?,
	onCharacterUnloading: (instances: CharacterShared.Instances, player: Player) -> ()?
): (Signal.Connection?, Signal.Connection?)
	return module.observeCharacter(localPlayer, onCharacterLoaded, onCharacterUnloading)
end

function module.getInstances(player: Player): CharacterShared.Instances?
	return playersToInstances[player]
end

function module.getAllInstances(): { [Player]: CharacterShared.Instances }
	return playersToInstances
end

function module.getInstancesFromPart(part: BasePart): (CharacterShared.Instances?, Player?)
	local player = CharacterShared.getPlayerFromInstance(part)
	if player then
		return playersToInstances[player], player
	end
	return nil, nil
end

function module.onPlayerAdded(player: Player)
	local function onCharacterAdded(character: Model)
		if not playersToInstances[player] then
			local instances = waitForInstances(character, player)
			playersToInstances[player] = instances
			module.characterLoaded:Fire(instances, player)
			if player == localPlayer then
				module.localCharacterLoaded:Fire(instances, player)
			end
		end
	end

	local function onCharacterRemoving(character: Model)
		local instances = playersToInstances[player]
		if instances then
			module.characterUnloading:Fire(instances, player)
			if player == localPlayer then
				module.localCharacterUnloading:Fire(instances, player)
			end
			playersToInstances[player] = nil
		end
	end

	if player.Character then
		onCharacterAdded(player.Character)
	end
	playerConnections[player] = {
		player.CharacterAdded:Connect(onCharacterAdded),
		player.CharacterRemoving:Connect(onCharacterRemoving),
	}
end

function module.onPlayerRemoving(player: Player)
	if playerConnections[player] then
		for _, connection in playerConnections[player] do
			connection:Disconnect()
		end
		playerConnections[player] = nil
	end
end

return module
