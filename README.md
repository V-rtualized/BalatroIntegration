# Integration

Automated integration testing for Balatro mods. Drive seeded runs programmatically, manipulate game state, interact with shops and hands, and write reproducible test suites with built-in assertions.

## Examples

Test a custom consumable that enhances cards to Gold:

```lua
BInt.register_test("arcane_arsenal:alchemist_enhances_cards", function(test)
    test:start_run({ seed = "ALCH1" })
    test:select_blind()

    test:spawn_consumable("c_arcane_the_alchemist")
    test:highlight({ 1, 2 })
    test:use_consumable("c_arcane_the_alchemist"):assert()

    local hand = test:get_hand()
    test:assert_eq(hand[1].enhancement, "m_gold", "Card 1 should be Gold enhanced")
    test:assert_eq(hand[2].enhancement, "m_gold", "Card 2 should be Gold enhanced")
end)
```

Mock RNG to force specific dice rolls on a custom joker:

```lua
BInt.register_test("odds_and_ends:loaded_dice_sequence", function(test)
    test:start_run({ seed = "DICE3" })
    test:skip_to(20, "small")
    test:select_blind()

    test:spawn_joker("j_odds_loaded_dice")

    test:mock_sequence("pseudorandom", { 2, 5 })

    test:highlight({ 1, 2, 3, 4, 5 })
    test:play_hand():assert()

    local score_after_first = test:get_score()

    test:highlight({ 1, 2, 3, 4, 5 })
    test:play_hand():assert()

    local score_after_second = test:get_score()
    test:assert_gt(
        score_after_second.scored_chips,
        score_after_first.scored_chips,
        "Roll of 5 should score more than roll of 2"
    )
end)
```

Force a custom boss blind and verify its behavior:

```lua
BInt.register_test("arcane_arsenal:miser_debuffs_gold_seals", function(test)
    test:mock("pseudorandom_element", "bl_arcane_the_miser")
    test:start_run({ seed = "MISER1" })

    test:skip_to(1, "boss")
    test:select_blind()

    local info = test:get_round_info()
    test:assert_eq(info.blind, "bl_arcane_the_miser", "Boss blind should be The Miser")

    test:set_seal(1, "Gold")
    test:highlight({ 1, 2, 3, 4, 5 })
    test:play_hand():assert()
end)
```

See [examples/](examples/) for complete test suites:
- **[ArcaneArsenal](examples/ArcaneArsenal/)** — tests for tarots, spectrals, vouchers, custom decks, boss blinds, and jokers
- **[OddsAndEnds](examples/OddsAndEnds/)** — tests for RNG-driven jokers with mock sequences and forced outcomes

## Installation

Requires [Steamodded](https://github.com/Steamodded/smods) >= 1.0.0~BETA-1221a and [Lovely](https://github.com/ethangreen-dev/lovely-injector) >= 0.9.

Copy the `Integration/` folder into your Balatro Mods directory:

- **Windows:** `%AppData%/Balatro/Mods/`
- **Linux (Proton):** `~/.steam/steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods/`
- **Linux (Flatpak):** `~/.var/app/com.valvesoftware.Steam/.steam/steam/steamapps/compatdata/2379780/pfx/drive_c/users/steamuser/AppData/Roaming/Balatro/Mods/`
- **macOS:** `~/Library/Application Support/Balatro/Mods/`

Load your tests conditionally:

```lua
if next(SMODS.find_mod("Integration")) then
    assert(SMODS.load_file('tests.lua'))()
end
```

## Documentation

See the [wiki](wiki/) for the full API reference:

- [Getting Started](wiki/Getting-Started.md) — write your first test
- [Run Control](wiki/Run-Control.md) — start and restart runs
- [Hand Interaction](wiki/Hand-Interaction.md) — highlight, play, discard
- [Shop Interaction](wiki/Shop-Interaction.md) — buy, sell, reroll
- [Cheats](wiki/Cheats.md) — spawn cards, set money, modify state
- [State Queries](wiki/State-Queries.md) — read game state for assertions
- [Mocking Randomness](wiki/Mocking-Randomness.md) — force specific RNG outcomes
- [Assertions](wiki/Assertions.md) — assert_eq, assert_gt, and more
- [Test Parameters](wiki/Test-Parameters.md) — speed, immortality, infinite money
- [Events](wiki/Events.md) — lifecycle hooks
