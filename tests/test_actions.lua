BInt.register_test("actions/start_run", function(t)
	t:start_run({ seed = "JOKER123" })
	t:assert_eq(t:get_state(), G.STATES.BLIND_SELECT, "should be on blind select")
	t:log("start_run reached BLIND_SELECT")
end)

BInt.register_test("actions/select_blind", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()
	t:assert_eq(t:get_state(), G.STATES.SELECTING_HAND, "should be selecting hand")
	local hand = t:get_hand()
	t:assert_true(#hand > 0, "should have cards in hand")
	t:log("select_blind works, hand has " .. #hand .. " cards")
end)

BInt.register_test("actions/highlight_and_play", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()

	t:highlight({ 1, 2, 3, 4, 5 }):assert()
	t:assert_eq(#t:get_highlighted(), 5, "should have 5 highlighted")

	t:play_hand():assert()
	local state = t:get_state()
	t:assert_true(
		state == G.STATES.SELECTING_HAND or state == G.STATES.ROUND_EVAL or state == G.STATES.GAME_OVER,
		"should be in a valid post-play state"
	)
	t:log("play_hand completed, state: " .. t:get_state_name())
end)

BInt.register_test("actions/highlight_by_id", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()

	local hand = t:get_hand()
	t:assert_true(#hand > 0, "need cards in hand")

	local first_id = hand[1].id
	t:highlight_by_id({ first_id }):assert()
	t:assert_eq(#t:get_highlighted(), 1, "should have 1 highlighted")
	t:log("highlight_by_id works for " .. first_id)
end)

BInt.register_test("actions/unhighlight_all", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()

	t:highlight({ 1, 2, 3 }):assert()
	t:assert_eq(#t:get_highlighted(), 3)

	t:unhighlight_all():assert()
	t:assert_eq(#t:get_highlighted(), 0, "should have 0 highlighted")
end)

BInt.register_test("actions/discard", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()

	local hand_before = #t:get_hand()
	t:highlight({ 1 }):assert()
	t:discard():assert()

	t:assert_eq(t:get_state(), G.STATES.SELECTING_HAND)
	t:log("discard completed, hand went from " .. hand_before .. " to " .. #t:get_hand())
end)

BInt.register_test("actions/play_hand_no_highlight_fails", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()
	t:unhighlight_all()

	local result = t:play_hand()
	result:assert_fail("play_hand with no highlighted cards should fail")
end)

BInt.register_test("actions/full_round", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()

	for i = 1, 4 do
		local state = t:get_state()
		if state ~= G.STATES.SELECTING_HAND then
			break
		end
		t:highlight({ 1, 2, 3, 4, 5 }):assert()
		t:play_hand():assert()
		t:log("played hand " .. i .. ", state: " .. t:get_state_name())
	end

	local final_state = t:get_state()
	t:assert_true(
		final_state == G.STATES.ROUND_EVAL
			or final_state == G.STATES.GAME_OVER
			or final_state == G.STATES.SELECTING_HAND,
		"should end in a valid state"
	)
end)

BInt.register_test("actions/go_to_shop", function(t)
	t:start_run({ seed = "JOKER123" })
	t:go_to_shop():assert()
	t:assert_eq(t:get_state(), G.STATES.SHOP, "should be in shop")
	local shop_cards = t:get_shop_cards()
	t:log("in shop with " .. #shop_cards .. " cards available")
end)

BInt.register_test("actions/go_to_shop_from_selecting", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()
	t:assert_eq(t:get_state(), G.STATES.SELECTING_HAND, "should be selecting hand")
	t:go_to_shop():assert()
	t:assert_eq(t:get_state(), G.STATES.SHOP, "should be in shop from SELECTING_HAND")
	t:log("go_to_shop from SELECTING_HAND works")
end)

BInt.register_test("actions/go_to_shop_and_leave", function(t)
	t:start_run({ seed = "JOKER123" })
	t:go_to_shop():assert()
	t:assert_eq(t:get_state(), G.STATES.SHOP, "should be in shop")
	t:leave_shop():assert()
	t:assert_eq(t:get_state(), G.STATES.BLIND_SELECT, "should be back on blind select")
	t:log("go_to_shop -> leave_shop works")
end)

BInt.register_test("actions/skip_blind", function(t)
	t:start_run({ seed = "JOKER123" })
	t:assert_eq(t:get_blind_on_deck(), "Small", "should start on Small blind")
	t:skip_blind():assert()
	t:assert_eq(t:get_state(), G.STATES.BLIND_SELECT, "should still be on blind select")
	t:assert_eq(t:get_blind_on_deck(), "Big", "should advance to Big blind")
	t:log("skip_blind works")
end)

BInt.register_test("actions/cash_out", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()
	for i = 1, 10 do
		if t:get_state() ~= G.STATES.SELECTING_HAND then
			break
		end
		t:highlight({ 1, 2, 3, 4, 5 }):assert()
		t:play_hand():assert()
	end
	if t:get_state() == G.STATES.ROUND_EVAL then
		t:cash_out():assert()
		t:assert_eq(t:get_state(), G.STATES.SHOP, "should be in shop after cash out")
		t:log("cash_out works")
	else
		t:log("round didn't end in ROUND_EVAL, skipping cash_out test (state: " .. t:get_state_name() .. ")")
	end
end)

BInt.register_test("actions/buy_card", function(t)
	t:start_run({ seed = "JOKER123" })
	t:go_to_shop():assert()
	t:set_money(999)
	local cards = t:get_shop_cards()
	t:assert_true(#cards > 0, "shop should have cards")
	local result = t:buy_card(1)
	result:assert()
	t:log("bought " .. result.card.key .. " for $" .. result.card.cost)
end)

BInt.register_test("actions/buy_voucher", function(t)
	t:start_run({ seed = "JOKER123" })
	t:go_to_shop():assert()
	t:set_money(999)
	local vouchers = t:get_shop_vouchers()
	t:assert_true(#vouchers > 0, "shop should have vouchers")
	local result = t:buy_voucher(1)
	result:assert()
	t:log("bought voucher " .. result.card.key)
end)

BInt.register_test("actions/sell_joker", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()
	t:spawn_joker("j_joker"):assert()
	t:assert_eq(#t:get_jokers(), 1, "should have 1 joker")
	local money_before = t:get_money()
	t:sell_joker(1):assert()
	t:assert_eq(#t:get_jokers(), 0, "should have 0 jokers after sell")
	t:assert_true(t:get_money() >= money_before, "should have at least same money")
	t:log("sell_joker works")
end)

BInt.register_test("actions/sell_consumable", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()
	t:spawn_consumable("c_fool"):assert()
	t:assert_eq(#t:get_consumables(), 1, "should have 1 consumable")
	t:sell_consumable(1):assert()
	t:assert_eq(#t:get_consumables(), 0, "should have 0 consumables after sell")
	t:log("sell_consumable works")
end)

BInt.register_test("actions/reroll", function(t)
	t:start_run({ seed = "JOKER123" })
	t:go_to_shop():assert()
	t:set_money(999)
	local cards_before = {}
	for _, c in ipairs(t:get_shop_cards()) do
		table.insert(cards_before, c.key)
	end
	t:reroll():assert()
	t:assert_eq(t:get_state(), G.STATES.SHOP, "should still be in shop")
	t:log("reroll works, had " .. #cards_before .. " cards before")
end)

BInt.register_test("actions/use_consumable", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()
	t:spawn_consumable("c_mercury"):assert()
	t:use_consumable(1):assert()
	t:assert_eq(#t:get_consumables(), 0, "consumable should be used up")
	t:log("use_consumable works")
end)

BInt.register_test("actions/highlight_by_rank", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()
	local hand = t:get_hand()
	local found_rank = hand[1].rank
	local short = found_rank == "10" and "10" or found_rank:sub(1, 1)
	if found_rank == "Jack" then
		short = "J"
	elseif found_rank == "Queen" then
		short = "Q"
	elseif found_rank == "King" then
		short = "K"
	elseif found_rank == "Ace" then
		short = "A"
	else
		short = tostring(found_rank)
	end
	t:highlight_by_rank({ short }):assert()
	t:assert_true(#t:get_highlighted() >= 1, "should have at least 1 highlighted")
	t:log("highlight_by_rank works for " .. short)
end)

BInt.register_test("actions/highlight_by_suit", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()
	local hand = t:get_hand()
	local suit = hand[1].suit
	t:highlight_by_suit({ suit }):assert()
	t:assert_true(#t:get_highlighted() >= 1, "should have at least 1 highlighted")
	t:log("highlight_by_suit works for " .. suit)
end)

BInt.register_test("actions/sort_hand", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()
	t:sort_hand("rank"):assert()
	t:assert_eq(t:get_state(), G.STATES.SELECTING_HAND, "should still be selecting")
	t:log("sort_hand works")
end)

BInt.register_test("actions/restart_run", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()
	t:restart_run():assert()
	t:assert_eq(t:get_state(), G.STATES.BLIND_SELECT, "should be on blind select after restart")
	t:log("restart_run works")
end)

BInt.register_test("actions/buy_pack_and_skip", function(t)
	t:start_run({ seed = "JOKER123" })
	t:go_to_shop():assert()
	t:set_money(999)
	local packs = t:get_shop_packs()
	if #packs > 0 then
		t:buy_pack(1):assert()
		local state = t:get_state()
		t:assert_true(
			state == G.STATES.TAROT_PACK
				or state == G.STATES.PLANET_PACK
				or state == G.STATES.SPECTRAL_PACK
				or state == G.STATES.STANDARD_PACK
				or state == G.STATES.BUFFOON_PACK
				or state == 999,
			"should be in a pack state"
		)
		t:skip_pack():assert()
		t:assert_eq(t:get_state(), G.STATES.SHOP, "should be back in shop")
		t:log("buy_pack and skip_pack work")
	else
		t:log("no packs in shop, skipping")
	end
end)
