# Genre Legends

Pilot one frame that shifts between ship and mech. Pick missions on an endless, forking star map,
and each mission type plays like a different arcade genre. Built in Godot 4 for the web, so it plays
in Safari on an iPad (add it to the Home Screen for full screen). No ads, no real money.

**Play:** https://heromedel.github.io/Genre-Legends/ (GitHub Pages serves the `playtest` branch, which only gets builds that passed every tester)

## What's new in 0.5

- **New art for the frames and gear:** five-pass vector art (outline, fill, shading, highlights, details), with a rim of light so your frame always stands out. Every piece of gear is redrawn to match.
- **Real transformations:** each frame is one set of parts that stands as the mech or folds into the ship. The helmet becomes the cockpit, the shoulders sweep out into wings, the legs fold into engines. Settings: "Transformation spin".
- **The Dropship transitions redrawn:** the launch bay is the Dropship itself, planet landings come down from above with your shadow closing in, dungeons have a torch-lit stone gate.
- **Fusions worth the wait:** Storm Halo's saws form an electric fence, Wraith Drive turns your dash into a wraith that tears through enemies, Event Horizon's orbs are small black holes, and Phoenix Driver fires real firebirds. Only fusions you can reach are mentioned.
- **Missions autosave:** close the browser mid-mission and the next start offers to continue right where you were.
- **No accidental upgrade picks:** a pick has to be a deliberate tap on the card.
- **Clearer words:** every boss phase banner rewritten, a wording check fixed a dozen descriptions that promised more than the game did, and homing shots now hit mirrored elites as the Guide says.
- "Get the latest version" asks first; the planet strip fits without a scroll bar.

## What's new in 0.4.2

- **A wider star map:** the command center's pages are tabs along the top and the planet card is a strip under the map, so the map gets the full width. The region's name no longer slides off the edge.
- **Banners you can read:** they stay up 2–3 s instead of 1.2 s.
- **Thunder Lance fires from the muzzle**, not from behind the mech.
- **Blood Pact** has its own price now: two seconds without a kill and your armor bleeds away (never below a third). It no longer touches the shield, so it doesn't overlap Glass Reactor.
- **Sound that comes back:** if the iPad suspends the game's audio, the next tap resumes it, and the play log records what happened to the audio.
- Skipping a cutscene or the Resonance splash is logged once per tap, not twice.

## What's new in 0.4.1

- **Resonance you can see:** a card that unlocks a Resonance tier wears its element's colour and a RESONANCE badge. Pick it and the action holds on a splash naming the tier and what it does. Your frame glows in the element's colour, brighter with each tier.
- **Resonance that matters:** Capacitor Discharge (Energy II: a breaking shield lets go in a lightning nova), Chain Reaction (Explosive II: blasts ripple through a crowd), Splinter Rounds (Kinetic II: shots burst into fragments on hit). Tier I is stronger across the board.
- **Banners stay clear of bosses:** mid-fight banners take whichever band is clear of the boss and you; wave counts are skipped during a fight; the objective has a dark plate so it reads over a boss's hull. Banners queued behind a card screen now wait instead of getting lost.
- **Build panel:** fusion progress says when a tech's Mk is too low to reach level 5.

## What's new in 0.4

- **Chained missions:** some planets crack open a fissure when the last hive nest falls; dive in and your mech becomes a ship for a Corridor Run. Some dungeons break out to the surface instead. The planet card tells you.
- **Livelier planets and dungeons:** planet biomes (verdant, desert, ice, volcanic) with ruins, wrecks, crystal fields and lava cracks; supply pods that land near you (with company); dungeon rooms with rugs, rune circles, rubble and rune traps.
- **The clone mirrors you:** it wears your gear and fires your own main weapon back, plus your Swarm Pods if they're online.
- **Boss warnings come first**, then the boss. Thunder Lance fires a real rail. Enemies hold back while the opening radio line is read. Mirrored elites crack eventually.
- **Settings, Accessibility:** Auto-aim (mech), off by default.
- **The Dropship:** every mission launches from its bay (the mech folds into a ship and blasts out), arrives in space, on a planet or at a dungeon gate, and ends with the trip home, or with a tow back aboard after a loss. Tap to skip.
- **Boss warnings name the boss** again, and the first radio line fits your form and auto-fire setting (from the 0.4 cold review).
- **Fairer fights from heromedel's logs:** boss bodies shove you clear instead of draining you; the Warden's stomps show their reach first and its flail hits softer; if the last boss falls while your wreck is still burning, you traded with it and the mission counts as won.
- **Settings, Accessibility:** Auto-fire (on by default). Off, weapons fire while you steer the ship or aim the mech (or hold J/Z or the right trigger).
- **Pause menu options:** music and sound sliders, screen shake and glowing bullets, without leaving the mission.
- **Ricochet in space:** missed shots fly off screen and glance back in from out of view, instead of bouncing off the screen's edge.
- **Tractor Beam** reels in semi-nearby drops with at most four beams, not the whole screen. **Hex Repeater** sounds softer.
- **The play log survives a reload**, and a stuck touch can no longer freeze the controls.

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

Two testers are agents rather than scripts: the cold first-impressions reviewer (screenshots only, one subject per
review, GDD 4E) and the wording checker (player-facing text against the code, GDD 4F). Their findings go into
`docs/REVIEW_LOG.md`.

Debug launches: add `?test=planet&boss=1&power=a&god=1` to the page URL (or use Settings → Debug Console).
Art: `?gallery=ship&zoom=4` draws one piece of art alone (`mech`, `dart`, a boss id, or an SVG path such as
`art/test/ship.svg`, with `&rim=1` for the rim light; `morph` loops the transformation; `&frame=tempest` picks the frame).
