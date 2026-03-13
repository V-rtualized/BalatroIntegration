--- The Alchemist (Tarot)
--- Select 1-3 cards in hand, converts them to Gold enhancement.
SMODS.Consumable({
	key = "the_alchemist",
	set = "Tarot",
	loc_txt = {
		name = "The Alchemist",
		text = {
			"Enhances up to",
			"{C:attention}#1#{} selected cards",
			"to {C:attention}Gold Cards{}",
		},
	},
	config = { extra = { max_cards = 3 } },
	cost = 4,

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.max_cards } }
	end,

	can_use = function(self, card)
		return G.hand and G.hand.highlighted and #G.hand.highlighted > 0
			and #G.hand.highlighted <= card.ability.extra.max_cards
	end,

	use = function(self, card, area, copier)
		for _, highlighted in ipairs(G.hand.highlighted) do
			highlighted:set_ability(G.P_CENTERS.m_gold)
			G.E_MANAGER:add_event(Event({
				func = function()
					highlighted:juice_up(0.3, 0.5)
					return true
				end,
			}))
		end
	end,
})

--- Nexus (Spectral)
--- Adds a Purple seal to all cards currently in hand.
SMODS.Consumable({
	key = "nexus",
	set = "Spectral",
	loc_txt = {
		name = "Nexus",
		text = {
			"Add a {C:purple}Purple Seal{}",
			"to all cards in hand",
		},
	},
	cost = 4,

	can_use = function(self, card)
		return G.hand and #G.hand.cards > 0
	end,

	use = function(self, card, area, copier)
		for _, hand_card in ipairs(G.hand.cards) do
			hand_card:set_seal("Purple", true, true)
			G.E_MANAGER:add_event(Event({
				func = function()
					hand_card:juice_up(0.3, 0.5)
					return true
				end,
			}))
		end
	end,
})

--- Bulk Discount (Voucher)
--- Rerolls cost $0 for the rest of the run.
SMODS.Voucher({
	key = "bulk_discount",
	loc_txt = {
		name = "Bulk Discount",
		text = {
			"Rerolls cost",
			"{C:money}$0{}",
		},
	},
	cost = 10,

	redeem = function(self, card)
		G.GAME.round_resets.reroll_cost = 0
		G.GAME.current_round.reroll_cost = 0
	end,
})

--- Glass Cannon Deck
--- Starts with only 20 cards (removes 2s through 8s), +$10, and 1 extra hand.
SMODS.Back({
	key = "glass_cannon",
	loc_txt = {
		name = "Glass Cannon Deck",
		text = {
			"Start with only {C:attention}24{} cards",
			"{C:blue}+1{} hand per round",
			"Start with {C:money}$10{} extra",
		},
	},
	config = {
		hands = 1,
		dollars = 10,
	},

	apply = function(self, back)
		-- Remove 2s through 8s via event (required for deck modification)
		G.E_MANAGER:add_event(Event({
			func = function()
				local dominated = {}
				for i = #G.playing_cards, 1, -1 do
					local card = G.playing_cards[i]
					local id = card:get_id()
					if id >= 2 and id <= 8 then
						table.insert(dominated, i)
					end
				end
				for _, i in ipairs(dominated) do
					local card = G.playing_cards[i]
					if card.area then
						card.area:remove_card(card)
					end
					card:remove()
					table.remove(G.playing_cards, i)
				end
				return true
			end,
		}))
	end,
})

--- The Miser (Boss Blind)
--- All cards with a Gold seal are debuffed.
SMODS.Blind({
	key = "the_miser",
	loc_txt = {
		name = "The Miser",
		text = {
			"All cards with a",
			"{C:attention}Gold Seal{} are debuffed",
		},
	},
	dollars = 5,
	mult = 2,
	boss = { min = 1, max = 10 },
	boss_colour = HEX("D4AF37"),

	recalc_debuff = function(self, card, from_blind)
		if card.seal == "Gold" then
			return true
		end
		return false
	end,
})

--- Scavenger (Joker)
--- Gains +$1 sell value each time you skip a booster pack.
--- Also gains +2 Mult per pack skipped.
SMODS.Joker({
	key = "scavenger",
	loc_txt = {
		name = "Scavenger",
		text = {
			"{C:mult}+#1#{} Mult",
			"{C:inactive}(+#2# per skipped pack)",
			"Gains {C:money}+$#3#{} sell value",
			"per skipped pack",
		},
	},
	config = { extra = { mult = 0, mult_per = 2, sell_bonus = 1, packs_skipped = 0 } },
	rarity = 2,
	cost = 5,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				card.ability.extra.mult,
				card.ability.extra.mult_per,
				card.ability.extra.sell_bonus,
			},
		}
	end,

	calculate = function(self, card, context)
		if context.joker_main and card.ability.extra.mult > 0 then
			return {
				mult_mod = card.ability.extra.mult,
				message = localize({
					type = "variable",
					key = "a_mult",
					vars = { card.ability.extra.mult },
				}),
			}
		end

		if context.skipping_booster and not context.blueprint then
			card.ability.extra.packs_skipped = card.ability.extra.packs_skipped + 1
			card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_per
			card.sell_cost = card.sell_cost + card.ability.extra.sell_bonus
			return {
				message = localize("k_upgrade_ex"),
				colour = G.C.MULT,
			}
		end
	end,
})

-- Load tests if Integration is available
if next(SMODS.find_mod("Integration")) then
	assert(SMODS.load_file("tests.lua"))()
end
