--[[
	Loader v0.1.0
	Author: Great_Bird
	Date: 2025-02-12
	Last updated: 2025-02-12

	Utilities for loading and running modules in Luau.

	Changelog:
	v0.1.0 (2025-02-12)
	- Notes: Release
]]

local module = {}

--[=[
	@param callback The function to call.
	@param ... The arguments to pass to the function.
	@return { success: true, yielded: boolean } | { success: false, error: string }	

	Detects if a function yielded when called.
]=]
function module.callNoYield<A...>(
	callback: (A...) -> (),
	...: A...
): { success: true, yielded: boolean } | { success: false, error: string }
	local thread = coroutine.create(callback)
	local success, err = coroutine.resume(thread, ...)
	local yielded = coroutine.status(thread) == "suspended"
	coroutine.close(thread) -- Stop the thread from running if it has yielded
	if not success then
		return { success = success, error = err }
	end
	return { success = success, yielded = yielded }
end

--[=[
	Returns whether the path to the passed module (i.e. `ReplicatedStorage/Folder/Subfolder/Module`) matches the given patterns.
	The path is constructed by concatenating the names of the ancestors of the module, separated by `/`.

	@param module The module to check.
	@param nameMatches A list of patterns which the module path must match at least one of.
	@param ignoreMatches A list of patterns that the module path must not match.
	@return Whether the module passed.
]=]
function module.filterModulePath(module: ModuleScript, nameMatches: { string }?, ignoreMatches: { string }?): boolean
	if not nameMatches and not ignoreMatches then
		return true
	end

	local ancestry = { module.Name }
	do
		local current = module.Parent
		while current do
			table.insert(ancestry, 1, current.Name)
			current = current.Parent
		end
	end
	local name = table.concat(ancestry, "/")

	if nameMatches then
		local nameMatch = false
		for _, match in nameMatches do
			if string.match(name, match) then
				nameMatch = true
				break
			end
		end
		if not nameMatch then
			return false
		end
	end

	if ignoreMatches then
		for _, match in ignoreMatches do
			if string.match(name, match) then
				return false
			end
		end
	end

	return true
end

--[=[
	Require all top-level modules (modules which are not children of other modules).

	@param ancestor The ancestor to search for top-level modules.
	@return A map of ModuleScripts to their respective modules.
]=]
function module.loadTopLevelModules(
	ancestor: Instance,
	nameMatches: { string }?,
	ignoreMatches: { string }?
): { [ModuleScript]: any }
	local moduleScriptsToModules: { [ModuleScript]: any } = {}
	local stack = { ancestor }
	while #stack > 0 do
		local instance = table.remove(stack) :: Instance
		if instance:IsA("ModuleScript") then
			if not module.filterModulePath(instance, nameMatches, ignoreMatches) then
				continue
			end

			local _, returnedModule = xpcall(require, function(err)
				error(`Failed to require {instance:GetFullName()}: {err}`)
			end, instance)
			
			moduleScriptsToModules[instance] = returnedModule
		else
			local children = instance:GetChildren()
			table.move(children, 1, #children, #stack + 1, stack)
		end
	end
	return moduleScriptsToModules
end

return module
