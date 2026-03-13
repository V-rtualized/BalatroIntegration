function BInt._context_methods:add_money(amount)
	local target = G.GAME.dollars + amount
	ease_dollars(amount)
	BInt._wait.for_condition(function()
		return G.GAME.dollars == target
	end)
end

function BInt._context_methods:set_money(amount)
	local delta = amount - G.GAME.dollars
	if delta ~= 0 then
		ease_dollars(delta)
		BInt._wait.for_condition(function()
			return G.GAME.dollars == amount
		end)
	end
end

function BInt._context_methods:set_hands(n)
	G.GAME.current_round.hands_left = n
end

function BInt._context_methods:set_discards(n)
	G.GAME.current_round.discards_left = n
end

function BInt._context_methods:set_reroll_cost(n)
	G.GAME.current_round.reroll_cost = n
end

function BInt._context_methods:spawn_joker(key)
	local card = create_card("Joker", G.jokers, nil, nil, nil, nil, key)
	card:add_to_deck()
	G.jokers:emplace(card)
	BInt._wait.frames(5)
	return BInt.Ok({ card = { key = key } })
end

function BInt._context_methods:spawn_consumable(key)
	local center = G.P_CENTERS[key]
	local card_type = center and center.set or "Tarot"
	local card = create_card(card_type, G.consumeables, nil, nil, nil, nil, key)
	card:add_to_deck()
	G.consumeables:emplace(card)
	BInt._wait.frames(5)
	return BInt.Ok({ card = { key = key } })
end

function BInt._context_methods:spawn_voucher(key)
	local card = create_card("Voucher", G.play, nil, nil, nil, nil, key)
	card:apply_to_run()
	card:start_dissolve()
	G.GAME.used_vouchers[key] = true
	BInt._wait.frames(5)
	return BInt.Ok({ card = { key = key } })
end

function BInt._context_methods:add_playing_card(id)
	local parsed = BInt._resolve.parse_card_id(id)
	if not parsed then
		return BInt.Fail("invalid_card_id", { id = id })
	end

	local front = nil
	for k, v in pairs(G.P_CARDS) do
		if v.value == parsed.rank and v.suit == parsed.suit then
			front = v
			break
		end
	end
	if not front then
		return BInt.Fail("invalid_card_id", { id = id })
	end

	local card = Card(G.deck.T.x, G.deck.T.y, G.CARD_W, G.CARD_H, front, G.P_CENTERS.c_base)
	card:add_to_deck()
	G.deck:emplace(card)
	G.playing_card = (G.playing_card or 0) + 1
	card.playing_card = G.playing_card
	table.insert(G.playing_cards, card)
	return BInt.Ok()
end

function BInt._context_methods:remove_playing_card(id)
	local parsed = BInt._resolve.parse_card_id(id)
	if not parsed then
		return BInt.Fail("invalid_card_id", { id = id })
	end
	for i, card in ipairs(G.playing_cards) do
		if card.base.value == parsed.rank and card.base.suit == parsed.suit then
			if card.area then
				card.area:remove_card(card)
			end
			card:remove()
			table.remove(G.playing_cards, i)
			return BInt.Ok()
		end
	end
	return BInt.Fail("card_not_found", { id = id })
end

function BInt._context_methods:set_joker_edition(id_or_index, edition)
	local card, err = BInt._resolve.joker(id_or_index)
	if not card then
		return BInt.Fail("joker_not_found", { reason = err })
	end
	card:set_edition({ [edition] = true }, true, true)
	return BInt.Ok()
end

function BInt._context_methods:set_enhancement(id_or_index, enhancement)
	local card, err = BInt._resolve.hand_card(id_or_index)
	if not card then
		return BInt.Fail("card_not_found", { reason = err })
	end
	card:set_ability(G.P_CENTERS[enhancement])
	return BInt.Ok()
end

function BInt._context_methods:set_seal(id_or_index, seal)
	local card, err = BInt._resolve.hand_card(id_or_index)
	if not card then
		return BInt.Fail("card_not_found", { reason = err })
	end
	card:set_seal(seal, true, true)
	return BInt.Ok()
end

function BInt._context_methods:unlock_all()
	for k, v in pairs(G.P_CENTERS) do
		v.unlocked = true
		v.discovered = true
		v.alerted = true
	end
	for k, v in pairs(G.P_BLINDS) do
		v.discovered = true
	end
	for k, v in pairs(G.P_TAGS) do
		v.discovered = true
	end
	for k, v in pairs(G.P_SEALS) do
		v.discovered = true
	end
end
