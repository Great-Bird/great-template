local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MockRBXScriptSignal = require(ReplicatedStorage.Testing.Mocks.DataTypes.MockRBXScriptSignal)

local module = {}

function module.new(id: number?)
	local displayName = "SirMockington"
	local name = "MockPlayer"
	local userId = 0
	if id then
		displayName ..= "The" .. id .. if id == 1 then "st" elseif id == 2 then "nd" elseif id == 3 then "rd" else "th"
		name ..= id
		userId = id
	end
	return {
		Character = nil,
		CharacterAdded = MockRBXScriptSignal.new(),
		CharacterRemoving = MockRBXScriptSignal.new(),
		DisplayName = displayName,
		Name = name,
		UserId = userId,
	}
end

return module
