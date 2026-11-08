# Genre Legends

Pilot one frame that shifts between ship and mech. Pick missions on an endless, forking star map,
and each mission type plays like a different arcade genre. Built in Godot 4 for the web, so it plays
in Safari on an iPad (add it to the Home Screen for full screen). No ads, no real money.

**Play:** https://heromedel.github.io/Genre-Legends/ (GitHub Pages serves the `playtest` branch, which only gets builds that passed every tester)

## What's new in 0.2

- **Upgrades with strategy:** fewer, bigger level-ups; Resonance tiers by element; cards that show what they build toward; risky cards; two rerolls; a Build screen in the pause menu and on level-ups.
- **Intentional difficulty:** hand-set first region tuned with an average-player bot; a Threat setting (Standard, Veteran, Casual).
- **Five-minute stages with mini-bosses:** Twin Aces, the Bulkhead Fortress, the Brood Queen and the Mimic King.
- **Lessons:** planet 3's needle swarms hand over Mirror Aegis, the first gate's Mirror Dreadnought hands over Swarm Pods, win or lose. Green dots mark new tech.
- **Losses still pay:** a share of the reward by progress, plus milestones (Records page), some of which bring Cluster Drones and Centi-Mechs into the galaxy.
- **Lt. Arden on the radio**, enemy traits on planet cards, Hazard routes, full screen in Safari, version stamp in the play log.

## What's in the first build (Plan A)

- **Mission types:** Star Cluster (formation shooter), Corridor Run (scrolling trench), Planet
  Exploration (open-area bullet hell) and Dungeon Delve (room-by-room crawler), each with its own
  enemies and a set-piece boss: the Hive Carrier, the Wyrm Engine, the Siege Crawler and the Hollow King.
- **Frame:** ship form for the shooters, mech form on the ground, with a transformation as each mission starts.
  Three frames (Vanguard, Tempest, Bulwark), each with a trait.
- **Tech:** 12 pieces of tech, each with two forks that change how it behaves, plus fusions when two
  are maxed. Only the main weapon starts online; level-ups, Salvage Crates and treasure pedestals power up the rest.
- **Star map:** procedurally generated and forever expanding, with forking routes, special conditions,
  region gates and themed branches whose prize is shown up front.
- **Play log:** Settings → Save play log file. It records taps, choices, hits and the full mission
  input, so `tests/replay_log.gd` can replay it exactly.

## Layout

| Path | What it is |
|---|---|
| `scripts/sim/` | The simulation: missions, stages, enemies, bosses, weapons. Deterministic and headless-testable. |
| `scripts/view/` | Drawing the simulation: art, effects, HUD, overlays, the mission screen. |
| `scripts/ui/` | Menus: title, command center (star map, hangar, R&D, settings), results. |
| `scripts/data/` | Tech, enemies, frames, mission types. |
| `scripts/main.gd` | The game's flow, top to bottom. |
| `docs/` | Standards, design document, labelling guide, roadmap. |
| `play/` | The web export served by GitHub Pages. Rebuild with `tools/export_web.sh`. |
| `tests/` | Testers (below). |

## Build and test

Requires Godot 4.6 with the web export templates.

```
tools/export_web.sh                                   # export to play/
godot --headless -s tests/test_rules.gd               # rules tests
godot --headless -s tests/qa_harness.gd -- all 2 all  # QA bots: every mission type at three progress levels
godot --headless -s tests/difficulty_report.gd -- 2   # average-player bot against the first region's targets
godot --headless -s tests/break_it.gd                 # break-it tester (headless half)
godot --headless -s tests/replay_log.gd -- log.txt    # replay a play log
tests/web/serve.sh &                                  # serve play/ on :8060, then:
node tests/web/first_impressions.js out/              # screenshots for the cold visual review
node tests/web/blind_playtester.js out/ 120           # fresh-save playthrough that saves a play log
```

Debug launches: add `?test=planet&boss=1&power=a&god=1` to the page URL (or use Settings → Debug Console).
