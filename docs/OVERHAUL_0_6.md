# Build 0.6: Damage, Loadout and Frames (design draft for review)

(Note) Draft for heromedel's review, written 2026-11-09 after the research below. Nothing here is built. Once
reviewed, the agreed points move into the GDD as section 13 with their tags, and this file becomes the build plan.
Every point is Ai-Generated-Proposal unless it names heromedel's words and carries their tag.

Based on: 33 points. 2 agreed (the two new slots, the Armor name), 11 proposals (heromedel's Proposed direction),
20 filled in here (6% / 33% / 61%). Revised the same day after a second research pass on frames, parts and stats.

## Why

(Note) From the code audit, 2026-11-09:

- The starter Vanguard has one pool of 155 (110 armor plus a 45 shield that refills after 2.5 s). On planet 1
  Standard, a bullet does 7.6, so the **21st** clean hit is the first lethal one, and Second Wind adds another.
- After a hit you are immune for only 0.45 s, so a ring of bullets can land a hit every half second.
- Nothing raises max armor or max shield, so a mid-game build survives better only through tech that erases,
  reflects or swallows bullets: Arc Blade, Orbital Halo, Mirror Aegis, Soul Lantern, Overheat Core's vent and
  every special. Almost all of the defence is also offence, and you never have to choose between them.
- Repairs are +25 (a sixth of the pool). Planet missions place 3, and dungeons drop one in 30% of cleared rooms.

## Research summary

- **The Binding of Isaac:**
  - Hit budget: 3 hearts, half-heart hits early, so about 6 clean hits.
  - From the Womb on, every hit doubles to a full heart. The game gets harder by making hits bigger, not the pool
    smaller.
  - About 15% of room clears drop a heart.
  - Holy Mantle blocks one hit per room.
  - Clean boss fights are rewarded (devil deal chance) without adding health.
- **Enter the Gungeon:**
  - 3 hearts, 6 hits.
  - An armor piece blocks one hit of any size and fires a free Blank as it breaks.
  - About 7% of rooms drop half a heart.
  - A no-hit boss fight gives a Master Round (+1 heart container).
- **Hades:**
  - 50 HP at the start.
  - Damage resistance per pick stays small (5–12.5%). The one large cap (80%) belongs to an accessibility mode.
  - Defensive boons take the same slots as damage boons.
- **Risk of Rain 2:** armor works as damage × 100 / (100 + armor). Each point adds the same effective HP and it
  never reaches immunity. Chance items stack as 1 − 1 / (1 + 0.15 × stacks) for the same reason.
- **Effective HP:** effective HP = HP / (1 − reduction).
  - Adding reductions together (25% four times) reaches immunity.
  - Even multiplying them (0.75⁴ = 68%) still more than triples effective HP.
  - Reductions from one family have to be capped or hyperbolic.
- **Armored Core 6:**
  - Over the legs' Load Limit, or over the generator's EN Output, the AC can't sortie at all.
  - Going over the Arms Load is allowed, at a cost.
- **Older Armored Core and MechWarrior:**
  - Heat comes in steps: a warning, then losses (energy, AP), then shutdown.
  - MechWarrior's Override keeps you running at the cost of internal damage.
- **Shmups:**
  - A life bar works in bullet hell when the hitbox is much smaller than the sprite, often shown as a dot.
  - Shields and armor soak the hits you can't avoid. A last-moment save, such as a deathbomb, softens the step from
    attrition to death.
  - Telegraphs need to land well inside reaction time: about 100 ms to notice, and anything slower than about
    200 ms feels sluggish.
- **Second pass, frames and parts (2026-11-09):**
  - Armored Core 6: two hard sortie limits (leg load, generator output) and one soft one (arms load). Light,
    medium and heavy aren't classes; they come from parts, and the parts that matter change how you move (hover,
    jump, no jump) as well as the numbers. Selling a part back refunds it in full so players experiment.
  - MechWarrior Online: a chassis' fixed hardpoints give it identity more than percentage quirks. Hidden "ghost
    heat" is widely resented.
  - FTL: every system bar needs a reactor bar; the Kestrel starts with exactly 8 of 8 used. The Stealth cruiser
    swaps shields for a cloak. Critics note power is rarely re-routed mid-fight, so the budget matters most when
    building.
  - Into the Breach: reactor cores as countable pips; a weapon on the "wrong" mech costs more cores rather than
    being banned. Its designers found animated previews worked where text descriptions failed.
  - Roguelite progress: unlocks that add options (FTL layouts, Hades aspects) age better than flat stat gains
    (Rogue Legacy 2's rising prices were its biggest criticism). Opt-in difficulty (Hades' Heat, Dead Cells' Boss
    Cells) hands challenge back.
  - Optional overheat is fun when the player chose it, running hot is rewarded (Darktide's Peril, Deep Rock's
    unstable overclocks), venting is a skill and the heat shows on the character; it's annoying when hidden or
    when it locks out control for long.
  - People count up to about four things at a glance; past that they have to count. Six Armor ticks read better
    grouped in threes.
- **Not confirmed by any source:** the base length of Isaac's and Gungeon's immunity after a hit.

## 13. Damage, Loadout and Frames

### Health and damage

- **13A. Proposed (2026-11-09):** Health is a hidden fine-grained number, not pips, so multipliers and stacking
  still work. A typical hit is 10, so 60 HP is "six hits" but can still take a 5, a 15 or a +10%. (heromedel.)
  - **Likely (2026-11-09):** The pool is called **Armor**: the mech is power armor, and the name reminds you someone
    is inside it. (heromedel.) The old armor and shield pools merge into it.
  - **Ai-Generated-Proposal:**
    - The bar has a tick every 10, so you read it as hits; every third tick is taller, so six hits read as two
      groups of three at a glance.
    - A hit flashes the ticks it took away.
- **13B. Proposed (2026-11-09):** The starter frame has no shield and about 6 hits. (heromedel.)
  - **Ai-Generated-Proposal:** Vanguard has 60 Armor. Planet 1 Standard's bullets do 7, so the starter can take about
    8 hits there and about 6 by the region gate.
- **13C. Ai-Generated-Proposal: one damage scale.**

  | What hits you | Base damage | Hits from 60 |
  |---|---|---|
  | Chip: acid tick, needle, wall scrape | 5 | 12 |
  | Normal bullet, small enemy contact | 10 | 6 |
  | Large enemy contact, mines, traps | 15 | 4 |
  | Elite or boss body contact | 20 | 3 |
  | Boss heavy attack (lasers, bombs, shockwaves) | 20–30, always telegraphed | 2–3 |

  - The current contact values (8 to 22) snap to these steps.
  - The hazards that ignore scaling today (acid, wall scrape, Brood Queen acid) start scaling with the planet like
    everything else.
- **13D. Ai-Generated-Proposal: harder means bigger hits.** As in Isaac's Womb, later regions make hits bigger in
  steps: region 0 ×1.0, region 1 ×1.3, region 2 ×1.6. Frame upgrades (13O) grow the pool to keep pace.
  - Danger, Hazard routes and Threat keep scaling hits as they do now: Casual ×0.65, Veteran ×1.3.
  - Nothing shrinks the pool.
- **13E. Ai-Generated-Proposal: immunity after a hit.**
  - Immunity after a hit goes from 0.45 s to 1.0 s, and to 1.3 s for hits of 20 or more. A bigger hit buys more
    recovery time.
  - The frame blinks the whole time.
  - With six hits, this keeps one bad volley from taking three of them at once.
- **13F. Ai-Generated-Proposal: a smaller hitbox.** The hitbox shrinks: the ship from radius 12 to 8, the mech from
  15 to 10. A 6-hit budget is only fair if a shot that clips the art's edge misses.
- **13G. Proposed (2026-11-09):** Repairs come less often. (heromedel.)
  - **Ai-Generated-Proposal:**
    - A repair is +15 Armor, a hit and a half.
    - Planet missions place 2. Dungeon rooms drop one 15% of the time (Isaac's rate), plus the shrine.
    - Clearing a mini-boss always drops one.
    - Field Repair and Salvage Cache are scaled to the new pool.
    - Blood Pact and Vampiric Plating are retuned so they heal in fractions of a tick.

### Slots

- **13H. Likely (2026-11-09):** Two new component slots: **Generator** (not only shields; the Arc Blade or Mawjig
  devices could go here) and **Plating**. (heromedel: "I am ok if we add one more new component slots".)
  - **Ai-Generated-Proposal:** Seven slots: main, weapon, weapon, support, special, generator, plating.
- **13I. Ai-Generated-Proposal: the Generator slot.** It holds the parts whose job is staying alive or holding
  ground, so that kind of defence competes for one slot:

  | Generator part | What it does |
  |---|---|
  | Shield Generator (new, blueprints like any tech) | Blocks one hit of any size. As it breaks: 1 s of immunity, and Capacitor Discharge still fires from it. Recharges 12 s later (8 s at level 5). Fork A: two charges. Fork B: a breaking shield lets go a Blank that clears nearby bullets. The frame shows the shield's state. |
  | Arc Blade (moves from weapon) | Unchanged. You take the blade instead of a shield. |
  | Mirror Aegis (moves from support) | Unchanged. |
  | Soul Lantern (moves from support) | The Mawjig device: wisps that swallow bullets. |

  - The weapon slots keep Swarm Pods, Orbital Halo and Starfall.
  - The support slot keeps Graze Engine, Overheat Core and Option Pods, and gains the cooling parts (13N).
  - The planet 3 lesson (GDD 9C) teaches the Generator slot. A starter with no shield finally makes the lesson
    matter.
- **13J. Proposed (2026-11-09):** Plating is just the frame's outer armour. Most plates are basic, trading Armor
  against weight and speed, like light and heavy, but with better names and occasionally better thought. A few
  rare ones can be strange and game-changing, and only rare or carefully balanced ones may touch attack (most
  defensive parts should not also be offence). Names are chosen with intent: an acronym that means something, a
  nod to another genre or to Infall, or a meaning inside this game. No dash, no ram. (heromedel.)
  - **Ai-Generated-Proposal (numbers are placeholders):**

    | Tier | Plate | What it does | Why the name |
    |---|---|---|---|
    | Starter | **DSP-1 Drop Plate** | Plain armour, weight 2 | Dropship Standard Plating, version 1: what your own Dropship prints (11M) |
    | Basic | **QRF Shell** | −10 Armor, weight 1, a little faster | Quick Reaction Force: the unit sent in first and fast |
    | Basic | **Jig-Weave Composite** | +15 Armor, weight 3 | Jigawatt-powered fibres woven through the armour (Infall) |
    | Basic | **Lunarium Bulk Plate** | +30 Armor, weight 4, a little slower | Mecha anime's wonder-alloys (heromedel: "sounds cool") |
    | Uncommon | **Mirrorwork Half Plate** | Lasers and beams do half | Cut from the Mirror Dreadnought's plates; could be its prize |
    | Uncommon | **Crusher-Rated Plate** | Blasts and shockwaves do half | Rated to survive the Crusher Gate |
    | Uncommon | **Jigawatt-Lined Plate** | Strong for its weight, draws 1 Output | Charged armour, which is why it costs power. (heromedel: "a bit boring but close to decent"; name to improve.) |
    | Rare | **Jig Phase Plate** | A hit drains in over 3 s; half of it fades if no other hit lands meanwhile | Salvage from a Jig Phase Drive (10E): hits phase partly out of this dimension and arrive late (heromedel liked the idea) |
    | Rare | **Last Legend Plate** | Below a third of your Armor, weapons fire faster; less Armor overall | The Guardian Legend, and our own title (heromedel: "interesting") |

  - **Proposed (2026-11-09):** Each plate levels up during a mission in its own way, over several levels, not one
    upgrade. Plain "+Armor" levels are fine for the starter plate. (heromedel.)
    - **Ai-Generated-Proposal:** DSP-1: +10 Armor a level. QRF Shell: faster each level. Jig-Weave Composite: shrugs
      off one more chip hit (5 or less) per stage each level. Lunarium Bulk Plate: work-hardens, each hit survived
      adds 1 max Armor for the mission, and each level raises that cap. Uncommon and rare plates: their twist grows
      each level (Mirrorwork halves beams, then blocks them outright for a moment after a hit, and so on).

- **13K. Ai-Generated-Proposal: defence that is also offence, beyond the Generator slot.**
  - Orbital Halo's saws still eat bullets, but each saw shatters after eating 3 and regrows 3 s later.
  - Specials keep clearing bullets. They're the Blanks of this game: one per cooldown, a decision every time.
  - Graze Engine's Adrenal Mend fork heals in fractions of a tick.
  - Elite and boss bodies hurt (20), so meleeing a boss costs real Armor unless you dodge out after each swing.
- **13L. Proposed (2026-11-09):** Ricochet shots go. (heromedel: "I think the ricochet shots are dumb".) This
  replaces his own example in GDD 7F and drops 11P.
  - **Ai-Generated-Proposal:** Pulse Driver's fork A becomes **Chain Bolts**: a bolt that kills jumps to the next
    enemy in reach, up to three times, as a visible arc. It keeps fork A as the single-target fork, and nothing flies
    off screen.
- **13M. Proposed (2026-11-09):** Option Pods are renamed, e.g. **Drone Pods**. (heromedel.)

### Load, Mawjig Output and heat

- **13N. Proposed (2026-11-09):** Frames have a **Max Load** and a **Mawjig Output**. Parts weigh something, and
  powered parts draw output wherever they're fitted. Heat only matters when you go over your output on purpose
  (overclocking). Optional coolers add room to overclock, and auxiliary generators add output, in a different slot.
  (heromedel.)
  - **Ai-Generated-Proposal:**
    - **Max Load is a hard limit**, as in Armored Core 6. Launch is greyed out, with the reason given, until the
      build is under it.
    - **Output is a soft limit.** Going over it makes the build *Overclocked*, and only then does a heat bar appear in
      the mission.
    - Heat rises with how far over output you are, while powered parts work.
    - Steps:
      - At 70% heat, a warning.
      - At 100%, the frame **vents**: powered parts go offline for 3 s and heat drops to 40%.
      - Armor is never lost to heat, so an overheat costs tempo, not your life (attrition).
    - Weight and draw are fixed per part and Mk, never by in-mission level, so an upgrade you pick never breaks the
      build.
    - Support-slot parts:
      - **Coolant Loop:** cools faster.
      - **Auxiliary Generator:** adds output and weighs a lot.
    - **Proposed (2026-11-09):** With overheating in the game, auto-fire is off by default (Settings, "Auto-fire:
      Off > On"). (heromedel.)
    - **Overheat Core** becomes the overclocker's tech. Its vent fires on every overheat and grows with the heat you
      had built up. That way the name finally means what it says.
  - **Ai-Generated-Proposal (revised after the second research pass): counted in pips, not tons.**
    - Load and Output are small whole numbers shown as pips, the way FTL shows reactor power and Into the Breach
      shows reactor cores: a part weighs 1 to 4 pips and draws 0 to 3. At a glance on an iPad, you can count pips;
      "112 t of 120 t" you have to read.
    - The Hangar shows two pip rows, Load and Output. Pips past your Output turn orange and the row reads
      **OVERCLOCKED**, so going over is a visible choice and never a hidden penalty (MechWarrior Online's "ghost
      heat" is the cautionary tale: invisible penalties are resented).
  - **Ai-Generated-Proposal: the element decides the cost, so no part needs its own special rule.** Energy and Mawjig
    tech is light but draws power; Kinetic and Explosive tech is heavy and draws little or none. That ties the two
    meters to Resonance (GDD 9H): an energy build leans on Output, an explosive build leans on Load, and the frames
    that favour one or the other (13O) favour those builds.

    | Part | Element | Weight | Draw |
    |---|---|---|---|
    | Pulse Driver / Thunder Lance / Hex Repeater | E / E / M | 1 / 1 / 1 | 1 / 3 / 2 |
    | Swarm Pods / Orbital Halo / Starfall | X / K / M | 3 / 2 / 1 | 0 / 1 / 3 |
    | Shield Generator / Arc Blade / Mirror Aegis / Soul Lantern | E / E / E / M | 1 / 1 / 1 / 1 | 3 / 2 / 3 / 2 |
    | Graze Engine / Overheat Core / Drone Pods | K / X / K | 1 / 2 / 2 | 0 / 0 / 1 |
    | Coolant Loop / Auxiliary Generator | none | 2 / 3 | 0 / adds 3 |
    | Nova Bomb / Time Brake / Ion Cannon / Thruster Explosion | X / M / E / K | 2 / 1 / 2 / 2 | 0 / 3 / 3 / 0 |
    | DSP-1 Drop Plate / QRF Shell / Jig-Weave Composite / Lunarium Bulk Plate | none | 2 / 1 / 3 / 4 | 0 |

    - The starter build (Pulse Driver, Arc Blade, Nova Bomb, DSP-1 Drop Plate) is 6 Load and 3 Output on a
      12 / 9 Vanguard: room to grow.
    - A greedy mid-game build (Thunder Lance, Swarm Pods, Orbital Halo, Shield Generator, Drone Pods, Ion Cannon,
      Lunarium Bulk Plate) is 15 Load and 11 Output.
      - Over Load, so it can't launch.
      - With DSP-1 Drop Plate it's 13: still over by one. Swap the Halo for Starfall and it fits at 12, but now it
        draws 13 of 9 Output: four pips overclocked.
      - From there: drop a powered part, trade Drone Pods for an Auxiliary Generator, move to the Tempest, or run hot.
  - **Ai-Generated-Proposal: heat, in numbers to start tuning from.**
    - Heat only exists on an overclocked build. It rises 2.5% a second for each pip over Output while you fight;
      Coolant Loop takes away one pip's worth. Two pips over is an overheat about every 20 s; four pips over, every
      10 s.
    - The frame shows it: vents glow orange, then red, before it vents (Hawken drops its arms; heat on the frame
      reads faster than a bar).
    - The vent is short (3 s) and only switches off powered parts; unpowered weapons keep firing. Players who never
      overclock never see any of it.
    - Running hot is rewarded, not just allowed (Darktide's Peril, Deep Rock's unstable overclocks): Overheat Core
      pays off the hotter you run, and its vent blast grows with the heat you'd built.

### Frames

- **13O. Proposed (2026-11-09):** Frames differ in what they can carry: high output, high load, high speed, or a
  built-in feature such as mini missiles. They improve through frame upgrades, or a bigger frame raises the limits.
  The starter's death protection is a bit boring. (heromedel.)
  - **Ai-Generated-Proposal:**

    | Frame | Armor | Load | Output | Speed | Identity |
    |---|---|---|---|---|---|
    | Vanguard (starter) | 60, +20 built in | 12 | 9 | 300 | A simple beginner build: built-in extra plating worth 2 more hits, replacing Second Wind (heromedel, Proposed). Balanced, so either element fits. |
    | Tempest | 40 | 9 | 13 | 370 | Fast and fragile, the energy frame: Energy and Mawjig builds fit, and it has room to overclock. Afterimage stays. |
    | Bulwark | 90 | 16 | 6 | 250 | Carries anything but powers little: the Kinetic and Explosive frame. Fortress Field reflects a quarter of the bullets that hit its front, with no shield needed. |
    | Later frames | | | | | **Proposed (heromedel):** a built-in Arc Blade, a built-in shield, or built-in mini missiles. **Ai-Generated-Proposal:** one built to overclock, with high cooling. |

  - **Proposed (2026-11-09):** A built-in part is a bonus on top of the frame's slots, costing no Load or Output,
    paid for by the frame's other numbers, its rarity or how hard it is to get. Vanguard's built-in plating is the
    first example. (heromedel: "probably".) Each new frame trades something for its built-in part, so frames don't
    creep upward in power.
  - **Proposed (2026-11-09):** Frame upgrades use **frame blueprints**. (heromedel.)
    - **Ai-Generated-Proposal:**
      - Frame blueprints drop like tech blueprints, from planets that show one on the card.
      - Each frame has three upgrade tiers. Each tier picks one of +1 Load, +1 Output, +10 Armor or better
        Cooling, so two Vanguards can grow differently. Tiers cost 3, 6 and 10 blueprints.
      - The caps are kept small on purpose. Research on Rogue Legacy 2 and Hades shows flat stat growth erodes
        difficulty; new frames and choices keep progress interesting without making planet 1 trivial later.
      - The Threat setting (Standard > Veteran > Casual) stays the way to make the game harder or easier on purpose,
        like Hades' Heat or Dead Cells' Boss Cells.

### Difficulty targets

- **13P. Ai-Generated-Proposal:** GDD 9A's targets are rewritten in hits, for an average player on Standard:

  | Planets | Hits taken | Notes |
  |---|---|---|
  | 1 | 1–3 of about 8 | |
  | 2–3 | 3–4 of about 6–7 | |
  | 4–5 | 4–5 | A loss now and then |
  | Region gate | | About 1 in 4 attempts lost, as before |

  - Boss health comes down as fights get deadlier: about −30% at first, tuned with the average-player bot.

## What the overhaul breaks, and how to mend it

(Note) Planning pass, 2026-11-09, from reading the upgrade cards, Resonance tiers and fusions in the code
(scripts/data/upgrade_data.gd). All Ai-Generated-Proposal unless a line says otherwise.

- **13Q. Where the new parts come from.**
  1. The planet 3 lesson (GDD 9C, Likely: "Shields on planet 3") gives the **Shield Generator** instead of Mirror
     Aegis. That's what the lesson always meant, and with no shield on the starter it finally matters. Mirror Aegis
     becomes a find on a later planet like other tech.
  2. Plates and generator parts are blueprints like all tech (GDD 7A). The starter plate is in the kit; the basic
     plates drop from ordinary planets; each uncommon plate comes from the boss it's named after (Mirrorwork from
     the Mirror Dreadnought, Crusher-Rated from the Crusher Gate); the rare ones are themed-branch prizes.
  3. Starting kit: Pulse Driver (main), Arc Blade (generator), Nova Bomb (special), DSP-1 Drop Plate (plating).
     Both weapon slots and the support slot start empty, as two of them do now.
- **13R. Fusions that the new slots break.** Reflex Blade fuses Arc Blade with Mirror Aegis, and both now live in
  the Generator slot, so it could never be built. Proposal: Reflex Blade fuses Arc Blade with **Graze Engine**
  instead (a blade that lives on near misses), keeping its effect. Every other fusion still pairs parts from
  different slots.
- **13S. Resonance with no shield.** Capacitor Discharge (Energy II) fires "when your shield breaks", and most
  builds will have no shield. Proposal: it fires when **you're hit**, or when a Shield Generator breaks, so it works
  for everyone and stays a moment worth having.
- **13T. Upgrade cards that the new rules break or make too strong.**
  1. **Glass Reactor** costs your shield, which most builds no longer have. New price: your plate's Armor bonus is
     gone for the mission.
  2. **Vampiric Plating** heals per kill. Against a six-hit pool that's a lot of healing from killing, the
     defence-from-offence we're cutting. It's renamed (it isn't a plate) and heals a tenth of a hit per kill, at most
     one hit per stage.
  3. **Overclocked Servos** keeps what it does (faster, and ramming hurts enemies more than you). Only the name
     changes, since "overclocked" will mean running past your Output: **Juggernaut Servos**, after the
     unstoppable-charge trope. (Ramming is fine; see GDD 1D.)
  4. **Field Repair** heals 40% of max Armor, two and a half hits from 60. Kept, but it can't be taken twice in one
     mission.
  5. **Blood Pact** and **Shrapnel Skin** are kept and retuned to the new numbers.
- **13U. Boss length.** With six hits instead of twenty, boss fights at today's 40–120 s would be gruelling. Boss and
  mini-boss health comes down about 30% to start, tuned with the average-player bot until a planet-1 boss runs
  30–45 s and a gate boss 60–90 s.
- **13V. Proposed (2026-11-09): saves start fresh.** heromedel would reset anyway, so there's no migration: 0.6
  starts a new save and says so on the title screen, and a mission checkpoint from an older build is cleared.

## Build plan (once approved)

(Note) Ai-Generated-Proposal: two builds rather than one, so the new damage model can be played and tuned before
the bigger Hangar systems sit on top of it.

### Plan A: build 0.6, hits that matter

1. **Damage model** (13A–13G): Armor as one pool with hit ticks, the damage scale, immunity after a hit, the smaller
   hitbox, rarer repairs.
2. **Generator and Plating slots** (13H–13J): the Shield Generator, the four basic plates, Arc Blade, Mirror Aegis
   and Soul Lantern moved, the planet 3 lesson giving the Shield Generator (13Q).
3. **What it breaks** (13K, 13R–13T): Orbital Halo saws, Reflex Blade, Capacitor Discharge, the cards.
4. **Frames' new Armor and Vanguard's built-in plate**, without Load and Output yet. Chain Bolts; auto-fire off by
   default.
5. **Retune** (13P, 13U): boss health and the average-player bot re-targeted to hits.
6. **A fresh save** (13V), the Guide and every changed text through the wording checker, rules tests updated.
7. **Testers:** cold reviews of the Hangar and one planet-3 run; one longer blind playtest, since it's a major change.

### Plan B: build 0.6.1, building a frame

1. **Load and Mawjig Output** in pips, the Hangar's two rows and the launch rule (13N).
2. **Overclock heat**, venting, the Coolant Loop and Auxiliary Generator, the Overheat Core rework.
3. **Frame identities**: Load, Output and speed per frame, frame blueprints and upgrade tiers (13O).
4. **Uncommon and rare plates** (13J) as boss prizes and themed-branch rewards.
5. Tested the same way, with a cold review of the Hangar's two meters.

## Questions

- **Q3.** Build it in two steps (0.6: hits that matter; 0.6.1: building a frame), or all at once as 0.6?

- **Q1.** Answered: Vanguard gets built-in extra plating, 2 hits (13O).
- **Q2.** Answered: frame upgrades use frame blueprints (13O).
