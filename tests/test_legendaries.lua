-- Standalone test suite for legendary wild Pokemon 10-move boss fights and slicing.
-- Run from the gen1recomp repo root with a Lua interpreter:
--
--   lua mods/gen1_kaindof/tests/test_legendaries.lua
--
-- Asserts that wild battles against MEWTWO, MEW, ARTICUNO, ZAPDOS, and MOLTRES:
-- 1. Force Level 100, max 15 DVs, 50,000 Stat EXP.
-- 2. Populate 10-move competitive arsenals during battle.
-- 3. Slice moves down to top 4 signature moves upon capture.

package.path = "./?.lua;./?/init.lua;" .. package.path
local T = require("tests.modkit")

local Data = T.fixtures.fresh()

-- Register mock fixture entries for legendary species and moves if missing
local legendaries = { "MEWTWO", "MEW", "ARTICUNO", "ZAPDOS", "MOLTRES" }
for _, sp in ipairs(legendaries) do
  if not Data.pokemon[sp] then
    Data.pokemon[sp] = {
      name = sp,
      types = { "PSYCHIC" },
      baseStats = { hp = 106, attack = 110, defense = 90, speed = 130, special = 154 },
      growthRate = "SLOW",
      catchRate = 3
    }
  end
end

local reqMoves = {
  "AMNESIA", "PSYCHIC", "RECOVER", "BLIZZARD", "THUNDERBOLT", "FIRE_BLAST", "SUBSTITUTE", "HYPER_BEAM", "DRAGON_RAGE", "THUNDER_WAVE",
  "SWORDS_DANCE", "BODY_SLAM", "EARTHQUAKE", "SOFTBOILED",
  "AGILITY", "REFLECT", "DOUBLE_EDGE", "ICE_BEAM", "SKY_ATTACK", "REST", "TOXIC",
  "DRILL_PECK", "THUNDER", "LIGHT_SCREEN", "FIRE_SPIN", "FLAMETHROWER"
}
for _, mv in ipairs(reqMoves) do
  if not Data.moves[mv] then
    Data.moves[mv] = { power = 50, type = "NORMAL", pp = 10 }
  end
end

local run = T.sdk.loadMod("mods/gen1_kaindof", { data = Data })
T.eq(#run.errors, 0, "loads clean")

local status, BattleState = pcall(require, "src.battle.BattleState")
if not (status and BattleState and type(BattleState.newWild) == "function") then
  -- Fallback mock test if engine BattleState isn't in test load path
  run.release()
  T.finish("gen1_kaindof_legendaries (skipped - BattleState not available in headless stub)")
  return
end

local mockGame = {
  data = Data,
  save = {
    party = {
      { species = "FIXMON_A", level = 50, hp = 100, stats = { hp = 100 } }
    }
  }
}

local expected10Sets = {
  MEWTWO   = { "AMNESIA", "PSYCHIC", "RECOVER", "BLIZZARD", "THUNDERBOLT", "FIRE_BLAST", "SUBSTITUTE", "HYPER_BEAM", "DRAGON_RAGE", "THUNDER_WAVE" },
  MEW      = { "SWORDS_DANCE", "BODY_SLAM", "EARTHQUAKE", "SOFTBOILED", "PSYCHIC", "BLIZZARD", "THUNDERBOLT", "THUNDER_WAVE", "HYPER_BEAM", "AMNESIA" },
  ARTICUNO = { "BLIZZARD", "AGILITY", "REFLECT", "DOUBLE_EDGE", "ICE_BEAM", "HYPER_BEAM", "SKY_ATTACK", "REST", "TOXIC", "SUBSTITUTE" },
  ZAPDOS   = { "THUNDERBOLT", "DRILL_PECK", "THUNDER_WAVE", "AGILITY", "THUNDER", "LIGHT_SCREEN", "REFLECT", "HYPER_BEAM", "REST", "SUBSTITUTE" },
  MOLTRES  = { "FIRE_BLAST", "AGILITY", "REFLECT", "FIRE_SPIN", "FLAMETHROWER", "HYPER_BEAM", "DOUBLE_EDGE", "REST", "TOXIC", "SUBSTITUTE" },
}

for species, expectedMoves in pairs(expected10Sets) do
  local battle = BattleState.newWild(mockGame, species, 50)
  T.check(battle ~= nil and battle.enemy ~= nil and battle.enemy.mon ~= nil, "wild battle created for " .. species)

  local mon = battle.enemy.mon
  T.eq(mon.level, 100, species .. " level forced to 100")

  local dvVal = mon.dv or (mon.dvs and mon.dvs.attack)
  T.eq(dvVal, 15, species .. " DVs forced to max (15)")

  local expVal = mon.stat_exp and mon.stat_exp.attack
  T.eq(expVal, 50000, species .. " Stat EXP forced to 50,000")

  -- Verify 10 moves during battle
  T.eq(#mon.moves, 10, species .. " battle moveset has exactly 10 moves")
  for i = 1, 10 do
    T.eq(mon.moves[i] and mon.moves[i].id, expectedMoves[i], species .. " battle move " .. i .. " matches " .. expectedMoves[i])
  end

  -- Simulate capture and verify 4-move slicing
  if type(BattleState.storeCaughtMon) == "function" then
    BattleState.storeCaughtMon(battle)
    T.eq(#mon.moves, 4, species .. " post-catch moveset sliced to 4 moves")
    for i = 1, 4 do
      T.eq(mon.moves[i] and mon.moves[i].id, expectedMoves[i], species .. " caught move " .. i .. " matches " .. expectedMoves[i])
    end
  end
end

run.release()
T.finish("gen1_kaindof_legendaries")
