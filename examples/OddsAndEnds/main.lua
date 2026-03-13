local rank_names = {
	[2] = "2",
	[3] = "3",
	[4] = "4",
	[5] = "5",
	[6] = "6",
	[7] = "7",
	[8] = "8",
	[9] = "9",
	[10] = "10",
	[11] = "Jack",
	[12] = "Queen",
	[13] = "King",
	[14] = "Ace",
}

--- Loaded Dice
--- Roll a d6 each hand played. Gain roll × 4 Mult.
SMODS.Joker({
	key = "loaded_dice",
	loc_txt = {
		name = "Loaded Dice",
		text = {
			"Roll a {C:attention}d6{} each hand,",
			"gain roll {C:mult}X#1#{} Mult",
			"{C:inactive}(Last roll: {C:attention}#2#{C:inactive})",
		},
	},
	config = { extra = { mult_per = 2, last_roll = 0 } },
	rarity = 1,
	cost = 4,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.mult_per, card.ability.extra.last_roll } }
	end,

	calculate = function(self, card, context)
		if context.joker_main then
			local roll = pseudorandom("loaded_dice", 1, 6)
			card.ability.extra.last_roll = roll
			return {
				mult_mod = roll * card.ability.extra.mult_per,
				message = localize({ type = "variable", key = "a_mult", vars = { roll * card.ability.extra.mult_per } }),
			}
		end
	end,
})

--- Royal Favor
--- Chooses a random rank when a blind is selected.
--- +3 Mult for each scored card matching that rank.
SMODS.Joker({
	key = "royal_favor",
	loc_txt = {
		name = "Royal Favor",
		text = {
			"{C:mult}+#1#{} Mult for each",
			"scored {C:attention}#2#{} card",
			"{C:inactive}(Changes each round)",
		},
	},
	config = { extra = { mult_per = 3, chosen_id = 14, chosen_name = "Ace" } },
	rarity = 1,
	cost = 5,
	blueprint_compat = true,
	eternal_compat = true,
	perishable_compat = true,

	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.mult_per, card.ability.extra.chosen_name } }
	end,

	calculate = function(self, card, context)
		if context.setting_blind and not context.blueprint then
			local chosen_id = pseudorandom("royal_favor", 2, 14)
			card.ability.extra.chosen_id = chosen_id
			card.ability.extra.chosen_name = rank_names[chosen_id]
			return {
				message = card.ability.extra.chosen_name .. "!",
			}
		end

		if context.individual and context.cardarea == G.play then
			if context.other_card:get_id() == card.ability.extra.chosen_id then
				return {
					mult = card.ability.extra.mult_per,
					card = card,
				}
			end
		end
	end,
})

--- Double or Nothing
--- End of round, 50/50: gain $8 or lose $4.
--- Tracks net winnings on the card.
SMODS.Joker({
	key = "double_or_nothing",
	loc_txt = {
		name = "Double or Nothing",
		text = {
			"End of round:",
			"{C:green}#1# in 2{} chance to gain {C:money}$#2#{}",
			"otherwise lose {C:money}$#3#{}",
			"{C:inactive}(Net: {C:money}$#4#{C:inactive})",
		},
	},
	config = { extra = { prob = 2, gain = 8, loss = 4, net = 0 } },
	rarity = 2,
	cost = 6,
	blueprint_compat = false,
	eternal_compat = true,
	perishable_compat = true,

	loc_vars = function(self, info_queue, card)
		return {
			vars = {
				G.GAME and G.GAME.probabilities.normal or 1,
				card.ability.extra.gain,
				card.ability.extra.loss,
				card.ability.extra.net,
			},
		}
	end,

	calculate = function(self, card, context)
		if context.end_of_round and context.main_eval then
			if pseudorandom("double_or_nothing") < G.GAME.probabilities.normal / card.ability.extra.prob then
				card.ability.extra.net = card.ability.extra.net + card.ability.extra.gain
				ease_dollars(card.ability.extra.gain)
				return {
					message = localize("$") .. card.ability.extra.gain,
					colour = G.C.MONEY,
				}
			else
				card.ability.extra.net = card.ability.extra.net - card.ability.extra.loss
				ease_dollars(-card.ability.extra.loss)
				return {
					message = "-" .. localize("$") .. card.ability.extra.loss,
					colour = G.C.RED,
				}
			end
		end
	end,
})

-- Load tests if Integration is available
if next(SMODS.find_mod("Integration")) then
	assert(SMODS.load_file("tests.lua"))()
end
