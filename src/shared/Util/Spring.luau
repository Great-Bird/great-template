--[[
	Spring v0.2.0
	Authors: SOLARSCUFFLE_BOT, Great_Bird
	Date: 2024-10-21

	Simple spring implementation for Roblox Luau.
	
	Changelog:
	v0.2.0
	- Breaking:
		- Stopped returning `spring.disconnect` from `Spring.new` and `Spring.cframe`
	v0.1.1
	- Changed:
		- Made changed types optional
		- Made disconnect a method of the spring
	- Fixed:
		- Bug with iterating over indexes instead of springs in the cframeSprings table
		- Type errors with calling `spring:changed`
	v0.1.0
	- Notes: Release
]]

--!nonstrict

local RunService = game:GetService("RunService")

local Spring = {}

export type Spring<T> = {
	frequency: number,
	damping: number,
	target: T,
	position: T,
	velocity: T,

	changed: (self: Spring<T>) -> ()?,
	disconnect: () -> (),
}

export type SpringCFrame = {
	frequency: number,
	angularFrequency: number,
	damping: number,
	angularDamping: number,

	target: CFrame,
	position: CFrame,

	velocity: Vector3,
	angularVelocity: Vector3,

	changed: (self: SpringCFrame) -> ()?,
	disconnect: () -> (),
}

-- The Runge-Kutta numerical integration of a dampened spring over elements of a field
local function springRungeKutta<T>(dt: number, position: T, velocity: T, frequency: number, damping: number): (T, T)
	local x1 = position
	local x2 = velocity
	local w = frequency
	local d = -2 * damping

	local w2 = w ^ 2
	local dt2 = 0.5 * dt

	local k1x = x2
	local k1v = d * w * x2 - w2 * x1

	local k2x = x2 + k1v * dt2
	local k2v = d * w * (x2 + k1v * dt2) - w2 * (x1 + k1x * dt2)

	local k3x = x2 + k2v * dt2
	local k3v = d * w * (x2 + k2v * dt2) - w2 * (x1 + k2x * dt2)

	local k4x = x2 + k3v * dt
	local k4v = d * w * (x2 + k3v * dt) - w2 * (x1 + k3x * dt)

	local dt6 = dt / 6
	local y1 = x1 + dt6 * (k1x + 2 * k2x + 2 * k3x + k4x)
	local y2 = x2 + dt6 * (k1v + 2 * k2v + 2 * k3v + k4v)

	return y1, y2
end

local function fieldUpdate<T>(self: Spring<T>, dt: number): T
	local g = self.target
	local p, v = springRungeKutta(dt, self.position - g, self.velocity, self.frequency, self.damping)
	self.position, self.velocity = p + g, v
	if self.changed then
		self.changed(self)
	end
	return p
end
Spring.update = fieldUpdate

local PI = math.pi
local TAU = 2 * PI

local function cframeUpdate(self: SpringCFrame, dt: number): CFrame
	-- Compute displacement relative to target
	local displacement = self.position.Position - self.target.Position
	-- Apply the damped spring model using Runge-Kutta integration
	local newDisplacement, newVelocity = springRungeKutta(dt, displacement, self.velocity, self.frequency, self.damping)
	-- Compute the change in displacement
	local deltaDisplacement = newDisplacement - displacement
	-- Update position incrementally
	self.velocity = newVelocity

	-- Compute the relative rotation from current to target
	local deltaCF = self.position.Rotation * self.target.Rotation:Inverse()
	local deltaAxis, deltaAngle = deltaCF:ToAxisAngle()
	-- Ensure angle is within [-pi, pi]
	if deltaAngle > PI then
		deltaAngle = deltaAngle - TAU
	elseif deltaAngle < -PI then
		deltaAngle = deltaAngle + TAU
	end
	-- Represent rotational displacement as a vector
	local rotationDisplacement = deltaAxis * deltaAngle
	-- Apply the damped spring model using Runge-Kutta integration
	local newRotationDisplacement, newAngularVelocity =
		springRungeKutta(dt, rotationDisplacement, self.angularVelocity, self.angularFrequency, self.angularDamping)
	-- Compute the change in rotational displacement
	local deltaRotationDisplacement = newRotationDisplacement - rotationDisplacement
	-- Reconstruct the incremental rotation
	local newDeltaAngle = deltaRotationDisplacement.Magnitude
	local newDeltaAxis = Vector3.new(0, 1, 0) -- Default axis
	if newDeltaAngle > 1e-8 then
		newDeltaAxis = deltaRotationDisplacement / newDeltaAngle
	else
		newDeltaAngle = 0
	end
	-- Create the incremental rotation CFrame
	local incrementalRotation = CFrame.fromAxisAngle(newDeltaAxis, newDeltaAngle)
	self.angularVelocity = newAngularVelocity

	-- Update rotation incrementally
	self.position = (incrementalRotation * self.position.Rotation) + (deltaDisplacement + self.position.Position)

	if self.changed then
		self.changed(self)
	end

	return self.position
end
Spring.updateCFrame = cframeUpdate

local linearSprings = {}
Spring.linearSprings = linearSprings

local cframeSprings = {}
Spring.cframeSprings = cframeSprings

function Spring.new<T>(
	initialPosition: T,
	frequency: number,
	damping: number,
	onChanged: (self: Spring<T>) -> ()?
): Spring<T>
	local self = {
		frequency = frequency,
		damping = damping,
		target = initialPosition,
		position = initialPosition,
		velocity = ((initialPosition :: any) * 0) :: T,
	}

	self.changed = onChanged

	table.insert(linearSprings, self)

	function self.disconnect()
		local index = table.find(linearSprings, self)
		if index then
			local last = #linearSprings
			linearSprings[index], linearSprings[last] = linearSprings[last], nil
		end
	end

	return self
end

function Spring.cframe(
	initialPosition: CFrame,
	frequency: number,
	damping: number,
	angularFrequency: number,
	angularDamping: number,
	onChanged: (self: SpringCFrame) -> ()?
): SpringCFrame
	local self = {
		target = initialPosition,
		position = initialPosition,
		frequency = frequency,
		angularFrequency = angularFrequency,
		damping = damping,
		angularDamping = angularDamping,
		velocity = Vector3.zero,
		angularVelocity = Vector3.zero,
	}

	self.changed = onChanged

	table.insert(cframeSprings, self)

	function self.disconnect()
		local index = table.find(cframeSprings, self)
		if index then
			local last = #cframeSprings
			cframeSprings[index], cframeSprings[last] = cframeSprings[last], nil
		end
	end

	return self
end

local connection
function Spring.connect()
	if connection then
		return
	end

	connection = RunService.Heartbeat:Connect(function(deltaTime)
		local dt = math.min(1 / 60, deltaTime)

		for _, spring in linearSprings do
			fieldUpdate(spring, dt)
		end

		for _, spring in cframeSprings do
			cframeUpdate(spring, dt)
		end
	end)
end

function Spring.disconnect()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

Spring.connect()

return Spring
