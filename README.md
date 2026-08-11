# Gen 1 Kaindof

A kaizo-style difficulty overhaul for [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp). This mod is available at [burningnite/gen1recomp-gen1-kaindof](https://github.com/burningnite/gen1recomp-gen1-kaindof) and releases can be found [here](https://github.com/burningnite/gen1recomp-gen1-kaindof/releases).

Every trainer fields a themed party of six with levels scaled to your average team level plus random(1..3), competitive Gen 1 movesets, and a competitive AI that exploits your weaknesses — while each area's wild encounter pool widens so you can build a team that keeps up.

Try it:

```sh
# from your gen1recomp checkout, with this folder copied to mods/gen1_kaindof
python3 tools/modkit.py validate mods/gen1_kaindof --base imported
python3 tools/modkit.py lint mods/gen1_kaindof
love .
```

## Install (players)

1. Copy this folder into the game's `mods/` directory as `gen1_kaindof`.
2. Launch the game and press **F10** (or Options → mod manager) to confirm it is enabled.
3. Disabling the mod in the manager restores vanilla exactly.

## What it changes

| Area | Change |
|---|---|
| Levels | **Scaled by class tier**: Regular trainers = player average + random(1..5), Gym Leaders = player average + random(5..10), Elite Four & Champion = player average + random(10..20) |
| DVs | **Scaled by trainer tier/class**: Early route = 3–5 DVs, Mid-tier = 6–9 DVs, Gym Leaders = 10–14 DVs, Elite Four = 15 DVs (max) |
| Stat EXP | **Scaled dynamically with level progression**: 0 Stat EXP early game $\rightarrow$ ~26,000 mid-game; capped at **50,000** for regular trainers, while Gym Leaders, Elite Four, and League Champion scale up to full **65,535** |
| Party size | Padded to 6 with **varied species themed to the trainer's class** (Bug Catchers bring bugs, Hikers bring rock/ground, gym leaders pad within their type) |
| Ace | Each padded party closes with one surprise ace (Bug Catcher → Scyther, Fisherman → Gyarados, Lance → second Dragonite…) one level above the team's old strongest |
| Movesets | ~55 species get a classic RBY competitive set (Tauros: Body Slam / Hyper Beam / Earthquake / Blizzard, Chansey: Ice Beam / Thunderbolt / Thunder Wave / Soft-Boiled, ...) — **only from level 25 up**, so endgame TM sets never appear on early-route trainers |
| Trainer AI | Wraps `battle.enemy_action`: picks optimal move by **type effectiveness × STAB**, avoids immunities, scores status/healing/setup/Explosion, and evaluates switches via a **Smart Switching Engine** (penalizes consecutive switches -3, grants +1 for telegraphed move dodges/no effective moves/free switch windows, -1 for stat boost investments/low HP player) |
| First rival battle | **Left completely vanilla** — one starter in Oak's lab, as it should be |
| Wild variety | Each zone's rare slots (the tail of the encounter table) are replaced with fresh, progression-tier species: Abra / Machop / Growlithe / Vulpix early, Scyther / Tangela / Electabuzz mid-game, Dratini / Lapras / Porygon late. Common slots keep the area's vanilla identity |
| Wild levels | A flat, static **+2** so fresh catches are viable against buffed trainers |
| Legendary Wilds | **Forced Level 100, 15 DVs, 50,000 Stat EXP, Competitive AI, 10-Move Boss Arsenals, & Post-Catch 4-Move Slicing** for Articuno, Zapdos, Moltres, Mewtwo, and Mew (supersedes all other wild mods) |

Items and the economy are untouched. Bench picks and rare-slot picks are
deterministic per trainer and per area, so two Youngsters on the same route
still field different teams and every area keeps a stable, plannable pool.
The AI only rewrites *move choice* in trainer battles — switching, item use,
and wild Pokémon behavior stay vanilla, and any battle state the mod cannot
read confidently falls back to the vanilla decision.

Team levels/padding and encounter changes are data-only (`patch` over the
merged registry view), so other mods editing the same records keep their
own fields. The mod wraps two engine seams: `trainer.party` carries the
curated movesets (registry party slots are schema-strict `{level, species}`,
but the battle builder honors a `moves` list on hook-returned slots), and
`battle.enemy_action` carries the competitive AI, returning the vanilla
action for item/switch turns, multi-turn locks, and anything it cannot
read. No ROM-derived bytes ship with the mod.

Tuning knobs, the per-class padding pools, the wild-encounter tier pools, and the moveset table live at the top of [main.lua](main.lua).

## Roadmap

- Per-player difficulty options via `options_schema`

## Development

- Docs: the [modding wiki](https://github.com/bryanthaboi/gen1recomp/wiki) — start with Concepts → Registries, then the Cookbook.
- Contribution rules and polish checklist: `CONTRIBUTING-mods.md` in the engine repo.
- Tests in `tests/` load the mod through the headless loader against the
  engine's fixture dataset; run from the engine repo root with the mod
  copied to `mods/gen1_kaindof` (`luajit mods/gen1_kaindof/tests/test_kaindof.lua`,
  or the whole T4 tier via `luajit tests/run_modkit.lua`, which discovers
  every `mods/<id>/tests` directory). `.modkitignore` keeps them out of the
  packed archive.
- Package for distribution with `python3 tools/modkit.py pack mods/gen1_kaindof`.

> Note: only the GitHub repo and the project Discord are official sources for
> Gen1Recomp. The site `gen1recomp.com` is disavowed by the maintainers — do not
> download mods or builds from it.
