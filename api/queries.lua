function BInt._context_methods:get_money()
	return G.GAME.dollars
end

function BInt._context_methods:get_hand()
	local cards = {}
	if G.hand then
		for _, card in ipairs(G.hand.cards) do
			local center_key = card.config.center.key
			table.insert(cards, {
				rank = card.base.value,
				suit = card.base.suit,
				id = BInt._resolve.card_to_id(card),
				enhancement = center_key ~= "c_base" and center_key or nil,
				seal = card.seal or nil,
			})
		end
	end
	return cards
end

function BInt._context_methods:get_jokers()
	local jokers = {}
	if G.jokers then
		for _, card in ipairs(G.jokers.cards) do
			table.insert(jokers, {
				key = card.config.center.key,
				edition = card.edition,
				eternal = card.ability.eternal or false,
				perishable = card.ability.perishable or false,
				rental = card.ability.rental or false,
				extra = card.ability.extra,
			})
		end
	end
	return jokers
end

function BInt._context_methods:get_consumables()
	local consumables = {}
	if G.consumeables then
		for _, card in ipairs(G.consumeables.cards) do
			table.insert(consumables, {
				key = card.config.center.key,
				type = card.config.center.set,
			})
		end
	end
	return consumables
end

function BInt._context_methods:get_shop_cards()
	local cards = {}
	if G.shop_jokers then
		for _, card in ipairs(G.shop_jokers.cards) do
			table.insert(cards, {
				key = card.config.center.key,
				cost = card.cost,
				type = card.ability.set,
			})
		end
	end
	return cards
end

function BInt._context_methods:get_shop_vouchers()
	local vouchers = {}
	if G.shop_vouchers then
		for _, card in ipairs(G.shop_vouchers.cards) do
			table.insert(vouchers, {
				key = card.config.center.key,
				cost = card.cost,
			})
		end
	end
	return vouchers
end

function BInt._context_methods:get_shop_packs()
	local packs = {}
	if G.shop_booster then
		for _, card in ipairs(G.shop_booster.cards) do
			table.insert(packs, {
				key = card.config.center.key,
				cost = card.cost,
			})
		end
	end
	return packs
end

function BInt._context_methods:get_round_info()
	return {
		ante = G.GAME.round_resets.ante,
		blind = G.GAME.blind and G.GAME.blind.name or nil,
		hands_left = G.GAME.current_round.hands_left,
		discards_left = G.GAME.current_round.discards_left,
		blind_chips = G.GAME.blind and G.GAME.blind.chips or 0,
		scored_chips = G.GAME.chips or 0,
	}
end

function BInt._context_methods:get_score()
	return {
		scored_chips = G.GAME.chips or 0,
		blind_chips = G.GAME.blind and G.GAME.blind.chips or 0,
		hands_left = G.GAME.current_round.hands_left,
		discards_left = G.GAME.current_round.discards_left,
	}
end

function BInt._context_methods:get_last_hand()
	return {
		hand_type = G.GAME.last_hand_played or "Unknown",
	}
end

function BInt._context_methods:get_deck()
	local cards = {}
	if G.deck then
		for _, card in ipairs(G.deck.cards) do
			table.insert(cards, {
				rank = card.base.value,
				suit = card.base.suit,
				id = BInt._resolve.card_to_id(card),
			})
		end
	end
	return cards
end

function BInt._context_methods:get_full_deck()
	local cards = {}
	local areas = {
		{ area = G.deck, name = "deck" },
		{ area = G.hand, name = "hand" },
		{ area = G.play, name = "play" },
		{ area = G.discard, name = "discard" },
	}
	for _, a in ipairs(areas) do
		if a.area then
			for _, card in ipairs(a.area.cards) do
				local center_key = card.config.center.key
				table.insert(cards, {
					rank = card.base.value,
					suit = card.base.suit,
					id = BInt._resolve.card_to_id(card),
					area = a.name,
					enhancement = center_key ~= "c_base" and center_key or nil,
					seal = card.seal or nil,
				})
			end
		end
	end
	return cards
end

function BInt._context_methods:get_pack_cards()
	local cards = {}
	if G.pack_cards then
		for _, card in ipairs(G.pack_cards.cards) do
			if card.ability.set == "Default" or card.ability.set == "Enhanced" then
				table.insert(cards, {
					rank = card.base.value,
					suit = card.base.suit,
					id = BInt._resolve.card_to_id(card),
					type = card.ability.set,
				})
			else
				table.insert(cards, {
					key = card.config.center.key,
					type = card.config.center.set,
				})
			end
		end
	end
	return cards
end

function BInt._context_methods:get_reroll_cost()
	return G.GAME.current_round.reroll_cost
end

function BInt._context_methods:get_highlighted()
	local cards = {}
	if G.hand then
		for _, card in ipairs(G.hand.highlighted) do
			local center_key = card.config.center.key
			table.insert(cards, {
				rank = card.base.value,
				suit = card.base.suit,
				id = BInt._resolve.card_to_id(card),
				enhancement = center_key ~= "c_base" and center_key or nil,
				seal = card.seal or nil,
			})
		end
	end
	return cards
end

function BInt._context_methods:get_blind_on_deck()
	return G.GAME.blind_on_deck
end

function BInt._context_methods:get_owned_vouchers()
	local vouchers = {}
	if G.GAME.used_vouchers then
		for key, _ in pairs(G.GAME.used_vouchers) do
			table.insert(vouchers, key)
		end
		table.sort(vouchers)
	end
	return vouchers
end

function BInt._context_methods:get_state()
	return G.STATE
end

function BInt._context_methods:get_state_name()
	for k, v in pairs(G.STATES) do
		if v == G.STATE then
			return k
		end
	end
	return tostring(G.STATE)
end
