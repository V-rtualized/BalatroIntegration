function BInt._context_methods:start_run(opts)
	opts = opts or {}

	if opts.deck then
		G.GAME.viewed_back = G.P_CENTERS[opts.deck]
	end

	local args = {
		stake = opts.stake,
		seed = opts.seed,
	}

	G.E_MANAGER:clear_queue()
	G:delete_run()
	G:start_run(args)

	BInt._wait.for_condition(function()
		return G.STATE == G.STATES.BLIND_SELECT and G.blind_select ~= nil
	end)

	BInt._wait.stable_drain()
end

function BInt._context_methods:select_blind()
	if not G.blind_select then
		return BInt.Fail("not_on_blind_select", { reason = "G.blind_select does not exist" })
	end

	local blind_key = G.GAME.round_resets.blind_choices[G.GAME.blind_on_deck]
	local blind_obj = G.P_BLINDS[blind_key]

	if not blind_obj then
		return BInt.Fail("blind_not_found", {
			blind_key = tostring(blind_key),
			blind_on_deck = tostring(G.GAME.blind_on_deck),
		})
	end

	local mock_e = {
		config = { ref_table = blind_obj },
		UIBox = {
			get_UIE_by_ID = function(self, id)
				return nil
			end,
		},
	}

	local ok, err = pcall(G.FUNCS.select_blind, mock_e)
	if not ok then
		return BInt.Fail("select_blind_error", { error = tostring(err) })
	end

	BInt._wait.for_condition(function()
		return G.STATE == G.STATES.SELECTING_HAND and G.hand and #G.hand.cards > 0
	end)
	return BInt.Ok()
end

function BInt._context_methods:skip_blind()
	if not G.blind_select then
		return BInt.Fail("not_on_blind_select")
	end

	local blind_before = G.GAME.blind_on_deck

	local tag_key = G.GAME.round_resets.blind_tags and G.GAME.round_resets.blind_tags[G.GAME.blind_on_deck]
	local tag_obj = nil
	if tag_key then
		for _, t in ipairs(G.GAME.tags) do
			if t.key == tag_key then
				tag_obj = t
				break
			end
		end
	end
	if not tag_obj then
		tag_obj = Tag(get_next_tag_key())
	end

	local mock_e = {
		UIBox = {
			get_UIE_by_ID = function(self, id)
				if id == "tag_container" then
					return { config = { ref_table = tag_obj } }
				end
				return nil
			end,
		},
	}

	G.FUNCS.skip_blind(mock_e)
	BInt._wait.for_condition(function()
		return G.GAME.blind_on_deck ~= blind_before
	end)
	BInt._wait.for_condition(function()
		return G.STATE == G.STATES.BLIND_SELECT and G.blind_select ~= nil
	end)
	return BInt.Ok()
end

function BInt._context_methods:play_hand()
	if not G.hand or not G.hand.highlighted or #G.hand.highlighted == 0 then
		return BInt.Fail("no_cards_highlighted")
	end
	if G.play and G.play.cards and G.play.cards[1] then
		return BInt.Fail("cards_already_in_play")
	end

	local hands_before = G.GAME.current_round.hands_played or 0
	G.FUNCS.play_cards_from_highlighted()

	BInt._wait.for_condition(function()
		return (G.GAME.current_round.hands_played or 0) > hands_before
	end)
	BInt._wait.for_any_state({
		G.STATES.SELECTING_HAND,
		G.STATES.ROUND_EVAL,
		G.STATES.GAME_OVER,
	})
	return BInt.Ok()
end

function BInt._context_methods:beat_blind()
	if G.STATE ~= G.STATES.SELECTING_HAND then
		return BInt.Fail("not_selecting_hand", { state = tostring(G.STATE) })
	end

	self:set_hands(1)

	self:highlight({ 1, 2, 3, 4, 5 })
	return self:play_hand()
end

function BInt._context_methods:discard()
	if not G.hand or not G.hand.highlighted or #G.hand.highlighted == 0 then
		return BInt.Fail("no_cards_highlighted")
	end

	local discards_before = G.GAME.current_round.discards_used or 0
	G.FUNCS.discard_cards_from_highlighted()
	BInt._wait.for_condition(function()
		return (G.GAME.current_round.discards_used or 0) > discards_before
	end)
	BInt._wait.for_condition(function()
		return G.STATE == G.STATES.SELECTING_HAND
	end)
	return BInt.Ok()
end

function BInt._context_methods:cash_out()
	BInt._wait.for_condition(function()
		return G.round_eval ~= nil
	end, nil, "Timeout waiting for round_eval UI")

	local mock_e = { config = {} }
	G.FUNCS.cash_out(mock_e)
	BInt._wait.for_state(G.STATES.SHOP)
	return BInt.Ok()
end

function BInt._context_methods:go_to_shop()
	if G.STATE == G.STATES.SHOP then
		return BInt.Ok()
	end

	if G.blind_select then
		G.blind_select:remove()
		G.blind_select = nil
	end
	if G.blind_prompt_box then
		G.blind_prompt_box:remove()
		G.blind_prompt_box = nil
	end
	if G.round_eval then
		G.round_eval:remove()
		G.round_eval = nil
	end

	if G.hand then
		G.hand:unhighlight_all()
		for i = #G.hand.cards, 1, -1 do
			draw_card(G.hand, G.deck, i * 100 / #G.hand.cards, "up", true)
		end
	end
	if G.play and G.play.cards then
		for i = #G.play.cards, 1, -1 do
			draw_card(G.play, G.deck, i * 100 / #G.play.cards, "up", true)
		end
	end

	G.GAME.round_resets.blind_states[G.GAME.blind_on_deck] = "Defeated"

	G.GAME.current_round.jokers_purchased = 0
	G.GAME.current_round.discards_left = math.max(0, G.GAME.round_resets.discards + G.GAME.round_bonus.discards)
	G.GAME.current_round.hands_left = math.max(1, G.GAME.round_resets.hands + G.GAME.round_bonus.next_hands)

	if G.GAME.round_resets.blind_states.Boss == "Defeated" then
		G.GAME.round_resets.blind_ante = G.GAME.round_resets.ante
		G.GAME.round_resets.blind_tags.Small = get_next_tag_key()
		G.GAME.round_resets.blind_tags.Big = get_next_tag_key()
	end
	reset_blinds()

	G.E_MANAGER:clear_queue()

	G.STATE = G.STATES.SHOP
	G.STATE_COMPLETE = false

	BInt._wait.for_condition(function()
		return G.shop ~= nil
	end, nil, "Timeout waiting for shop UI")
	BInt._wait.stable_drain()
	return BInt.Ok()
end

function BInt._context_methods:leave_shop()
	G.E_MANAGER:clear_queue()

	local mock_e = {}
	G.FUNCS.toggle_shop(mock_e)
	BInt._wait.for_condition(function()
		return G.STATE == G.STATES.BLIND_SELECT and G.blind_select ~= nil
	end)
	return BInt.Ok()
end

function BInt._context_methods:buy_card(id_or_index)
	local card, err = BInt._resolve.shop_card(id_or_index)
	if not card then
		return BInt.Fail("not_in_shop", { key = tostring(id_or_index), reason = err })
	end

	if self._params.infinite_money and G.GAME.dollars < card.cost then
		ease_dollars(card.cost - G.GAME.dollars + 1)
		BInt._wait.stable_drain()
	end

	local mock_e = { config = { ref_table = card } }

	if not G.FUNCS.check_for_buy_space(card) then
		return BInt.Fail("no_space", { key = card.config.center.key })
	end

	G.FUNCS.buy_from_shop(mock_e)
	BInt._wait.stable_drain()
	return BInt.Ok({ card = { key = card.config.center.key, cost = card.cost } })
end

function BInt._context_methods:buy_voucher(id_or_index)
	local card, err = BInt._resolve.shop_voucher(id_or_index)
	if not card then
		return BInt.Fail("not_in_shop", { key = tostring(id_or_index), reason = err })
	end

	if self._params.infinite_money and G.GAME.dollars < card.cost then
		ease_dollars(card.cost - G.GAME.dollars + 1)
		BInt._wait.stable_drain()
	end

	local mock_e = { config = { ref_table = card } }
	G.FUNCS.buy_from_shop(mock_e)
	BInt._wait.stable_drain()
	return BInt.Ok({ card = { key = card.config.center.key, cost = card.cost } })
end

function BInt._context_methods:buy_pack(id_or_index)
	local card, err = BInt._resolve.shop_pack(id_or_index)
	if not card then
		return BInt.Fail("not_in_shop", { key = tostring(id_or_index), reason = err })
	end

	if self._params.infinite_money and G.GAME.dollars < card.cost then
		ease_dollars(card.cost - G.GAME.dollars + 1)
		BInt._wait.stable_drain()
	end

	local mock_e = { config = { ref_table = card, id = "buy_and_use" } }
	G.FUNCS.buy_from_shop(mock_e)

	BInt._wait.for_any_state({
		G.STATES.TAROT_PACK,
		G.STATES.PLANET_PACK,
		G.STATES.SPECTRAL_PACK,
		G.STATES.STANDARD_PACK,
		G.STATES.BUFFOON_PACK,
		G.STATES.SMODS_BOOSTER_OPENED,
	})
	BInt._wait.for_condition(function()
		return G.pack_cards and G.pack_cards.cards and #G.pack_cards.cards > 0
	end, nil, "Timeout waiting for pack cards")
	return BInt.Ok({ card = { key = card.config.center.key, cost = card.cost } })
end

function BInt._context_methods:sell_joker(id_or_index)
	local card, err = BInt._resolve.joker(id_or_index)
	if not card then
		return BInt.Fail("joker_not_found", { key = tostring(id_or_index), reason = err })
	end
	local mock_e = { config = { ref_table = card } }
	G.FUNCS.sell_card(mock_e)
	BInt._wait.stable_drain()
	return BInt.Ok({ card = { key = card.config.center.key } })
end

function BInt._context_methods:sell_consumable(id_or_index)
	local card, err = BInt._resolve.consumable(id_or_index)
	if not card then
		return BInt.Fail("consumable_not_found", { key = tostring(id_or_index), reason = err })
	end
	local mock_e = { config = { ref_table = card } }
	G.FUNCS.sell_card(mock_e)
	BInt._wait.stable_drain()
	return BInt.Ok({ card = { key = card.config.center.key } })
end

function BInt._context_methods:reroll()
	if G.GAME.dollars < G.GAME.current_round.reroll_cost and G.GAME.current_round.free_rerolls <= 0 then
		if self._params.infinite_money then
			ease_dollars(G.GAME.current_round.reroll_cost - G.GAME.dollars + 1)
			BInt._wait.stable_drain()
		else
			return BInt.Fail("not_enough_money", {
				cost = G.GAME.current_round.reroll_cost,
				dollars = G.GAME.dollars,
			})
		end
	end

	local mock_e = {}
	G.FUNCS.reroll_shop(mock_e)
	BInt._wait.stable_drain()
	return BInt.Ok()
end

function BInt._context_methods:use_consumable(id_or_index)
	local card, err = BInt._resolve.consumable(id_or_index)
	if not card then
		return BInt.Fail("consumable_not_found", { key = tostring(id_or_index), reason = err })
	end
	local mock_e = { config = { ref_table = card, button = "use_card" } }
	G.FUNCS.use_card(mock_e)
	BInt._wait.stable_drain()
	return BInt.Ok({ card = { key = card.config.center.key } })
end

function BInt._context_methods:highlight(indices)
	if not G.hand then
		return BInt.Fail("no_hand")
	end
	while G.hand.highlighted[1] do
		G.hand:remove_from_highlighted(G.hand.highlighted[1])
	end
	for _, i in ipairs(indices) do
		local card = G.hand.cards[i]
		if card then
			G.hand:add_to_highlighted(card, true)
		end
	end
	return BInt.Ok()
end

function BInt._context_methods:highlight_by_rank(ranks)
	if not G.hand then
		return BInt.Fail("no_hand")
	end
	while G.hand.highlighted[1] do
		G.hand:remove_from_highlighted(G.hand.highlighted[1])
	end
	local used = {}
	for _, rank in ipairs(ranks) do
		local full_rank = BInt._resolve.RANK_MAP[rank] or rank
		for i, card in ipairs(G.hand.cards) do
			if card.base.value == full_rank and not used[i] then
				G.hand:add_to_highlighted(card, true)
				used[i] = true
				break
			end
		end
	end
	return BInt.Ok()
end

function BInt._context_methods:highlight_by_suit(suits)
	if not G.hand then
		return BInt.Fail("no_hand")
	end
	while G.hand.highlighted[1] do
		G.hand:remove_from_highlighted(G.hand.highlighted[1])
	end
	local used = {}
	for _, suit in ipairs(suits) do
		for i, card in ipairs(G.hand.cards) do
			if card.base.suit == suit and not used[i] then
				G.hand:add_to_highlighted(card, true)
				used[i] = true
				break
			end
		end
	end
	return BInt.Ok()
end

function BInt._context_methods:highlight_by_id(ids)
	if not G.hand then
		return BInt.Fail("no_hand")
	end
	while G.hand.highlighted[1] do
		G.hand:remove_from_highlighted(G.hand.highlighted[1])
	end
	local used = {}
	for _, id in ipairs(ids) do
		local parsed = BInt._resolve.parse_card_id(id)
		if parsed then
			for i, card in ipairs(G.hand.cards) do
				if card.base.value == parsed.rank and card.base.suit == parsed.suit and not used[i] then
					G.hand:add_to_highlighted(card, true)
					used[i] = true
					break
				end
			end
		end
	end
	return BInt.Ok()
end

function BInt._context_methods:unhighlight_all()
	if not G.hand then
		return BInt.Ok()
	end
	while G.hand.highlighted[1] do
		G.hand:remove_from_highlighted(G.hand.highlighted[1])
	end
	return BInt.Ok()
end

function BInt._context_methods:sort_hand(method)
	if not G.hand then
		return BInt.Fail("no_hand")
	end
	G.hand:sort(method)
	return BInt.Ok()
end

function BInt._context_methods:choose_pack_card(id_or_index)
	local card, err = BInt._resolve.pack_card(id_or_index)
	if not card then
		return BInt.Fail("not_in_pack", { key = tostring(id_or_index), reason = err })
	end
	local mock_e = { config = { ref_table = card, button = "use_card" } }
	G.FUNCS.use_card(mock_e)
	BInt._wait.stable_drain()
	return BInt.Ok({ card = { key = card.config.center.key } })
end

function BInt._context_methods:skip_pack()
	local mock_e = {}
	G.FUNCS.skip_booster(mock_e)
	BInt._wait.for_state(G.STATES.SHOP)
	return BInt.Ok()
end

function BInt._context_methods:restart_run()
	G.E_MANAGER:clear_queue()
	G:delete_run()
	G:start_run({})
	BInt._wait.for_condition(function()
		return G.STATE == G.STATES.BLIND_SELECT and G.blind_select ~= nil
	end)
	return BInt.Ok()
end

function BInt._context_methods:skip_to(ante, blind)
	blind = blind or "small"

	if not G.GAME then
		return BInt.Fail("no_run", { reason = "skip_to called outside of a run" })
	end

	G.GAME.round_resets.ante = ante

	if blind == "small" then
		G.GAME.round_resets.blind_states = { Small = "Select", Big = "Upcoming", Boss = "Upcoming" }
		G.GAME.blind_on_deck = "Small"
	elseif blind == "big" then
		G.GAME.round_resets.blind_states = { Small = "Defeated", Big = "Select", Boss = "Upcoming" }
		G.GAME.blind_on_deck = "Big"
	elseif blind == "boss" then
		G.GAME.round_resets.blind_states = { Small = "Defeated", Big = "Defeated", Boss = "Select" }
		G.GAME.blind_on_deck = "Boss"
	else
		return BInt.Fail("invalid_blind", { blind = blind })
	end

	G.GAME.round_resets.blind_tags = G.GAME.round_resets.blind_tags or {}
	G.GAME.round_resets.blind_tags.Small = get_next_tag_key()
	G.GAME.round_resets.blind_tags.Big = get_next_tag_key()

	G.GAME.round_resets.boss_rerolled = false

	G.STATE = G.STATES.BLIND_SELECT
	G.STATE_COMPLETE = false

	BInt._wait.for_condition(function()
		return G.STATE == G.STATES.BLIND_SELECT and G.blind_select ~= nil
	end)
	return BInt.Ok()
end
