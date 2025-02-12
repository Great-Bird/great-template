local Players = game:GetService("Players")

export type Instances = {
	animator: Animator,
	character: Model,
	head: Part,
	humanoid: Humanoid,
	player: Player,
	rootPart: Part,
}

local module = {}

function module.getPlayerFromInstance(instance: Instance): Player?
	local current: Instance? = instance
	while current do
		local player = Players:GetPlayerFromCharacter(current :: any)
		if player then
			return player
		end
		current = current:FindFirstAncestorOfClass("Model")
	end
	return nil
end

return module
