--[[
	VFXUtil v0.2.1
	Author: Great_Bird
	Date: 2024-09-21
	Last updated: 2025-05-10

	Utilities for creating visual effects in Roblox.

	Changelog:
	v0.2.1 (2025-05-10)
	- Added:
		- `VFXUtil.enableVFX` function to enable ParticleEmitters, Beams, Decals, and Lights.
	v0.2.0 (2025-02-12)
	- Breaking:
		- Removed `VFXUtil.lerp` in favor of `math.lerp`.
	v0.1.0 (2024-09-21)
	- Notes: Release
]]

--!strict

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local vfxFolder = Instance.new("Folder")
do
	vfxFolder.Name = "_VFX"
	vfxFolder.Parent = workspace
end

export type VFXTween = {
	updateConnection: RBXScriptConnection,
	updateCallback: UpdateCallback,
	cancel: () -> (),
	finish: () -> (),
	pause: () -> (),
	play: () -> (),
}
export type TweenFinishedCallback = ("Canceled" | "Completed") -> ()
export type UpdateCallback = (alpha: number) -> ()

local module = {}

--[=[
	Takes a TweenInfo and simulates a tween by calling `updateCallback` with an `alpha` parameter.
	The `updateCallback` describes the tweened state at a specific point in time.
	The `onFinished` callback is called after the tween is complete.

	```lua
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local oldPos = part.Position
	local newPos = oldPos + Vector3.yAxis * 5
	local updateCallback = function(alpha)
		part.Position = oldPos:Lerp(newPos)
	end
	local onFinished = function()
		print("Tween is done!")
	end
	VFXUtil.tween(tweenInfo, updateCallback, onFinished)
	```

	This function returns an object.
	Return object properties:
	* `updateConnection` - The connection that updates the tween.

	Return object methods:
	* `cancel` - Cancels the tween and calls `onFinished` with "Canceled".
	* `finish` - Finishes the tween and calls `onFinished` with "Completed".
	* `pause` - Pauses the tween.
	* `play` - Plays or unpauses the tween.
]=]
local function tween(tweenInfo: TweenInfo, updateCallback: (alpha: number) -> (), onFinished: TweenFinishedCallback?)
	local repeatCount = tweenInfo.RepeatCount
	local delayTime = tweenInfo.DelayTime
	local tweenTime = tweenInfo.Time
	local easingStyle = tweenInfo.EasingStyle
	local easingDirection = tweenInfo.EasingDirection
	local reverses = tweenInfo.Reverses

	local timeElapsed = 0
	local cycleTime = (if reverses then 2 else 1) * tweenTime
	local fullTweenTime = if repeatCount < 0 then math.huge else (cycleTime + delayTime) * (repeatCount + 1)

	local connection: RBXScriptConnection

	local function cancel()
		connection:Disconnect()
		updateCallback(0)
		if onFinished then
			onFinished("Canceled")
		end
	end

	local function finish()
		connection:Disconnect()
		updateCallback(1)
		if onFinished then
			onFinished("Completed")
		end
	end

	local function pause()
		connection:Disconnect()
	end

	local function update(dt: number)
		timeElapsed += dt

		if timeElapsed >= fullTweenTime then
			connection:Disconnect()
			if reverses then
				updateCallback(0)
			else
				updateCallback(1)
			end
			if onFinished then
				onFinished("Completed")
			end
			return
		end

		-- We don't need to handle the case where alpha is greater than 1, because we've already handled the case where
		-- timeElapsed is greater than tweenTime
		local timeElapsedThisCycle = timeElapsed % cycleTime
		local alpha = math.max(0, timeElapsedThisCycle) / cycleTime
		if reverses and timeElapsedThisCycle > tweenTime then
			alpha = 1 - alpha
		end
		local easedAlpha = TweenService:GetValue(alpha, easingStyle, easingDirection)
		updateCallback(easedAlpha)
	end

	local function play()
		connection = RunService.Heartbeat:Connect(update)
	end

	play()

	return {
		updateCallback = updateCallback,
		updateConnection = connection,

		cancel = cancel,
		finish = finish,
		pause = pause,
		play = play,
	}
end
module.tween = tween

--[=[
	Tweens the scale of the model.
]=]
function module.tweenScale(model: Model, tweenInfo: TweenInfo, newScale: number, onFinished: TweenFinishedCallback?)
	local originalScale = model:GetScale()

	local function update(alpha: number)
		model:ScaleTo(math.lerp(originalScale, newScale, alpha))
	end

	return tween(tweenInfo, update, onFinished)
end

--[=[
	Tweens the pivot of the model.
]=]
function module.tweenPivot(model: Model, tweenInfo: TweenInfo, newPivot: CFrame, onFinished: TweenFinishedCallback?)
	local originalPivot = model:GetPivot()

	local function update(alpha: number)
		model:PivotTo(originalPivot:Lerp(newPivot, alpha))
	end

	return tween(tweenInfo, update, onFinished)
end

--[=[
	Gets the maximum time ParticleEmitters inside the passed instance will stay visible for.
	Useful for waiting until all particles have disappeared on their own before deleting the VFX.
]=]
function module.getMaxParticleLifetime(root: PVInstance): number
	local maxLifetime = 0

	for _, descendant in root:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			maxLifetime = math.max(maxLifetime, descendant.Lifetime.Max)
		end
	end

	return maxLifetime
end

--[=[
	Enables ParticleEmitters, Beams, Decals, and Lights inside the passed instance.
	Useful for starting a continued effect.
]=]
function module.enableVFX(root: PVInstance)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = true
		elseif descendant:IsA("Beam") then
			descendant.Enabled = true
		elseif descendant:IsA("Light") then
			descendant.Enabled = true
		elseif descendant:IsA("Decal") then
			descendant.Transparency = 0
		end
	end
end

--[=[
	Disables ParticleEmitters, Beams, Decals, and Lights inside the passed instance.
	Useful for stopping an effect without removing existing particles.
	Returns the max particle lifetime for the effect, similarly to `VFXUtil.getMaxParticleLifetime`.
]=]
function module.disableVFX(root: PVInstance): number
	local maxLifetime = 0
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			maxLifetime = math.max(maxLifetime, descendant.Lifetime.Max)
			descendant.Enabled = false
		elseif descendant:IsA("Beam") then
			descendant.Enabled = false
		elseif descendant:IsA("Light") then
			descendant.Enabled = false
		elseif descendant:IsA("Decal") then
			descendant.Transparency = 1
		end
	end
	return maxLifetime
end

--[=[
	Clones the passed instance, and then calls Emit on all descendant ParticleEmitters with an EmitCount attribute.
	Returns the thread used to destroy the cloned instance and call `onFinished`, as well as
	the cloned instance. If you cancel the thread, the onus is on you to call `onFinished` and
	destroy the instance.
]=]
function module.emitParticles(
	root: PVInstance,
	cframe: CFrame,
	onFinished: (lifetime: number) -> ()?
): (PVInstance, thread)
	local vfx = root:Clone()
	vfx:PivotTo(cframe)
	vfx.Parent = vfxFolder

	local maxLifetime = 0

	local function finish()
		vfx:Destroy()
		if onFinished then
			onFinished(maxLifetime)
		end
	end

	for _, descendant in vfx:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			maxLifetime = math.max(maxLifetime, descendant.Lifetime.Max)

			local emitCount = tonumber(descendant:GetAttribute("EmitCount"))
			local emitDelay = tonumber(descendant:GetAttribute("EmitDelay"))
			if not emitCount then
				continue
			end

			if emitDelay then
				maxLifetime = math.max(maxLifetime, descendant.Lifetime.Max + emitDelay)
				task.delay(emitDelay, function()
					descendant:Emit(emitCount)
				end)
			else
				descendant:Emit(emitCount)
			end
		end
	end

	return vfx, task.delay(maxLifetime, finish)
end

return module
