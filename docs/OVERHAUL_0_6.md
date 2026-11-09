# Build 0.6: Damage, Loadout and Frames (spec)

(Note) The spec for the 0.6 overhaul, settled with heromedel on 2026-11-09 and built in two steps: **Plan A (0.6)**,
hits that matter, then **Plan B (0.6.1)**, building a frame. Once built, these points move into the GDD as section 13.
Points carry heromedel's tag where he set the direction; the numbers and details that fill each one in are
Ai-Generated-Proposal, chosen from the research below and the code audit, and tuned with the average-player bot.
The game is semi-casual: every system here should read at a glance on an iPad, and depth comes from choices, not
from arithmetic.

## Why

From the code audit (2026-11-09):

- The starter has 155 armor and shield to burn, and a planet 1 bullet does 7.6. The 21st clean hit is the first
  lethal one, and Second Wind adds another.
- Immunity after a hit lasts 0.45 s.
- Nothing raises max armor, so a stronger build survives only through tech that erases, reflects or swallows
  bullets. Almost every defence is also offence, so there's never a choice between them.
- Boss fights run 40–120 s, because there was never any danger in drawing them out.

## Research it rests on

- **Hit budgets:**
  - The Binding of Isaac and Enter the Gungeon both start you at about 6 hits.
  - Isaac makes later floors harder by doubling hits, not by shrinking the pool.
  - Both pace healing hard: Isaac drops a heart from about 15% of rooms, Gungeon from about 7%.
- **Stacking:**
  - Reductions that add together reach immunity, and even multiplying reductions stack fast.
  - Small, capped resistances (Hades, 5–12.5% a pick) and one-hit blockers (Holy Mantle, Gungeon armour) keep a hit
    budget meaningful.
- **Budgets:**
  - Armored Core 6 blocks a sortie over its load and energy limits, and its parts change how you move.
  - FTL and Into the Breach show power as countable pips.
  - Hidden penalties (MechWarrior Online's "ghost heat") are resented.
- **Optional heat:** fun when the player chose it, running hot pays off (Darktide, Deep Rock Galactic) and the heat
  shows on the character (Hawken).
- **Progress:** unlocks that add options age better than flat stat growth (FTL layouts and Hades aspects, against
  Rogue Legacy 2's rising prices). Opt-in difficulty (Hades' Heat) hands challenge back. Our Threat setting already
  does this.

# Plan A: build 0.6, hits that matter

## Armor and damage

- **13A. Proposed (2026-11-09):** Health is a hidden fine-grained number, so multipliers and stacking still work, read
  as hits. (heromedel.)
  - **Likely (2026-11-09):** One pool, called **Armor**: the mech is power armour with someone inside. The old
    armor and shield pools merge. (heromedel.)
  - The bar has a tick every 10 and a taller tick every 30, so it reads as hits in groups of three.
  - A hit flashes the ticks it took.
- **13B. Proposed (2026-11-09):** The starter has no shield and about 6 hits, plus built-in plating worth 2 more.
  (heromedel.)
  - **The Vanguard has 60 Armor plus 20 built in: 80.** On planet 1 a bullet does 7, so it can take 11 clean hits there.
  - By the region gate a bullet does 11, so it can take 7.
- **13C. One damage scale.** Every source snaps to one of these steps, then scales with the planet (13D):

  | What hits you | Base damage |
  |---|---|
  | Chip: acid tick, needle, wall scrape, mirrored-elite bounce | 5 |
  | Bullet, small enemy contact, mine | 10 |
  | Large enemy contact (Brute, Warlord, Mimic, Knight), rune trap, supply pod impact | 15 |
  | Elite, boss or boss-part body contact | 20 |
  | Boss heavy attack: lasers, bombs, shockwaves, always telegraphed | 25 |

  The sources that ignore scaling today (acid, wall scrape, Brood Queen acid) scale like everything else.
- **13D. Harder means bigger hits.** In region 0, the hand-tuned planet steps stay (0.7 to 1.1). Each later region
  multiplies hits in steps:

  | Region | Hits ×, on top of each region's planet steps |
  |---|---|
  | 1 | 1.3 |
  | 2 | 1.6 |
  | 3 and beyond | +0.25 per region |

  - This replaces the old smooth formula.
  - Genre weights, Hazard routes and Threat stay as they are.
  - Nothing ever shrinks your pool.
- **13E. Immunity after a hit.** 1.0 s, or 1.3 s for hits of 20 or more. The frame blinks throughout. One bad
  volley costs one hit, not three.
- **13F. Hitboxes.** The ship's hitbox goes from 12 to 8, the mech's from 15 to 10. The art is unchanged, so a shot
  that clips a wingtip misses. A six-hit budget is only fair if only real hits land.
- **13G. Proposed (2026-11-09): repairs come less often.** (heromedel.)
  - A repair is +15 Armor, a hit and a half.
  - Planet missions place two.
  - In dungeons, a cleared room drops one 15% of the time, plus the shrine room.
  - Every mini-boss drops one when it falls.
  - Star Cluster and Corridor have none, as now.
- **13H. Boss length.** Every boss and mini-boss has 70% of its current health, through one factor (BOSS_HEALTH in
  mission data), not 21 separate edits. The average-player bot then tunes that factor until a planet 1 boss lasts
  30–45 s and a gate boss 60–90 s.
- **13I. Difficulty targets,** replacing 9A's, for an average player on Standard:

  | Planet | Hits taken |
  |---|---|
  | 1 | 1–3 |
  | 2–3 | 3–5 |
  | 4–5 | 4–6, with a loss now and then |
  | 6 (region gate) | About 1 in 4 attempts lost, as before |

## Seven slots

- **13J. Likely (2026-11-09):** Two new slots, **Generator** and **Plating**. (heromedel.) The seven are main,
  weapon, weapon, support, special, generator, plating.
- **13K. The Generator slot.** It holds the parts that keep you alive or hold ground, so that kind of defence is one
  choice, not a stack:

  | Generator part | What it does |
  |---|---|
  | **Shield Generator** (new) | A bubble that blocks one hit of any size, then 1 s of immunity as it breaks. It recharges 12 s later (8 s at level 5). The frame shows it. Fork A, Twin Cell: two charges. Fork B, Breaker Pulse: a breaking shield sets off a blast that clears bullets around you. |
  | **Arc Blade** (moves from weapon) | Unchanged. |
  | **Mirror Aegis** (moves from support) | Unchanged. |
  | **Soul Lantern** (moves from support) | Unchanged. |

  - The weapon slots keep Swarm Pods, Orbital Halo and Starfall.
  - The support slot keeps Graze Engine, Overheat Core and Drone Pods.
- **13L. Proposed (2026-11-09): plating is the frame's outer armour.** Most plates are basic and trade Armor
  against weight and speed. A few rare ones are strange and change how you play, and only rare or carefully balanced
  ones may touch attack. Names are chosen with intent. (heromedel.)
  - In 0.6 only the starter plate exists; the rest arrive with Load in 0.6.1 (21H).
  - **DSP-1 Drop Plate** (Dropship Standard Plating, version 1, what your own Dropship prints) adds no Armor. It's
    the plating every frame starts with. Its levels during a mission are plain reinforcement, +10 Armor each,
    which heromedel said is fine for the starter.
- **13M. Proposed (2026-11-09): each plate levels up in its own way, over several levels.** (heromedel.) See 21H.

## Fixing what the new rules break

- **13N. Defence that's also offence.**
  - Orbital Halo's saws still eat bullets, but each saw breaks after three and regrows 3 s later.
  - Specials keep clearing bullets: they're this game's Blanks, one per cooldown and a decision each time.
  - Graze Engine's Adrenal Mend fork repairs 3 Armor per Overdrive, not 10.
- **13O. Fusions.** Reflex Blade fused Arc Blade with Mirror Aegis, which now share a slot. It fuses Arc Blade with
  **Graze Engine** instead: blade sweeps catch the bullets you've just grazed and throw them back as homing blades.
  Every other fusion already pairs different slots.
- **13P. Resonance.** Capacitor Discharge (Energy II) now goes off whenever you're hit, or when a Shield Generator
  breaks. It releases the same lightning nova that strikes six enemies and clears nearby bullets, so it works with
  every build.
- **13Q. Upgrade cards, retuned for an 80-Armor pool:**

  | Card | Change |
  |---|---|
  | Field Repair | Repairs 30 Armor (three hits). Once per mission. |
  | Vampiric Plating | Renamed **Mawjig Siphon**, since it isn't a plate. Kills siphon 1 Armor each, at most 10 per stage per stack. |
  | Blood Pact | Kills repair 1.5. After 2 s without a kill, Armor bleeds away 2 a second, never below a third. |
  | Glass Reactor | +50% damage. The price is now a third of your max Armor, gone for the mission. |
  | Overclocked Servos | Renamed **Juggernaut Servos**; "overclocked" will mean running past your Output. Still 15% faster, and ramming still hurts enemies more than you (GDD 1D). |
  | Salvage Cache | +10 Armor and a reroll. |
  | Last Stand, Shrapnel Skin, Echo Chamber, Lucky Salvage, Tractor Beam, Adrenaline Junkie | Unchanged. |

## Frames in 0.6

- **13R. Armor for the three frames,** before Load and Output arrive in 0.6.1:

  | Frame | Armor | Speed | Trait |
  |---|---|---|---|
  | Vanguard | 60 + 20 built-in plating | 300 | Built-in plating replaces Second Wind (heromedel). |
  | Tempest | 45 | 370 | Afterimage, unchanged. |
  | Bulwark | 100 | 250 | Fortress Field now reflects a quarter of the bullets that hit the frame's front. It no longer needs a shield to work. |

- **13S. Proposed (2026-11-09): a built-in part is a bonus on top,** costing no Load or Output (once those exist),
  paid for by the frame's other numbers, rarity or how hard it is to get. (heromedel.)

## Starting out and the lessons

- **13T. Likely (2026-11-08, GDD 9C): shields on planet 3.** The planet 3 lesson now gives the Shield Generator.
  - Its needle swarms are what a one-hit blocker is for.
  - Mirror Aegis becomes ordinary loot on later planets.
- **13U. The starting kit:**
  - Main: Pulse Driver.
  - Generator: Arc Blade.
  - Special: Nova Bomb.
  - Plating: DSP-1 Drop Plate.
  - Both weapon slots and the support slot start empty.
- **13V. Proposed (2026-11-09): a fresh save.** 0.6 starts a new save, says so on the title screen, and clears any
  older build's mission checkpoint. (heromedel: he'd reset anyway.)

## Also in 0.6 (heromedel)

- **13W. Proposed (2026-11-09):** Ricochet shots go. Pulse Driver's fork A becomes **Chain Bolts**:
  - A kill arcs to the next enemy within reach, up to three times.
  - Each jump does 80% of the bolt before it.
  - It stays the single-target fork, and nothing flies off screen.
- **13X. Proposed (2026-11-09):** Auto-fire is off by default (Settings, "Auto-fire: Off > On").

# Plan B: build 0.6.1, building a frame

- **21A. Proposed (2026-11-09):** Frames have **Max Load** and **Mawjig Output**. Every part weighs something, and
  powered parts draw Output. Heat only exists when you go past your Output on purpose. Coolers and auxiliary
  generators sit in the support slot. (heromedel.)
- **21B. Pips.** Load and Output are small whole numbers shown as two rows of pips in the Hangar.
  - Max Load is a hard limit: Launch is greyed out, with the reason, until the build fits.
  - Pips past your Output turn orange and the row reads **OVERCLOCKED**, so going over is a visible choice.
- **21C. The element sets the cost.** Energy and Mawjig parts are light but draw power; Kinetic and Explosive parts
  are heavy and draw little. That ties both meters to Resonance with no special rules.

  | Part | Element | Weight | Draw |
  |---|---|---|---|
  | Pulse Driver / Thunder Lance / Hex Repeater | E / E / M | 1 / 1 / 1 | 1 / 3 / 2 |
  | Swarm Pods / Orbital Halo / Starfall | X / K / M | 3 / 2 / 1 | 0 / 1 / 3 |
  | Shield Generator / Arc Blade / Mirror Aegis / Soul Lantern | E / E / E / M | 1 / 1 / 1 / 1 | 3 / 2 / 3 / 2 |
  | Graze Engine / Overheat Core / Drone Pods | K / X / K | 1 / 2 / 2 | 0 / 0 / 1 |
  | Coolant Loop / Auxiliary Generator | - | 2 / 3 | 0 / adds 3 |
  | Nova Bomb / Time Brake / Ion Cannon / Thruster Explosion | X / M / E / K | 2 / 1 / 2 / 2 | 0 / 3 / 3 / 0 |

  - The starter build weighs 6 Load and draws 3 Output, on a frame with 12 Load and 9 Output.
  - A greedy mid-game build overflows Load until you trade a heavy part, then runs a few pips hot. That's the
    choice the meters exist to make.
- **21D. Heat.**
  - **When it rises:** only on an overclocked build. Heat climbs 2.5% a second for each pip over Output while you
    fight, and the Coolant Loop takes off one pip's worth.
  - **What you see:** the vents glow orange, then red.
  - **At 100%:** the frame vents. For 3 s, powered parts go offline and heat drops to 40%. Unpowered weapons keep
    firing, and Armor is never lost.
  - **Overheat Core** becomes the overclocker's tech: its vent fires on every overheat and grows with the heat
    you'd built up.
  - Weight and draw depend on the part and its Mk, never on in-mission level, so an upgrade never breaks a build.
- **21E. Frames:**

  | Frame | Armor | Load | Output | Speed | Identity |
  |---|---|---|---|---|---|
  | Vanguard | 60 + 20 built in | 12 | 9 | 300 | Balanced: either element fits. |
  | Tempest | 45 | 9 | 13 | 370 | The energy frame, with room to overclock. |
  | Bulwark | 100 | 16 | 6 | 250 | The kinetic and explosive frame, carries anything. |

  New frames come later, each built around a built-in part: a built-in Arc Blade, a built-in Shield Generator,
  built-in shoulder missiles (heromedel). Each pays for its part in Load, Output or Armor.
- **21F. Proposed (2026-11-09): frame upgrades use frame blueprints.** (heromedel.)
  - Frame blueprints drop from planets that show one on their card.
  - Each frame has three tiers, costing 3, 6 and 10 blueprints.
  - Each tier picks one of: +1 Load, +1 Output, +10 Armor, or faster cooling. Two Vanguards can grow differently,
    and the small caps keep planet 1 from becoming trivial.
- **21G. Where the other plates come from:**
  - Basic plates drop from ordinary planets.
  - Each uncommon plate is the prize of the boss it's named after.
  - The rare plates are themed-branch prizes.
- **21H. The plates.** Each levels in its own way during a mission:

  | Tier | Plate | Armor, weight | What it does | Each level | Why the name |
  |---|---|---|---|---|---|
  | Starter | **DSP-1 Drop Plate** | +0, 2 | Plain | +10 Armor | Dropship Standard Plating, version 1 |
  | Basic | **QRF Shell** | −10, 1 | 10% faster | +5% speed | Quick Reaction Force: first in, fast |
  | Basic | **Jig-Weave Composite** | +15, 3 | Shrugs off the first chip hit (5 or less) each stage | One more chip hit per stage | Jigawatt-powered fibres woven through it (Infall) |
  | Basic | **Lunarium Bulk Plate** | +30, 4 | 10% slower | Work-hardens: each hit survived adds 1 max Armor for the mission; each level raises the cap by 5 | Mecha anime's wonder-alloys |
  | Uncommon | **Mirrorwork Half Plate** | +10, 2 | Lasers and beams do half | Level 3: a beam blocks entirely for 1 s after any hit; level 5: 2 s | Cut from the Mirror Dreadnought, its prize |
  | Uncommon | **Crusher-Rated Plate** | +10, 3 | Blasts and shockwaves do half | Level 3: explosions no longer push you; level 5: blasts do a third | Rated to survive the Crusher Gate |
  | Uncommon | **Arc-Lined Plate** | +20, 1, draws 1 Output | The strongest armour for its weight | Each level, +5 Armor | Armour lined with live current, which is why it costs power |
  | Rare | **Jig Phase Plate** | +0, 2 | A hit drains in over 3 s; half of it fades if no other hit lands meanwhile | Each level, the fading part grows by 10% | Salvage from a Jig Phase Drive (GDD 10E): hits phase partly out of this dimension and arrive late |
  | Rare | **Last Legend Plate** | −10, 2 | Below a third of your Armor, weapons fire 30% faster | Each level, +5% faster | The Guardian Legend, and our own title |

# Building it

## Plan A (0.6)

1. **Armor and damage:**
   - Armor as one pool with hit ticks.
   - The damage steps, region steps, immunity after a hit, hitboxes, repairs and boss health (13A–13H).
2. **The Generator and Plating slots:**
   - The Shield Generator and DSP-1 Drop Plate.
   - Arc Blade, Mirror Aegis and Soul Lantern move.
   - The planet 3 lesson gives the Shield Generator, and the starting kit changes (13J–13M, 13T, 13U).
3. **What the new rules break:** the Halo's saws, Reflex Blade, Capacitor Discharge, the cards, Chain Bolts,
   auto-fire off by default (13N–13Q, 13W, 13X).
4. **The frames' new Armor and traits** (13R), and a fresh save (13V).
5. **Retune:**
   - The average-player bot and the difficulty report are re-targeted to 13I, and the boss health factor is set
     from the bot's fight times.
   - The rules tests are updated.
6. **Text:** the Guide to Guardians, tech, card and frame text, checked by the wording checker.
7. **Testers:**
   - Cold reviews of the Hangar's new slots and of one planet 3 run.
   - One longer blind playtest, since this is a major overhaul.

## Plan B (0.6.1)

1. **Load and Output:** pips, the Hangar's two rows and the launch rule (21A–21C).
2. **Heat:** venting, the Coolant Loop, the Auxiliary Generator and the Overheat Core rework (21D).
3. **Frames:** Load, Output and speed for each (21E); frame blueprints and tiers (21F).
4. **The other plates**, as boss prizes and branch rewards (21G, 21H).
5. **Testing** the same way, with a cold review of the Hangar's two meters.
