# Genre Legends

Pilot one frame that shifts between ship and mech. Pick missions on an endless, forking star map,
and each mission type plays like a different arcade genre. Built in Godot 4 for the web, so it plays
in Safari on an iPad (add it to the Home Screen for full screen). No ads, no real money.

**Play:** https://heromedel.github.io/Genre-Legends/ (GitHub Pages serves the `playtest` branch, which only gets builds that passed every tester)

## What's new in 0.4

- **Chained missions:** some planets crack open a fissure when the last hive nest falls; dive in and your mech becomes a ship for a Corridor Run. Some dungeons break out to the surface instead. The planet card tells you.
- **Livelier planets and dungeons:** planet biomes (verdant, desert, ice, volcanic) with ruins, wrecks, crystal fields and lava cracks; supply pods that land near you (with company); dungeon rooms with rugs, rune circles, rubble and rune traps.
- **The clone mirrors you:** it wears your gear and fires your own main weapon back, plus your Swarm Pods if they're online.
- **Boss warnings come first**, then the boss. Thunder Lance fires a real rail. Enemies hold back while the opening radio line is read. Mirrored elites crack eventually.
- **Settings, Accessibility:** Auto-aim (mech), off by default.
- **The Dropship:** every mission launches from its bay (the mech folds into a ship and blasts out), arrives in space, on a planet or at a dungeon gate, and ends with the trip home, or with a tow back aboard after a loss. Tap to skip.
- **Fairer fights from heromedel's log:** boss bodies shove you clear instead of draining you; the Warden's stomps show their reach first.

## What's new in 0.3.2

- **Four new mini-bosses**, a third for every mission type: the Swarm Marshal (a command ship drilling its escort into formations), the Salvo Barge (salvos of homing drones you shoot down), the Ring Obelisk (bullet-hell spirals and gapped rings) and the Blade Wraith (three flying swords; the ghost is solid only while they're thrown).

## What's new in 0.3.1

- **The boss's prize:** the last boss drops the planet's blueprints as a big golden cache; grab it (it drifts to you) to end the mission. Levels and crates after the boss falls are banked as extra blueprints instead of offering upgrades you can't use.
- **The Clone Projector** is a rare surprise: about one Star Cluster planet in four.
- **Settings, Accessibility:** "Bullets glow in the dark" (off by default).

## What's new in 0.3

- **Frames show their gear:** every equipped tech has a part on the ship and the mech. Parts unfold as tech comes online, change with forks, and fusions link them in gold. Each frame's mech has its own look.
- **Eight new bosses and mini-bosses**, two of each per mission type, named on the planet card: the Clone Projector (turn your clone to your side), the Bounty Hunter Ace (the Tempest Run's prize fight), the Crusher Gate, the Leviathan, the Dune Maw, the Storm Colossus, the Gazer and the Warden.
- **Elite enemies** with a twist: shielded, splitting or mirrored.
- **Four new tech:** Option Pods, Soul Lantern, Ion Cannon and Thruster Explosion, plus the Starbreaker and Wraith Drive fusions.
- **Route events** on the way to planets, each a choice with a risk.
- **Bigger moments** on boss kills, elite kills, Resonance tiers and fusions; **each genre has its own sound**.
- **Readability:** banners clear of the HUD, needles that look like needles, bullets visible in the dark, a bigger dungeon minimap, a sword-shaped Arc Blade icon.

## What's new in 0.2.2

- **Salvage Crates** spin three reels that add up to 1-6 upgrades, and list what every upgrade does. Lucky Salvage improves the odds.
- **Guide to Guardians** (new rail page): lore, how things work, and entries for every enemy, boss, tech and fusion you find.
- **Fixes from play:** Twin Aces health bar, Hive Carrier lasers that always leave a lane (shown in advance, one hit per pass), Hangar dot clears, R&D dot when an upgrade is ready, Starfall and Wildfire text.
- **Tractor Beam** is a visible beam with a sensible reach; **Ricochet Rounds** bounce off the field's edges and keep hunting.
- **Themed branches** are now the riskier path, and their prize planet is a Hazard. Radio lines are louder and cover special conditions.

## What's new in 0.2.1

- **Settings → Get the latest version:** shows which build you're on and clears the offline copy so the newest build loads. Your save is kept.
- **Guardian of the Realms** subtitle, and Mawjig explained in R&D and on the Build screen.

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
