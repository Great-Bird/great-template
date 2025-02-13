--[[
	RandomPoint v0.2.1
	Author: Great_Bird
	Date: 2024-11-20
	Last edited: 2025-02-12

	RandomPoint library for generating uniform random points inside parts.

	Usage:
	```lua
	local RandomPoint = require(path.to.RandomPoint)

	local part = workspace.Part
	local point = RandomPoint.inPart(part) -- Works with any primitive part! Not uniform for CornerWedges.
	```

	Changelog:
	v0.2.1
	- Added file information.
	v0.2.0
	- Made random point generation functions uniformly random.
	v0.1.0
	- Notes: Release
]]

--!optimize 2

local random = Random.new()

local module = {}

--[=[
	Sets the random number generator to use for generating random points.

	@param newRandom The new random number generator to use.
]=]
local function setRandom(newRandom: Random)
	random = newRandom
end
module.setRandom = setRandom

--[=[
	Returns a uniformly random point inside the box.

	@param cframe The CFrame of the box.
	@param size The size of the box.
	@return A point inside the box.
]=]
local function inBox(cframe: CFrame, size: Vector3): Vector3
	local halfSizeX = size.X / 2
	local halfSizeY = size.Y / 2
	local halfSizeZ = size.Z / 2
	local x = random:NextNumber(-halfSizeX, halfSizeX)
	local y = random:NextNumber(-halfSizeY, halfSizeY)
	local z = random:NextNumber(-halfSizeZ, halfSizeZ)
	return cframe:PointToWorldSpace(Vector3.new(x, y, z))
end
module.inBox = inBox

--[=[
	Returns a uniformly random point inside the wedge.

	@param cframe The CFrame of the wedge.
	@param size The size of the wedge.
	@return A point inside the wedge.
]=]
local function inWedge(cframe: CFrame, size: Vector3): Vector3
	local sizeY = size.Y
	local sizeZ = size.Z
	local halfSizeX = size.X / 2
	local halfSizeY = sizeY / 2
	local halfSizeZ = sizeZ / 2
	local x = random:NextNumber(-halfSizeX, halfSizeX)
	local yProportion = 1 - random:NextNumber()
	local zProportion = random:NextNumber()
	if yProportion + zProportion > 1 then
		yProportion = 1 - yProportion
		zProportion = 1 - zProportion
	end
	local y = sizeY * yProportion - halfSizeY
	local z = (1 - sizeZ * zProportion) + halfSizeZ
	return cframe:PointToWorldSpace(Vector3.new(x, y, z))
end
module.inWedge = inWedge

--[=[
	Returns a **non-uniformly** random point inside the corner wedge.

	### Note: The distribution is not uniform.

	@param cframe The CFrame of the corner wedge.
	@param size The size of the corner wedge.
	@return A point inside the corner wedge.
]=]
local function inCornerWedge(cframe: CFrame, size: Vector3): Vector3
	local sizeX = size.X
	local sizeY = size.Y
	local sizeZ = size.Z
	local halfSizeX = sizeX / 2
	local halfSizeY = sizeY / 2
	local halfSizeZ = sizeZ / 2
	local x = random:NextNumber(-halfSizeX, halfSizeX)
	local z = random:NextNumber(-halfSizeZ, halfSizeZ)
	local xProportion = math.clamp((x + halfSizeX) / sizeX, 0, 1)
	local zProportion = 1 - math.clamp((z + halfSizeZ) / sizeZ, 0, 1)
	local proportion = math.min(xProportion, zProportion)
	local maxY = sizeY * proportion
	local y = random:NextNumber(0, maxY) - halfSizeY
	return cframe:PointToWorldSpace(Vector3.new(x, y, z))
end
module.inCornerWedge = inCornerWedge

--[=[
	Returns a uniformly random point inside the cylinder.

	Credit: https://devforum.roblox.com/t/how-to-generate-a-random-rotation-and-much-more/1549051

	@param cframe The CFrame of the cylinder.
	@param size The size of the cylinder.
	@return A point inside the cylinder.
]=]
local function inCylinder(cframe: CFrame, size: Vector3): Vector3
	local halfSizeX = size.X / 2
	local halfSizeY = size.Y / 2
	local x = random:NextNumber(-halfSizeX, halfSizeX)
	local angle = random:NextNumber(0, 2 * math.pi)
	local distance = math.sqrt(random:NextNumber()) * halfSizeY
	local y = math.sin(angle) * distance
	local z = math.cos(angle) * distance
	return cframe:PointToWorldSpace(Vector3.new(x, y, z))
end
module.inCylinder = inCylinder

--[=[
	Returns a uniformly random point on the surface of the ball within the given angle range.

	Credit: https://devforum.roblox.com/t/how-to-generate-a-random-rotation-and-much-more/1549051

	@param minAngle The minimum angle from the axis in radians.
	@param maxAngle The maximum angle from the axis in radians.
	@param axis A unit vector representing the direction to generate the point from.
	@param perpendicular A unit vector perpendicular to the axis.
	@return A point on the surface of the ball within the given angle range.
]=]
local function onBallSurfaceWithinAngle(
	cframe: CFrame,
	size: Vector3,
	minAngle: number,
	maxAngle: number,
	axis: Vector3,
	perpendicular: Vector3
): Vector3
	local lengthMin = math.cos(maxAngle)
	local lengthMax = math.cos(minAngle)
	local length = (lengthMax - lengthMin) * math.random() + lengthMin
	local radius = math.sqrt(1 - length * length)
	local angle = 2 * math.pi * math.random()
	local u, v = radius * math.cos(angle), radius * math.sin(angle)
	local position = (length * axis + u * perpendicular + v * axis:Cross(perpendicular)) * size.X / 2
	return cframe:PointToWorldSpace(position)
end
module.onBallSurfaceWithinAngle = onBallSurfaceWithinAngle

--[=[
	Returns a uniformly random point inside the ball.

	Credit: https://devforum.roblox.com/t/how-to-generate-a-random-rotation-and-much-more/1549051

	@param cframe The CFrame of the ball.
	@param size The size of the ball.
	@return A point inside the ball.
]=]
local function inBall(cframe: CFrame, size: Vector3): Vector3
	local radius = size.X / 2
	local distance = random:NextNumber() ^ (1 / 3) * radius
	return cframe:PointToWorldSpace(random:NextUnitVector() * distance)
end
module.inBall = inBall

--[=[
	Returns a uniformly random point inside the ball within the given angle range.

	Credit: https://devforum.roblox.com/t/how-to-generate-a-random-rotation-and-much-more/1549051

	@param cframe The CFrame of the ball.
	@param size The size of the ball.
	@param minAngle The minimum angle from the axis in radians.
	@param maxAngle The maximum angle from the axis in radians.
	@param axis A unit vector representing the direction to generate the point from.
	@param perpendicular A unit vector perpendicular to the axis.
	@return A point inside the ball within the given angle range.
]=]
local function inBallWithinAngle(
	cframe: CFrame,
	size: Vector3,
	minAngle: number,
	maxAngle: number,
	axis: Vector3,
	perpendicular: Vector3
): Vector3
	local lengthMin = math.cos(maxAngle)
	local lengthMax = math.cos(minAngle)
	local length = (lengthMax - lengthMin) * math.random() + lengthMin
	local radius = math.sqrt(1 - length * length)
	local angle = 2 * math.pi * math.random()
	local u, v = radius * math.cos(angle), radius * math.sin(angle)
	local outerPosition = (length * axis + u * perpendicular + v * axis:Cross(perpendicular))
	local position = random:NextNumber() ^ (1 / 3) * size.X / 2 * outerPosition
	return cframe:PointToWorldSpace(position)
end
module.inBallWithinAngle = inBallWithinAngle

--[=[
	Returns a uniformly random point inside the part using its CFrame and size, as if it were the specified shape.
	Unsupported part shapes will fall back to a box.

	Will not be uniform for `Enum.PartType.CornerWedge`.

	@param part The part to generate a random point in.
	@param shape The shape to assume the part is.
	@return A point inside the part, as if it had the given shape.
]=]
local function inPartWithShape(part: BasePart, shape: Enum.PartType): Vector3
	if shape == Enum.PartType.Block then
		return inBox(part.CFrame, part.Size)
	elseif shape == Enum.PartType.Cylinder then
		return inCylinder(part.CFrame, part.Size)
	elseif shape == Enum.PartType.Ball then
		return inBall(part.CFrame, part.Size)
	elseif shape == Enum.PartType.Wedge then
		return inWedge(part.CFrame, part.Size)
	else
		-- Unsupported part shape, fall back to box
		return inBox(part.CFrame, part.Size)
	end
end
module.inPartWithShape = inPartWithShape

--[=[
	Returns a uniformly random point inside the part.
	Unsupported part types will fall back to a box.

	Will not be uniform for `Enum.PartType.CornerWedge`.

	@param part The part to generate a random point in.
	@return A point inside the part.
]=]
local function inPart(part: BasePart): Vector3
	local className = part.ClassName
	if className == "Part" then
		return inPartWithShape(part, (part :: Part).Shape)
	elseif className == "WedgePart" then
		return inWedge(part.CFrame, part.Size)
	elseif className == "CornerWedgePart" then
		return inCornerWedge(part.CFrame, part.Size)
	else
		-- Unsupported part type, fall back to box
		return inBox(part.CFrame, part.Size)
	end
end
module.inPart = inPart

return module
