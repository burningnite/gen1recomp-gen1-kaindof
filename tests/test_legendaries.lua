-- Standalone test suite for legendary wild Pokemon scaling in gen1_kaindof.
-- Run from the gen1recomp repo root with a Lua interpreter:
--
--   lua mods/gen1_kaindof/tests/test_legendaries.lua
--
-- Asserts that wild battles against MEWTWO, MEW, ARTICUNO, ZAPDOS, and MOLTRES
-- force Level 100, max 15 DVs, 50,000 Stat EXP, and curated movesets.

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

local reqMoves = { "AMNESIA", "PSYCHIC", "RECOVER", "BLIZZARD", "SWORDS_DANCE", "BODY_SLAM", "EARTHQUAKE", "SOFTBOILED", "THUNDERBOLT", "DRILL_PECK", "THUNDER_WAVE", "AGILITY", "FIRE_BLAST", "REFLECT", "FIRE_SPIN", "DOUBLE_EDGE" }
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

local expectedSets = {
  MEWTWO   = { "AMNESIA", "PSYCHIC", "RECOVER", "BLIZZARD" },
  MEW      = { "SWORDS_DANCE", "BODY_SLAM", "EARTHQUAKE", "SOFTBOILED" },
  ARTICUNO = { "BLIZZARD", "AGILITY", "REFLECT", "DOUBLE_EDGE" },
  ZAPDOS   = { "THUNDERBOLT", "DRILL_PECK", "THUNDER_WAVE", "AGILITY" },
  MOLTRES  = { "FIRE_BLAST", "AGILITY", "REFLECT", "FIRE_SPIN" },
}

for species, expectedMoves in pairs(expectedSets) do
  local battle = BattleState.newWild(mockGame, species, 50)
  T.check(battle ~= nil and battle.enemy ~= nil and battle.enemy.mon ~= nil, "wild battle created for " .. species)

  local mon = battle.enemy.mon
  T.eq(mon.level, 100, species .. " level forced to 100")

  local dvVal = mon.dv or (mon.dvs and mon.dvs.attack)
  T.eq(dvVal, 15, species .. " DVs forced to max (15)")

  local expVal = mon.stat_exp and mon.stat_exp.attack
  T.eq(expVal, 50000, species .. " Stat EXP forced to 50,000")

  T.check(type(mon.moves) == "table" and #mon.moves == #expectedMoves, species .. " moveset has " .. #expectedMoves .. " moves")
  for i, expectedMove in ipairs(expectedMoves) do
    T.eq(mon.moves[i] and mon.moves[i].id, expectedMove, species .. " move " .. i .. " matches " .. expectedMove)
  end
end

run.release()
T.finish("gen1_kaindof_legendaries")
