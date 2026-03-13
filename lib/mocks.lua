BInt._mock_queues = {}

local _orig = {
	poll_edition = poll_edition,
	pseudorandom_element = pseudorandom_element,
	pseudorandom = pseudorandom,
}

local _orig_smods = {}

local function init_smods_originals()
	if not _orig_smods.poll_seal and SMODS.poll_seal then
		_orig_smods.poll_seal = SMODS.poll_seal
		_orig_smods.poll_rarity = SMODS.poll_rarity
		_orig_smods.poll_enhancement = SMODS.poll_enhancement
	end
end

function BInt._install_mocks()
	poll_edition = function(...)
		local queue = BInt._mock_queues["poll_edition"]
		if queue and #queue > 0 then
			return table.remove(queue, 1)
		end
		return _orig.poll_edition(...)
	end

	pseudorandom_element = function(_t, seed, ...)
		local queue = BInt._mock_queues["pseudorandom_element"]
		if queue and #queue > 0 then
			local key = table.remove(queue, 1)
			return _t[key], key
		end
		return _orig.pseudorandom_element(_t, seed, ...)
	end

	pseudorandom = function(seed, min, max)
		local queue = BInt._mock_queues["pseudorandom"]
		if queue and #queue > 0 then
			return table.remove(queue, 1)
		end
		return _orig.pseudorandom(seed, min, max)
	end

	init_smods_originals()
	if _orig_smods.poll_seal then
		SMODS.poll_seal = function(...)
			local queue = BInt._mock_queues["SMODS.poll_seal"]
			if queue and #queue > 0 then
				return table.remove(queue, 1)
			end
			return _orig_smods.poll_seal(...)
		end

		SMODS.poll_rarity = function(...)
			local queue = BInt._mock_queues["SMODS.poll_rarity"]
			if queue and #queue > 0 then
				return table.remove(queue, 1)
			end
			return _orig_smods.poll_rarity(...)
		end

		SMODS.poll_enhancement = function(...)
			local queue = BInt._mock_queues["SMODS.poll_enhancement"]
			if queue and #queue > 0 then
				return table.remove(queue, 1)
			end
			return _orig_smods.poll_enhancement(...)
		end
	end
end

function BInt._mocks_cleanup()
	BInt._mock_queues = {}
end

BInt._install_mocks()
