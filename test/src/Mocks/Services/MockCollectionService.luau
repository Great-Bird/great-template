local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local TableUtil = require(ReplicatedStorage.Shared.Util.TableUtil)
local MockRBXScriptSignal = require(ReplicatedStorage.Testing.Mocks.DataTypes.MockRBXScriptSignal)

local jest = JestGlobals.jest

export type MockCollectionService = {
	AddTag: (self: MockCollectionService, instance: Instance, tag: string) -> (),
	_addTag: any,

	RemoveTag: (self: MockCollectionService, instance: Instance, tag: string) -> (),
	_removeTag: any,

	HasTag: (self: MockCollectionService, instance: Instance, tag: string) -> boolean,
	_hasTag: any,

	GetTagged: (self: MockCollectionService, tag: string) -> { Instance },
	_getTagged: any,

	GetTags: (self: MockCollectionService, instance: Instance) -> { string },
	_getTags: any,

	GetAllTags: (self: MockCollectionService) -> { string },
	_getAllTags: any,

	GetInstanceAddedSignal: (
		self: MockCollectionService,
		tag: string
	) -> MockRBXScriptSignal.MockRBXScriptSignal<Instance>,
	_getInstanceAddedSignal: any,

	GetInstanceRemovedSignal: (
		self: MockCollectionService,
		tag: string
	) -> MockRBXScriptSignal.MockRBXScriptSignal<Instance>,
	_getInstanceRemovedSignal: any,

	_tagsToInstances: { [string]: { Instance } },
	_tagsToInstanceAddedSignals: { [string]: MockRBXScriptSignal.MockRBXScriptSignal<Instance> },
	_tagsToInstanceRemovedSignals: { [string]: MockRBXScriptSignal.MockRBXScriptSignal<Instance> },
}

local module = {}

function module.new(): MockCollectionService
	local self = {
		_tagsToInstances = {},
		_tagsToInstanceAddedSignals = {},
		_tagsToInstanceRemovedSignals = {},
	}

	self._addTag, self.AddTag = jest.fn(module.AddTag)
	self._removeTag, self.RemoveTag = jest.fn(module.RemoveTag)
	self._hasTag, self.HasTag = jest.fn(module.HasTag)
	self._getTagged, self.GetTagged = jest.fn(module.GetTagged)
	self._getTags, self.GetTags = jest.fn(module.GetTags)
	self._getAllTags, self.GetAllTags = jest.fn(module.GetAllTags)
	self._getInstanceAddedSignal, self.GetInstanceAddedSignal = jest.fn(module.GetInstanceAddedSignal)
	self._getInstanceRemovedSignal, self.GetInstanceRemovedSignal = jest.fn(module.GetInstanceRemovedSignal)

	return self
end

function module.AddTag(self: MockCollectionService, instance: Instance, tag: string)
	self._tagsToInstances[tag] = self._tagsToInstances[tag] or {}
	table.insert(self._tagsToInstances[tag], instance)
	module.GetInstanceAddedSignal(self, tag):_fire(instance)
end

function module.RemoveTag(self: MockCollectionService, instance: Instance, tag: string)
	local tagged = self._tagsToInstances[tag]
	if tagged then
		local index = table.find(tagged, instance)
		if index then
			table.remove(tagged, index)
			module.GetInstanceRemovedSignal(self, tag):_fire(instance)
		end
		if #tagged == 0 then
			self._tagsToInstances[tag] = nil
		end
	end
end

function module.HasTag(self: MockCollectionService, instance: Instance, tag: string): boolean
	local tagged = self._tagsToInstances[tag]
	return tagged and table.find(tagged, instance) ~= nil
end

function module.GetTagged(self: MockCollectionService, tag: string): { Instance }
	-- Unfortunately, we can't detect `instance:AddTag` and `instance:RemoveTag` calls
	local tagged = self._tagsToInstances[tag]
	return if tagged then table.clone(tagged) else {}
end

function module.GetTags(self: MockCollectionService, instance: Instance): { string }
	local tags = {}
	for tag, tagged in self._tagsToInstances do
		if table.find(tagged, instance) then
			table.insert(tags, tag)
		end
	end
	return tags
end

function module.GetAllTags(self: MockCollectionService): { string }
	return TableUtil.keys(self._tagsToInstances)
end

function module.GetInstanceAddedSignal(self: MockCollectionService, tag: string)
	if not self._tagsToInstanceAddedSignals[tag] then
		self._tagsToInstanceAddedSignals[tag] = MockRBXScriptSignal.new()
	end
	return self._tagsToInstanceAddedSignals[tag]
end

function module.GetInstanceRemovedSignal(self: MockCollectionService, tag: string)
	if not self._tagsToInstanceRemovedSignals[tag] then
		self._tagsToInstanceRemovedSignals[tag] = MockRBXScriptSignal.new()
	end
	return self._tagsToInstanceRemovedSignals[tag]
end

return module
