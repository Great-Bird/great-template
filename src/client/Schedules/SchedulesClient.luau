local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Schedule = require(ReplicatedStorage.Shared.Util.Schedule)
local CharacterShared = require(ReplicatedStorage.Shared.Character.CharacterShared)

--[[
	Each schedule is a queue of functions that will be executed in order. This is useful for ensuring that certain
	functions will run after others. For example, you may want to load a player's backpack after loading their character.
]]
return {
	initialize = Schedule.parallel() :: Schedule.ParallelSchedule<>,
	start = Schedule.parallel() :: Schedule.ParallelSchedule<>,

	loadPlayer = Schedule.parallel() :: Schedule.ParallelSchedule<Player>,
	unloadPlayer = Schedule.parallel() :: Schedule.ParallelSchedule<Player>,
	loadLocalPlayer = Schedule.parallel() :: Schedule.ParallelSchedule<Player>,
	unloadLocalPlayer = Schedule.parallel() :: Schedule.ParallelSchedule<Player>,

	loadCharacter = Schedule.parallel() :: Schedule.ParallelSchedule<CharacterShared.Instances, Player>,
	unloadCharacter = Schedule.parallel() :: Schedule.ParallelSchedule<CharacterShared.Instances, Player>,
	loadLocalCharacter = Schedule.parallel() :: Schedule.ParallelSchedule<CharacterShared.Instances, Player>,
	unloadLocalCharacter = Schedule.parallel() :: Schedule.ParallelSchedule<CharacterShared.Instances, Player>,

	heartbeat = Schedule.parallel() :: Schedule.ParallelSchedule<number>,
	stepped = Schedule.parallel() :: Schedule.ParallelSchedule<number>,
	renderStepped = Schedule.parallel() :: Schedule.ParallelSchedule<number>,
	preRender = Schedule.parallel() :: Schedule.ParallelSchedule<number>,
	preAnimation = Schedule.parallel() :: Schedule.ParallelSchedule<number>,
	preSimulation = Schedule.parallel() :: Schedule.ParallelSchedule<number>,
	postSimulation = Schedule.parallel() :: Schedule.ParallelSchedule<number>,
}
