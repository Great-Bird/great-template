--[[
	AssertInstance v0.1.0
	Author: Great_Bird
	Date: 2025-02-12
	Last updated: 2025-02-12

	Library for asserting instance properties in Roblox and automatically
	writing high-quality error messages.

	Usage:
	```lua
	local AssertInstance = require(path.to.AssertInstance)

	local part = AssertInstance.hasChild(workspace, "Part")
	local humanoid = AssertInstance.hasDescendant(workspace, "Humanoid")
	local player = AssertInstance.isA(humanoid.Parent, "Model")
	local partChildren = AssertInstance.hasChildrenWhichAre(part, "BasePart")
	```

	Changelog:
	v0.1.0 (2025-02-12)
	- Notes: Release
]]

--[=[
	Returns "a (thing)" or "an (object)" based on the first letter of the input string.

	```lua
	print(a("Instance")) -- "an Instance"
	print(a("string")) -- "a string"
	```
]=]
local function a(noun: string): string
	return (if string.find(noun, "^[aeiouAEIOU]") then "an " else "a ") .. noun
end

local function oneOf(
	multipleFormat: string | (string) -> string,
	singleFormat: string | (string) -> string,
	nouns: { string }
)
	if #nouns > 1 then
		local concat = table.concat(nouns, ", ")
		if type(multipleFormat) == "function" then
			return multipleFormat(concat)
		else
			return string.format(multipleFormat, concat)
		end
	else
		local first = nouns[1]
		if type(singleFormat) == "function" then
			return singleFormat(first)
		else
			return string.format(singleFormat, first)
		end
	end
end

local function tostringAll(values: { any }): { string }
	local strings = {}
	for i, value in values do
		strings[i] = tostring(value)
	end
	return strings
end

local function splitValues(types: string?): { string }
	return if types then string.split(types, "|") else {}
end

local module = {}

local function hasChild(parent: Instance, childName: string, childClass: string?, recursive: boolean?): Instance
	local child = parent:FindFirstChild(childName, recursive)
	if child then
		if childClass then
			local classes = splitValues(childClass)
			if #classes == 0 then
				error("childClass cannot be an empty string")
			end
			for _, class in classes do
				if child:IsA(class) then
					return child
				end
			end
		else
			return child
		end
	end

	error(
		`{parent:GetFullName()} must have a {if recursive then "descendant" else "child"} named "{childName}"{oneOf(
			" which is one of the classes: %s",
			" which is a %s",
			splitValues(childClass)
		)}`
	)
end

--[=[
	Checks if an instance has a child with a given name and (optionally) class.

	@param parent The instance to check.
	@param childName The name of the child to check for.
	@param childClass The class of the child to check for. Pass nil to not check the class. Can be a single class or a list of classes separated by "|".
	@return The child instance.
]=]
function module.hasChild(parent: Instance, childName: string, childClass: string?): Instance & any
	return hasChild(parent, childName, childClass)
end

--[=[
	Checks if an instance has a descendant with a given name and (optionally) class.

	@param parent The instance to check.
	@param descendantName The name of the descendant to check for.
	@param descendantClass The class of the descendant to check for. Pass nil to not check the class. Can be a single class or a list of classes separated by "|".
	@return The descendant instance.
]=]
function module.hasDescendant(parent: Instance, descendantName: string, descendantClass: string?): Instance & any
	return hasChild(parent, descendantName, descendantClass, true)
end

--[=[
	Checks if an instance is of a given class.

	@param instance The instance to check.
	@param className The class to check for. Can be a single class or a list of classes separated by "|".
	@return The same instance.
]=]
function module.isA(instance: Instance, className: string): Instance & any
	local classes = splitValues(className)
	if #classes == 0 then
		error("className cannot be an empty string")
	end
	for _, class in classes do
		if instance:IsA(class) then
			return instance
		end
	end

	error(`{instance:GetFullName()} must be {oneOf("one of the classes: %s", a, classes)}; got {a(instance.ClassName)}`)
end

--[=[
	Checks if an instance has children of a given class.

	@param parent The instance to check.
	@param childClass The class of the children to check for. Pass nil to not check the class. Can be a single class or a list of classes separated by "|".
	@param minimumChildren The minimum number of children the instance must have. Pass nil to not check the number of children.
	@return The children of the instance.
]=]
function module.hasChildrenWhichAre(parent: Instance, childClass: string?, minimumChildren: number?): { Instance & any }
	local children = parent:GetChildren()
	if minimumChildren and #children < minimumChildren then
		-- stylua: ignore
		error(`{parent:GetFullName()} must have at least {minimumChildren} children{
			oneOf(" which are one of the classes: %s", " which are %ss", splitValues(childClass))
		}; got {#children}`)
	end
	if childClass then
		local classes = splitValues(childClass)
		for _, child in children do
			local valid = false
			for _, class in classes do
				if child:IsA(class) then
					valid = true
					break
				end
			end
			if not valid then
				-- stylua: ignore
				error(`{parent:GetFullName()} must have{
					if minimumChildren then ` at least {minimumChildren}` else ""
				} children which are {
					oneOf("one of the classes: %s", "%ss", classes)
				}; but found {a(child.ClassName)} named "{child.Name}"`)
			end
		end
	end
	return children
end

--[=[
	Checks if an instance has children with given names.

	@param parent The instance to check.
	@param childNames The names of the children to check for.
	@param childClass The class of the children to check for. Pass nil to not check the class. Can be a single class or a list of classes separated by "|".
	@return A dictionary of the checked children, with their names as keys.
]=]
function module.hasChildrenNamed(
	parent: Instance,
	childNames: { string },
	childClass: string?
): { [string]: Instance & any }
	local children = {}
	for _, childName in childNames do
		children[childName] = hasChild(parent, childName, childClass)
	end
	return children
end

--[=[
	Checks if an instance has children with given names and classes.

	@param parent The instance to check.
	@param childNamesToClasses A dictionary of child names to their classes. The classes can be a single class or a list of classes separated by "|".
	@return A dictionary of the checked children, with their names as keys.
]=]
function module.childrenMatchesRecord(
	parent: Instance,
	childNamesToClasses: { [string]: string }
): { [string]: Instance & any }
	local children = {}
	for childName, childClass in childNamesToClasses do
		children[childName] = hasChild(parent, childName, childClass)
	end
	return children
end

--[=[
	Checks if an instance has a tag with a given name.

	@param instance The instance to check.
	@param tagName The name of the tag to check for. Can be a single tag or a list of tags separated by "|".
	@return The matched tag value.
]=]
function module.hasTag(instance: Instance, tagName: string)
	local tags = splitValues(tagName)
	if #tags == 0 then
		error("tagName cannot be an empty string")
	end
	for _, tag in tags do
		if instance:HasTag(tag) then
			return tag
		end
	end
	error(`{instance:GetFullName()} must have{
		oneOf(" one of the tags: %s", " the tag %s", tags)
	}`)
end

--[=[
	Checks if an instance has an attribute with a given name and type.

	The `expectedType` parameter can be a single type or a list of types separated by "|", e.g. "string|number".
	If not specified, does not check the attribute's type.

	The `expectedValue` parameter can be a single value or a list of values. If a list of values is provided,
	the attribute value must be one of the values in the list.
	When nil is passed for `expectedValue`, the check is not performed. If you want to check for nil, pass "nil" to the
	`expectedType` parameter instead.

	@param instance The instance to check.
	@param attributeName The name of the attribute to check for.
	@param expectedType The type of the attribute to check for. Pass nil to not check the type.
	@param expectedValue The value of the attribute to check for. Pass nil to not check the value, or pass a table of values to check against.
	@return The value of the attribute.
]=]
-- TODO: Allow expectedValue to be a dictionary of values
function module.hasAttribute(
	instance: Instance,
	attributeName: string,
	expectedType: string?,
	expectedValue: (any | { any })?
): any
	local value = instance:GetAttribute(attributeName)

	if expectedType then
		local attributeTypes = splitValues(expectedType)
		local valid = false
		local valueType = typeof(value)
		for _, expectedType in attributeTypes do
			if valueType == expectedType then
				valid = true
				break
			end
		end
		if not valid then
			-- stylua: ignore
			error(`{instance:GetFullName()} must have an attribute named "{attributeName}" of {
				oneOf("one of the types: %s;", "type %s", attributeTypes)
			}; {
				if type(expectedValue) == "table" then oneOf("which must have one of the values: %s; ", "which must have the value %s; ", tostringAll(expectedValue))
				elseif expectedValue ~= nil then `which must have the value {expectedValue}; `
				else ""
			}got {value} ({valueType})`)
		end
	end

	if expectedValue ~= nil then
		local valid = false
		if expectedType and string.find(expectedType, "nil") and value == nil then
			valid = true
		elseif type(expectedValue) == "table" then
			if #expectedValue == 0 then
				error("expectedValue cannot be an empty table")
			end
			for _, expectedValue in expectedValue :: { any } do
				if value == expectedValue then
					valid = true
					break
				end
			end
		else
			valid = value == expectedValue
		end

		if not valid then
			-- stylua: ignore
			error(`{instance:GetFullName()} must have an attribute named "{attributeName}" {
				oneOf("of one of the types: %s; and ", "of type %s and ", splitValues(expectedType))
			} with {
				oneOf("one of the values: %s", "the value %s", tostringAll(expectedValue))	
			}; got {value}`)
		end
	end

	return value
end

return module
