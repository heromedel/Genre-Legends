class_name DepotData
## The Supply Depot (GDD 8B): the game's nod to mobile games, with none of their tricks (GDD 8A). Mawjig
## Crystals are earned by playing and checking in, never bought, and spent on Derelict Dives: the Dropship scans
## a field of wrecks, you pick one, and its drone brings back what it finds.
## Pure data; Save holds the crystals and the check-in, DerelictDives runs a dive.

## Daily check-in: one tile a day you play, any days, never reset for missing one. Day 7 loops back to day 1.
## Each tile is a different kind of reward (heromedel: "more varied").
##   crystals, frame_blueprints, main_blueprints (for your main weapon), free_dive, start_crate (next mission).
const CHECKIN := [
	{"crystals": 2, "text": "2 Crystals"},
	{"main_blueprints": 3, "text": "3 blueprints for your main weapon"},
	{"frame_blueprints": 1, "text": "1 Frame Blueprint"},
	{"crystals": 3, "text": "3 Crystals"},
	{"free_dive": 1, "text": "A free Derelict Dive"},
	{"start_crate": 1, "text": "Your next mission opens with a Salvage Crate"},
	{"crystals": 10, "frame_blueprints": 2, "text": "10 Crystals and 2 Frame Blueprints"},
]

## What missions pay in crystals: one for any mission (losses still pay, GDD 9D), more for a win.
const MISSION_CRYSTALS := 1
const WIN_CRYSTALS := 1
const FIRST_CLEAR_CRYSTALS := 2
const GATE_FIRST_CLEAR_CRYSTALS := 5
const MILESTONE_CRYSTALS := 3

## Derelict Dives.
const DIVE_COST := 10
## Odds by rarity. Every tenth dive without a Rare or better is a Rare at least.
const RARITY_WEIGHTS := {"common": 67.0, "rare": 28.0, "legendary": 5.0}
const PITY := 10
const RARITY_NAMES := {"common": "Common", "rare": "Rare", "legendary": "Prototype"}
const RARITY_COLORS := {"common": Color(0.55, 0.85, 1.0), "rare": Color(0.8, 0.55, 1.0), "legendary": Color(1.0, 0.8, 0.35)}

## The wrecks a scan can turn up. Each leans its haul one way, so the pick is a real choice:
##   slots: which loadout slots its blueprints come from ([] = Frame Blueprints instead).
##   prototype: how much likelier a Prototype is aboard.
const WRECKS := {
	"gunship": {"name": "Gunship Wreck", "text": "Weapon blueprints: main weapons, weapons and specials.", "slots": ["main", "weapon", "special"], "prototype": 1.0, "color": Color(1.0, 0.55, 0.4)},
	"carrier": {"name": "Frame Carrier", "text": "Frame Blueprints, for frame tiers.", "slots": [], "prototype": 1.0, "color": Color(1.0, 0.8, 0.35)},
	"research": {"name": "Research Vessel", "text": "Any blueprints, and twice the chance of a Prototype.", "slots": ["main", "weapon", "support", "special", "generator", "plating"], "prototype": 2.0, "color": Color(0.8, 0.55, 1.0)},
	"freighter": {"name": "Armored Freighter", "text": "Plating, generator and support blueprints.", "slots": ["support", "generator", "plating"], "prototype": 1.0, "color": Color(0.55, 0.85, 1.0)},
}
