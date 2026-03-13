BInt.register_test("profile/test_profile_active", function(t)
	t:assert_eq(G.SETTINGS.profile, 9701, "should be on test profile slot 9701")
end)

BInt.register_test("profile/original_profile_saved", function(t)
	t:assert_true(BInt._profile._original ~= nil, "original profile should be saved")
	t:assert_true(
		BInt._profile._original >= 1 and BInt._profile._original <= 3,
		"original profile should be a normal slot (1-3)"
	)
end)

BInt.register_test("profile/save_hooks_installed", function(t)
	G:save_progress()
	save_run()
	t:log("save_progress and save_run called without error (hooked)")
end)

BInt.register_test("profile/everything_unlocked_by_default", function(t)
	local locked_count = 0
	for k, v in pairs(G.P_CENTERS) do
		if not v.unlocked then
			locked_count = locked_count + 1
		end
	end
	t:assert_eq(locked_count, 0, "all centers should be unlocked by default in test suite")
end)

BInt.register_test("profile/clean_profile_vanilla_defaults", function(t)
	local locked_count = 0
	for k, v in pairs(G.P_CENTERS) do
		if v.set and not v.unlocked then
			locked_count = locked_count + 1
		end
	end
	t:log("Locked centers on clean profile: " .. locked_count)
	t:assert_gt(locked_count, 0, "clean profile should have some locked centers")
end, { clean_profile = true })

BInt.register_test("profile/unlocked_after_clean_profile", function(t)
	local locked_count = 0
	for k, v in pairs(G.P_CENTERS) do
		if not v.unlocked then
			locked_count = locked_count + 1
		end
	end
	t:assert_eq(locked_count, 0, "everything should be re-unlocked after clean_profile test")
end)

BInt.register_test("profile/clean_profile_fresh_stats", function(t)
	local profile = G.PROFILES[9701]
	t:assert_true(profile ~= nil, "test profile should exist")

	if profile.career_stats then
		t:assert_eq(
			profile.career_stats.c_wins or 0,
			0,
			"clean profile should have 0 wins"
		)
		t:assert_eq(
			profile.career_stats.c_losses or 0,
			0,
			"clean profile should have 0 losses"
		)
	end
	t:log("Clean profile stats verified")
end, { clean_profile = true })

BInt.register_test("profile/clean_profile_can_unlock_mid_test", function(t)
	local locked_before = 0
	for k, v in pairs(G.P_CENTERS) do
		if v.set and not v.unlocked then
			locked_before = locked_before + 1
		end
	end
	t:assert_gt(locked_before, 0, "should have locked centers on clean profile")

	t:unlock_all()

	local locked_after = 0
	for k, v in pairs(G.P_CENTERS) do
		if not v.unlocked then
			locked_after = locked_after + 1
		end
	end
	t:assert_eq(locked_after, 0, "unlock_all should unlock everything")
	t:log("Unlocked " .. locked_before .. " centers mid-test")
end, { clean_profile = true })
