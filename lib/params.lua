BInt._params = {}
BInt._params._saved = {}

BInt._params._originals = {}

local function capture_originals()
	if BInt._params._originals._captured then
		return
	end
	BInt._params._originals._captured = true
	BInt._params._originals.delay = delay
	BInt._params._originals.attention_text = attention_text
	BInt._params._originals.card_eval_status_text = card_eval_status_text
	BInt._params._originals.juice_card = juice_card
	BInt._params._originals.draw_card = draw_card
	BInt._params._originals.ease_discard = ease_discard
	BInt._params._originals.ease_hands_played = ease_hands_played
	BInt._params._originals.level_up_hand = level_up_hand
	BInt._params._originals.update_hand_text = update_hand_text
	BInt._params._originals.play_sound = play_sound
	BInt._params._originals.juice_up = Moveable.juice_up
	BInt._params._originals.add_event = EventManager.add_event
end

local function install_speed(multiplier)
	BInt._params._speed_multiplier = multiplier
	BInt._params._queue_retriggers = math.max(0, math.floor(multiplier / 64) - 1)
end

local function uninstall_speed()
	BInt._params._speed_multiplier = nil
	BInt._params._queue_retriggers = nil
end

local function install_anim_skip()
	local orig = BInt._params._originals

	delay = function() end

	attention_text = function(...)
		if G.STATE == G.STATES.HAND_PLAYED then
			return
		end
		return orig.attention_text(...)
	end

	card_eval_status_text = function(...)
		local args = { ... }
		local extra = args[6] or {}
		if extra and extra.playing_cards_created then
			playing_card_joker_effects(extra.playing_cards_created)
		end
		return
	end

	juice_card = function() end
	Moveable.juice_up = function() end

	draw_card = function(...)
		BInt._params._force_non_blocking = true
		orig.draw_card(...)
		BInt._params._force_non_blocking = false
	end

	ease_discard = function(...)
		local args = { ... }
		args[2] = true
		return orig.ease_discard(unpack(args))
	end

	ease_hands_played = function(...)
		local args = { ... }
		args[2] = true
		return orig.ease_hands_played(unpack(args))
	end

	level_up_hand = function(...)
		local args = { ... }
		args[3] = true
		return orig.level_up_hand(unpack(args))
	end

	update_hand_text = function(config, vals, ...)
		BInt._params._extract_func = true
		config = config or {}
		config.immediate = true
		config.nopulse = true
		config.delay = 0
		config.blocking = false
		if vals then
			vals.StatusText = nil
		end
		return orig.update_hand_text(config, vals, ...)
	end

	play_sound = function(...)
		if G.STATE == G.STATES.HAND_PLAYED then
			return
		end
		return orig.play_sound(...)
	end

	EventManager.add_event = function(self, event, queue, ...)
		if not queue or queue == "base" then
			if BInt._params._extract_func and event.func then
				BInt._params._extract_func = false
				event.func()
				return
			end
			if not event.handy_never_modify then
				event.blocking = false
				event.blockable = false
				event.delay = (event.timer == "REAL") and event.delay or (event.trigger == "ease" and 0.0001 or 0)
			end
		end
		return orig.add_event(self, event, queue, ...)
	end

	BInt._params._anim_skip_installed = true
end

local function uninstall_anim_skip()
	if not BInt._params._anim_skip_installed then
		return
	end
	local orig = BInt._params._originals

	delay = orig.delay
	attention_text = orig.attention_text
	card_eval_status_text = orig.card_eval_status_text
	juice_card = orig.juice_card
	Moveable.juice_up = orig.juice_up
	draw_card = orig.draw_card
	ease_discard = orig.ease_discard
	ease_hands_played = orig.ease_hands_played
	level_up_hand = orig.level_up_hand
	update_hand_text = orig.update_hand_text
	play_sound = orig.play_sound
	EventManager.add_event = orig.add_event

	BInt._params._anim_skip_installed = nil
	BInt._params._extract_func = nil
	BInt._params._force_non_blocking = nil
end

function BInt._params.apply(params)
	params = params or {}
	capture_originals()

	local speed = params.speed
	if speed == nil then
		speed = 512
	end
	if speed and speed > 1 then
		install_speed(speed)
	end

	local skip = params.skip_anim
	if skip == nil then
		skip = true
	end
	if skip then
		install_anim_skip()
	end

	if params.immortal then
		BInt._params._saved.end_round = end_round
		local orig_end_round = end_round
		end_round = function(...)
			if G.GAME and G.GAME.blind and G.GAME.chips < G.GAME.blind.chips then
				G.GAME.chips = G.GAME.blind.chips
			end
			return orig_end_round(...)
		end
		BInt._params._immortal_hook = true
	end

	if params.clean_profile then
		BInt._profile.reset_test_profile()
		BInt._params._clean_profile_active = true
	end
end

function BInt._params.restore()
	uninstall_speed()
	uninstall_anim_skip()

	if BInt._params._saved.end_round then
		end_round = BInt._params._saved.end_round
	end

	BInt._params._immortal_hook = nil

	if BInt._params._clean_profile_active then
		BInt._profile.unlock_all()
		BInt._params._clean_profile_active = nil
	end

	BInt._params._saved = {}
end

function BInt._params.update_speed()
	local mult = BInt._params._speed_multiplier
	if not mult or mult <= 1 then
		return
	end

	G.SPEEDFACTOR = (G.SPEEDFACTOR or 1) * mult

	local retriggers = BInt._params._queue_retriggers or 0
	if retriggers > 0 then
		local v = G.VIBRATION
		local j = G.ROOM.jiggle
		for i = 1, retriggers do
			local events_count = 0
			for k, q in pairs(G.E_MANAGER.queues or {}) do
				events_count = events_count + #q
			end
			if events_count > 1 then
				G.E_MANAGER:update(0, true)
			else
				break
			end
		end
		G.VIBRATION = v
		G.ROOM.jiggle = j
	end
end
