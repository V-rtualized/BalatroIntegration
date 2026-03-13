function BInt._context_methods:mock(func_name, value)
	BInt._mock_queues[func_name] = BInt._mock_queues[func_name] or {}
	table.insert(BInt._mock_queues[func_name], value)
end

function BInt._context_methods:mock_sequence(func_name, values)
	BInt._mock_queues[func_name] = BInt._mock_queues[func_name] or {}
	for _, v in ipairs(values) do
		table.insert(BInt._mock_queues[func_name], v)
	end
end

function BInt._context_methods:clear_mock(func_name)
	BInt._mock_queues[func_name] = {}
end

function BInt._context_methods:clear_all_mocks()
	BInt._mock_queues = {}
end
