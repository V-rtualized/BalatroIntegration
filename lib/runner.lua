BInt._runner = {}

function BInt.register_test(name, func, params)
	table.insert(BInt._tests, {
		name = name,
		func = func,
		params = params or {},
	})
end

function BInt.run_tests(pattern)
	if BInt._running then
		sendDebugMessage("Tests already running", BInt._MOD_METADATA.id)
		return
	end

	local tests = {}
	for _, test in ipairs(BInt._tests) do
		if not pattern or test.name:find(pattern, 1, true) then
			table.insert(tests, test)
		end
	end

	if #tests == 0 then
		sendDebugMessage("No tests match pattern: " .. (pattern or "*"), BInt._MOD_METADATA.id)
		return
	end

	BInt._running = true
	BInt._profile.setup()
	BInt._test_queue = tests
	BInt._suite_results = {
		passed = 0,
		failed = 0,
		errors = {},
		total = #tests,
		start_time = G.TIMERS.REAL,
	}
	BInt._output.suite_start(#tests)
	BInt._emit("suite_start", #tests)

	BInt._runner.run_next()
end

function BInt.run_test(name)
	BInt.run_tests(name)
end

function BInt._runner.run_next()
	if #BInt._test_queue == 0 then
		BInt._suite_results.duration = G.TIMERS.REAL - BInt._suite_results.start_time
		BInt._output.suite_complete(BInt._suite_results)
		BInt._emit("suite_complete", BInt._suite_results)
		BInt._profile.teardown()
		return
	end

	local test = table.remove(BInt._test_queue, 1)
	local ctx = BInt.create_context(test.name, test.params)
	BInt._active_context = ctx

	BInt._emit("test_start", test.name)
	BInt._output.test_start(test.name)

	if BInt._params and BInt._params.apply then
		BInt._params.apply(test.params)
	end

	local co = coroutine.create(function()
		test.func(ctx)
	end)
	BInt._active_coroutine = co

	local ok, action, data = coroutine.resume(co)
	if not ok then
		BInt._runner.handle_error(action)
	elseif coroutine.status(co) == "dead" then
		BInt._runner.handle_complete()
	elseif action == "FAIL" then
		BInt._runner.handle_fail(data)
	end
end

function BInt._runner.handle_complete()
	local ctx = BInt._active_context
	local duration = G.TIMERS.REAL - ctx._start_time
	if ctx._failed then
		BInt._suite_results.failed = BInt._suite_results.failed + 1
		table.insert(BInt._suite_results.errors, { name = ctx._name, message = ctx._fail_message })
		BInt._output.test_fail(ctx._name, ctx._fail_message, duration)
		BInt._emit("test_fail", ctx._name, ctx._fail_message, duration)
	else
		BInt._suite_results.passed = BInt._suite_results.passed + 1
		BInt._output.test_pass(ctx._name, duration)
		BInt._emit("test_pass", ctx._name, duration)
	end
	BInt._runner.cleanup()
	BInt._runner.run_next()
end

function BInt._runner.handle_fail(msg)
	local ctx = BInt._active_context
	local duration = G.TIMERS.REAL - ctx._start_time
	BInt._suite_results.failed = BInt._suite_results.failed + 1
	table.insert(BInt._suite_results.errors, { name = ctx._name, message = msg })
	BInt._output.test_fail(ctx._name, msg, duration)
	BInt._emit("test_fail", ctx._name, msg, duration)
	BInt._runner.cleanup()
	BInt._runner.run_next()
end

function BInt._runner.handle_error(err)
	local ctx = BInt._active_context
	local duration = ctx and (G.TIMERS.REAL - ctx._start_time) or 0
	local name = ctx and ctx._name or "unknown"
	BInt._suite_results.failed = BInt._suite_results.failed + 1
	table.insert(BInt._suite_results.errors, { name = name, message = "ERROR: " .. tostring(err) })
	BInt._output.test_fail(name, "ERROR: " .. tostring(err), duration)
	BInt._emit("test_fail", name, "ERROR: " .. tostring(err), duration)
	BInt._runner.cleanup()
	BInt._runner.run_next()
end

function BInt._runner.cleanup()
	BInt._active_coroutine = nil
	BInt._active_context = nil
	BInt._wait_condition = nil

	G.E_MANAGER:clear_queue()

	if BInt._params and BInt._params.restore then
		BInt._params.restore()
	end

	if BInt._mocks_cleanup then
		BInt._mocks_cleanup()
	end
end

function BInt.on(event, callback)
	BInt._events[event] = BInt._events[event] or {}
	table.insert(BInt._events[event], callback)
end

function BInt._emit(event, ...)
	if BInt._events[event] then
		for _, cb in ipairs(BInt._events[event]) do
			local ok, err = pcall(cb, ...)
			if not ok then
				sendDebugMessage("Event handler error (" .. event .. "): " .. tostring(err), BInt._MOD_METADATA.id)
			end
		end
	end
end
