BInt.register_test("debug/blind_select_state", function(t)
	t:start_run({ seed = "JOKER123" })
	t:log("STATE: " .. tostring(G.STATE))
	t:log("blind_select: " .. tostring(G.blind_select ~= nil))
	t:log("blind_prompt_box: " .. tostring(G.blind_prompt_box ~= nil))
	t:log("blind_on_deck: " .. tostring(G.GAME.blind_on_deck))
	t:log("G.GAME.blind: " .. tostring(G.GAME.blind ~= nil))

	local choices = G.GAME.round_resets.blind_choices
	if choices then
		for k, v in pairs(choices) do
			t:log("blind_choice[" .. k .. "] = " .. tostring(v))
		end
	end

	local blind_key = G.GAME.round_resets.blind_choices[G.GAME.blind_on_deck]
	local blind_obj = G.P_BLINDS[blind_key]
	t:log("blind_key: " .. tostring(blind_key))
	t:log("blind_obj: " .. tostring(blind_obj ~= nil))

	local mock_e = {
		config = { ref_table = blind_obj },
		UIBox = {
			get_UIE_by_ID = function(self, id)
				return nil
			end,
		},
	}
	local ok, err = pcall(G.FUNCS.select_blind, mock_e)
	t:log("pcall select_blind: ok=" .. tostring(ok) .. " err=" .. tostring(err))

	if ok then
		BInt._wait.frames(60)
		t:log("after 60 frames, STATE: " .. tostring(G.STATE))
		BInt._wait.frames(300)
		t:log("after 300 more frames, STATE: " .. tostring(G.STATE))
		BInt._wait.frames(600)
		t:log("after 600 more frames, STATE: " .. tostring(G.STATE))
	end
end)
