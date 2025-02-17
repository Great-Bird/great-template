--!nonstrict

--[[
	Unit tests for the Tagged library.

	Throughout the file, instance paths are used to refer to instances in the mockFolder. This is done so that `it.each`
	tests can reference instances before the tests run.
	The paths are defined in the `paths` table. The `toInstance` function is used to convert a path to an instance, and
	the `toInstances` function is used to convert a list of paths to a list of instances.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local MockCollectionService = require(ReplicatedStorage.Testing.Mocks.Services.MockCollectionService)
local TableUtil = require(script.Parent.TableUtil)

local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

type MockFolder = Folder & {
	Subfolder: Folder & {
		TaggedPart: Part,
		UntaggedPart: Part,
	},
	TaggedModel: Model,
}

jest.useFakeTimers()

describe("Tagged", function()
	local mockCollectionService: MockCollectionService.MockCollectionService
	local Tagged
	local mockTag = "Tagged_Test_MockTag"
	local mockContainerTag = "Tagged_Test_MockContainerTag"
	local emptyTag = "Tagged_Test_EmptyTag"
	local awaitedTag = "Tagged_Test_AwaitedTag"

	-- Define the instances outside once so they can be reused between tests. They are destroyed in afterAll.
	-- This is necessary so `it.each` tables can reference the instances before tests run.
	local mockFolder: MockFolder
	local paths = {
		["MockFolder"] = "MockFolder",
		["MockFolder.Subfolder"] = "MockFolder.Subfolder",
		["MockFolder.TaggedModel"] = "MockFolder.TaggedModel",
		["MockFolder.Subfolder.TaggedPart"] = "MockFolder.Subfolder.TaggedPart",
		["MockFolder.Subfolder.UntaggedPart"] = "MockFolder.Subfolder.UntaggedPart",
		["None"] = "nil",
	}
	local pathsToInstances = {}

	local function toInstance(path: string): Instance?
		return pathsToInstances[path]
	end

	local function toInstances(paths: { string }): { Instance }
		local result = {}
		for _, path in paths do
			local instance = toInstance(path)
			if instance then
				table.insert(result, instance)
			end
		end
		return result
	end

	local function sortByName(instances: { Instance }): { Instance }
		table.sort(instances, function(a, b)
			return a.Name < b.Name
		end)
		return instances
	end

	local function instancesMatchPaths(instances: { Instance }, paths: { string }): boolean
		local pathsAsInstances = sortByName(toInstances(paths))
		sortByName(instances)
		return TableUtil.equalsDeep(instances, pathsAsInstances)
	end

	beforeEach(function()
		jest.resetModules()

		jest.mock(ReplicatedStorage.Shared.Services.CollectionService, MockCollectionService.new)

		mockCollectionService = require(ReplicatedStorage.Shared.Services.CollectionService) :: any
		Tagged = require(script.Parent.Tagged)

		mockFolder = Instance.new("Folder") :: MockFolder
		mockFolder.Name = "Tagged_Test_MockFolder"
		mockCollectionService:AddTag(mockFolder, mockContainerTag)
		mockFolder.Parent = game

		local subfolder = Instance.new("Folder")
		subfolder.Name = "Subfolder"
		mockCollectionService:AddTag(subfolder, mockContainerTag)
		subfolder.Parent = mockFolder

		local taggedPart = Instance.new("Part")
		taggedPart.Name = "TaggedPart"
		mockCollectionService:AddTag(taggedPart, mockTag)
		taggedPart.Parent = subfolder

		local untaggedPart = Instance.new("Part")
		untaggedPart.Name = "UntaggedPart"
		untaggedPart.Parent = subfolder

		local taggedModel = Instance.new("Model")
		taggedModel.Name = "TaggedModel"
		mockCollectionService:AddTag(taggedModel, mockTag)
		taggedModel.Parent = mockFolder

		for _, path in paths do
			local split = string.split(path, ".")
			if split[1] == paths.None then
				continue
			end
			local currentInstance = mockFolder
			for i = 2, #split do
				currentInstance = currentInstance[split[i]]
			end
			pathsToInstances[path] = currentInstance
		end
	end)

	afterEach(function()
		mockCollectionService:GetInstanceAddedSignal(mockTag):_disconnectAll()
		mockCollectionService:GetInstanceRemovedSignal(mockTag):_disconnectAll()
		mockFolder:Destroy()
		pathsToInstances = {}
	end)

	describe(".get", function()
		it("returns a cached table that is updated with new instances with the tag", function()
			local tagged = Tagged.get(mockTag)
			local newTaggedPart = Instance.new("Part")
			newTaggedPart.Name = "NewTaggedPart"
			mockCollectionService:AddTag(newTaggedPart, mockTag)
			mockCollectionService:GetInstanceAddedSignal(mockTag):_fire(newTaggedPart)
			newTaggedPart.Parent = toInstance(paths["MockFolder.Subfolder"])

			expect(tagged).toContain(newTaggedPart)

			newTaggedPart:Destroy()
		end)
	end)

	describe(".all", function()
		it("returns a cloned table that is not updated with new instances with the tag", function()
			local tagged = Tagged.all(mockTag)
			local newTaggedPart = Instance.new("Part")
			newTaggedPart.Name = "NewTaggedPart"
			mockCollectionService:AddTag(newTaggedPart, mockTag)
			mockCollectionService:GetInstanceAddedSignal(mockTag):_fire(newTaggedPart)
			newTaggedPart.Parent = toInstance(paths["MockFolder.Subfolder"])

			expect(tagged).never.toContain(newTaggedPart)

			newTaggedPart:Destroy()
		end)
	end)

	describe("collection getters", function()
		it.each {
			{ tag = mockTag, expected = { paths["MockFolder.TaggedModel"], paths["MockFolder.Subfolder.TaggedPart"] } },
			{ tag = emptyTag, expected = {} },
		}(".get($tag) returns $expected", function(ref)
			local result = Tagged.get(ref.tag)
			expect(instancesMatchPaths(result, ref.expected)).toBe(true)
		end)

		it.each {
			{ tag = mockTag, expected = { paths["MockFolder.TaggedModel"], paths["MockFolder.Subfolder.TaggedPart"] } },
			{ tag = emptyTag, expected = {} },
		}(".all($tag) returns $expected", function(ref)
			local result = Tagged.all(ref.tag)
			expect(instancesMatchPaths(result, ref.expected)).toBe(true)
		end)

		it.each {
			{ tag = mockTag, class = "Part", expected = { paths["MockFolder.Subfolder.TaggedPart"] } },
			{ tag = mockTag, class = "Model", expected = { paths["MockFolder.TaggedModel"] } },
			{ tag = emptyTag, class = "Part", expected = {} },
			{ tag = mockTag, class = "Folder", expected = {} },
		}(".allWhichAre($tag, $class) returns $expected", function(ref)
			local result = Tagged.allWhichAre(ref.tag, ref.class)
			expect(instancesMatchPaths(result, ref.expected)).toBe(true)
		end)

		-- stylua: ignore
		it.each {
			{ tag = mockTag, ancestor = paths["MockFolder"], expected = { paths["MockFolder.TaggedModel"], paths["MockFolder.Subfolder.TaggedPart"] } },
			-- { tag = emptyTag, ancestor = paths["MockFolder"], expected = {} },
		}(".descendants($tag, $ancestor) returns $expected", function(ref)
			local result = Tagged.descendants(ref.tag, toInstance(ref.ancestor))
			expect(instancesMatchPaths(result, ref.expected)).toBe(true)
		end)

		-- stylua: ignore
		it.each {
			{ tag = mockTag, ancestor = paths["MockFolder"], class = "Part", expected = { paths["MockFolder.Subfolder.TaggedPart"] } },
			{ tag = mockTag, ancestor = paths["MockFolder"], class = "Model", expected = { paths["MockFolder.TaggedModel"] } },
			{ tag = emptyTag, ancestor = paths["MockFolder"], class = "Part", expected = {} },
			{ tag = mockTag, ancestor = paths["MockFolder"], class = "Folder", expected = {} },
		}(".descendantsWhichAre($tag, $ancestor, $class) returns $expected", function(ref)
			local result = Tagged.descendantsWhichAre(ref.tag, toInstance(ref.ancestor), ref.class)
			expect(instancesMatchPaths(result, ref.expected)).toBe(true)
		end)

		-- stylua: ignore
		it.each {
			{ tag = mockTag, ancestor = paths["MockFolder"], expected = { paths["MockFolder.TaggedModel"], paths["MockFolder.Subfolder.TaggedPart"] } },
			{ tag = emptyTag, ancestor = paths["MockFolder"], expected = {} },
		}(".withAncestor($tag, $ancestor) returns $expected", function(ref)
			local result = Tagged.withAncestor(ref.tag, toInstance(ref.ancestor))
			expect(instancesMatchPaths(result, ref.expected)).toBe(true)
		end)

		-- stylua: ignore
		it.each {
			{ tag = mockTag, ancestor = paths["MockFolder"], class = "Part", expected = { paths["MockFolder.Subfolder.TaggedPart"] } },
			{ tag = mockTag, ancestor = paths["MockFolder"], class = "Model", expected = { paths["MockFolder.TaggedModel"] } },
			{ tag = emptyTag, ancestor = paths["MockFolder"], class = "Part", expected = {} },
			{ tag = mockTag, ancestor = paths["MockFolder"], class = "Folder", expected = {} },
		}(".withAncestorWhichAre($tag, $ancestor, $class) returns $expected", function(ref)
			local result = Tagged.withAncestorWhichAre(ref.tag, toInstance(ref.ancestor), ref.class)
			expect(instancesMatchPaths(result, ref.expected)).toBe(true)
		end)

		it.each {
			{ tag = mockTag, parent = paths["MockFolder"], expected = { paths["MockFolder.TaggedModel"] } },
			{ tag = emptyTag, parent = paths["MockFolder"], expected = {} },
		}(".children($tag, $parent) returns $expected", function(ref)
			local result = Tagged.children(ref.tag, toInstance(ref.parent))
			expect(instancesMatchPaths(result, ref.expected)).toBe(true)
		end)

		-- stylua: ignore
		it.each {
			{ tag = mockTag, parent = paths["MockFolder"], class = "Part", expected = {} },
			{ tag = mockTag, parent = paths["MockFolder"], class = "Model", expected = { paths["MockFolder.TaggedModel"] } },
			{ tag = emptyTag, parent = paths["MockFolder"], class = "Model", expected = {} },
			{ tag = mockTag, parent = paths["MockFolder"], class = "Folder", expected = {} },
		}(".childrenWhichAre($tag, $parent, $class) returns $expected", function(ref)
			local result = Tagged.childrenWhichAre(ref.tag, toInstance(ref.parent), ref.class)
			expect(instancesMatchPaths(result, ref.expected)).toBe(true)
		end)

		it.each {
			{ tag = mockTag, parent = paths["MockFolder"], expected = { paths["MockFolder.TaggedModel"] } },
			{ tag = emptyTag, parent = paths["MockFolder"], expected = {} },
		}(".withParent($tag, $parent) returns $expected", function(ref)
			local result = Tagged.withParent(ref.tag, toInstance(ref.parent))
			expect(instancesMatchPaths(result, ref.expected)).toBe(true)
		end)

		-- stylua: ignore
		it.each {
			{ tag = mockTag, parent = paths["MockFolder"], class = "Part", expected = {} },
			{ tag = mockTag, parent = paths["MockFolder"], class = "Model", expected = { paths["MockFolder.TaggedModel"] } },
			{ tag = emptyTag, parent = paths["MockFolder"], class = "Model", expected = {} },
			{ tag = mockTag, parent = paths["MockFolder"], class = "Folder", expected = {} },
		}(".withParentWhichAre($tag, $parent, $class) returns $expected", function(ref)
			local result = Tagged.withParentWhichAre(ref.tag, toInstance(ref.parent), ref.class)
			expect(instancesMatchPaths(result, ref.expected)).toBe(true)
		end)
	end)

	describe("first getters", function()
		-- These tests assume the functions return the first instance in the table returned by
		-- `CollectionService:GetTagged` which satisfies the conditions.

		it.each {
			{ tag = mockTag, expected = paths["MockFolder.Subfolder.TaggedPart"] },
			{ tag = emptyTag, expected = paths.None },
		}(".first($tag) returns $expected", function(ref)
			local result = Tagged.first(ref.tag)
			expect(result == toInstance(ref.expected)).toBe(true)
		end)

		it.each {
			{ tag = mockTag, class = "Part", expected = paths["MockFolder.Subfolder.TaggedPart"] },
			{ tag = mockTag, class = "Model", expected = paths["MockFolder.TaggedModel"] },
			{ tag = emptyTag, class = "Part", expected = paths.None },
			{ tag = mockTag, class = "Folder", expected = paths.None },
		}(".firstWhichIsA($tag, $class) returns $expected", function(ref)
			local result = Tagged.firstWhichIsA(ref.tag, ref.class)
			expect(result == toInstance(ref.expected)).toBe(true)
		end)

		-- stylua: ignore
		it.each {
			{ tag = mockTag, instance = paths["MockFolder"], expected = paths["MockFolder.Subfolder.TaggedPart"] },
			{ tag = emptyTag, instance = paths["MockFolder"], expected = paths.None },
		}(".firstDescendant($tag, $instance) returns $expected", function(ref)
			local result = Tagged.firstDescendant(ref.tag, toInstance(ref.instance))
			expect(result == toInstance(ref.expected)).toBe(true)
		end)

		-- stylua: ignore
		it.each {
			{ tag = mockTag, class = "Part", instance = paths["MockFolder"], expected = paths["MockFolder.Subfolder.TaggedPart"] },
			{ tag = mockTag, class = "Model", instance = paths["MockFolder"], expected = paths["MockFolder.TaggedModel"] },
			{ tag = emptyTag, class = "Part", instance = paths["MockFolder"], expected = paths.None },
			{ tag = mockTag, class = "Folder", instance = paths["MockFolder"], expected = paths.None },
		}(".firstDescendantWhichIsA($tag, $instance, $class) returns $expected", function(ref)
			local result = Tagged.firstDescendantWhichIsA(ref.tag, toInstance(ref.instance), ref.class)
			expect(result == toInstance(ref.expected)).toBe(true)
		end)

		it.each {
			{ tag = mockTag, ancestor = paths["MockFolder"], expected = paths["MockFolder.Subfolder.TaggedPart"] },
			{ tag = emptyTag, ancestor = paths["MockFolder"], expected = paths.None },
		}(".firstWithAncestor($tag, $ancestor) returns $expected", function(ref)
			local result = Tagged.firstWithAncestor(ref.tag, toInstance(ref.ancestor))
			expect(result == toInstance(ref.expected)).toBe(true)
		end)

		-- stylua: ignore
		it.each {
			{ tag = mockTag, class = "Part", instance = paths["MockFolder"], expected = paths["MockFolder.Subfolder.TaggedPart"] },
			{ tag = mockTag, class = "Model", instance = paths["MockFolder"], expected = paths["MockFolder.TaggedModel"] },
			{ tag = emptyTag, class = "Part", instance = paths["MockFolder"], expected = paths.None },
			{ tag = mockTag, class = "Folder", instance = paths["MockFolder"], expected = paths.None },
		}(".firstWithAncestorWhichIsA($tag, $ancestor, $class) returns $expected", function(ref)
			local result = Tagged.firstWithAncestorWhichIsA(ref.tag, toInstance(ref.ancestor), ref.class)
			expect(result == toInstance(ref.expected)).toBe(true)
		end)

		-- stylua: ignore
		it.each {
			{ tag = mockContainerTag, instance = paths["MockFolder.Subfolder.TaggedPart"], expected = paths["MockFolder.Subfolder"] },
			{ tag = mockContainerTag, instance = paths["MockFolder.TaggedModel"], expected = paths["MockFolder"] },
			{ tag = emptyTag, instance = paths["MockFolder.Subfolder.TaggedPart"], expected = paths.None },
		}(".firstAncestor($tag, $instance) returns $expected", function(ref)
			local result = Tagged.firstAncestor(ref.tag, toInstance(ref.instance))
			expect(result == toInstance(ref.expected)).toBe(true)
		end)

		-- stylua: ignore
		it.each {
			{ tag = mockContainerTag, class = "Folder", instance = paths["MockFolder.Subfolder.TaggedPart"], expected = paths["MockFolder.Subfolder"] },
			{ tag = mockContainerTag, class = "Folder", instance = paths["MockFolder.TaggedModel"], expected = paths["MockFolder"] },
			{ tag = emptyTag, class = "Folder", instance = paths["MockFolder.Subfolder.TaggedPart"], expected = paths.None },
			{ tag = mockContainerTag, class = "Part", instance = paths["MockFolder.Subfolder.TaggedPart"], expected = paths.None },
		}(".firstAncestorWhichIsA($tag, $class, $instance) returns $expected", function(ref)
			local result = Tagged.firstAncestorWhichIsA(ref.tag, toInstance(ref.instance), ref.class)
			expect(result == toInstance(ref.expected)).toBe(true)
		end)
	end)

	describe("waitForFirst getters", function()
		describe("returning immediately", function()
			it(".waitForFirst returns the instance with the tag immediately if present", function()
				local result = Tagged.waitForFirst(mockTag)
				expect(result == toInstance(paths["MockFolder.Subfolder.TaggedPart"])).toBe(true)
			end)

			it(".waitForFirstWhichIsA returns the instance with the tag and class immediately if present", function()
				local result = Tagged.waitForFirstWhichIsA(mockTag, "Part")
				expect(result == toInstance(paths["MockFolder.Subfolder.TaggedPart"])).toBe(true)
			end)

			it(".waitForFirstDescendant returns the descendant with the tag immediately if present", function()
				local result = Tagged.waitForFirstDescendant(mockTag, toInstance(paths["MockFolder"]))
				expect(result == toInstance(paths["MockFolder.Subfolder.TaggedPart"])).toBe(true)
			end)
	
			-- stylua: ignore
			it(".waitForFirstDescendantWhichIsA returns the descendant with the tag and class immediately if present", function()
				local result = Tagged.waitForFirstDescendantWhichIsA(mockTag, toInstance(paths["MockFolder"]), "Part")
				expect(result == toInstance(paths["MockFolder.Subfolder.TaggedPart"])).toBe(true)
			end)

			it(".waitForFirstAncestor returns the ancestor with the tag immediately if present", function()
				local result =
					Tagged.waitForFirstAncestor(mockContainerTag, toInstance(paths["MockFolder.Subfolder.TaggedPart"]))
				expect(result == toInstance(paths["MockFolder.Subfolder"])).toBe(true)
			end)
	
			-- stylua: ignore
			it(".waitForFirstAncestorWhichIsA returns the ancestor with the tag and class immediately if present", function()
				local result = Tagged.waitForFirstAncestorWhichIsA(mockContainerTag, toInstance(paths["MockFolder.Subfolder.TaggedPart"]), "Folder")
				expect(result == toInstance(paths["MockFolder.Subfolder"])).toBe(true)
			end)
		end)

		describe("yielding", function()
			describe(".waitForFirst", function()
				it("returns when an instance with the tag is added", function(_, done)
					expect.assertions(2)

					local instance = toInstance(paths["MockFolder"])

					task.spawn(function()
						local result = Tagged.waitForFirst(awaitedTag)
						xpcall(function()
							expect(result == instance).toBe(true)
							done()
						end, done)
					end)

					expect(Tagged.first(awaitedTag) == nil).toBe(true)
					mockCollectionService:AddTag(instance, awaitedTag)
				end)
			end)

			describe(".waitForFirstWhichIsA", function()
				it("returns when an instance with the tag and class is added", function(_, done)
					expect.assertions(3)

					local taggedFolder = toInstance(paths["MockFolder"])
					local taggedPart = toInstance(paths["MockFolder.Subfolder.TaggedPart"])

					task.spawn(function()
						local result = Tagged.waitForFirstWhichIsA(awaitedTag, "Part")
						xpcall(function()
							expect(result == taggedPart).toBe(true)
							done()
						end, done)
					end)

					expect(Tagged.firstWhichIsA(awaitedTag, "Part") == nil).toBe(true)
					mockCollectionService:AddTag(taggedFolder, awaitedTag)
					expect(Tagged.firstWhichIsA(awaitedTag, "Part") == nil).toBe(true)
					mockCollectionService:AddTag(taggedPart, awaitedTag)
				end)
			end)

			describe(".waitForFirstDescendant", function()
				it("returns when a descendant is given the tag", function(_, done)
					expect.assertions(2)

					local ancestor = toInstance(paths["MockFolder"])
					local instance = toInstance(paths["MockFolder.Subfolder.TaggedPart"])

					task.spawn(function()
						local result = Tagged.waitForFirstDescendant(awaitedTag, ancestor)
						xpcall(function()
							expect(result == instance).toBe(true)
							done()
						end, done)
					end)

					expect(Tagged.firstDescendant(awaitedTag, ancestor) == nil).toBe(true)
					mockCollectionService:AddTag(instance :: Instance, awaitedTag)
				end)

				it("returns when another instance with the tag is parented to the instance", function(_, done)
					expect.assertions(2)

					local initialParent = toInstance(paths["MockFolder"])
					local ancestor = toInstance(paths["MockFolder.Subfolder"])

					local instance = Instance.new("Part")
					instance.Name = "NewTaggedPart"
					instance.Parent = initialParent

					task.spawn(function()
						local result = Tagged.waitForFirstDescendant(awaitedTag, ancestor)
						xpcall(function()
							expect(result == instance).toBe(true)
							done()
						end, done)
					end)

					expect(Tagged.firstDescendant(awaitedTag, ancestor) == nil).toBe(true)
					mockCollectionService:AddTag(instance, awaitedTag)
					instance.Parent = ancestor
				end)
			end)

			describe(".waitForFirstDescendantWhichIsA", function()
				it("returns when a descendant with the class is given the tag", function(_, done)
					expect.assertions(2)

					local ancestor = toInstance(paths["MockFolder"])
					local instance = toInstance(paths["MockFolder.Subfolder.TaggedPart"])

					task.spawn(function()
						local result = Tagged.waitForFirstDescendantWhichIsA(awaitedTag, ancestor, "Part")
						xpcall(function()
							expect(result == instance).toBe(true)
							done()
						end, done)
					end)

					expect(Tagged.firstDescendantWhichIsA(awaitedTag, ancestor, "Part") == nil).toBe(true)
					mockCollectionService:AddTag(instance :: Instance, awaitedTag)
				end)

				it("returns when another instance with the tag and class is parented to the instance", function(_, done)
					expect.assertions(2)

					local initialParent = toInstance(paths["MockFolder"])
					local ancestor = toInstance(paths["MockFolder.Subfolder"])

					local instance = Instance.new("Part")
					instance.Name = "NewTaggedPart"
					instance.Parent = initialParent

					task.spawn(function()
						local result = Tagged.waitForFirstDescendantWhichIsA(awaitedTag, ancestor, "Part")
						xpcall(function()
							expect(result == instance).toBe(true)
							done()
						end, done)
					end)

					expect(Tagged.firstDescendantWhichIsA(awaitedTag, ancestor, "Part") == nil).toBe(true)
					mockCollectionService:AddTag(instance, awaitedTag)
					instance.Parent = ancestor
				end)
			end)
		end)

		describe(".waitForFirstWithAncestor", function()
			it("returns when a descendant is given the tag", function(_, done)
				expect.assertions(2)

				local ancestor = toInstance(paths["MockFolder"])
				local instance = toInstance(paths["MockFolder.Subfolder.TaggedPart"])

				task.spawn(function()
					local result = Tagged.waitForFirstWithAncestor(awaitedTag, ancestor)
					xpcall(function()
						expect(result == instance).toBe(true)
						done()
					end, done)
				end)

				expect(Tagged.firstDescendant(awaitedTag, ancestor) == nil).toBe(true)
				mockCollectionService:AddTag(instance :: Instance, awaitedTag)
			end)

			it("returns when a descendant with the tag is parented to the ancestor", function(_, done)
				expect.assertions(2)

				local initialParent = toInstance(paths["MockFolder"])
				local ancestor = toInstance(paths["MockFolder.Subfolder"])

				local instance = Instance.new("Part")
				instance.Name = "NewTaggedPart"
				instance.Parent = initialParent

				task.spawn(function()
					local result = Tagged.waitForFirstWithAncestorWhichIsA(awaitedTag, ancestor)
					xpcall(function()
						expect(result == instance).toBe(true)
						done()
					end, done)
				end)

				expect(Tagged.firstDescendant(awaitedTag, ancestor) == nil).toBe(true)
				mockCollectionService:AddTag(instance, awaitedTag)
				instance.Parent = ancestor
			end)
		end)

		describe(".waitForFirstWithAncestorWhichIsA", function()
			it("returns when a descendant with the class is given the tag", function(_, done)
				expect.assertions(2)

				local ancestor = toInstance(paths["MockFolder"])
				local instance = toInstance(paths["MockFolder.Subfolder.TaggedPart"])

				task.spawn(function()
					local result = Tagged.waitForFirstWithAncestorWhichIsA(awaitedTag, ancestor, "Part")
					xpcall(function()
						expect(result == instance).toBe(true)
						done()
					end, done)
				end)

				expect(Tagged.firstDescendantWhichIsA(awaitedTag, ancestor, "Part") == nil).toBe(true)
				mockCollectionService:AddTag(instance :: Instance, awaitedTag)
			end)

			it("returns when a descendant with the tag and class is parented to the ancestor", function(_, done)
				expect.assertions(2)

				local initialParent = toInstance(paths["MockFolder"])
				local ancestor = toInstance(paths["MockFolder.Subfolder"])

				local instance = Instance.new("Part")
				instance.Name = "NewTaggedPart"
				instance.Parent = initialParent

				task.spawn(function()
					local result = Tagged.waitForFirstWithAncestorWhichIsA(awaitedTag, ancestor, "Part")
					xpcall(function()
						expect(result == instance).toBe(true)
						done()
					end, done)
				end)

				expect(Tagged.firstDescendantWhichIsA(awaitedTag, ancestor, "Part") == nil).toBe(true)
				mockCollectionService:AddTag(instance, awaitedTag)
				instance.Parent = ancestor
			end)
		end)

		describe(".waitForFirstAncestor", function()
			it("returns when an ancestor is given the tag", function(_, done)
				expect.assertions(2)

				local ancestor = toInstance(paths["MockFolder.Subfolder"])
				local instance = toInstance(paths["MockFolder.Subfolder.TaggedPart"])

				task.spawn(function()
					local result = Tagged.waitForFirstAncestor(awaitedTag, instance)
					xpcall(function()
						expect(result == ancestor).toBe(true)
						done()
					end, done)
				end)

				expect(Tagged.firstAncestor(awaitedTag, instance) == nil).toBe(true)
				mockCollectionService:AddTag(ancestor, awaitedTag)
			end)

			it("returns when the instance is re-parented to an ancestor with the tag", function(_, done)
				expect.assertions(2)

				local initialParent = toInstance(paths["MockFolder.Subfolder"])
				local ancestor = toInstance(paths["MockFolder.TaggedModel"])
				mockCollectionService:AddTag(ancestor, awaitedTag)

				local instance = Instance.new("Part")
				instance.Name = "NewUntaggedPart"
				instance.Parent = initialParent

				task.spawn(function()
					local result = Tagged.waitForFirstAncestor(awaitedTag, instance)
					xpcall(function()
						expect(result == ancestor).toBe(true)
						done()
					end, done)
				end)

				expect(Tagged.firstAncestor(awaitedTag, instance) == nil).toBe(true)
				instance.Parent = ancestor
			end)
		end)

		describe(".waitForFirstAncestorWhichIsA", function()
			it("returns when an ancestor with the class is given the tag", function(_, done)
				expect.assertions(2)

				local ancestor = toInstance(paths["MockFolder"])
				local instance = toInstance(paths["MockFolder.Subfolder.TaggedPart"])

				task.spawn(function()
					local result = Tagged.waitForFirstAncestorWhichIsA(awaitedTag, instance, "Folder")
					xpcall(function()
						expect(result == ancestor).toBe(true)
						done()
					end, done)
				end)

				expect(Tagged.firstAncestorWhichIsA(awaitedTag, instance, "Folder") == nil).toBe(true)
				mockCollectionService:AddTag(ancestor, awaitedTag)
			end)

			it("returns when the instance is re-parented to an ancestor with the tag and class", function(_, done)
				expect.assertions(2)

				local initialParent = toInstance(paths["MockFolder.Subfolder"])
				local ancestor = toInstance(paths["MockFolder.TaggedModel"])
				mockCollectionService:AddTag(ancestor :: Instance, awaitedTag)

				local instance = Instance.new("Part")
				instance.Name = "NewUntaggedPart"
				instance.Parent = initialParent

				task.spawn(function()
					local result = Tagged.waitForFirstAncestorWhichIsA(awaitedTag, instance, "Model")
					xpcall(function()
						expect(result == ancestor).toBe(true)
						done()
					end, done)
				end)

				expect(Tagged.firstAncestorWhichIsA(awaitedTag, instance, "Model") == nil).toBe(true)
				instance.Parent = ancestor
			end)
		end)
	end)

	describe(".observe", function()
		it("calls the callback for each currently tagged instance", function()
			local callback = jest.fn()
			local disconnect = Tagged.observe(mockTag, callback)
			expect(callback).toHaveBeenCalledWith(toInstance(paths["MockFolder.TaggedModel"]))
			expect(callback).toHaveBeenCalledWith(toInstance(paths["MockFolder.Subfolder.TaggedPart"]))
			disconnect()
		end)

		it("calls the callback for each new tagged instance", function()
			local callback = jest.fn()
			local disconnect = Tagged.observe(awaitedTag, callback)
			local newTaggedPart = Instance.new("Part")
			newTaggedPart.Name = "NewTaggedPart"
			newTaggedPart.Parent = toInstance(paths["MockFolder.Subfolder"])
			expect(callback).never.toHaveBeenCalled()
			mockCollectionService:AddTag(newTaggedPart, awaitedTag)
			expect(callback).toHaveBeenLastCalledWith(newTaggedPart)
			disconnect()
		end)

		it("calls the cleanup function for each removed instance", function()
			local cleanup = jest.fn()
			local callback = jest.fn(function()
				return cleanup
			end)
			local disconnect = Tagged.observe(mockTag, callback)
			local taggedPart = toInstance(paths["MockFolder.Subfolder.TaggedPart"])
			expect(cleanup).never.toHaveBeenCalled()
			mockCollectionService:RemoveTag(taggedPart, mockTag)
			expect(cleanup).toHaveBeenCalled()
			disconnect()
		end)

		it("calls the cleanup function for each tagged instance when the disconnect function is called", function()
			local cleanup = jest.fn()
			local callback = jest.fn(function()
				return cleanup
			end)
			local disconnect = Tagged.observe(mockTag, callback)
			expect(cleanup).never.toHaveBeenCalled()
			disconnect()
			expect(cleanup).toHaveBeenCalledTimes(2)
		end)

		it("does not call the callback after the disconnect function has been called", function()
			local callback = jest.fn()
			local disconnect = Tagged.observe(mockTag, callback)
			disconnect()
			local newTaggedPart = Instance.new("Part")
			newTaggedPart.Name = "NewTaggedPart"
			newTaggedPart.Parent = toInstance(paths["MockFolder.Subfolder"])
			mockCollectionService:AddTag(newTaggedPart, mockTag)
			expect(callback).never.toHaveBeenCalledWith(newTaggedPart)
		end)
	end)

	describe(".observeWithAncestor", function()
		it("calls the callback for each currently tagged descendant", function()
			local callback = jest.fn()
			local ancestor = toInstance(paths["MockFolder.Subfolder"])
			local disconnect = Tagged.observeWithAncestor(mockTag, ancestor, callback)
			expect(callback).toHaveBeenCalledWith(toInstance(paths["MockFolder.Subfolder.TaggedPart"]))
			disconnect()
		end)

		it("calls the callback when a tagged instance is parented to the ancestor", function()
			local callback = jest.fn()
			local ancestor = toInstance(paths["MockFolder.Subfolder"])
			local disconnect = Tagged.observeWithAncestor(awaitedTag, ancestor, callback)
			local newTaggedPart = Instance.new("Part")
			newTaggedPart.Name = "NewTaggedPart"
			newTaggedPart.Parent = ancestor
			expect(callback).never.toHaveBeenCalled()
			mockCollectionService:AddTag(newTaggedPart, awaitedTag)
			expect(callback).toHaveBeenCalledWith(newTaggedPart)
			disconnect()
		end)

		it("calls the callback when a descendant is given the tag", function()
			local callback = jest.fn()
			local ancestor = toInstance(paths["MockFolder"])
			local disconnect = Tagged.observeWithAncestor(awaitedTag, ancestor, callback)
			local descendant = toInstance(paths["MockFolder.Subfolder.UntaggedPart"])
			expect(callback).never.toHaveBeenCalled()
			mockCollectionService:AddTag(descendant, awaitedTag)
			expect(callback).toHaveBeenCalledWith(descendant)
			disconnect()
		end)

		it("calls the cleanup function when a descendant is parented to another instance", function(_, done)
			local cleanup = jest.fn()
			local callback = jest.fn(function()
				return cleanup
			end)
			local ancestor = toInstance(paths["MockFolder.Subfolder"])
			local disconnect = Tagged.observeWithAncestor(mockTag, ancestor, callback)
			local tagged = toInstance(paths["MockFolder.Subfolder.TaggedPart"])
			expect(callback).toHaveBeenCalledWith(tagged)
			expect(cleanup).never.toHaveBeenCalled()
			tagged.Parent = toInstance(paths["MockFolder"])
			-- Defer to ensure the parent change is processed
			task.defer(function()
				expect(cleanup).toHaveBeenCalled()
				disconnect()
				done()
			end)
			jest.runAllTimers()
		end)

		it("does not call the cleanup function when a re-parented descendant remains under the ancestor", function(_, done)
			local cleanup = jest.fn()
			local callback = jest.fn(function()
				return cleanup
			end)
			local ancestor = toInstance(paths["MockFolder"])
			local disconnect = Tagged.observeWithAncestor(mockTag, ancestor, callback)
			local tagged = toInstance(paths["MockFolder.Subfolder.TaggedPart"])
			expect(callback).toHaveBeenCalledWith(tagged)
			expect(cleanup).never.toHaveBeenCalled()
			tagged.Parent = ancestor
			-- Defer to ensure the parent change is processed
			task.defer(function()
				expect(cleanup).never.toHaveBeenCalled()
				disconnect()
				done()
			end)
			jest.runAllTimers()
		end)

		it("calls the cleanup function for each tagged descendant when the disconnect function is called", function()
			local cleanup = jest.fn()
			local callback = jest.fn(function()
				return cleanup
			end)
			local ancestor = toInstance(paths["MockFolder.Subfolder"])
			local disconnect = Tagged.observeWithAncestor(mockTag, ancestor, callback)
			expect(cleanup).never.toHaveBeenCalled()
			disconnect()
			expect(cleanup).toHaveBeenCalledTimes(1)
		end)

		it("does not call the callback after the disconnect function has been called", function()
			local callback = jest.fn()
			local ancestor = toInstance(paths["MockFolder.Subfolder"])
			local disconnect = Tagged.observeWithAncestor(awaitedTag, ancestor, callback)
			disconnect()
			local newTaggedPart = Instance.new("Part")
			newTaggedPart.Name = "NewTaggedPart"
			newTaggedPart.Parent = ancestor
			mockCollectionService:AddTag(newTaggedPart, awaitedTag)
			expect(callback).never.toHaveBeenCalled()
		end)
	end)
end)
