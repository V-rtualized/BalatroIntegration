BInt._context_methods = setmetatable({}, { __index = BInt._assertion_methods })

function BInt.create_context(test_name, params)
	local ctx = {
		_name = test_name,
		_params = params or {},
		_start_time = G.TIMERS.REAL,
		_failed = false,
		_fail_message = nil,
	}
	return setmetatable(ctx, { __index = BInt._context_methods })
end
