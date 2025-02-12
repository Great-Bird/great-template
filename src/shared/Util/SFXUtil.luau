--[[
	SFXUtil v0.2.0
	Author: Great_Bird
	Date: 2024-09-21
	Last updated: 2025-02-12

	Utilities for playing sound effects and music in Roblox.

	Sound effects usage:
	```lua
	local SFXUtil = require(path.to.SFXUtil)

	-- SFXUtil.sfx points to the instance at SoundService.SFX. You can change this at runtime if you want to use a different path.
	local stoneBreakSound = SFXUtil.sfx.StoneBreak
	local stoneBreakSoundConfig: SFXUtil.SFXConfig = {
		-- Sound properties
		volume = 0.5,
		playbackSpeed = 1.5,
		looped = true,

		-- nil by default. If set, multiplies the volume by a random number between this value and its reciprocal.
		playbackSpeedRandomnessFactor = 1.2,

		-- false by default. Controls whether the sound is destroyed once it stops playing.
		preserveWhenDone = false,

		-- See the SFXUtil.SFXConfig type definition for more options.
	}
	
	-- Plays a sound which, by default, will be destroyed once it stops playing.
	local clonedSound = SFXUtil.playSound(stoneBreakSound, stoneBreakSoundConfig)
	task.wait(0.5)
	clonedSound:Stop() -- Will destroy the sound
	```

	Music usage:
	```lua
	local SFXUtil = require(path.to.SFXUtil)

	-- SFXUtil.music points to the instance at SoundService.Music. You can change this at runtime if you want to use a different path.
	local epicMusic = SFXUtil.music.EpicMusic
	local epicMusicConfig: SFXUtil.MusicConfig = {
		-- Sound properties
		volume = 0.5,
		playbackSpeed = 1.5,
		looped = true,

		-- MusicConfig supports the same fields as SFXConfig, with some extra fields.
		playbackSpeedRandomnessFactor = 1.2,
		preserveWhenDone = false,

		-- TweenInfo for cross-fading the music in and out.
		fadeTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0),

		-- See the SFXUtil.MusicConfig type definition for more options.
	}
	```

	Changelog:
	v0.2.0 (2025-02-12)
	- Breaking:
		- Made all SFXConfig and MusicConfig properties camelCase.
		- Changed `SFXConfig.Local` to `SFXConfig.playLocally`.
	- Changes:
		- Allow `nil` to be passed into `SFXUtil.playMusic` to fade out music.
		- Added documentation at the top of the file.
	v0.1.0 (2024-09-21)
	- Notes: Release
]]

--!strict

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local isServer = RunService:IsServer()
local currentMusic: Sound? = nil

local crossFadeConnection: RBXScriptConnection? = nil

--- @class SFXUtil
local module = {
	-- If these are not the paths you want to use, change them at runtime
	sfx = SoundService:FindFirstChild("SFX"),
	music = SoundService:FindFirstChild("Music"),
}

--[=[
	@interface SFXConfig
	@within SFXUtil
	
	.playbackSpeedRandomnessFactor number?
	If set, multiplies the playback speed by a random number between this value and its reciprocal.
	For example, if set to 2, will multiply the sound's PlaybackSpeed by random(0.5, 2).
	This is useful for adding some variance to a rapidly repeated sound.

	.volumeRandomnessFactor number?
	If set, multiplies the volume by a random number between this value and its reciprocal.
	For example, if set to 2, will multiply the sound's Volume by random(0.5, 2).
	This is useful for adding some variance to a rapidly repeated sound.
	
	.playLocally boolean?
	If set, uses `SoundService:PlayLocalSound` to play the sound.
	Note: `SoundService:PlayLocalSound` is not equivalent to `sound:Play`. Properties changes will not
	affect the sound, and events will not fire.
	
	.usePassedInstance boolean?
	If set to true, does not clone the passed sound.
	This is useful if you have a pre-configured sound you want to play.
	
	.volumeFactor number?
	If set, multiplies the sound's volume by this value.
	This is useful if each sound needs its volume set individually, but you want control over how loud
	they play.
	
	.preserveWhenDone boolean?
	If set, does not destroy the sound instance once it stops playing audio on `sound.Ended`,
	`sound.Paused`, and `sound.Stopped`.
	Only set this property if you intend on using the sound after it stops playing.
	
	.rollOffMinDistance number?,
	.rollOffMaxDistance number?,
	.PlaybackSpeed number?,
	.volume number?,
	.looped boolean?,
	.timePosition number?,
	
	A specification for how to play a sound.
]=]
export type SFXConfig = {
	playbackSpeedRandomnessFactor: number?,
	volumeRandomnessFactor: number?,
	playLocally: boolean?,
	usePassedInstance: boolean?,
	volumeFactor: number?,
	preserveWhenDone: boolean?,

	rollOffMinDistance: number?,
	rollOffMaxDistance: number?,
	PlaybackSpeed: number?,
	volume: number?,
	looped: boolean?,
	timePosition: number?,
}

--[=[
	@interface MusicConfig
	@within SFXUtil
	
	.fadeTweenInfo TweenInfo?
	The TweenInfo to use for cross-fading music.
	If you'd like to set TweenInfo specifically for fading in or out, see `fadeInTweenInfo` and
	`fadeOutTweenInfo`.
	
	.fadeInTweenInfo TweenInfo?
	The TweenInfo to use for fading in the new music.
	
	.fadeOutTweenInfo TweenInfo?
	The TweenInfo to use for fading out the old music.
]=]
export type MusicConfig = SFXConfig & {
	fadeTweenInfo: TweenInfo?,
	fadeInTweenInfo: TweenInfo?,
	fadeOutTweenInfo: TweenInfo?,
}

--[=[
	Gets a list of sounds starting with `name`, followed by a number.
	For example: Sound1, Sound2, ..., SoundN, where N = `amount`.
	
	@param name string -- The name of the sound effect, e.g. "Sound".
	@param parent Instance -- The parent to check the children of.
	@param amount number? -- The amount of sounds to return. Defaults to nil, in which case the function returns all sounds with the title.
	@return { Sound }
]=]
function module.getSoundList(name: string, parent: Instance, amount: number?): { Sound }
	local sounds: { Sound } = {}

	local maxAmount = amount or math.huge

	repeat
		local instance = parent:FindFirstChild(name .. #sounds + 1, true)
		if instance then
			if not instance:IsA("Sound") then
				error(`{instance:GetFullName()} is not a Sound`)
			end

			table.insert(sounds, instance)
		end
	until #sounds >= maxAmount or not instance

	return sounds
end

local function applyConfig(sound: Sound, config: SFXConfig)
	if config.rollOffMaxDistance then
		sound.RollOffMaxDistance = config.rollOffMaxDistance
	end
	if config.rollOffMinDistance then
		sound.RollOffMinDistance = config.rollOffMinDistance
	end
	if config.volume then
		sound.Volume = config.volume
	end
	if config.PlaybackSpeed then
		sound.PlaybackSpeed = config.PlaybackSpeed
	end
	if config.looped then
		sound.Looped = config.looped
	end
	if config.timePosition then
		sound.TimePosition = config.timePosition
	end

	local volumeFactor = config.volumeFactor
	if volumeFactor then
		sound.Volume *= volumeFactor
	end

	local playbackSpeedRandomFactor = config.playbackSpeedRandomnessFactor
	if playbackSpeedRandomFactor then
		sound.PlaybackSpeed *= math.random() * (playbackSpeedRandomFactor - 1 / playbackSpeedRandomFactor) + 1 / playbackSpeedRandomFactor
	end

	local volumeRandomFactor = config.volumeRandomnessFactor
	if volumeRandomFactor then
		sound.Volume *= math.random() * (volumeRandomFactor - 1 / volumeRandomFactor) + 1 / volumeRandomFactor
	end
end

local function playSound(sound: Sound, config: SFXConfig?)
	local sfxConfig: SFXConfig = config or {}

	-- Make sure the sound will actually play, in case the user did not specify the sound's parent.
	if not sound.Parent then
		sound.Parent = SoundService
	end

	if sfxConfig.playLocally and not isServer then
		SoundService:PlayLocalSound(sound)
	else
		sound:Play()
	end
end

local function createDisposableClone(sound: Sound, config: SFXConfig)
	local clone = sound:Clone()

	if not config.preserveWhenDone then
		-- Destroy the sound when not in use
		local function destroySound()
			clone:Destroy()
		end

		clone.Stopped:Once(destroySound)
		clone.Ended:Once(destroySound)
		clone.Paused:Once(destroySound)
	end

	return clone
end

--[=[
	Applies the SFXConfig on the sound.
	
	@param sound Sound -- The sound to apply the SFXConfig on.
	@param config SFXConfig -- The SFXConfig to apply onto the sound.
	@return Sound -- The resulting sound. Will be a clone of the passed sound, unless `config.usePassedInstance` is specified.
]=]
function module.applyConfig(sound: Sound, config: SFXConfig): Sound
	if not config.usePassedInstance then
		sound = createDisposableClone(sound, config)
	end

	applyConfig(sound, config)

	return sound
end

--[=[
	Plays a sound. Destroys the sound immediately if it stops playing.
	
	@param sound Sound -- The sound to play.
	@param config SFXConfig? -- A table describing how to play the sound.
	@param parent Instance? -- The instance to parent the sound to.
	@return Sound -- The sound that was played. Usually a clone.
]=]
function module.playSound(sound: Sound, config: SFXConfig?, parent: Instance?): Sound
	sound = module.applyConfig(sound, config or {})
	if parent then
		sound.Parent = parent
	end

	playSound(sound, config)

	return sound
end

local function fadeOutMusic(sound: Sound, config: MusicConfig)
	local tweenInfo = config.fadeOutTweenInfo or config.fadeTweenInfo

	if not (sound.IsPlaying and tweenInfo and (tweenInfo.Time > 0 or tweenInfo.DelayTime > 0)) then
		sound:Stop() -- Always fire `Stopped` event
		return
	end

	local tween = TweenService:Create(sound, tweenInfo, {
		Volume = 0,
	})
	tween:Play()
	tween.Completed:Once(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed then
			sound:Stop()
		end
	end)
end

local function fadeInMusic(sound: Sound, config: MusicConfig)
	local tweenInfo = config.fadeInTweenInfo or config.fadeTweenInfo

	if not tweenInfo then
		playSound(sound, config)
		return
	end

	local fullVolume = sound.Volume
	sound.Volume = 0
	local tween = TweenService:Create(sound, tweenInfo, {
		Volume = fullVolume,
	})
	tween:Play()

	local connection: RBXScriptConnection
	connection = tween:GetPropertyChangedSignal("PlaybackState"):Connect(function()
		local playbackState = tween.PlaybackState

		if playbackState == Enum.PlaybackState.Playing or playbackState == Enum.PlaybackState.Completed then
			-- Only play the sound once the tween is playing. This prevents the music from sounding
			-- "cut off" from the beginning if `TweenInfo.DelayTime` is set.
			playSound(sound, config)
			connection:Disconnect()
		elseif playbackState == Enum.PlaybackState.Cancelled or playbackState == Enum.PlaybackState.Paused then
			-- A new tween may have been created on the sound. Stop waiting to play the sound again.
			connection:Disconnect()
		end
	end)
	crossFadeConnection = connection
end

local function crossFadeMusic(sound: Sound?, config: MusicConfig?)
	local musicConfig: MusicConfig = config or {}

	-- Cancel any previous fading
	if crossFadeConnection then
		crossFadeConnection:Disconnect()
	end

	local lastMusic = currentMusic
	if lastMusic then
		fadeOutMusic(lastMusic, musicConfig)
	end

	currentMusic = sound
	-- We don't need to fade in if the new music is nothing
	if sound then
		fadeInMusic(sound, musicConfig)
	end
end

--[=[
	Plays music. Destroys the sound immediately if it stops playing.
	Only one music sound can play at a time. When called while some music is being played,
	each sound will have its volume smoothly transitioned.
	
	@param sound Sound? -- The sound to play. Pass nil to fade out music.
	@param config MusicConfig? -- A table describing how to play the music.
	@param parent Instance? -- The instance to parent the sound to.
	@return Sound -- The sound that was played. Usually a clone.
]=]
function module.playMusic(sound: Sound?, config: MusicConfig?, parent: Instance?): Sound
	if sound then
		sound = module.applyConfig(sound, config or {})
		if parent then
			sound.Parent = parent
		end
	end

	crossFadeMusic(sound, config)

	return sound :: Sound
end

--[=[
	Stops music from being played.
	
	@param config MusicConfig? -- A table describing how to stop playing the music. If not specified, immediately stops the music.
]=]
function module.stopMusic(config: MusicConfig?)
	crossFadeMusic(nil, config)
end

return module
