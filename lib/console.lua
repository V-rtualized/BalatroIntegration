if not BInt._dp_api then
	return
end

local api = BInt._dp_api

-- integration:run [pattern] — run tests
api.addCommand({
	name = "run",
	shortDesc = "Run integration tests",
	desc = "Run integration tests. Usage: integration:run [pattern]\n\nWithout args, runs all registered tests.\nWith a pattern, runs tests whose name contains the pattern.",
	exec = function(args, rawArgs, dp)
		if rawArgs and rawArgs ~= "" then
			BInt.run_tests(rawArgs)
		else
			BInt.run_tests()
		end
		return "Tests started."
	end,
})

-- integration:list [pattern] — list registered tests
api.addCommand({
	name = "list",
	shortDesc = "List registered tests",
	desc = "List registered integration tests. Usage: integration:list [pattern]",
	exec = function(args, rawArgs, dp)
		if #BInt._tests == 0 then
			return "No tests registered."
		end
		local out = "Registered tests (" .. #BInt._tests .. "):\n"
		for _, test in ipairs(BInt._tests) do
			if not rawArgs or rawArgs == "" or test.name:find(rawArgs, 1, true) then
				out = out .. "  " .. test.name .. "\n"
			end
		end
		return out
	end,
})

-- integration:status — show last suite results
api.addCommand({
	name = "status",
	shortDesc = "Show last test run results",
	desc = "Shows the results of the last test suite run, or current progress if tests are running.",
	exec = function(args, rawArgs, dp)
		if BInt._running then
			local r = BInt._suite_results
			return "Running... "
				.. r.passed
				.. " passed, "
				.. r.failed
				.. " failed, "
				.. (r.passed + r.failed)
				.. "/"
				.. r.total
		end
		if not BInt._suite_results then
			return "No tests have been run yet."
		end
		local r = BInt._suite_results
		local out = r.passed .. " passed, " .. r.failed .. " failed"
		if r.duration then
			out = out .. string.format(" (%.1fs)", r.duration)
		end
		if #r.errors > 0 then
			out = out .. "\n\nFailures:"
			for _, e in ipairs(r.errors) do
				out = out .. "\n  " .. e.name .. ": " .. e.message
			end
		end
		return out
	end,
})

-- integration:stop — abort running tests
api.addCommand({
	name = "stop",
	shortDesc = "Stop running tests",
	desc = "Aborts the current test run if one is in progress.",
	exec = function(args, rawArgs, dp)
		if not BInt._running then
			return "No tests are running."
		end
		BInt._runner.cleanup()
		BInt._test_queue = {}
		BInt._profile.teardown_sync()
		BInt._running = false
		return "Tests stopped."
	end,
})
