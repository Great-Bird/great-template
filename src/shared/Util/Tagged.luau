--[[
	Tagged v0.1.1
	Author: Great_Bird
	Date: 2024-11-20
	Last updated: 2025-02-12

	Tagged utility library for writing higher-performance code that interacts with CollectionService-tagged instances.

	Usage:
	```lua
	local Tagged = require(path.to.Tagged)

	local singleInstance = Tagged.first("MyTag")
	local killbrick = Tagged.firstWhichIsA("Killbrick", "BasePart")
	local gunTool = Tagged.firstWithAncestorWhichIsA("Firearm", workspace, "Tool")

	local player = Tagged.waitForFirstWithAncestor("Player", game, "Player")

	local allTagged = Tagged.get("Tag")
	local allPartDescendantsWithTag = Tagged.descendantsWhichAre("Tag", workspace.Folder, "BasePart")

	Tagged.observeWithAncestor("Enemy", workspace, function(instance)
		local humanoid = instance.Humanoid
		local oldHealth = humanoid.Health
		local healthChangedConnection = instance.Humanoid.HealthChanged:Connect(function(newHealth)
			if newHealth < oldHealth then
				print(`Enemy {instance.Name} took an ouchie`)
			end
			oldHealth = humanoid.Health
		end)

		return function()
			healthChangedConnection:Disconnect()
		end
	end)
	```

	Changelog:
	v0.1.1 (2025-02-12)
	- Changes:
		- Added information at top of file.
	v0.1.0
	- Notes: Release
]]

local CollectionService = game:GetService("CollectionService")

local cachedCollections: { [string]: { Instance } } = {}

-- HACK: This is a workaround for stylua removing the parentheses around the return type () -> (() -> ()?) in the
-- function signatures below, which breaks the type checking. This is a bug in stylua.
type CleanupFn = () -> ()

local function getTagged(tag: string)
	if cachedCollections[tag] then
		return cachedCollections[tag]
	end

	local instances = CollectionService:GetTagged(tag)
	if #instances == 0 then
		return instances
	end

	cachedCollections[tag] = instances

	local instancesToIndexes: { [Instance]: number } = {}
	for i, instance in instances do
		instancesToIndexes[instance] = i
	end

	local addedConnection, removedConnection

	addedConnection = CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		local index = #instances + 1
		instances[index] = instance
		instancesToIndexes[instance] = index
	end)

	removedConnection = CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		local index = instancesToIndexes[instance]
		local lastIndex = #instances
		if lastIndex == 1 then
			cachedCollections[tag] = nil
			addedConnection:Disconnect()
			removedConnection:Disconnect()
			return
		end
		instancesToIndexes[instances[lastIndex]] = index
		instancesToIndexes[instance] = nil
		instances[index], instances[lastIndex] = instances[lastIndex], nil
	end)

	return instances
end

local module = {}

--[=[
	Returns the internal, cached collection of instances with the specified tag.
	
	**WARNING: Do not modify the returned table! Doing so will modify the cached collection, which will lead to undefined behavior.**
	Use this function for read-only access to the collection. Alternatively, use `all` to get a copy of the collection.
]=]
module.get = getTagged

--[=[
	Returns all instances with the specified tag.
]=]
function module.all(tag: string): { Instance }
	return table.clone(getTagged(tag))
end

--[=[
	Returns all instances with the specified tag and class.
]=]
function module.allWhichAre(tag: string, class: string)
	local taggedInstances = {}
	for _, instance in getTagged(tag) do
		if instance:IsA(class) then
			table.insert(taggedInstances, instance)
		end
	end
	return taggedInstances
end

--[=[
	Returns the first instance with the specified tag.
]=]
function module.first(tag: string): Instance?
	return getTagged(tag)[1]
end

--[=[
	Returns the first instance with the specified tag.
	If no instance is found, waits for an instance to be added with the tag.
]=]
function module.waitForFirst(tag: string): Instance
	local first = getTagged(tag)[1]
	if first then
		return first
	end
	return CollectionService:GetInstanceAddedSignal(tag):Wait()
end

--[=[
	Returns the first instance with the specified tag and class.
]=]
function module.firstWhichIsA(tag: string, class: string): Instance?
	for _, instance in getTagged(tag) do
		if instance:IsA(class) then
			return instance
		end
	end
	return nil
end

--[=[
	Returns the first instance with the specified tag and class.
	If no instance is found, waits for an instance to be added with the tag and class.
]=]
function module.waitForFirstWhichIsA(tag: string, class: string): Instance
	local first = module.firstWhichIsA(tag, class)
	if first then
		return first
	end

	local added = CollectionService:GetInstanceAddedSignal(tag)
	local current
	repeat
		current = added:Wait()
	until current:IsA(class)
	return current
end

--[=[
	Returns the first instance with the specified tag.
	Respects depth-first search, i.e. children of each instance are checked before siblings.
]=]
function module.firstDescendant(tag: string, ancestor: Instance): Instance?
	for _, instance in ancestor:GetDescendants() do
		if CollectionService:HasTag(instance, tag) then
			return instance
		end
	end
	return nil
end

local function waitForFirstDescendant(tag: string, ancestor: Instance, class: string?)
	local mainThread = coroutine.running()

	local descendantAddedConnection
	local instanceAddedConnection

	descendantAddedConnection = ancestor.DescendantAdded:Connect(function(instance)
		if CollectionService:HasTag(instance, tag) and (not class or instance:IsA(class)) then
			task.spawn(mainThread, instance)
		end
	end)

	instanceAddedConnection = CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		if instance:IsDescendantOf(ancestor) and (not class or instance:IsA(class)) then
			task.spawn(mainThread, instance)
		end
	end)

	local instance = coroutine.yield()

	descendantAddedConnection:Disconnect()
	instanceAddedConnection:Disconnect()

	return instance
end

--[=[
	Returns the first descendant of the ancestor with the specified tag.
	If no descendant is found, waits for an descendant to be added with the tag.
]=]
function module.waitForFirstDescendant(tag: string, ancestor: Instance): Instance
	local first = module.firstDescendant(tag, ancestor)
	if first then
		return first
	end
	return waitForFirstDescendant(tag, ancestor)
end

--[=[
	Returns the first descendant of the ancestor with the specified tag and class.
]=]
function module.firstDescendantWhichIsA(tag: string, ancestor: Instance, class: string): Instance?
	for _, instance in ancestor:GetDescendants() do
		if CollectionService:HasTag(instance, tag) and instance:IsA(class) then
			return instance
		end
	end
	return nil
end

--[=[
	Returns the first descendant of the ancestor with the specified tag and class.
	If no descendant is found, waits for a descendant to be added with the tag and class.
]=]
function module.waitForFirstDescendantWhichIsA(tag: string, ancestor: Instance, class: string): Instance
	local first = module.firstDescendantWhichIsA(tag, ancestor, class)
	if first then
		return first
	end
	return waitForFirstDescendant(tag, ancestor, class)
end

--[=[
	Returns the first tagged instance which is a descendant of the given ancestor.
]=]
function module.firstWithAncestor(tag: string, ancestor: Instance): Instance?
	for _, instance in getTagged(tag) do
		if instance:IsDescendantOf(ancestor) then
			return instance
		end
	end
	return nil
end

--[=[
	Returns the first tagged instance which is a descendant of the given ancestor.
	If no descendant is found, waits for a descendant to be added with the tag.
]=]
function module.waitForFirstWithAncestor(tag: string, ancestor: Instance): Instance
	local first = module.firstWithAncestor(tag, ancestor)
	if first then
		return first
	end
	return waitForFirstDescendant(tag, ancestor)
end

--[=[
	Returns the first tagged instance which is a descendant of the given ancestor and is of the specified class.
]=]
function module.firstWithAncestorWhichIsA(tag: string, ancestor: Instance, class: string): Instance?
	for _, instance in getTagged(tag) do
		if instance:IsDescendantOf(ancestor) and instance:IsA(class) then
			return instance
		end
	end
	return nil
end

--[=[
	Returns the first tagged instance which is a descendant of the given ancestor and is of the specified class.
	If no descendant is found, waits for a descendant to be added with the tag and class.
]=]
function module.waitForFirstWithAncestorWhichIsA(tag: string, ancestor: Instance, class: string): Instance
	local first = module.firstWithAncestorWhichIsA(tag, ancestor, class)
	if first then
		return first
	end
	return waitForFirstDescendant(tag, ancestor, class)
end

--[=[
	Returns the first ancestor of the instance with the specified tag.
]=]
function module.firstAncestor(tag: string, instance: Instance): Instance?
	local ancestor = instance.Parent
	while ancestor do
		if CollectionService:HasTag(ancestor, tag) then
			return ancestor
		end
		ancestor = ancestor.Parent
	end
	return nil
end

local function waitForFirstAncestor(tag: string, instance: Instance, class: string?)
	local mainThread = coroutine.running()

	local ancestryChangedConnection
	local instanceAddedConnection

	ancestryChangedConnection = instance.AncestryChanged:Connect(function(_, ancestor)
		local current = ancestor
		while current do
			if CollectionService:HasTag(current, tag) and (not class or current:IsA(class)) then
				task.spawn(mainThread, current)
			end
			current = current.Parent
		end
	end)

	instanceAddedConnection = CollectionService:GetInstanceAddedSignal(tag):Connect(function(ancestor)
		if ancestor:IsAncestorOf(instance) and (not class or ancestor:IsA(class)) then
			task.spawn(mainThread, ancestor)
		end
	end)

	local ancestor = coroutine.yield()

	ancestryChangedConnection:Disconnect()
	instanceAddedConnection:Disconnect()

	return ancestor
end

--[=[
	Returns the first ancestor of the instance with the specified tag.
	If no ancestor is found, waits for an ancestor to be added with the tag.
]=]
function module.waitForFirstAncestor(tag: string, instance: Instance): Instance
	local ancestor = module.firstAncestor(tag, instance)
	if ancestor then
		return ancestor
	end
	return waitForFirstAncestor(tag, instance)
end

--[=[
	Returns the first ancestor of the instance with the specified tag and class.
]=]
function module.firstAncestorWhichIsA(tag: string, instance: Instance, class: string): Instance?
	local ancestor = instance.Parent
	while ancestor do
		if CollectionService:HasTag(ancestor, tag) and ancestor:IsA(class) then
			return ancestor
		end
		ancestor = ancestor.Parent
	end
	return nil
end

--[=[
	Returns the first ancestor of the instance with the specified tag and class.
	If no ancestor is found, waits for an ancestor to be added with the tag and class.
]=]
function module.waitForFirstAncestorWhichIsA(tag: string, instance: Instance, class: string): Instance
	local ancestor = module.firstAncestorWhichIsA(tag, instance, class)
	if ancestor then
		return ancestor
	end
	return waitForFirstAncestor(tag, instance, class)
end

--[=[
	Returns all descendants of the given ancestor with the specified tag.
	Similar to `withAncestor`, but checks if each descendant has the tag.
	Prefer over `withAncestor` when there is a low number of descendants.
]=]
function module.descendants(tag: string, ancestor: Instance)
	local taggedDescendants = {}
	for _, instance in ancestor:GetDescendants() do
		if CollectionService:HasTag(instance, tag) then
			table.insert(taggedDescendants, instance)
		end
	end
	return taggedDescendants
end

--[=[
	Returns all descendants of the given ancestor with the specified tag and class.
	Similar to `descendants`, but checks if each descendant has the tag and class.
	Prefer over `withAncestorWhichAre` when there is a low number of descendants.
]=]
function module.descendantsWhichAre(tag: string, ancestor: Instance, class: string)
	local taggedDescendants = {}
	for _, instance in ancestor:GetDescendants() do
		if CollectionService:HasTag(instance, tag) and instance:IsA(class) then
			table.insert(taggedDescendants, instance)
		end
	end
	return taggedDescendants
end

--[=[
	Returns all tagged instances which are descendants of the given ancestor.
	Similar to `descendants`, but checks if each tagged instance is a descendant of the ancestor.
	Prefer over `descendants` when there is a low number of tagged instances.
]=]
function module.withAncestor(tag: string, ancestor: Instance)
	local taggedDescendants = {}
	for _, instance in getTagged(tag) do
		if instance:IsDescendantOf(ancestor) then
			table.insert(taggedDescendants, instance)
		end
	end
	return taggedDescendants
end

--[=[
	Returns all tagged instances which are descendants of the given ancestor and are of the specified class.
	Similar to `withAncestor`, but checks if each tagged instance is a descendant of the ancestor and is of the specified class.
	Prefer over `descendantsWhichAre` when there is a low number of tagged instances.
]=]
function module.withAncestorWhichAre(tag: string, ancestor: Instance, class: string)
	local taggedDescendants = {}
	for _, instance in getTagged(tag) do
		if instance:IsDescendantOf(ancestor) and instance:IsA(class) then
			table.insert(taggedDescendants, instance)
		end
	end
	return taggedDescendants
end

--[=[
	Returns all children of the given parent with the specified tag.
	Similar to `withParent`, but checks if each child has the tag.
	Prefer over `withParent` when there is a low number of children.
]=]
function module.children(tag: string, parent: Instance)
	local taggedChildren = {}
	for _, instance in parent:GetChildren() do
		if CollectionService:HasTag(instance, tag) then
			table.insert(taggedChildren, instance)
		end
	end
	return taggedChildren
end

--[=[
	Returns all children of the given parent with the specified tag and class.
	Similar to `children`, but checks if each child has the tag and class.
	Prefer over `withParentWhichAre` when there is a low number of children.
]=]
function module.childrenWhichAre(tag: string, parent: Instance, class: string)
	local taggedChildren = {}
	for _, instance in parent:GetChildren() do
		if CollectionService:HasTag(instance, tag) and instance:IsA(class) then
			table.insert(taggedChildren, instance)
		end
	end
	return taggedChildren
end

--[=[
	Returns all tagged instances which are children of the given parent.
	Similar to `children`, but checks if each tagged instance is a child of the parent.
	Prefer over `children` when there is a low number of tagged instances.
]=]
function module.withParent(tag: string, parent: Instance)
	local taggedChildren = {}
	for _, instance in getTagged(tag) do
		if instance.Parent == parent then
			table.insert(taggedChildren, instance)
		end
	end
	return taggedChildren
end

--[=[
	Returns all tagged instances which are children of the given parent and are of the specified class.
	Similar to `withParent`, but checks if each tagged instance is a child of the parent and is of the specified class.
	Prefer over `childrenWhichAre` when there is a low number of tagged instances.
]=]
function module.withParentWhichAre(tag: string, parent: Instance, class: string)
	local taggedChildren = {}
	for _, instance in getTagged(tag) do
		if instance.Parent == parent and instance:IsA(class) then
			table.insert(taggedChildren, instance)
		end
	end
	return taggedChildren
end

--[=[
	Observes instances with the specified tag.
	When an instance with the tag is added, the callback is called with the instance.
	When an instance with the tag is removed, the cleanup function returned by the callback is called.

	Returns a function that, when called, disconnects the observation and calls the returned cleanup function.

	```lua
	local disconnect = Tagged.observe("Tag", function(instance)
		print("Instance added:", instance)
		return function()
			print("Instance removed:", instance)
		end
	end)

	-- Later
	disconnect()
	```
]=]
function module.observe(tag: string, callback: (instance: Instance) -> CleanupFn?): () -> ()
	local cleanupFns: { [Instance]: () -> () } = {}

	local function onInstanceAdded(instance: Instance)
		cleanupFns[instance] = callback(instance) :: () -> ()
	end

	local function onInstanceRemoved(instance: Instance)
		local cleanupFn = cleanupFns[instance]
		if cleanupFn then
			cleanupFn()
			cleanupFns[instance] = nil
		end
	end

	for _, instance in getTagged(tag) do
		task.spawn(onInstanceAdded, instance)
	end

	local addedConn = CollectionService:GetInstanceAddedSignal(tag):Connect(onInstanceAdded)
	local removedConn = CollectionService:GetInstanceRemovedSignal(tag):Connect(onInstanceRemoved)

	return function()
		addedConn:Disconnect()
		removedConn:Disconnect()
		for instance, cleanupFn in cleanupFns do
			cleanupFn()
		end
		table.clear(cleanupFns)
	end
end

--[=[
	Observes instances with the specified tag that are descendants of the ancestor.
	When an instance with the tag is added and is a descendant of the ancestor, the callback is called with the instance.
	When an instance with the tag is removed or is no longer a descendant of the ancestor, the cleanup function returned by the callback is called.

	Returns a function that, when called, disconnects the observation and calls the returned cleanup function.

	```lua
	local disconnect = Tagged.observeUnderAncestor("Tag", ancestor, function(instance)
		print("Instance added:", instance)
		return function()
			print("Instance removed:", instance)
		end
	end)

	-- Later
	disconnect()
	```
]=]
function module.observeWithAncestor(
	tag: string,
	ancestor: Instance,
	callback: (instance: Instance) -> CleanupFn?
): () -> ()
	local cleanupFns: { [Instance]: () -> () } = {}
	local ancestryConnections = {}

	local function onAncestryChanged(instance: Instance)
		if ancestor:IsAncestorOf(instance) then
			if not cleanupFns[instance] then
				cleanupFns[instance] = callback(instance) :: () -> ()
			end
		else
			local cleanupFn = cleanupFns[instance]
			-- Don't disconnect the `AncestryChanged` connection here, as we want to detect if the instance is reparented back
			if cleanupFn then
				cleanupFn()
				cleanupFns[instance] = nil
			end
		end
	end

	local function onInstanceAdded(instance: Instance)
		onAncestryChanged(instance)
		ancestryConnections[instance] = instance.AncestryChanged:Connect(function(child, parent)
			onAncestryChanged(instance)
		end)
	end

	local function onInstanceRemoved(instance: Instance)
		local cleanupFn = cleanupFns[instance]
		if cleanupFn then
			cleanupFn()
			cleanupFns[instance] = nil
			ancestryConnections[instance]:Disconnect()
			ancestryConnections[instance] = nil
		end
	end

	for _, instance in getTagged(tag) do
		task.spawn(onInstanceAdded, instance)
	end

	local addedConn = CollectionService:GetInstanceAddedSignal(tag):Connect(onInstanceAdded)
	local removedConn = CollectionService:GetInstanceRemovedSignal(tag):Connect(onInstanceRemoved)

	return function()
		addedConn:Disconnect()
		removedConn:Disconnect()

		for instance, cleanupFn in cleanupFns do
			cleanupFn()
		end
		table.clear(cleanupFns)

		for instance, conn in ancestryConnections do
			conn:Disconnect()
		end
		table.clear(ancestryConnections)
	end
end

return module
