BInt.register_test("resolve/parse_ace_of_spades", function(t)
	local card = BInt._resolve.parse_card_id("As")
	t:assert_eq(card.rank, "Ace")
	t:assert_eq(card.suit, "Spades")
end)

BInt.register_test("resolve/parse_king_of_hearts", function(t)
	local card = BInt._resolve.parse_card_id("Kh")
	t:assert_eq(card.rank, "King")
	t:assert_eq(card.suit, "Hearts")
end)

BInt.register_test("resolve/parse_10_of_diamonds", function(t)
	local card = BInt._resolve.parse_card_id("10d")
	t:assert_eq(card.rank, "10")
	t:assert_eq(card.suit, "Diamonds")
end)

BInt.register_test("resolve/parse_2_of_clubs", function(t)
	local card = BInt._resolve.parse_card_id("2c")
	t:assert_eq(card.rank, "2")
	t:assert_eq(card.suit, "Clubs")
end)

BInt.register_test("resolve/parse_queen_of_diamonds", function(t)
	local card = BInt._resolve.parse_card_id("Qd")
	t:assert_eq(card.rank, "Queen")
	t:assert_eq(card.suit, "Diamonds")
end)

BInt.register_test("resolve/parse_jack_of_clubs", function(t)
	local card = BInt._resolve.parse_card_id("Jc")
	t:assert_eq(card.rank, "Jack")
	t:assert_eq(card.suit, "Clubs")
end)

BInt.register_test("resolve/parse_invalid_returns_nil", function(t)
	local card, err = BInt._resolve.parse_card_id("Zz")
	t:assert_eq(card, nil, "invalid ID should return nil")
	t:assert_eq(err, "invalid_card_id")
end)

BInt.register_test("resolve/in_area_not_found", function(t)
	local card, err = BInt._resolve.in_area(nil, 1, function() end)
	t:assert_eq(card, nil)
	t:assert_eq(err, "area_not_found")
end)

BInt.register_test("resolve/in_area_index_out_of_range", function(t)
	local mock_area = { cards = { "a", "b" } }
	local card, err = BInt._resolve.in_area(mock_area, 99, function() end)
	t:assert_eq(card, nil)
	t:assert_eq(err, "index_out_of_range")
end)

BInt.register_test("resolve/in_area_by_index", function(t)
	local mock_area = { cards = { "first", "second", "third" } }
	local card = BInt._resolve.in_area(mock_area, 2, function() end)
	t:assert_eq(card, "second")
end)

BInt.register_test("resolve/in_area_by_key", function(t)
	local mock_area = { cards = { { id = "x" }, { id = "y" }, { id = "z" } } }
	local card = BInt._resolve.in_area(mock_area, "y", function(c) return c.id end)
	t:assert_eq(card.id, "y")
end)

BInt.register_test("resolve/in_area_key_not_found", function(t)
	local mock_area = { cards = { { id = "x" } } }
	local card, err = BInt._resolve.in_area(mock_area, "nope", function(c) return c.id end)
	t:assert_eq(card, nil)
	t:assert_eq(err, "key_not_found")
end)
