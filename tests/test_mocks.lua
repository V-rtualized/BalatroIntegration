BInt.register_test("mocks/mock_and_clear", function(t)
	t:mock("pseudorandom", 0.5)
	t:assert_true(#BInt._mock_queues["pseudorandom"] == 1, "queue should have 1 entry")
	t:clear_mock("pseudorandom")
	t:assert_true(#BInt._mock_queues["pseudorandom"] == 0, "queue should be empty after clear")
end)

BInt.register_test("mocks/mock_sequence", function(t)
	t:mock_sequence("pseudorandom", { 0.1, 0.2, 0.3 })
	t:assert_eq(#BInt._mock_queues["pseudorandom"], 3, "queue should have 3 entries")
	t:clear_all_mocks()
	t:assert_true(BInt._mock_queues["pseudorandom"] == nil, "queue should be nil after clear_all")
end)

BInt.register_test("mocks/pseudorandom_intercept", function(t)
	t:mock("pseudorandom", 0.99)
	local val = pseudorandom("test_seed")
	t:assert_eq(val, 0.99, "should return mocked value")
	t:assert_eq(#(BInt._mock_queues["pseudorandom"] or {}), 0, "queue should be consumed")
end)

BInt.register_test("mocks/pseudorandom_with_range", function(t)
	t:mock("pseudorandom", 5)
	local val = pseudorandom("test_seed", 1, 10)
	t:assert_eq(val, 5, "mock should return 5 directly")

	t:mock("pseudorandom", 14)
	val = pseudorandom("test_seed", 2, 14)
	t:assert_eq(val, 14, "mock should return 14 directly")
end)

BInt.register_test("mocks/pseudorandom_fallthrough", function(t)
	local val = pseudorandom("test_seed_fallthrough")
	t:assert_true(type(val) == "number", "should return a number from original")
end)

BInt.register_test("mocks/cleanup_between_tests", function(t)
	t:assert_true(
		BInt._mock_queues["pseudorandom"] == nil or #BInt._mock_queues["pseudorandom"] == 0,
		"mock queues should be clean at test start"
	)
end)
