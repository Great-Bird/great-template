local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CharacterShared = require(ReplicatedStorage.Shared.Character.CharacterShared)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local SchedulesServer = require(ServerScriptService.Server.Schedules.SchedulesServer)
local Signal = require(ReplicatedStorage.Packages.Signal)

local playersToInstances: { [Player]: CharacterShared.Instances } = {}
local playerJanitor = Janitor.new()

local module = {
	characterLoaded = Signal.new() :: Signal.Signal<CharacterShared.Instances, Player>,
	characterUnloading = Signal.new() :: Signal.Signal<CharacterShared.Instances, Player>,
}

local function setInstances(character: Model, player: Player)
	local rootPart = character:WaitForChild("HumanoidRootPart")
	assert(rootPart:IsA("Part"), "Character must have a HumanoidRootPart as its PrimaryPart")
	local humanoid = character:WaitForChild("Humanoid")
	assert(humanoid:IsA("Humanoid"), "Character must have a Humanoid")
	local animator = humanoid:WaitForChild("Animator")
	assert(animator:IsA("Animator"), "Character must have an Animator")
	local head = character:WaitForChild("Head")
	assert(head:IsA("Part"), "Character must have a Head Part")

	local instances: CharacterShared.Instances = {
		animator = animator,
		character = character,
		head = head,
		humanoid = humanoid,
		player = player,
		rootPart = rootPart,
	}
	playersToInstances[player] = instances
	module.characterLoaded:Fire(instances, player)
	SchedulesServer.loadCharacter.start(instances, player)

	return instances
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

module.loadPlayerJob = SchedulesServer.loadPlayer.job(function(player)
	local function onCharacterAdded(character: Model)
		assert(not playersToInstances[player], "Character is already loaded")

		-- Set instances for character immediately so the client gets the CoinHitbox as soon as possible
		setInstances(character, player)
	end

	local function onCharacterRemoving(character: Model)
		local instances = playersToInstances[player]
		assert(instances, "Character must be loaded in order to remove character")

		module.characterUnloading:Fire(instances, player)
		SchedulesServer.unloadCharacter.start(instances, player)
		playersToInstances[player] = nil
	end

	if player.Character then
		onCharacterAdded(player.Character)
	end
	local janitor = Janitor.new()
	janitor:Add(player.CharacterAdded:Connect(onCharacterAdded))
	janitor:Add(player.CharacterRemoving:Connect(onCharacterRemoving))
	playerJanitor:Add(janitor, "Destroy", player)
end)

module.unloadPlayerJob = SchedulesServer.unloadPlayer.job(function(player)
	playerJanitor:Remove(player)
end)

return module
