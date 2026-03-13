BInt.register_test("params/default_speed_512", function(t)
	t:assert_true(BInt._params._speed_multiplier == 512, "default speed should be 512x")
	t:assert_true(BInt._params._anim_skip_installed, "animations should be skipped by default")
end)

BInt.register_test("params/custom_speed", function(t)
	t:assert_true(not BInt._params._speed_multiplier, "speed multiplier should not be set at 1x")
	t:assert_true(not BInt._params._anim_skip_installed, "animations should not be skipped")
end, { speed = 1, skip_anim = false })

BInt.register_test("params/restored_after_custom", function(t)
	t:assert_true(BInt._params._speed_multiplier == 512, "speed should be restored to 512x")
	t:assert_true(BInt._params._anim_skip_installed, "anim skip should be restored")
end)

BInt.register_test("params/infinite_money_flag", function(t)
	t:assert_true(t._params.infinite_money, "infinite_money should be set on context")
end, { infinite_money = true })

BInt.register_test("params/no_params_default", function(t)
	t:assert_true(not t._params.infinite_money, "infinite_money should not be set by default")
end)

BInt.register_test("params/infinite_money_buy", function(t)
	t:start_run({ seed = "JOKER123" })
	t:select_blind():assert()
	t:go_to_shop():assert()
	t:assert_eq(t:get_state(), G.STATES.SHOP, "should be in shop")

	t:set_money(0)
	t:assert_eq(t:get_money(), 0, "should have $0")

	local shop_cards = t:get_shop_cards()
	if #shop_cards > 0 then
		local result = t:buy_card(1)
		result:assert()
		t:assert_true(t:get_money() >= 0, "should have money after infinite_money buy")
		t:log("bought card with infinite_money, money: $" .. t:get_money())
	else
		t:log("no shop cards available, skipping buy test")
	end
end, { infinite_money = true })
