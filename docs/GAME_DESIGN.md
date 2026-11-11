# Genre Legends — Game Design Document

(Note) Points are tagged by how firmly heromedel has agreed to them, per the Design Doc Labelling Guide (`docs/DESIGN_DOC_LABELLING_GUIDE.md`). Strongest first: Hard Rule, Decided, Likely, Proposed, Ai-Generated-Proposal, Open, Unlikely, Rejected. Points are referenced as section number plus letter, e.g. 1A.

(Note) Sources: heromedel's original idea message and its follow-up (shared 2026-11-08 with "don't take this as law"), and the discussion in this session. The earlier web prototype is not a source.

## 1. Core Rules

- **1A. Decided (2026-11-08):** Features and abilities follow the so-called "Rule of Cool".
  - **Definition:** When designing a feature or ability, go with the cool option, not the expected, standard or bare-minimum one.
  - **Cool means exciting to get and to use.** It should feel game-changing, or give the player something new to experiment with (Game Project Standards, Engagement & Discovery).
  - **It covers the effect, not just the name.** A cooler name should come with a cooler effect, not a standard ability renamed.
  - **Realism is never the reason to cut a cool idea.** Things that make no physical sense, like ricochet shots or sound in space, are fine when they make the game cooler.
- **1B. Likely (2026-11-08):** The game leans heavily into its genres' tropes.
- **1C. Likely (2026-11-08):** Power-ups are interesting and change how the game plays. Plain stat or utility upgrades such as a dash or more energy are not enough, even for beginner equipment.
- **1D. Decided (2026-11-09):** When options are offered side by side as alternatives (two forks, two parts for one slot, a pair of choices), they must not be the same kind of ability. If one is a dash, the other can't also be a dash. This rules out only duplicates between alternatives: a dash, a ram or any other ability is fine on its own. (heromedel: "If one is a dash the alternative cannot also be a dash".)

## 2. Platform & Build

- **2A. Likely (2026-11-08):** The game is built in Godot 4 and exported for the web.
- **2B. Likely (2026-11-08):** It is hosted on GitHub Pages and must play well on an iPad mini in Safari: touch controls, tap to start audio, light on memory.
- **2C. Likely (2026-11-08):** The earlier web prototype from another session is treated as a crude prototype only. The game is redesigned and massively expanded rather than ported: varied bosses, better levels, more unique enemies and waves, and a clean, good-looking presentation.
- **2D. Proposed (2026-11-08):** Controllers are supported.

## 3. How This Game Is Built

- **3A. Decided (2026-11-08):** Build freely means the design isn't held to minute details agreed in advance. It does not mean building whatever was just said. Every change of direction or new piece of work goes through the Game Project Standards workflow: discuss it, show a plan, get permission, then build. Ideas that would hurt the game are discussed, not built. Check-ins are playable builds.
- **3B. Likely (2026-11-08):** Before a build reaches heromedel, Claude's own testers (section 4) play it, and the problems they find are fixed first.
- **3C. Likely (2026-11-08):** Builds go to Claude's own branch first. Ask heromedel before pushing to the `playtest` branch: he may still be playing the build that's there.
- **3D. Likely (2026-11-08):** When heromedel gives an example, or something clearly labelled as an example, it illustrates the idea. Claude doesn't have to copy or implement the example directly, and isn't limited to it.
- **3E. Hard Rule (2026-11-09):** Questions to heromedel are only real ones. In his words:
  > "You are not required to find a question.
  > You are not required to end a reply with questions.
  > You do not need to repeat decided on or numbered points or suggestions as a question.
  > The style guide of using Q1, Q2, Q3, if for if you have real questions, it is not meant to tell you to find questions. Do not nit pick or look for problems just to have some. Ask legit real questions when you actually, naturally have them and they have not been answered and you cannot find the answer and only if it is not a gap you were expected to fill in."

## 4. Testing & Play Log

- **4A. Likely (2026-11-08):** Claude keeps a test harness, a QA harness, a blind playtester (plays like a new player using only what's on screen) and a break-it playtester (does everything wrong, tries to break or exploit the game).
- **4B. Likely (2026-11-08):** A third playtester checks visuals, first impressions and assumptions by describing what it sees, cold. It catches things like a sword arc that looks nothing like a sword arc.
- **4E. Likely (2026-11-09):** Cold reviews run in small batches, one subject each (a level, a boss, a menu), so each review goes deeper and its findings come back while the work is fresh, not after a 30-minute sweep. Longer playtests and full sweeps are kept for major overhauls and major changes, sometimes, not every build. Every finding is triaged into the review log (`docs/REVIEW_LOG.md`): acted on, saved for later, or discarded with a note saying why it wasn't relevant. (heromedel's process.)
- **4F. Likely (2026-11-09):** A wording checker reviews the text players read: is it accurate to what the code does, human readable, free of AI conventions and not oddly abrupt? (heromedel, after Time Brake's text promised more than it did.) Its findings go into the review log like any other review.
- **4C. Likely (2026-11-08):** A built-in play log that, when heromedel sends it, is as good as watching him play the whole time: what he tapped and did, where he got stuck or panicked, readable like a replay.
- **4D. Likely (2026-11-08):** A player's behaviour in a play log isn't automatically a problem. Missing a lot may just be the player screwing around. Claude's own bots doing something they weren't supposed to is different, and is a bug.
  - **Ai-Generated-Proposal (2026-11-08) — how 4C works:** The simulation runs on a fixed step with seeded randomness, so the recorded input replays the run exactly. The log also records menu taps, touches and game events with timestamps. Long idle stretches and bursts of erratic input are marked "possibly stuck" or "possibly panicking" as hints, never verdicts (4D). The log is exported as a text code to paste into chat.

## 5. Game Concept

- **5A. Proposed (2026-11-08):** The main game area is a command center: a menu with text and icons.
- **5B. Likely (2026-11-08):** The player picks the kind of mission they want to do, e.g. dungeon crawling versus shoot 'em up.
- **5C. Proposed (2026-11-08):** Pick a planet on a procedurally generated, forever-expanding star map, see what it needs, its mission type and info, and choose to do it.
  - **Ai-Generated-Proposal (2026-11-08):** Routes fork, and what a planet shows (what it needs, danger, reward, special conditions) is what makes the choice. Named regions and landmark planets keep the map feeling like a place. Every mission type is available somewhere near the front.
- **5D. Likely (2026-11-08):** Cool features unlock through the star map.
  - **Proposed (2026-11-08):** Not every branch is random. A themed branch leans on one genre, with special enemies and a special region name, and ends in an unlock that makes sense, such as a special frame or a new upgrade menu.
  - **Ai-Generated-Proposal (2026-11-08):** The map shows a themed branch's prize before you commit to it.
- **5E. Proposed (2026-11-08):** You pilot a mech that can turn into a ship. Its form matches the mission type: ship, mech, turret or tank.
  - **Ai-Generated-Proposal (2026-11-08):** The transformation plays as the mission starts. A combining super-robot form is kept for giant bosses.
  - **Likely (2026-11-09):** The form change is a real transformation, not a flash: the mech's parts fold in as the ship's body slides out. Built with and without a full-turn spin, a setting ("Transformation spin: On > Off") so heromedel can compare. (heromedel asked whether it was "just poof".)
- **5F. Proposed (2026-11-08):** Abilities work in every mission type.
  - **Ai-Generated-Proposal (2026-11-08):** Each piece of tech has a version for each form, e.g. a shoulder chaingun is a wing gun on the ship and a turret on the tank.
- **5G. Proposed (2026-11-08):** Base ships (frames) have their own stats and unique properties.

## 6. Mission Types

- **6A. Proposed (2026-11-08):** Star Cluster: a shoot 'em up, similar to but not limited to Galaga or the corridors in The Guardian Legend.
- **6B. Proposed (2026-11-08):** Planetary Defense: Space Invaders or Missile Command style, stuck to the bottom of the screen.
- **6C. Proposed (2026-11-08):** Planet Exploration: a large open-area bullet hell, like Realm of the Mad God.
- **6D. Proposed (2026-11-08):** Dungeon (subterranean): a bullet hell dungeon crawler with rooms, like The Binding of Isaac or The Legend of Zelda.
- **6E. Proposed (2026-11-08):** Tank: top-down tank commander missions.
- **6F. Proposed (2026-11-08):** Other similar games and missions can be worked in.
- **6G. Proposed (2026-11-08):** A single stage can launch from one mission type into another, if it's done well. heromedel's examples:
  - Roaming a planet bullet-hell style, finding a corridor and diving in, shape-shifting into a ship for a corridor level.
  - Defending a Missile Command level until ships show up and it becomes Space Invaders; when the boss attacks, the player drops the turret and launches off the planet to fight it Galaga style.
  - **Ai-Generated-Proposal (2026-11-08):** Every mission type is built from the start so it can hand off mid-mission, carrying health, in-mission upgrades and the form change.
  - **Ai-Generated-Proposal (2026-11-09):** Built in 0.4: about a third of eligible Planet Exploration planets open a fissure when the last nest falls and dive into a short Corridor Run with its boss; some dungeons' boss doors break out to the surface for a short planet run and its boss. The planet card says so.
- **6H. Proposed (2026-11-08):** Every boss is a set piece: its own body, a warning intro, phases that change the arena, and its own mechanic. (Claude's idea; heromedel: "sounds cool".)

## 7. Equipment & Upgrades

- **7A. Proposed (2026-11-08):** Loot is Tech Blueprints. About 3 unlock a weapon or ability, and an increasing amount, following a formula, upgrades it.
- **7B. Proposed (2026-11-08):** A limited number can be equipped before a mission, either by category (e.g. Weapon, Armor, Passive, Special) or by Armored Core-style slots (e.g. back-mounted shield, shoulder chaingun, primary weapon in one hand, thruster/legs). Slots might complicate it.
- **7C. Proposed (2026-11-08):** Equipping doesn't give full power. Tech is upgraded during missions, like Vampire Survivors or Cell Survivor, probably with a point system, missable drops and occasionally a slot-machine upgrade.
- **7D. Proposed (2026-11-08):** Only the base weapon starts working in a mission, so base weapons are their own category.
  - **Ai-Generated-Proposal (2026-11-11):** The parts that are the frame itself start working too: the plating, the power parts, and the Generator part. With hits that matter, the design review's bot runs died at level 1-2 with the Generator part still offline, so the slot that keeps you alive meant nothing in exactly the deaths players remember. Weapons, supports and specials still come online through level-ups and crates.
- **7E. Proposed (2026-11-08):** Tech can draw on MechWarrior, Armored Core and The Guardian Legend, or be magic abilities described as Mawjig energy.
- **7G. Likely (2026-11-09):** Fusions stay at max level (both tech at level 5, so Mk 3), as a late-game goal, as long as each fusion is game-changing enough to be impressive. (heromedel.) The game only mentions a fusion when the mission can reach it.
- **7F. Proposed (2026-11-08):** Upgrades fork a weapon into different behaviours (e.g. ricochet as an upgrade step of the starter weapon), and two pieces of high-level tech can fuse into a named fusion with a new effect. (Claude's idea; heromedel: "sounds cool".)

## 8. Rewards, Co-op & Extras

- **8A. Likely (2026-11-08):** No ads and no real money. The game is played instead of ad-driven mobile games.
- **8B. Proposed (2026-11-08):** A few mock mobile-game features such as rewards, gems and reward paths, maybe with fake in-game money.
- **8E. Proposed (2026-11-11):** A few of the mock mobile features: gems called **Mawjig Crystals**, spent on rare draws, and daily check-ins. Daily rewards are varied, and the amounts are small (one tenth of a typical mobile game's). (heromedel: "maybe instead of drops it could be something cooler".)
  - **Ai-Generated-Proposal (2026-11-11):** Built in 0.6.1 as the **Supply Depot** tab. Crystals come from missions (1, +1 for a win, +2 for a first clear, +5 for a gate's first clear), milestones (+3) and the check-in, never from money (8A). The check-in is a 7-tile week that never resets for a missed day: 2 crystals, 3 main-weapon blueprints, a Frame Blueprint, 3 crystals, a free dive, a Salvage Crate at the start of the next mission, then 10 crystals and 2 Frame Blueprints. The draw is a **Derelict Dive** (10 crystals): a scan turns up three of four kinds of wreck (Gunship: weapon blueprints; Frame Carrier: Frame Blueprints; Research Vessel: twice the Prototype chance; Armored Freighter: plating, generator and support blueprints), you pick one, and its haul is Common 67% (2 blueprints), Rare 28% (5, or 3 Frame Blueprints), or Prototype 5% (an unfound tech, unlocked), with a Rare at least every 10 dives. Boss plates and branch prizes never come from dives.
- **8C. Likely (2026-11-08):** Co-op is not shared-screen.
- **8D. Proposed (2026-11-08):** Co-op device to device or over the local network, with controllers, and maybe trading frames or cards.
  - **Ai-Generated-Proposal (2026-11-08):** Pairing uses a code shown on one device and entered on the other (peer-to-peer, no server to set up). Trading uses single-use trade codes that remove the item from the sender's save.

## 9. Difficulty, Lessons & Progress (build 0.2)

- **9A. Likely (2026-11-08):** Difficulty for the first planets is set on purpose, with a target for how much an average player gets hurt, not an arbitrary formula. Losses are expected (as in FTL); challenge with some grind is good, all grind is bad, and there are never paywalls.
  - **Ai-Generated-Proposal (2026-11-08):** Targets on Standard: planet 1, 2–5 hits and 75–90% armor left; planets 2–3, 6–10 hits and 50–70% left; planets 4–5, 10–15 hits and 35–55% left; planet 6 (region gate), about 1 in 4 average attempts lost. Tuned with an "average player" QA bot. A Threat setting (Standard > Veteran > Casual) scales everything.
- **9B. Likely (2026-11-08):** Stages run about five minutes, and some have mini-bosses.
- **9C. Likely (2026-11-08):** A planet can be built to beat you without one important tech; losing (or winning) unlocks that tech, and an indicator points you to equip it. It teaches that unlocks come even when you lose, that losses are expected, and to watch your build. The tech helps a lot rather than being strictly required, and you get it either way.
  - **Likely (2026-11-08):** Shields on planet 3, mini missiles on planet 6.
  - **Ai-Generated-Proposal (2026-11-08):** Planet 3 throws needle swarms that Mirror Aegis stops and reflects; planet 6 is a mirror-hulled gate boss whose back vents homing Swarm Pods can reach. Both start out of the starting kit. A green dot marks new unequipped tech.
- **9D. Likely (2026-11-08):** Losing still unlocks things: partial rewards, and achievements, including harder, rarer ones like The Binding of Isaac's. Some achievements add new enemies to the galaxy, announced (e.g. "Cluster Drones have been spotted in the galaxy").
- **9E. Likely (2026-11-08):** Recurring characters are fine if not overly cheesy. At most one or two things to read at the start of a mission, often none; no long monologues. No in-game characters whose death loses you the mission.
  - **Ai-Generated-Proposal (2026-11-08):** An operations officer on the radio delivers these short lines.
- **9F. Likely (2026-11-08):** Planet cards list the enemy traits you'll face, so loadout choice matters.
- **9G. Proposed (2026-11-08):** Some branches, forks or clusters are intentionally hard until you have a good build or grind a little.
- **9H. Ai-Generated-Proposal (2026-11-08):** In-mission upgrades get strategy from fewer, bigger level-ups, elemental Resonance tiers, cards that show what they build toward, risky cards, two rerolls per mission and a Build screen.
  - **Likely (2026-11-09):** Reaching a Resonance tier is obvious when it happens, shown right as you pick the upgrade that gave it, with a little splash. (heromedel.)
  - **Ai-Generated-Proposal (2026-11-09):** Built in 0.4.1. A card that unlocks a tier wears the element's colour and a RESONANCE badge; picking it holds the action on a splash naming the tier and what it does; the frame glows in the element's colour, more with each tier. Tiers that were plain stat boosts became effects you can see: Capacitor Discharge (Energy II: a breaking shield lets go in a lightning nova), Chain Reaction (Explosive II: what a blast kills explodes a beat later, up to three links), Splinter Rounds (Kinetic II: shots that have flown a while burst into two fragments on hit). Tier I is stronger: arcs every 4th hit, Volatile 1 in 3, Destabilize (then Hex Touch) +30%; Storm Front arcs every 2nd hit.

## 10. Setting & Lore

- **10A. Decided (2026-11-08):** The subtitle is "Guardian of the Realms".
- **10B. Decided (2026-11-08):** Star systems sit in star clusters, in regions of a galaxy. A realm is something else: a dimension, plane, demi-plane, pocket dimension, magic dungeon or anything like that.
  - **Likely (2026-11-08):** The word "realm" is kept for those only, never used for regions or clusters.
- **10C. Likely (2026-11-08):** Infall is at most a different realm or galaxy, not the same place. Tie-ins and nods are fine, and things can occasionally be borrowed.
- **10D. Likely (2026-11-08):** Mawjig (from Infall: Materials Worth of Jigawatts) is explained in game as "A measurement of matter and energy used in advanced or physics bending technology." The game also gives the full name, Materials Worth of Jigawatts.
- **10E. Proposed (2026-11-08):** A regular Jig Drive isn't built to jump dimensions; a temporal variant might be. In Infall, rumours said an ancient relic, the Orb of Chulak (a Stargate SG-1 nod), could open a wormhole to another dimension.
  - **Likely (2026-11-09):** A Jig Drive is a jump drive for travelling through space, never between realms. Crossing into another dimension is ancient Chulak tech (the SG-1 nod), or needs its own name, such as a **Jig Phase Drive** (phasing into a different dimension). Jigawatt-powered tech in general is just Jigawatt-powered, not Jig Drive. (heromedel.)
  - **Ai-Generated-Proposal (2026-11-08):** Reaching a realm is a big, rare event (a relic, a temporal drive), and each realm plays by its own rules, so the late game can feel like a different game.
- **10F. Likely (2026-11-11):** Mawjig is high-tech, physics-bending technology, not witchcraft, so its tech isn't named like spells or curses. (heromedel didn't like "Hex".) The Hex Repeater became the **Flux Repeater**: its orbs leave enemies **unstable**. The Mawjig Resonance tiers are now Destabilize, Cascade and Meteor Lure.
- **10G. Likely (2026-11-11):** A beacon is a jump beacon: it guides Jig Drives from cluster to cluster. Nobody touches one, and it isn't a Mawjig object. Raw Mawjig turns up in things like a reactor core spilled from a wreck. Events and text keep to what things would really be and do. (heromedel, on the 0.5 "Mawjig Beacon" event.)

## 11. Playtest Refinements (builds 0.2.2 and 0.3)

- **11A. Likely (2026-11-08):** A Salvage Crate is three reels whose faces add up to the number of upgrades. Zeros outnumber ones, which outnumber twos, and the last reel has no zeros, so every crate gives 1 to 6 with no jumps. (heromedel's design.)
  - **Ai-Generated-Proposal (2026-11-08):** (Retuned in 11Y.) Reels of six 0s, three 1s and one 2, then eight 1s and two 2s: 1 = 28.8%, 2 = 36%, 3 = 24%, 4 = 9%, 5 = 2%, 6 = 0.2%, average 2.2. The crate screen lists what every upgrade does.
- **11B. Likely (2026-11-08):** Lucky Salvage reads "Crates have improved odds": the first reel loses its zeros (at least 2; average 2.6 since 11Y).
- **11C. Likely (2026-11-08):** The in-game encyclopedia is called the Guide to Guardians. Explanations such as Mawjig live there rather than on working screens.
  - **Ai-Generated-Proposal (2026-11-08):** Lore, how-it-works, Resonance and special conditions are always there; enemies, bosses, tech and fusions fill in as you meet, beat or unlock them.
- **11D. Proposed (2026-11-08):** Tractor Beam is a visible beam that reels in semi-nearby drops, as long as it doesn't clutter the battlefield.
- **11E. Proposed (2026-11-08):** Star Cluster's capture trope works without lives: a clone enemy scans you and projects a hologram. Kill the clone, or break the projector's shell and pick up the projector, which turns the clone to your side. An arrow points at the projector, green like a pickup. (heromedel's idea.)
  - **Ai-Generated-Proposal (2026-11-08):** The clone copies a weaker version of your current build (your main weapon and one other tech). Built in 0.4: it wears your gear, fires a hologram copy of your main weapon, and turns your Swarm Pods on you if they're online.
  - **Likely (2026-11-08):** It's a rare surprise, not a regular: about 1 in 4 Star Cluster planets. It's still named on the planet card. More mini-bosses join each mission type's pool.
- **11F. Likely (2026-11-08):** The ship and mech look different depending on the frame and what's equipped.
- **11G. Ai-Generated-Proposal (2026-11-08):** Themed branches play harder than the route beside them and their prize planet is a Hazard, so the optional path is the riskier one (supports 9G).
- **11I. Likely (2026-11-08):** The last boss drops the mission's loot (the planet's blueprints) as a prize; the stage continues until you grab it, then ends with the usual results. (heromedel's idea.)
  - **Ai-Generated-Proposal (2026-11-08):** The prize drifts to you after 3 seconds. After the boss falls, levels and crates no longer offer upgrades; each is banked as an extra blueprint of the planet's tech.
- **11K. Likely (2026-11-09):** Auto-aim for the mech is an accessibility option, off by default: Settings, "Auto-aim (mech): Off > On". Without it the mech faces where you aim, or where you move.
- **11L. Likely (2026-11-09):** When a mission opens with a radio line, the enemies hold back until it's read. (heromedel's idea: a delay before enemies rush in.)
- **11M. Likely (2026-11-09):** The frame lives in a Dropship. Each mission opens with it turning into a ship and launching from the bay, then arriving: straight into space, down to a planet and landing as the mech, or walking into a dungeon as the mech. Missions end with it returning to the Dropship. Inspired by The Guardian Legend's transitions, not a copy. (heromedel's idea.)
  - **Ai-Generated-Proposal (2026-11-09):** Each transition runs 2.5–4.5 s and a tap skips it. Chains get their own (diving down the fissure, bursting up out of the dungeon), and a loss ends with the Dropship towing the wreck aboard: recovered, not dead. Route-event choices show just the action, no hint (heromedel).
- **11N. Likely (2026-11-09):** Auto-fire can be turned off in every mission type: Settings, "Auto-fire: On > Off". (heromedel's request.)
  - **Ai-Generated-Proposal (2026-11-09):** Off, weapons fire while you steer the ship or hold the mech's aim stick, or hold a fire key or trigger. Support tech (pods, lantern, halo) keeps working on its own.
- **11O. Ai-Generated-Proposal (2026-11-09):** The pause menu has the music and sound sliders and the in-mission accessibility toggles (screen shake, glowing bullets). Auto-aim and auto-fire stay on the Settings page, since they apply from the next mission.
- **11P. Rejected (2026-11-09):** Ricochet shots that miss leave the screen and come back from out of view. (heromedel: "I think the ricochet shots are dumb"; replaced by Chain Bolts, 13W.)
  - **Ai-Generated-Proposal (2026-11-09):** Each flies 25–90 px out of view, then comes back the way it came, turned up to about 45 degrees as if off a round rock, at 70% damage. Planet and dungeon walls still bounce where you can see.
- **11Q. Ai-Generated-Proposal (2026-11-09):** If the last boss falls to your shots while your wreck is still burning, you traded with it: the mission counts as won and the prize is yours.
- **11R. Likely (2026-11-09):** The command center's pages are tabs along the top and the planet card is a strip under the star map, so the map gets the full width. (heromedel's idea.)
  - **Ai-Generated-Proposal (2026-11-09):** The map zooms out a little on short screens so a whole region fits top to bottom, and each region's name stays pinned inside the view.
- **11S. Likely (2026-11-09):** Banners stay up long enough to read comfortably: 1.2 s was too fast even for a fast reader. (heromedel.)
  - **Ai-Generated-Proposal (2026-11-09):** 2 s plus a little per letter, at most 3.2 s.
- **11T. Ai-Generated-Proposal (2026-11-09):** Each risky card has its own price, so taking one never makes another free (heromedel spotted Glass Reactor and Blood Pact both costing the shield). Blood Pact: kills repair armor, but two seconds without a kill bleeds armor away, never below a third.
- **11U. Likely (2026-11-09):** A mission in progress autosaves every few seconds, and if the browser closes mid-mission, the next start offers to continue it. (heromedel.)
  - **Ai-Generated-Proposal (2026-11-09):** Every 5 s (and when the tab loses focus) the checkpoint saves how the mission was launched and every input so far; continuing rebuilds the mission and fast-forwards the deterministic simulation through the inputs, then resumes paused. Abandoning settles it like the pause menu's abandon, so a loss still pays. A checkpoint from an older build can't be replayed, and the player is told so.
- **11V. Likely (2026-11-09):** Upgrade cards can't be picked by accident. (heromedel.)
  - **Ai-Generated-Proposal (2026-11-09):** A pick is a deliberate tap: it starts on the card, at least half a second after the cards appear, and doesn't slide more than a little.
- **11W. Likely (2026-11-09):** The special can be fired by a gesture as well as the button: tap, then tap again and hold; the second touch aims (or steers) as usual and fires the special when it lifts. Settings: "Double-tap special: On > Off". (heromedel's gesture.) The mech also keeps its aim for 0.8 s after the aim stick is let go.
- **11J. Likely (2026-11-08):** Bullets that glow in the dark are an accessibility option, not a rule: Settings, "Bullets glow in the dark: Off > On".
- **11H. Ai-Generated-Proposal (2026-11-08):** Explosive Resonance III is renamed Wildfire, and burning effects never mention the ground, since many fights are in space.

- **11Y. Likely (2026-11-11):** Salvage Crates came too often and pushed heromedel into a different build than the one he was going for. They now lean mostly toward deepening the tech you have, and only rarely unlock something new. (heromedel.)
  - **Ai-Generated-Proposal (2026-11-11):** Each crate upgrade levels tech already online, weighted toward what you've levelled most; 15% of the time it brings new tech online instead (always, if nothing online can level). Crates are rarer and a little smaller: elites drop one 28% of the time (was 49%), planet supply pods land every 80–105 s with six raiders (was 38–50 s with four), and the reels are 7 zeros, 2 ones and 1 two on the first two and 9 ones and 1 two on the last: 1 = 44%, 2 = 30%, 3 = 19%, 4 = 5%, 5 = 1.3%, 6 = 0.1%, average 1.9. The reels are now rolling slot-machine drums that blur, then settle on their faces with a bounce.
- **11X. Proposed (2026-11-09):** Real environmental hazards on some planets: meteor swarms that can hit you or your shields (and maybe enemies and theirs), and ion storms whose pulses knock one or two pieces of equipment offline for 15 to 30 seconds. (heromedel's idea, saved for the roadmap: Plan H.)

## 12. Build 0.3 Content

- **12A. Ai-Generated-Proposal (2026-11-08):** Each mission type has two bosses and (from build 0.3.2) three mini-bosses; a planet's pair is fixed by the map and shown on its card. The first planet always has the classic pair, and the Tempest Run ends on the Bounty Hunter Ace.
- **12B. Ai-Generated-Proposal (2026-11-08):** Elites with a twist (shielded, splitting, mirrored) appear from planet 2, more each region, doubled by Bounty Hunters. Mirrored elites appear from region 2 on.
- **12C. Ai-Generated-Proposal (2026-11-08):** New tech: Option Pods (renamed Drone Pods in 0.5.1, heromedel) and Soul Lantern (support), Ion Cannon and Thruster Explosion (special), with the Starbreaker and Wraith Drive fusions. Thruster Explosion is built from heromedel's Rule of Cool example (1A).
- **12D. Ai-Generated-Proposal (2026-11-08):** Route events on the way to a planet: a choice with a risk, paying out at once or shaping the mission.
  - **Likely (2026-11-11):** The 0.5 events weren't good enough: "touch something for a bonus" with no real risk and the only other option doing nothing, the same few events again and again, and no way to see what you got once the mission started. (heromedel.)
  - **Ai-Generated-Proposal (2026-11-11):** Rebuilt in 0.6.1 as twelve events where most options cost something (Armor at the start, crystals, blueprints, a harder mission) and pay something different; build-gated options in cyan that appear only with the right tech equipped (a Shield Generator boards the rigged derelict safely, a special blasts through the ambush, a Coolant Loop vents through the ion squall); the last event met is never met again next; and the mission opens with banners naming the event and exactly what it changed, including the names of any cards it fitted. Events have their own cold-review captures now.
- **12E. Ai-Generated-Proposal (2026-11-08):** Big moments freeze the action for a heartbeat (boss kills, elites, Resonance tiers, fusions), and each genre has its own instruments.

## 13. Build 0.6: Hits That Matter

(Note) The full spec, with every number and the research behind it, is `docs/OVERHAUL_0_6.md`; its points keep
these letters. Plan B (build 0.6.1: Load, Mawjig Output, heat, frame identities, the other plates) is points 21A–21H
there.

- **13A. Proposed (2026-11-09):** Health is a hidden fine-grained number, read as hits. (heromedel.)
  - **Likely (2026-11-09):** One pool, called **Armor**. (heromedel.)
- **13B. Proposed (2026-11-09):** The starter has no shield and about 6 hits, plus built-in plating worth 2 more. (heromedel.) Vanguard: 60 + 20.
- **13C–13I. Ai-Generated-Proposal (2026-11-09):** Five hit sizes (5, 10, 15, 20, 25); bigger hits each region; 1 s of immunity after a hit; smaller hitboxes; repairs +15 and rarer (13G Proposed, heromedel); bosses at 70% health; difficulty targets in hits.
- **13J. Likely (2026-11-09):** Two new slots, Generator and Plating. (heromedel.) **13K:** the Shield Generator, Arc Blade, Mirror Aegis and Soul Lantern share the Generator slot.
- **13L, 13M. Proposed (2026-11-09):** Plating is the frame's outer armour, mostly basic, named with intent; each plate levels up in its own way. (heromedel.)
- **13N–13Q. Ai-Generated-Proposal (2026-11-09):** Halo saws break after three bullets; Reflex Blade fuses Arc Blade with Graze Engine; Capacitor Discharge on any hit; cards retuned for an 80-Armor pool.
- **13Y. Ai-Generated-Proposal (2026-11-10):** Build 0.6.1 (Plan B, points 21A–21I of the spec): Max Load and Mawjig Output as pips in the Hangar, heat and vents for overclocked builds, the Coolant Loop and Auxiliary Generator, frame tiers bought with Frame Blueprints, and eight new plates from planets, bosses and branches.
- **13R, 13S:** Frame Armor; built-in parts are bonuses on top (Proposed, heromedel). **13T:** the planet 3 lesson gives the Shield Generator (9C). **13V:** a fresh save (Proposed, heromedel). **13W:** Chain Bolts replace Ricochet (Proposed, heromedel). **13X:** auto-fire off by default (Proposed, heromedel).

## Decision Log

| Date | Points | Decision |
|---|---|---|
| 2026-11-08 | 1A | Features and abilities follow the Rule of Cool, with its definition. |
| 2026-11-08 | 1B, 1C | Lean into the tropes; power-ups must be interesting, not plain dash/energy upgrades. |
| 2026-11-08 | 2A–2C | Rebuild in Godot for web, hosted on GitHub Pages and playable on iPad mini; earlier prototype is reference only. |
| 2026-11-08 | 3A, 3B | Agree the basics, then Claude builds freely and checks in with playable builds tested by its own playtesters. |
| 2026-11-08 | 3A | Clarified: building freely never skips discuss, plan and permission. |
| 2026-11-08 | 3C | Push to Claude's own branch first; ask before pushing to `playtest`. |
| 2026-11-08 | 3D | heromedel's examples illustrate ideas; they aren't specs to copy or limits. |
| 2026-11-08 | 4A–4D | Five testers including a first-impressions visual tester; a play log as good as watching; player behaviour isn't automatically a problem. |
| 2026-11-08 | 5A–8D | Concept, mission types, equipment and co-op recorded from the original idea message and this session's discussion. |
| 2026-11-08 | 9A–9H | Build 0.2 plan approved: intentional difficulty, five-minute stages, lesson planets, losses that still pay, radio officer, enemy traits, hard branches, strategic upgrades. |
| 2026-11-08 | 10A–10E | Subtitle; what realms are; Infall as a separate realm with nods; how Mawjig is explained; how dimensions might be reached. |
| 2026-11-08 | 10A, 10B | Subtitle and the meaning of realms set to Decided; keeping the word for realms only is Likely. |
| 2026-11-08 | 10D, 11A–11H | Playtest refinements: three-reel crates, Lucky Salvage odds, the Guide to Guardians with Mawjig's full name, a visible Tractor Beam, the clone-and-projector capture idea, frames that show their gear, harder themed branches, Wildfire. |
| 2026-11-08 | 12A–12E | Build 0.3 content built from the approved list: frame gear, new bosses, elites, new tech, route events, big moments, genre music. |
| 2026-11-08 | 11E, 11I, 11J | The Clone Projector becomes a rare surprise; the last boss drops a prize you collect before the mission ends; glowing bullets become an accessibility option. |
| 2026-11-09 | 6G, 11K, 11L | First chained missions built; mech auto-aim becomes an accessibility option; enemies hold back while the opening radio line is read. |
| 2026-11-09 | 11M | The Dropship and its launch, arrival and return transitions around every mission. |
| 2026-11-09 | 11N to 11Q | Auto-fire becomes an option in every mode; options on the pause menu; Ricochet comes back from off screen; a boss that falls as you do counts as a win. |
| 2026-11-09 | 9H | Resonance tiers made obvious (card badge, splash on pick, frame glow) and the flat tiers reworked into visible effects. |
| 2026-11-09 | 11R to 11T | Tabs on top and the planet card under a full-width star map; banners that stay up long enough to read; risky cards with their own prices. |
| 2026-11-09 | 11X | Environmental hazards (meteor swarms, ion storms) saved as an idea: ROADMAP Plan H. |
| 2026-11-09 | 11U, 11V | Missions autosave and can be continued after the browser closes; no accidental upgrade picks. |
| 2026-11-09 | 5E, 7G | A real transformation between forms (spin as a setting while it's compared); fusions stay at max level if they're impressive enough. |
| 2026-11-09 | 4F | A wording checker for player-facing text. |
| 2026-11-09 | 4E | Cold reviews in small, focused batches; every finding triaged into the review log. |
| 2026-11-09 | 10E | A Jig Drive only jumps through space; crossing realms is ancient Chulak tech or a Jig Phase Drive. |
| 2026-11-09 | 1D | Alternatives offered side by side are never the same kind of ability; a dash or ram on its own is fine. |
| 2026-11-09 | 3E | Hard Rule: only real questions; never invent questions, end on them by habit, or re-ask decided points. |
| 2026-11-09 | 13A–13X, 11P | Build 0.6 built: hits that matter, the Generator and Plating slots, the Shield Generator, Chain Bolts replacing Ricochet. |
| 2026-11-10 | 13Y | Build 0.6.1 built: Load and Output, heat, power parts, frame tiers, the other plates. |
| 2026-11-11 | 10F | Mawjig tech is physics bending, not witchcraft: Hex becomes Flux, hexed becomes unstable. |
| 2026-11-11 | 7D, 13A | From the design review: the Generator part starts online; the Armor bar's cells are this planet's plain bullet; the Hangar says how often an overclocked build vents. (Drone Pods moving to the weapon slot was reverted: heromedel wants them beside the homing Swarm Pods.) |
| 2026-11-11 | 10G | Beacons are jump beacons for Jig Drives; the "Mawjig Beacon" event became a Loose Mawjig Core and a Damaged Jump Beacon. |
| 2026-11-11 | 12D | Route events rebuilt: real trade-offs, build-gated options, no repeats, and the mission announces what changed. |
| 2026-11-11 | 8E | Mawjig Crystals, a daily check-in and Derelict Dives in a Supply Depot tab. |
| 2026-11-11 | 11Y | Crates deepen your build, are rarer and smaller, and roll like real slot reels. |
