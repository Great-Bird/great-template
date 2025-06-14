--[=[
	Paste this script in the command bar to run it.

	Uses the last selected instance to replace all other selected instances.
	If the selected instance is a PVInstance, attempts to move the replacement
	instance to it.
]=]

local ChangeHistoryService = game:GetService "ChangeHistoryService"
local Selection = game:GetService "Selection"

local RECORDING_NAME = "ReplaceInstancesWithLastSelected"

local selection = Selection:Get()
local lastSelected = table.remove(selection)
if not lastSelected then
	warn "No instances selected"
	return
end

if ChangeHistoryService:IsRecordingInProgress() then
	warn "Recording in progress, cannot replace instances"
	return
end

local identifier = ChangeHistoryService:TryBeginRecording(RECORDING_NAME)
if not identifier then
	warn "Failed to begin recording changes"
	return
end

for _, instance in selection do
	local parent = instance.Parent
	local clone = lastSelected:Clone()

	if instance:IsA "PVInstance" and clone:IsA "PVInstance" then
		clone:PivotTo(instance:GetPivot())
	end

	if instance:IsA "Model" and clone:IsA "Model" then
		clone:ScaleTo(instance:GetScale())
	end

	clone.Parent = parent
	instance.Parent = nil
end

ChangeHistoryService:FinishRecording(identifier, Enum.FinishRecordingOperation.Commit)
