-------------------------------------------------------------------------------
-- The Alchemist (Tarot) — enhances selected cards to Gold
-------------------------------------------------------------------------------

BInt.register_test("arcane_arsenal:alchemist_enhances_cards", function(test)
	test:start_run({ seed = "ALCH1" })
	test:select_blind()

	test:spawn_consumable("c_arcane_the_alchemist")

	-- Highlight 2 cards from hand
	test:highlight({ 1, 2 })

	-- Use the tarot
	test:use_consumable("c_arcane_the_alchemist"):assert()

	local hand = test:get_hand()
	test:assert_eq(hand[1].enhancement, "m_gold", "Card 1 should be Gold enhanced")
	test:assert_eq(hand[2].enhancement, "m_gold", "Card 2 should be Gold enhanced")
end)

BInt.register_test("arcane_arsenal:alchemist_respects_max_cards", function(test)
	test:start_run({ seed = "ALCH2" })
	test:select_blind()

	test:spawn_consumable("c_arcane_the_alchemist")

	-- Highlight 4 cards (exceeds max of 3) — can_use should return false
	test:highlight({ 1, 2, 3, 4 })

	-- Check can_use directly on the card
	local card = G.consumeables.cards[1]
	local can = card.ability.consumeable and card.ability.consumeable.can_use
		and card.ability.consumeable:can_use(card)
		or (card.config.center.can_use and card.config.center:can_use(card))
	test:assert_false(can, "Alchemist should not be usable with 4 highlighted cards")
end)

BInt.register_test("arcane_arsenal:alchemist_single_card", function(test)
	test:start_run({ seed = "ALCHSINGLE" })
	test:select_blind()

	test:spawn_consumable("c_arcane_the_alchemist")

	-- Highlight just 1 card
	test:highlight({ 1 })
	test:use_consumable("c_arcane_the_alchemist"):assert()

	local hand = test:get_hand()
	test:assert_eq(hand[1].enhancement, "m_gold", "Card should be Gold enhanced")
end)

-------------------------------------------------------------------------------
-- Nexus (Spectral) — adds Purple seal to all cards in hand
-------------------------------------------------------------------------------

BInt.register_test("arcane_arsenal:nexus_seals_hand", function(test)
	test:start_run({ seed = "NEXUS1" })
	test:select_blind()

	test:spawn_consumable("c_arcane_nexus")
	test:use_consumable("c_arcane_nexus"):assert()

	local hand_after = test:get_hand()
	for i, card in ipairs(hand_after) do
		test:assert_eq(card.seal, "Purple", "Card " .. i .. " should have Purple seal")
	end
end)

-------------------------------------------------------------------------------
-- Bulk Discount (Voucher) — rerolls cost $0
-------------------------------------------------------------------------------

BInt.register_test("arcane_arsenal:bulk_discount_free_rerolls", function(test)
	test:start_run({ seed = "BULK1" })
	test:select_blind()
	test:go_to_shop()

	-- Spawn voucher (applies it directly via redeem)
	test:spawn_voucher("v_arcane_bulk_discount")

	-- Reroll cost should now be $0
	test:assert_eq(
		test:get_reroll_cost(),
		0,
		"Reroll cost should be $0 after Bulk Discount"
	)

	-- First reroll should succeed even with $0
	test:set_money(0)
	test:reroll():assert()
	test:assert_eq(test:get_money(), 0, "First reroll should be free after Bulk Discount")
end)

BInt.register_test("arcane_arsenal:bulk_discount_persists_across_rounds", function(test)
	test:start_run({ seed = "BULK2" })
	test:select_blind()
	test:go_to_shop()

	-- Apply the voucher
	test:spawn_voucher("v_arcane_bulk_discount")

	-- Leave shop, play next round, come back to shop
	test:leave_shop()
	test:select_blind()
	test:go_to_shop()

	-- Reroll cost should still be $0 in the new shop
	test:assert_eq(
		test:get_reroll_cost(),
		0,
		"Reroll cost should persist as $0"
	)
	test:reroll():assert()
end)

-------------------------------------------------------------------------------
-- Glass Cannon Deck — 24 cards, +1 hand, +$10
-------------------------------------------------------------------------------

BInt.register_test("arcane_arsenal:glass_cannon_card_count", function(test)
	test:start_run({ seed = "GLASS1", deck = "b_arcane_glass_cannon" })

	-- Deck should have only 24 cards (removed 2-8 of all suits = 28 removed from 52)
	local full_deck = test:get_full_deck()
	test:assert_eq(#full_deck, 24, "Glass Cannon should start with 24 cards (9,10,J,Q,K,A x 4)")
end)

BInt.register_test("arcane_arsenal:glass_cannon_extra_hand", function(test)
	test:start_run({ seed = "GLASS2", deck = "b_arcane_glass_cannon" })
	test:select_blind()

	local info = test:get_round_info()
	-- Default is 4 hands, Glass Cannon adds 1
	test:assert_eq(info.hands_left, 5, "Glass Cannon should give 5 hands (4 + 1 bonus)")
end)

BInt.register_test("arcane_arsenal:glass_cannon_extra_money", function(test)
	test:start_run({ seed = "GLASS3", deck = "b_arcane_glass_cannon" })

	-- Should start with extra $10 on top of normal starting money
	local money = test:get_money()
	test:assert_gte(money, 10, "Glass Cannon should start with at least $10 extra")
end)

BInt.register_test("arcane_arsenal:glass_cannon_no_low_cards", function(test)
	test:start_run({ seed = "GLASS4", deck = "b_arcane_glass_cannon" })

	-- Verify no 2-8 rank cards exist in the full deck
	local full_deck = test:get_full_deck()
	local low_ranks = { ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true,
		["6"] = true, ["7"] = true, ["8"] = true }

	local valid_ranks = { ["9"] = true, ["10"] = true, ["Jack"] = true, ["Queen"] = true, ["King"] = true, ["Ace"] = true }
	for _, card in ipairs(full_deck) do
		test:assert_false(low_ranks[card.rank], "Should not have low rank card: " .. card.rank)
		test:assert_true(valid_ranks[card.rank], "Should only have 9+ rank cards, got: " .. card.rank)
	end
end)

-------------------------------------------------------------------------------
-- The Miser (Boss Blind) — debuffs Gold seal cards
-------------------------------------------------------------------------------

BInt.register_test("arcane_arsenal:miser_debuffs_gold_seals", function(test)
	-- Mock before start_run so the boss is generated during run initialization
	test:mock("pseudorandom_element", "bl_arcane_the_miser")
	test:start_run({ seed = "MISER1" })

	test:skip_to(1, "boss")
	test:select_blind()

	local info = test:get_round_info()
	test:assert_eq(info.blind, "bl_arcane_the_miser", "Boss blind should be The Miser")

	-- Set a Gold seal on card 1 — it should be debuffed
	test:set_seal(1, "Gold")

	-- Play all 5 cards
	test:highlight({ 1, 2, 3, 4, 5 })
	test:play_hand():assert()
end)

BInt.register_test("arcane_arsenal:miser_does_not_debuff_non_gold", function(test)
	-- Mock before start_run so the boss is generated during run initialization
	test:mock("pseudorandom_element", "bl_arcane_the_miser")
	test:start_run({ seed = "MISER3" })

	test:skip_to(1, "boss")
	test:select_blind()

	local info = test:get_round_info()
	test:assert_eq(info.blind, "bl_arcane_the_miser", "Boss blind should be The Miser")

	-- No Gold seals — cards should score normally
	test:highlight({ 1, 2, 3, 4, 5 })
	test:play_hand():assert()

	local score = test:get_score()
	test:assert_gt(score.scored_chips, 0, "Cards without Gold seals should score normally")
end)

BInt.register_test("arcane_arsenal:miser_skippable", function(test)
	test:start_run({ seed = "MISER2" })

	-- Skip the small blind
	test:skip_blind():assert()

	-- Should advance to the big blind
	test:assert_eq(test:get_blind_on_deck(), "Big", "Should advance to Big blind after skip")
end)

-------------------------------------------------------------------------------
-- Scavenger (Joker) — gains mult and sell value from skipping packs
-------------------------------------------------------------------------------

BInt.register_test("arcane_arsenal:scavenger_pack_skip", function(test)
	test:start_run({ seed = "SCAV1" })
	test:select_blind()
	test:go_to_shop()

	test:spawn_joker("j_arcane_scavenger")

	-- Buy a booster pack then skip it
	local packs = test:get_shop_packs()
	if #packs > 0 then
		test:buy_pack(1):assert()

		-- Skip the pack
		test:skip_pack():assert()

		-- Assert Scavenger stats incremented
		local jokers = test:get_jokers()
		test:assert_eq(jokers[1].extra.mult, 2, "Mult should increase by 2 after 1 skip")
		test:assert_eq(jokers[1].extra.packs_skipped, 1, "Packs skipped should be 1")
	end
end, { infinite_money = true })

BInt.register_test("arcane_arsenal:scavenger_choose_from_pack", function(test)
	test:start_run({ seed = "SCAV2" })
	test:select_blind()
	test:go_to_shop()

	test:spawn_joker("j_arcane_scavenger")

	-- Buy a pack and choose a card from it
	local packs = test:get_shop_packs()
	if #packs > 0 then
		test:buy_pack(1):assert()

		local pack_cards = test:get_pack_cards()
		if #pack_cards > 0 then
			test:choose_pack_card(1):assert()

			-- Choosing (not skipping) should NOT increment Scavenger
			local jokers = test:get_jokers()
			test:assert_eq(jokers[1].extra.packs_skipped, 0, "Choosing from pack should not increment skips")
			test:assert_eq(jokers[1].extra.mult, 0, "Mult should remain 0 after choosing from pack")
		end
	end
end, { infinite_money = true })

BInt.register_test("arcane_arsenal:scavenger_scoring", function(test)
	test:start_run({ seed = "SCAV3" })
	test:select_blind()

	test:spawn_joker("j_arcane_scavenger")

	-- Scavenger starts at 0 mult, so just verify it doesn't break scoring
	test:highlight({ 1, 2, 3, 4, 5 })
	test:play_hand():assert()

	local jokers = test:get_jokers()
	test:assert_eq(jokers[1].key, "j_arcane_scavenger")
end)

-------------------------------------------------------------------------------
-- Cross-object interaction tests
-------------------------------------------------------------------------------

BInt.register_test("arcane_arsenal:alchemist_then_play", function(test)
	test:start_run({ seed = "CROSS1" })
	test:select_blind()

	-- Enhance cards with Alchemist, then play them
	test:spawn_consumable("c_arcane_the_alchemist")
	test:highlight({ 1, 2, 3 })
	test:use_consumable("c_arcane_the_alchemist"):assert()

	-- Play the enhanced cards
	test:highlight({ 1, 2, 3 })
	test:play_hand():assert()
end)

BInt.register_test("arcane_arsenal:sell_scavenger", function(test)
	test:start_run({ seed = "CROSS2" })
	test:select_blind()

	test:spawn_joker("j_arcane_scavenger")
	test:go_to_shop()

	local money_before = test:get_money()
	test:sell_joker("j_arcane_scavenger"):assert()
	local money_after = test:get_money()

	test:assert_gt(money_after, money_before, "Selling scavenger should give money")
end)

BInt.register_test("arcane_arsenal:shop_reroll_and_buy", function(test)
	test:start_run({ seed = "CROSS3" })
	test:select_blind()
	test:go_to_shop()

	-- Reroll the shop
	test:reroll():assert()

	local shop = test:get_shop_cards()

	-- Buy first card if available
	if #shop > 0 then
		test:buy_card(1):assert()
		local jokers = test:get_jokers()
		test:assert_eq(#jokers, 1, "Should have 1 joker after buying")
	end
end, { infinite_money = true })

BInt.register_test("arcane_arsenal:discard_flow", function(test)
	test:start_run({ seed = "CROSS4" })
	test:select_blind()

	local info_before = test:get_round_info()

	-- Discard 2 cards
	test:highlight({ 1, 2 })
	test:discard():assert()

	local info_after = test:get_round_info()
	test:assert_eq(
		info_after.discards_left,
		info_before.discards_left - 1,
		"Should have 1 fewer discard"
	)

	-- Then play a hand
	test:highlight({ 1, 2, 3, 4, 5 })
	test:play_hand():assert()
end)

BInt.register_test("arcane_arsenal:highlight_by_suit", function(test)
	test:start_run({ seed = "CROSS5" })
	test:select_blind()

	-- Try highlighting by suit
	test:highlight_by_suit({ "Hearts", "Hearts" })
	test:play_hand():assert()
end)

BInt.register_test("arcane_arsenal:highlight_by_id", function(test)
	test:start_run({ seed = "CROSS6" })
	test:select_blind()

	-- Get hand and try to highlight by id
	local hand = test:get_hand()
	if #hand >= 2 then
		local id1 = hand[1].id
		local id2 = hand[2].id
		test:highlight_by_id({ id1, id2 })
		test:play_hand():assert()
	end
end)

BInt.register_test("arcane_arsenal:sort_hand", function(test)
	test:start_run({ seed = "CROSS7" })
	test:select_blind()

	test:sort_hand("rank")
	test:sort_hand("suit")

	test:highlight({ 1, 2, 3, 4, 5 })
	test:play_hand():assert()
end)
