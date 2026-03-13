BInt._wait = {}

local DEFAULT_TIMEOUT = 10

local _game_update_ref = Game.update
function Game:update(dt)
	_game_update_ref(self, dt)

	if BInt._running and BInt._params and BInt._params.update_speed then
		BInt._params.update_speed()
	end

	if BInt._active_coroutine and BInt._wait_condition then
		if BInt._wait_condition() then
			BInt._wait_condition = nil
			local ok, action, data = coroutine.resume(BInt._active_coroutine)
			if not ok then
				if BInt._teardown_active then
					sendDebugMessage("Teardown error: " .. tostring(action), BInt._MOD_METADATA.id)
					BInt._active_coroutine = nil
					BInt._teardown_active = nil
					BInt._running = false
					return
				end
				BInt._runner_handle_error(action)
			elseif coroutine.status(BInt._active_coroutine) == "dead" then
				if BInt._teardown_active then
					BInt._active_coroutine = nil
					BInt._teardown_active = nil
					return
				end
				BInt._runner_handle_complete()
			elseif action == "FAIL" then
				BInt._runner_handle_fail(data)
			end
		end
	end
end

function BInt._runner_handle_error(err)
	BInt._runner.handle_error(err)
end

function BInt._runner_handle_complete()
	BInt._runner.handle_complete()
end

function BInt._runner_handle_fail(msg)
	BInt._runner.handle_fail(msg)
end

local function make_timeout(timeout, fail_msg)
	local deadline = G.TIMERS.REAL + (timeout or DEFAULT_TIMEOUT)
	return function()
		if G.TIMERS.REAL > deadline then
			if BInt._active_context then
				BInt._active_context._failed = true
				BInt._active_context._fail_message = fail_msg or "Timeout"
			end
			return true
		end
		return false
	end
end

local function check_timeout_fail()
	if BInt._active_context and BInt._active_context._failed then
		coroutine.yield("FAIL", BInt._active_context._fail_message)
	end
end

function BInt._wait.queues_empty()
	for _, q in pairs(G.E_MANAGER.queues) do
		if #q > 0 then
			return false
		end
	end
	return true
end

function BInt._wait.base_queue_empty()
	local base = G.E_MANAGER.queues["base"]
	return not base or #base == 0
end

function BInt._wait.stable_drain(stable_frames, timeout)
	stable_frames = stable_frames or 5
	local stable_count = 0
	local last_size = -1
	local timed_out = make_timeout(timeout, "Timeout waiting for stable drain")
	BInt._wait_condition = function()
		if timed_out() then
			return true
		end
		if G.SCORING_COROUTINE then
			stable_count = 0
			return false
		end
		local base = G.E_MANAGER.queues["base"]
		local size = base and #base or 0
		if size == last_size then
			stable_count = stable_count + 1
			return stable_count >= stable_frames
		end
		last_size = size
		stable_count = 0
		return false
	end
	coroutine.yield()
	check_timeout_fail()
end

function BInt._wait.for_state(target_state, timeout)
	local match_count = 0
	local timed_out = make_timeout(timeout, "Timeout waiting for state " .. tostring(target_state))
	BInt._wait_condition = function()
		if timed_out() then
			return true
		end
		if G.STATE == target_state then
			match_count = match_count + 1
			return match_count >= 3
		end
		match_count = 0
		return false
	end
	coroutine.yield()
	check_timeout_fail()
end

function BInt._wait.for_any_state(target_states, timeout)
	local match_count = 0
	local target_set = {}
	for _, s in ipairs(target_states) do
		target_set[s] = true
	end
	local timed_out = make_timeout(timeout, "Timeout waiting for target states")
	BInt._wait_condition = function()
		if timed_out() then
			return true
		end
		if target_set[G.STATE] then
			match_count = match_count + 1
			return match_count >= 3
		end
		match_count = 0
		return false
	end
	coroutine.yield()
	check_timeout_fail()
end

function BInt._wait.for_condition(fn, timeout, fail_msg)
	local timed_out = make_timeout(timeout, fail_msg or "Timeout waiting for condition")
	BInt._wait_condition = function()
		if timed_out() then
			return true
		end
		return fn()
	end
	coroutine.yield()
	check_timeout_fail()
end

function BInt._wait.frames(n)
	local count = 0
	BInt._wait_condition = function()
		count = count + 1
		return count >= n
	end
	coroutine.yield()
end
