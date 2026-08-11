-- Headless loader test for gen1_kaindof. Run from the gen1recomp repo root
-- with a Lua interpreter:
--
--   lua mods/gen1_kaindof/tests/test_kaindof.lua
--
-- Asserts the mod's load-time patching and runtime hook behavior:
-- levels scale by class tier, DVs tier by class, Stat EXP scales with
-- progression (capped at 50,000 for regular, 65,535 for bosses), and wild
-- levels bump +2.

package.path = "./?.lua;./?/init.lua;" .. package.path
local T = require("tests.modkit")

local Data = T.fixtures.fresh()

-- Add water encounter zone to fixture dataset to verify water wild encounters
Data.encounters.FIX_ROUTE.water = {
  slots = {
    { level = 10, species = "FIXMON_A" },
    { level = 15, species = "FIXMON_B" },
  }
}

local run = T.sdk.loadMod("mods/gen1_kaindof", { data = Data })
T.eq(#run.errors, 0, "loads clean")

-- -------------------------------------------------------------------
-- 1. Load-time Registry Patching
-- -------------------------------------------------------------------
local trainer = Data.trainers.OPP_FIX_YOUNGSTER
T.check(trainer and type(trainer.parties) == "table", "fixture trainer present")
local party = trainer.parties[1]
T.check(party[1].level >= 6 and party[1].level <= 10, "slot 1 bumped 5 -> 5 + random(1..5)")
T.check(party[2].level >= 6 and party[2].level <= 10, "slot 2 bumped 5 -> 5 + random(1..5)")

-- Party size and schema checks
T.check(#party >= 2 and #party <= 6, "party size stays in bounds")
for i, slot in ipairs(party) do
  T.check(type(slot.level) == "number" and type(slot.species) == "string",
    "slot " .. i .. " keeps the strict {level, species} shape")
  T.check(Data.pokemon[slot.species] ~= nil,
    "slot " .. i .. " species exists in the registry (" .. slot.species .. ")")
end

-- -------------------------------------------------------------------
-- 2. Wild Encounters (Grass and Water slots)
-- -------------------------------------------------------------------
local route = Data.encounters.FIX_ROUTE
T.check(route and route.grass and type(route.grass.slots) == "table", "fixture route grass present")
T.eq(route.grass.slots[1].level, 5, "grass slot 1 bumped 3 -> 5")
T.eq(route.grass.slots[2].level, 6, "grass slot 2 bumped 4 -> 6")

T.check(route.water and type(route.water.slots) == "table", "fixture route water present")
T.eq(route.water.slots[1].level, 12, "water slot 1 bumped 10 -> 12")
T.eq(route.water.slots[2].level, 17, "water slot 2 bumped 15 -> 17")

-- -------------------------------------------------------------------
-- 3. Runtime Hooks & Seams
-- -------------------------------------------------------------------
local Runtime = require("src.mods.Runtime")
T.check(Runtime.wantsHook("trainer.party"), "trainer.party hook registered")
T.check(Runtime.wantsHook("battle.enemy_action"), "battle.enemy_action hook registered")

-- -------------------------------------------------------------------
-- 4. Runtime Trainer Level, DV, and Stat EXP Scaling Tests
-- -------------------------------------------------------------------

-- Emit game.ready event to set live player party (avg level = 30)
local gameMock = {
  save = {
    party = {
      { level = 30, species = "FIXMON_A" },
      { level = 30, species = "FIXMON_B" },
    }
  }
}

if run.loader and run.loader.events then
  run.loader.events:emit("game.ready", { game = gameMock })
end

-- Helper to invoke the trainer.party hook chain directly
local function callTrainerPartyHook(oppClass, partyIndex, partySlots)
  local nextFn = function(c, pi, p) return partySlots end
  local chain = run.loader and run.loader.hooks and run.loader.hooks.chains["trainer.party"]
  if chain then
    local out = partySlots
    for _, wrapper in ipairs(chain) do
      local currentNext = nextFn
      out = wrapper(currentNext, oppClass, partyIndex, out) or out
    end
    return out
  end
  return partySlots
end

local inputParty = {
  { level = 5, species = "FIXMON_A" },
  { level = 5, species = "FIXMON_B" },
}

-- 4a. Regular Trainer (OPP_YOUNGSTER): level +1..5, DVs 3..5, Stat EXP progression
local regOut = callTrainerPartyHook("OPP_YOUNGSTER", 1, inputParty)
T.check(regOut[1].level >= 31 and regOut[1].level <= 35,
  "Regular trainer level scaled to player avg (30) + random(1..5)")
local regDv = regOut[1].dv or (regOut[1].dvs and regOut[1].dvs.attack)
T.check(regDv >= 3 and regDv <= 5, "Regular trainer DVs in 3..5 range")
local regExp = regOut[1].stat_exp and regOut[1].stat_exp.attack
T.check(regExp ~= nil and regExp > 0 and regExp <= 50000,
  "Regular trainer Stat EXP scaled with progression and <= 50,000")

-- 4b. Gym Leader (OPP_BROCK): level +5..10, DVs 10..12, Stat EXP progression
local brockOut = callTrainerPartyHook("OPP_BROCK", 1, inputParty)
T.check(brockOut[1].level >= 35 and brockOut[1].level <= 40,
  "Gym Leader level scaled to player avg (30) + random(5..10)")
local brockDv = brockOut[1].dv or (brockOut[1].dvs and brockOut[1].dvs.attack)
T.check(brockDv >= 10 and brockDv <= 12, "Gym Leader DVs in 10..12 range")

-- 4c. Elite Four (OPP_LANCE): level +10..20, DVs 15, Max Stat EXP at high level
-- Update gameMock player average level to 65
gameMock.save.party = { { level = 65 }, { level = 65 } }
local lanceOut = callTrainerPartyHook("OPP_LANCE", 1, inputParty)
T.check(lanceOut[1].level >= 75 and lanceOut[1].level <= 85,
  "Elite Four level scaled to player avg (65) + random(10..20)")
local lanceDv = lanceOut[1].dv or (lanceOut[1].dvs and lanceOut[1].dvs.attack)
T.eq(lanceDv, 15, "Elite Four DVs set to max (15)")
local lanceExp = lanceOut[1].stat_exp and lanceOut[1].stat_exp.attack
T.eq(lanceExp, 65535, "Elite Four Stat EXP scales to max (65,535)")

-- 4d. Regular Trainer Stat EXP Cap Test at high level (65+)
local regHighOut = callTrainerPartyHook("OPP_YOUNGSTER", 1, inputParty)
local regHighExp = regHighOut[1].stat_exp and regHighOut[1].stat_exp.attack
T.eq(regHighExp, 50000, "Regular trainer Stat EXP capped at 50,000 even at level 65+")

run.release()
T.finish("gen1_kaindof")
