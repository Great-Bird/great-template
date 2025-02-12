--!strict

local process = require("@lune/process")
local stdio = require("@lune/stdio")

local color = stdio.color

local function printTaskCompleted(successMessage: string)
	stdio.write(`✅ {color("green")}{successMessage}{color("reset")}\n`)
end

local function printTaskInProgress(message: string)
	stdio.write(`🔄 {color("yellow")}{message}{color("reset")}\n`)
end

local function printTaskFailed(errorMessage: string, stderr: string?)
	if stderr and stderr ~= "" then
		stdio.ewrite(`❌ {color("red")}{errorMessage}:\n{stderr}{color("reset")}\n`)
	else
		stdio.ewrite(`❌ {color("red")}{errorMessage}{color("reset")}\n`)
	end
end

local function printAllCompleted()
	print(`{color("green")}All tasks completed!{color("reset")}`)
end

local function spawnProcess(
	programName: string,
	parameters: { string }?,
	options: process.SpawnOptions?,
	successMessage: string?,
	errorMessage: string?
)
	local result = process.spawn(programName, parameters, options)
	if result.ok and result.code == 0 then
		if successMessage then
			printTaskCompleted(successMessage)
		end
	else
		if errorMessage then
			printTaskFailed(errorMessage, result.stderr)
		end
		process.exit(1)
	end
	return result
end

return {
	printAllCompleted = printAllCompleted,
	printTaskCompleted = printTaskCompleted,
	printTaskFailed = printTaskFailed,
	printTaskInProgress = printTaskInProgress,
	spawnProcess = spawnProcess,
}
