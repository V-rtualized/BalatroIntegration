BInt._profile = {}
BInt._profile._original = nil
BInt._teardown_active = nil

local TEST_PROFILE = 9701

local _orig_save_progress = nil
local _orig_save_run = nil

local function install_save_hooks()
	if _orig_save_progress then
		return
	end
	_orig_save_progress = Game.save_progress
	_orig_save_run = save_run

	Game.save_progress = function(self) end
	save_run = function() end
end

local function uninstall_save_hooks()
	if not _orig_save_progress then
		return
	end
	Game.save_progress = _orig_save_progress
	save_run = _orig_save_run
	_orig_save_progress = nil
	_orig_save_run = nil
end

local function unlock_all()
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

local function delete_profile_files(profile)
	local prefix = profile .. "/"
	love.filesystem.remove(prefix .. "profile.jkr")
	love.filesystem.remove(prefix .. "save.jkr")
	love.filesystem.remove(prefix .. "meta.jkr")
	love.filesystem.remove(prefix .. "unlock_notify.jkr")
	love.filesystem.remove(profile .. "")
end

function BInt._profile.setup()
	BInt._profile._original = G.SETTINGS.profile
	install_save_hooks()
	G.PROFILES[TEST_PROFILE] = {}
	G:load_profile(TEST_PROFILE)
	unlock_all()
	sendDebugMessage("Switched to test profile (slot " .. TEST_PROFILE .. ")", BInt._MOD_METADATA.id)
end

function BInt._profile.teardown()
	BInt._teardown_active = true

	local co = coroutine.create(function()
		G.E_MANAGER:clear_queue()
		G:delete_run()

		uninstall_save_hooks()
		delete_profile_files(TEST_PROFILE)
		G.PROFILES[TEST_PROFILE] = nil

		G:load_profile(BInt._profile._original)
		G:init_item_prototypes()
		G:main_menu()

		BInt._wait.for_condition(function()
			return G.STATE == G.STATES.MENU
		end, 30, "Timeout waiting for main menu after test suite")

		G:save_settings()
		sendDebugMessage("Restored original profile (slot " .. BInt._profile._original .. ")", BInt._MOD_METADATA.id)
		BInt._profile._original = nil
		BInt._running = false
	end)

	BInt._active_coroutine = co
	local ok, err = coroutine.resume(co)
	if not ok then
		sendDebugMessage("Teardown error on initial resume: " .. tostring(err), BInt._MOD_METADATA.id)
		BInt._active_coroutine = nil
		BInt._teardown_active = nil
		uninstall_save_hooks()
		if BInt._profile._original then
			G.SETTINGS.profile = BInt._profile._original
			BInt._profile._original = nil
		end
		BInt._running = false
	end
end

function BInt._profile.unlock_all()
	unlock_all()
end

function BInt._profile.reset_test_profile()
	delete_profile_files(TEST_PROFILE)
	G.PROFILES[TEST_PROFILE] = {}
	G:load_profile(TEST_PROFILE)
	G:init_item_prototypes()

	local hooked = _orig_save_progress ~= nil
	if hooked then
		Game.save_progress = _orig_save_progress
	end
	SMODS.SAVE_UNLOCKS()
	if hooked then
		Game.save_progress = function(self) end
	end

	sendDebugMessage("Reset test profile to clean (vanilla default) state", BInt._MOD_METADATA.id)
end

function BInt._profile.teardown_sync()
	uninstall_save_hooks()
	if BInt._profile._original then
		G.SETTINGS.profile = BInt._profile._original
		sendDebugMessage("Restored original profile (slot " .. BInt._profile._original .. ")", BInt._MOD_METADATA.id)
		BInt._profile._original = nil
	end
end
