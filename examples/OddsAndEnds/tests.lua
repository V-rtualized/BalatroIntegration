-------------------------------------------------------------------------------
-- Loaded Dice
-------------------------------------------------------------------------------

BInt.register_test("odds_and_ends:loaded_dice_max_roll", function(test)
	test:start_run({ seed = "DICE1" })
	test:select_blind()

	test:spawn_joker("j_odds_loaded_dice")

	-- Force max roll
	test:mock("pseudorandom", 6)

	test:highlight({ 1, 2, 3, 4, 5 })
	test:play_hand():assert()

	local jokers = test:get_jokers()
	test:assert_eq(jokers[1].key, "j_odds_loaded_dice")
	test:assert_eq(jokers[1].extra.last_roll, 6, "Last roll should be 6")
end)

BInt.register_test("odds_and_ends:loaded_dice_min_roll", function(test)
	test:start_run({ seed = "DICE2" })
	test:select_blind()

	test:spawn_joker("j_odds_loaded_dice")

	-- Force min roll
	test:mock("pseudorandom", 1)

	test:highlight({ 1, 2, 3, 4, 5 })
	test:play_hand():assert()

	local jokers = test:get_jokers()
	test:assert_eq(jokers[1].extra.last_roll, 1, "Last roll should be 1")
end)

BInt.register_test("odds_and_ends:loaded_dice_sequence", function(test)
	test:start_run({ seed = "DICE3" })
	test:skip_to(20, "small")
	test:select_blind()

	test:spawn_joker("j_odds_loaded_dice")

	-- Play two hands with different forced rolls
	test:mock_sequence("pseudorandom", { 2, 5 })

	test:highlight({ 1, 2, 3, 4, 5 })
	test:play_hand():assert()

	local score_after_first = test:get_score()

	test:highlight({ 1, 2, 3, 4, 5 })
	test:play_hand():assert()

	local score_after_second = test:get_score()
	test:assert_gt(
		score_after_second.scored_chips,
		score_after_first.scored_chips,
		"Roll of 5 should score more than roll of 2"
	)
end)

-------------------------------------------------------------------------------
-- Royal Favor
-------------------------------------------------------------------------------

BInt.register_test("odds_and_ends:royal_favor_matching_cards", function(test)
	test:start_run({ seed = "ROYAL1" })

	test:spawn_joker("j_odds_royal_favor")

	-- Force chosen rank to Ace (id 14)
	test:mock("pseudorandom", 14)
	test:select_blind()

	-- Verify chosen rank is Ace
	local jokers = test:get_jokers()
	test:assert_eq(jokers[1].extra.chosen_id, 14, "Chosen rank should be Ace (id 14)")
	test:assert_eq(jokers[1].extra.chosen_name, "Ace", "Chosen name should be Ace")

	-- Play a pair of aces — should get +3 mult per ace = +6 mult
	test:highlight_by_rank({ "A", "A" })
	test:play_hand():assert()
end)

BInt.register_test("odds_and_ends:royal_favor_no_match", function(test)
	test:start_run({ seed = "ROYAL2" })

	test:spawn_joker("j_odds_royal_favor")

	-- Force chosen rank to 2 (id 2)
	test:mock("pseudorandom", 2)
	test:select_blind()

	-- Play only aces — no 2s, so Royal Favor shouldn't add mult
	test:highlight_by_rank({ "A", "A" })
	test:play_hand():assert()
end)

BInt.register_test("odds_and_ends:royal_favor_rank_changes_each_round", function(test)
	test:start_run({ seed = "ROYAL3" })

	test:spawn_joker("j_odds_royal_favor")

	-- Round 1: force King (id 13)
	test:mock("pseudorandom", 13)
	test:select_blind()

	local jokers_r1 = test:get_jokers()
	local rank_r1 = jokers_r1[1].extra.chosen_name

	-- Advance to round 2 via shop
	test:go_to_shop()

	-- Round 2: force 7 (id 7)
	test:mock("pseudorandom", 7)
	test:leave_shop()
	test:select_blind()

	local jokers_r2 = test:get_jokers()
	local rank_r2 = jokers_r2[1].extra.chosen_name

	test:assert_eq(rank_r1, "King", "Round 1 should pick King")
	test:assert_eq(rank_r2, "7", "Round 2 should pick 7")
end)

-------------------------------------------------------------------------------
-- Double or Nothing
-------------------------------------------------------------------------------

BInt.register_test("odds_and_ends:double_or_nothing_config", function(test)
	test:start_run({ seed = "DON1" })
	test:select_blind()

	test:spawn_joker("j_odds_double_or_nothing")

	local jokers = test:get_jokers()
	test:assert_eq(jokers[1].key, "j_odds_double_or_nothing")
	test:assert_eq(jokers[1].extra.prob, 2, "Prob should be 1 in 2")
	test:assert_eq(jokers[1].extra.gain, 8, "Gain should be $8")
	test:assert_eq(jokers[1].extra.loss, 4, "Loss should be $4")
	test:assert_eq(jokers[1].extra.net, 0, "Net should start at 0")
end)

BInt.register_test("odds_and_ends:double_or_nothing_scoring", function(test)
	test:start_run({ seed = "DON2" })
	test:select_blind()

	test:spawn_joker("j_odds_double_or_nothing")

	-- Verify joker config
	local jokers = test:get_jokers()
	test:assert_eq(jokers[1].key, "j_odds_double_or_nothing")
	test:assert_eq(jokers[1].extra.gain, 8, "Gain should be $8")
	test:assert_eq(jokers[1].extra.loss, 4, "Loss should be $4")
	test:assert_eq(jokers[1].extra.net, 0, "Net should start at 0")

	-- Play a hand — joker doesn't fire on joker_main, only end_of_round
	test:highlight({ 1, 2, 3, 4, 5 })
	test:play_hand():assert()
end)

BInt.register_test("odds_and_ends:double_or_nothing_win", function(test)
	test:start_run({ seed = "DON3" })
	test:select_blind()

	test:spawn_joker("j_odds_double_or_nothing")

	-- Force win: pseudorandom returns < 0.5
	test:mock("pseudorandom", 0.1)

	-- Beat the blind so end_of_round context fires
	test:beat_blind():assert()

	-- Transition to shop (skipping round eval screen)
	test:go_to_shop()

	-- Verify net increased by gain amount
	local jokers = test:get_jokers()
	test:assert_eq(jokers[1].extra.net, 8, "Net should be +8 after winning")
end, { immortal = true })

BInt.register_test("odds_and_ends:double_or_nothing_loss", function(test)
	test:start_run({ seed = "DON4" })
	test:select_blind()

	test:spawn_joker("j_odds_double_or_nothing")

	-- Force loss: pseudorandom returns >= 0.5
	test:mock("pseudorandom", 0.9)

	-- Beat the blind so end_of_round context fires
	test:beat_blind():assert()

	-- Transition to shop (skipping round eval screen)
	test:go_to_shop()

	-- Verify net decreased by loss amount
	local jokers = test:get_jokers()
	test:assert_eq(jokers[1].extra.net, -4, "Net should be -4 after losing")
end, { immortal = true })
