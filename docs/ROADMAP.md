# Genre Legends — Roadmap

(Note) Everything here is Ai-Generated-Proposal (2026-11-08) unless a line cites a GDD point, in which case it carries that point's tag. heromedel asked for a roadmap covering all 8 mission types, with 3 built in depth first and depth and width added each update (GDD 3A). Plans are letters, steps are numbers.

## The 8 mission types

| # | Mission type | Frame form | Source |
|---|---|---|---|
| 1 | Star Cluster: formation shooter | Ship | GDD 6A |
| 2 | Corridor Run: scrolling corridor shooter | Ship | GDD 6A |
| 3 | Planet Exploration: open-area bullet hell | Mech | GDD 6C |
| 4 | Dungeon: room-by-room bullet hell crawler | Mech | GDD 6D |
| 5 | Planetary Defense: bottom-of-screen defense | Turret / tank | GDD 6B |
| 6 | Tank Assault: top-down tank commander | Tank | GDD 6E |
| 7 | Horde Siege: survive the swarm | Mech | Ai-Generated-Proposal |
| 8 | Titan Hunt: one giant set-piece boss | Combined super-robot | Ai-Generated-Proposal (GDD 5E proposal) |

## Plan A: Foundation and the first three

(Note) First playable built 2026-11-08: all seven steps have a first version. Balance and polish continue from heromedel's play.

1. Godot project, single-threaded web export, GitHub Pages deploy, iPad touch controls, tap to start (GDD 2A, 2B).
2. Core systems: the frame and its forms, combat, a fixed-step simulation with seeded randomness, mission hand-off support (GDD 6G proposal), play log and replay (GDD 4C), admin console and debug log.
3. Command center and star map with forking routes and planet info (GDD 5A–5D).
4. Planet Exploration, Star Cluster with Corridor Run, and Dungeon, each with its own enemies, a set-piece boss and its genre's tropes (GDD 1B, 6H).
5. Equipment: blueprints, loadout, in-mission upgrades that fork, the starter weapon (GDD 7A–7F).
6. Testers: test harness, QA bots, blind, break-it and first-impressions playtesters (GDD 4A, 4B).
7. First playable build on GitHub Pages.

## Plan B: First chained mission

1. Planet Exploration that dives into a Corridor Run mid-mission (GDD 6G, heromedel's first example).
2. More depth for the first three: more enemies, bosses, branch themes and fusions.

## Build 0.2 (2026-11-08, approved plan A–H in GDD 9)

(Note) Done: strategic upgrades, intentional first-region difficulty, five-minute stages and mini-bosses, lesson planets, losses that pay and milestones, radio officer, enemy traits, Hazard routes, full screen, version stamp, hangar pop-up.

## Build 0.2.2 (2026-11-08, from heromedel's playtest)

(Note) Done: Twin Aces health bar, dodgeable Hive Carrier lasers, Hangar and R&D dots, three-reel crates with effect text, visible Tractor Beam, Ricochet that bounces off edges, a louder radio with special-condition lines, the Guide to Guardians, harder themed branches, text that never mentions the ground in space (GDD 11A–11H).

## Build 0.3: content (approved 2026-11-08)

(Note) Built 2026-11-08: steps 1-7 and the readability pass's cheaper items (banners, needles, bullets in the dark, minimap, Arc Blade icon). Still open from step 8: Planet Exploration ground and dungeon rooms with more life, Thunder Lance as a real rail, the star map cut off at the right, boss warnings before the boss is in view, boss bar colours.

1. Frames show their body and gear: parts fold away offline, deploy online, change with forks and merge in fusions (GDD 11F).
2. A new boss and mini-boss for each mission type, named on the planet card, including the clone and projector (GDD 11E) and a Bounty Hunter Ace for the Tempest Run.
3. Elite enemies with modifiers and better loot.
4. Two new support and two new special tech, with fusions.
5. Map events between planets: derelicts, distress calls, traders, ambushes.
6. Bigger moments: hit-stop on big kills, screen-filling boss deaths, a show for Resonance tiers and fusions.
7. Music and sound that fit each genre.
8. Readability pass from the 0.2.2 cold review: no pile-up of banners, boss names and bars at the top of the screen; Planet Exploration ground and dungeon rooms with more life; needles that look like needles; Thunder Lance as a real rail; a clearer Arc Blade icon; star map not cut off at the right; boss warnings before the boss is in view; boss bars coloured unlike the player's bars; a readable dungeon minimap; bullets visible in the Hollow King's darkness.
9. Later: the Daily Signal and portals into pocket dungeons (with Plan G).

## Build 0.3.1 (2026-11-08)

(Note) Done: the boss's prize (GDD 11I) with levels banked after the boss, the rare Clone Projector (11E), the bullet-glow accessibility option (11J).

## Build 0.3.2: more mini-bosses (approved 2026-11-08)

(Note) Built 2026-11-09: Swarm Marshal, Salvo Barge, Ring Obelisk, Blade Wraith.

1. A third mini-boss for each mission type, so the rare Clone Projector and every other pool have variety.

## Build 0.4 (approved 2026-11-09)

(Note) Built 2026-11-09: chained missions (Plan B step 1), planet biomes and landmarks, supply pods, dungeon room dressing and rune traps, a real rail for Thunder Lance, boss warnings before the boss arrives, a clone that mirrors your build, Nova Bomb on the mech's back, the radio hold, auto-aim as an option, cracking mirrored elites, the Dropship transitions; from heromedel's 0.3.2 logs: auto-fire as an option, pause menu options, off-screen ricochet, a tighter Tractor Beam, a softer Hex Repeater, the trade-kill win, a persistent play log and touch fixes. Difficulty calibration waits for heromedel's next logs.

## Build 0.4.1 (approved 2026-11-09)

(Note) Built 2026-11-09: Resonance tiers made obvious and significant (GDD 9H), boss banners clear of the boss, fusion progress that explains Mk caps.

## Build 0.4.2 (2026-11-09, from heromedel's 0.4.1 log)

(Note) Built 2026-11-09: tabs on top and a full-width star map (GDD 11R), readable banners (11S), Blood Pact's own price (11T), Thunder Lance from the muzzle, audio that resumes on a tap and is logged.

## Plan C: Defense and tanks

1. Planetary Defense and Tank Assault, sharing the tank form.
2. heromedel's second chain: Planetary Defense turns into an invader wave, then launches into a Star Cluster boss fight (GDD 6G).

## Plan D: Remaining mission types

1. Horde Siege.
2. Titan Hunt and the combined super-robot form.

## Plan G: Realms (later)

1. The first realm: a dimension reached through a rare event, with its own galaxy, look and rules (GDD 10B, 10E).

## Plan E: Co-op and trading

1. Controller support (GDD 2D).
2. Device-to-device co-op and trade codes (GDD 8C, 8D).

## Plan F: Rewards layer

1. Mock mobile-game rewards with no ads and no real money (GDD 8A, 8B).
