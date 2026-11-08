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

## 4. Testing & Play Log

- **4A. Likely (2026-11-08):** Claude keeps a test harness, a QA harness, a blind playtester (plays like a new player using only what's on screen) and a break-it playtester (does everything wrong, tries to break or exploit the game).
- **4B. Likely (2026-11-08):** A third playtester checks visuals, first impressions and assumptions by describing what it sees, cold. It catches things like a sword arc that looks nothing like a sword arc.
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
- **6H. Proposed (2026-11-08):** Every boss is a set piece: its own body, a warning intro, phases that change the arena, and its own mechanic. (Claude's idea; heromedel: "sounds cool".)

## 7. Equipment & Upgrades

- **7A. Proposed (2026-11-08):** Loot is Tech Blueprints. About 3 unlock a weapon or ability, and an increasing amount, following a formula, upgrades it.
- **7B. Proposed (2026-11-08):** A limited number can be equipped before a mission, either by category (e.g. Weapon, Armor, Passive, Special) or by Armored Core-style slots (e.g. back-mounted shield, shoulder chaingun, primary weapon in one hand, thruster/legs). Slots might complicate it.
- **7C. Proposed (2026-11-08):** Equipping doesn't give full power. Tech is upgraded during missions, like Vampire Survivors or Cell Survivor, probably with a point system, missable drops and occasionally a slot-machine upgrade.
- **7D. Proposed (2026-11-08):** Only the base weapon starts working in a mission, so base weapons are their own category.
- **7E. Proposed (2026-11-08):** Tech can draw on MechWarrior, Armored Core and The Guardian Legend, or be magic abilities described as Mawjig energy.
- **7F. Proposed (2026-11-08):** Upgrades fork a weapon into different behaviours (e.g. ricochet as an upgrade step of the starter weapon), and two pieces of high-level tech can fuse into a named fusion with a new effect. (Claude's idea; heromedel: "sounds cool".)

## 8. Rewards, Co-op & Extras

- **8A. Likely (2026-11-08):** No ads and no real money. The game is played instead of ad-driven mobile games.
- **8B. Proposed (2026-11-08):** A few mock mobile-game features such as rewards, gems and reward paths, maybe with fake in-game money.
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
