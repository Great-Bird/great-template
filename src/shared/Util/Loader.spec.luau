local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)

local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

describe("Loader", function()
	local Loader

	beforeEach(function()
		jest.resetModules()

		Loader = require(script.Parent.Loader)
	end)

	describe(".callNoYield", function()
		local function returns()
			return "hello"
		end

		local function yields()
			task.wait()
			return "hello"
		end

		local function errors()
			error("error")
		end

		it("returns success=true and yielded=false when the function does not yield", function()
			local result = Loader.callNoYield(returns)
			expect(result).toEqual { success = true, yielded = false }
		end)

		it("returns success=true and yielded=true when the function yields", function()
			local result = Loader.callNoYield(yields)
			expect(result).toEqual { success = true, yielded = true }
		end)

		it("returns success=false and the error message when the function errors", function()
			local result = Loader.callNoYield(errors) :: { error: string, success: false }
			expect(result.success).toBe(false)
			expect(type(result.error)).toBe("string")
		end)

		it("does not continue running the function after it yields", function()
			local variable = 0

			local function setsVariable()
				task.wait()
				variable += 1
			end

			local result = Loader.callNoYield(setsVariable)
			expect(result).toEqual { success = true, yielded = true }
			expect(variable).toBe(0)
		end)
	end)

	describe(".filterModulePath", function()
		local rootFolder = Instance.new("Folder")
		rootFolder.Name = "Root"

		local subFolder = Instance.new("Folder")
		subFolder.Name = "SubFolder"
		subFolder.Parent = rootFolder

		local module = Instance.new("ModuleScript")
		module.Name = "Module"
		module.Parent = rootFolder

		local moduleInsideSubFolder = Instance.new("ModuleScript")
		moduleInsideSubFolder.Name = "SubModule"
		moduleInsideSubFolder.Parent = subFolder

		it("returns true when nameMatches and ignoreMatches are nil", function()
			expect(Loader.filterModulePath(module)).toBe(true)
		end)

		it("returns true when the module path matches any of the nameMatches", function()
			expect(Loader.filterModulePath(module, { "Dummy", "Test", "^Root" }, nil)).toBe(true)
		end)

		it("returns false when the module path does not match any of the nameMatches", function()
			expect(Loader.filterModulePath(module, { "SubFolder" }, nil)).toBe(false)
		end)

		it("returns false when the module path matches any of the ignoreMatches", function()
			expect(Loader.filterModulePath(moduleInsideSubFolder, nil, { "SubFolder" })).toBe(false)
		end)

		it("returns true when the module path does not match any of the ignoreMatches", function()
			expect(Loader.filterModulePath(module, nil, { "SubFolder" })).toBe(true)
		end)
	end)

	describe(".topLevelModules", function()
		local mockInstanceTree
		local mockModuleScript
		local mockSubfolder
		local mockModuleScriptInSubfolder
		local mockSubModuleScript
		local mockIgnoredModuleScript
		local mockMatchedModuleScript
		beforeEach(function()
			mockInstanceTree = Instance.new("Folder")
			mockInstanceTree.Name = "MockInstanceTree"

			mockModuleScript = Instance.new("ModuleScript")
			mockModuleScript.Name = "MockModuleScript"
			mockModuleScript.Source = [[
				return {
					message = "Hello, world!",
				}
			]]
			mockModuleScript.Parent = mockInstanceTree

			mockSubfolder = Instance.new("Folder")
			mockSubfolder.Name = "MockSubfolder"
			mockSubfolder.Parent = mockInstanceTree

			mockModuleScriptInSubfolder = Instance.new("ModuleScript")
			mockModuleScriptInSubfolder.Name = "MockModuleScriptInSubfolder"
			mockModuleScriptInSubfolder.Source = [[
				return {
					message = "Howdy, kids!",
				}
			]]
			mockModuleScriptInSubfolder.Parent = mockSubfolder

			mockSubModuleScript = Instance.new("ModuleScript")
			mockSubModuleScript.Name = "MockSubModuleScript"
			mockSubModuleScript.Source = [[
				return {
					message = "I'm a sub-module!",
				}
			]]
			mockSubModuleScript.Parent = mockModuleScript

			mockIgnoredModuleScript = Instance.new("ModuleScript")
			mockIgnoredModuleScript.Name = "MockIgnoredModuleScript.spec"
			mockIgnoredModuleScript.Source = [[
				return {
					message = "I'm ignored!",
				}
			]]
			mockIgnoredModuleScript.Parent = mockInstanceTree

			mockMatchedModuleScript = Instance.new("ModuleScript")
			mockMatchedModuleScript.Name = "MockMatchedModuleScript"
			mockMatchedModuleScript.Source = [[
				return {
					message = "I'm matched!",
				}
			]]
			mockMatchedModuleScript.Parent = mockInstanceTree
		end)

		describe(".loadTopLevelModules", function()
			it("does not error", function()
				expect(function()
					Loader.loadTopLevelModules(mockInstanceTree)
				end).never.toThrow()
			end)

			it("requires only top-level modules", function()
				local moduleScriptsToModules = Loader.loadTopLevelModules(mockInstanceTree)
				expect(moduleScriptsToModules[mockModuleScript]).toBeDefined()
				expect(moduleScriptsToModules[mockModuleScriptInSubfolder]).toBeDefined()
				expect(moduleScriptsToModules[mockMatchedModuleScript]).toBeDefined()
				expect(moduleScriptsToModules[mockIgnoredModuleScript]).toBeDefined()
				expect(moduleScriptsToModules[mockSubModuleScript]).toBeUndefined()
			end)

			it("only ignores modules that match the ignoreMatches pattern", function()
				local moduleScriptsToModules = Loader.loadTopLevelModules(mockInstanceTree, nil, { "%.spec$" })
				expect(moduleScriptsToModules[mockModuleScript]).toBeDefined()
				expect(moduleScriptsToModules[mockIgnoredModuleScript]).toBeUndefined()
			end)

			it("only requires modules that match the nameMatches pattern if specified", function()
				local moduleScriptsToModules = Loader.loadTopLevelModules(mockInstanceTree, { "Matched" })
				expect(moduleScriptsToModules[mockModuleScript]).toBeUndefined()
				expect(moduleScriptsToModules[mockMatchedModuleScript]).toBeDefined()
				expect(moduleScriptsToModules[mockIgnoredModuleScript]).toBeUndefined()
			end)
		end)
	end)
end)
