# Changelog

All notable changes to this mod are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/), versions follow semver.

## 0.6.0 - 2026-08-11

### Added
- **10-Move Legendary Boss Arsenals**: Wild encounters with `MEWTWO`, `MEW`, `ARTICUNO`, `ZAPDOS`, and `MOLTRES` operate with an expanded 10-move competitive toolkit in battle.
- **Competitive AI Armed for Wild Legendaries**: Updated `battle.enemy_action` so wild legendary encounters evaluate move efficiency, STAB, status, healing, and smart switching using the same competitive AI as Elite Four and Champion battles.
- **Post-Catch 4-Move Slicing**: Wrapped `BattleState.storeCaughtMon` to automatically slice caught legendary Pokémon's moves down to the top 4 signature moves before saving to the player's party or PC box, maintaining save file compatibility.

## 0.5.0 - 2026-08-11

### Added
- **Legendary Wild Pokémon Scaling**: Wild encounters with `MEWTWO`, `MEW`, `ARTICUNO`, `ZAPDOS`, and `MOLTRES` are automatically scaled to Level 100, max 15 DVs, 50,000 Stat EXP, and assigned curated competitive movesets, superseding any other wild Pokémon mods.
- **Standalone Legendary Unit Test Suite**: Created [`tests/test_legendaries.lua`](file:///home/jack/bin/gen1recomp/mods/gen1-kaindof/tests/test_legendaries.lua) to verify legendary wild encounter stat recalculation, level overrides, DVs, Stat EXP, and movesets.

## 0.4.0 - 2026-08-11

### Added
- **Smart Switching Evaluation Engine**: Score-based switch decision logic for trainer AI. Evaluates consecutive switch penalties (-3), pro-switch conditions (+1 for no effective moves, free switch window, telegraphed attack dodge, severe debuffs, or bad type matchup), and anti-switch conditions (-1 for opponent low HP with speed advantage, stat boost investment, or statused opponent), permitting switches only when `switchScore >= 0`.

## 0.3.1 - 2026-08-11

### Fixed
- Fixed endless AI switching loop by overriding vanilla switch actions (`action.special = "switch"`) with best competitive attack moves while preserving trainer item usage.

## 0.3.0 - 2026-08-11

### Changed
- Class-tiered level bonus scaling: regular trainers +1..5, Gym Leaders +5..10, Elite Four & Champion +10..20 over average player team level.
- Class-tiered DV scaling: early route 3-5, mid-tier 6-9, Gym Leaders 10-14, Elite Four 15 (max).
- Progressive Stat EXP scaling: 0 early game, capped at 50,000 for regular trainers, up to 65,535 max for Gym Leaders, Elite Four, & Champion.
- Rebranded repository to Gen 1 Kaindof (`gen1_kaindof`).
- Expanded unit test suite (`tests/test_kaindof.lua`) to cover all trainer tiers, DVs, Stat EXP capping, and wild encounter slots.

## 0.2.0 - 2026-08-11

### Changed
- Scaled enemy trainer levels dynamically to (average player team level) + class tier bonus (1-5 for regular trainers, 5-10 for Gym Leaders, 10-20 for Elite Four & Champion).
- Scaled enemy trainer DVs by class tier (3-5 early routes, 6-9 mid-tier, 10-14 Gym Leaders, 15 Elite Four).
- Scaled enemy trainer Stat EXP dynamically with level progression, capped at 50,000 for regular trainers and 65,535 (max) for Gym Leaders, Elite Four, and League Champion.
- Updated repository manifest URL to `burningnite/gen1recomp-gen1-kaindof`.

## 0.1.0 - 2026-08-05

### Added

- Trainer levels scaled to (average player team level) + random(1 to 3)
  (capped at 100), applied to every roster in each trainer class's parties list.
- Trainer DVs scaled per class tier/location (3-5 early, 6-9 mid, 10-14 Gym Leaders, 15 Elite Four).
- Trainer Stat EXP dynamically scaled from 0 (early game, <=15); capped at 50,000 for regular trainers while Gym Leaders, Elite Four, and Champion scale up to full 65,535.
- Trainer parties padded to 6 with varied species themed to the trainer's
  class, closed by one surprise ace one level above the old strongest.
- Competitive RBY movesets for ~55 species, carried by the trainer.party
  hook (registry party slots are schema-strict) and gated to level 25+ so
  endgame TM sets never appear on early-route trainers.
- The first rival battle is exempt and stays vanilla (one starter).
- Each encounter zone's rare slots (grass and water) replaced with fresh
  progression-tier species, never duplicating the zone's natives.
- Wild levels raised by a flat, static +2 (capped at 100).
- Competitive trainer AI via the battle.enemy_action hook: merged-type-chart
  damage scoring with STAB, immunity avoidance, effect-classified move
  roles (fixed damage scored by real damage, status spreading, low-HP
  healing, situational setup, Explosion held until near-KO), with vanilla
  fallback for item/switch turns and multi-turn locks.
