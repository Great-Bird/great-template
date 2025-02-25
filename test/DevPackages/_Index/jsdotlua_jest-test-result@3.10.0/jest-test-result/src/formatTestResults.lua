-- ROBLOX upstream: https://github.com/facebook/jest/blob/v28.0.0/packages/jest-test-result/src/formatTestResults.ts
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]

local LuauPolyfill = require(script.Parent.Parent:WaitForChild('luau-polyfill'))
local Array = LuauPolyfill.Array
local Boolean = LuauPolyfill.Boolean
local Object = LuauPolyfill.Object

local types = require(script.Parent:WaitForChild('types'))
type AggregatedResult = types.AggregatedResult
type AssertionResult = types.AssertionResult
type CodeCoverageFormatter = types.CodeCoverageFormatter
type CodeCoverageReporter = types.CodeCoverageReporter
type FormattedAssertionResult = types.FormattedAssertionResult
type FormattedTestResult = types.FormattedTestResult
type FormattedTestResults = types.FormattedTestResults
type TestResult = types.TestResult

local formatTestAssertion

local function formatTestResult(
	testResult: TestResult,
	codeCoverageFormatter: CodeCoverageFormatter?,
	reporter: CodeCoverageReporter?
): FormattedTestResult
	local assertionResults = Array.map(testResult.testResults, formatTestAssertion)
	if testResult.testExecError ~= nil then
		local now = DateTime.now().UnixTimestampMillis
		return {
			assertionResults = assertionResults,
			coverage = {},
			endTime = now,
			message = if testResult.failureMessage ~= nil
				then testResult.failureMessage
				else testResult.testExecError.message,
			name = testResult.testFilePath,
			startTime = now,
			status = "failed",
			summary = "",
		}
	else
		local allTestsPassed = testResult.numFailingTests == 0
		return {
			assertionResults = assertionResults,
			coverage = if codeCoverageFormatter ~= nil
				then codeCoverageFormatter(testResult.coverage, reporter)
				else testResult.coverage,
			endTime = testResult.perfStats["end"],
			message = if testResult.failureMessage ~= nil then testResult.failureMessage else "",
			name = testResult.testFilePath,
			startTime = testResult.perfStats.start,
			status = if Boolean.toJSBoolean(allTestsPassed) then "passed" else "failed",
			summary = "",
		}
	end
end

function formatTestAssertion(assertion: AssertionResult): FormattedAssertionResult
	local result: FormattedAssertionResult = {
		ancestorTitles = assertion.ancestorTitles,
		duration = assertion.duration,
		failureMessages = nil,
		fullName = assertion.fullName,
		location = assertion.location,
		status = assertion.status,
		title = assertion.title,
	}
	if assertion.failureMessages then
		result.failureMessages = assertion.failureMessages
	end
	return result
end

local function formatTestResults(
	results: AggregatedResult,
	codeCoverageFormatter: CodeCoverageFormatter?,
	reporter: CodeCoverageReporter?
): FormattedTestResults
	local testResults = Array.map(results.testResults, function(testResult)
		return formatTestResult(testResult, codeCoverageFormatter, reporter)
	end)
	return Object.assign({}, results, { testResults = testResults })
end

return {
	default = formatTestResults,
}
