# Cold Review Log

(Note) Every finding from a cold first-impressions review (GDD 4B, 4E) lands here once, with what was done about it.
Newest review first. Status is one of: **Fixed** (with the build), **Saved** (worth doing, not yet; says when or what
it waits on), **Discarded** (says why it isn't relevant, e.g. a screenshot caught mid-transition, or it conflicts with
a design point).

| Review | Subject | Finding | Status | Note |
|---|---|---|---|---|
| heromedel (2026-11-09) | Boss banners | "SHIELD DOWN - HE'S EXPOSED" is bad and boring wording; nine bosses said "X EXPOSED" in some form. | **Fixed** (0.5) | Every phase banner rewritten to say what that boss does ("THE ACE'S SHIELD SHATTERS", "THE CRUSHER JAMS OPEN"...); the Bulkhead Fortress no longer shares the Crusher Gate's line. |
| heromedel | Twin Rails | "Fires two rails in a V, then three." unclear (three needs level 5, so Mk 3). | **Fixed** (0.5) | "Fires two rails in a V. Three at level 5." (heromedel's wording). |
| Frames review (2026-11-09) | Player frames, new art | Vanguard strongest; the cyan rim reads as "player"; ship and mech read as the same machine. | **Saved** | Keep: the rim and the chevron as facing marker. |
| Frames review | Gear on the frames | Pale, flat, pasted-on parts; an arrow-like weapon, a nose clamp, a star that reads as a hit spark; grey ghost copies. | **Fixed** (0.5) | Ghosts were a misfiring outline trick, removed; every part redrawn in the frames' style (next commit). |
| Frames review | Bulwark mech | Reads as a crate with no front; close to the loot chest's colour. | **Fixed** (0.5) | A chevron on the shield plate and a bolder visor. |
| Frames review | Tempest mech | Swept fins read as a kickstand or legs. | **Fixed** (0.5) | Short jet fins on the backpack with thrusters at the tips. |
| Frames review | Mechs | About 6% of the screen: small on an iPad mini. | **Fixed** (0.5) | Mechs draw 1.2x (the hitbox is unchanged). |
| Frames review | Hangar | Locked frames dimmed to olive and brown. | **Discarded** | Intentional: locked. |
| Wording check (2026-11-09) | Tech, upgrades, radio, guide, events | Descriptions that promised more than the code does: Time Brake ("slams the brakes"), Graze's "double", Option Pods' "copies", Soul Lantern's wisp counts, Arc Blade's swapped steps, Supernova Rings, Meteor Shower, Overheat Core, Shockwave, Supernova Core, Armageddon, Cluster Drones, Centi-Mechs, the needle radio line, the Clone Projector, Distress Call, Wandering Trader. | **Fixed** (0.5) | Each rewritten to say what the code does. |
| Wording check | Level-5 steps | Labels with no effect ("Cataclysm", "Star-killer", "Reactor"...) are the whole text of an upgrade card. | **Fixed** (0.5) | "Name: effect", e.g. "Cataclysm: harder, faster meteors". |
| Wording check | Guide, Elites | Homing shots never hit mirrored elites, though the Guide says they get through. | **Fixed** (0.5) | A code bug: homing shots now hit mirrored elites; against the Mirror Dreadnought they still curve past its hull to the vents (GDD 9C). |
| Wording check | Radio, Pulse Driver, Mimic, boss titles | Three-sentence radio lines; "a blank slate that grows into something wild"; "Until it isn't"; two near-identical boss titles. | **Fixed** (0.5) | Shorter lines, plain descriptions, new titles for the Brood Queen and Mirror Dreadnought. |
| Wording check | Mission types | Star Cluster's unused type text says "take down their carrier", wrong on Bounty Hunter planets. | **Saved** | The text isn't shown anywhere yet; fix it if it ever is. |
| Art test (2026-11-09) | Five-pass style vs current | Both cold reviewers (QA and blind playtester) picked the five-pass style for all four pieces without knowing which was new. | **Saved** | Supports the art overhaul (heromedel's idea). The fixes below go into it. |
| Art test | Mech | Reads as seen from the front (visor and crest look like a face), so only the gun shows the facing. | **Saved** | Redraw from above: shoulders, top of the head, barrel reaching forward past the body. |
| Art test | All pieces | Dark outlines and maroon hulls fade into dark space. | **Saved** | Add a thin rim light in the side's colour (cyan for the player, red for enemies). |
| Art test | All pieces | Fine details (wing lights, panel lines, the Dart's nose) turn to noise at real size. | **Saved** | Fewer, bigger details; let outline and silhouette do the work. |
| Art test | Hive Carrier | Turrets are the same maroon as the hull; the stern engine racks could pass for launch bays. | **Saved** | Contrasting turret colour; make the engines read as engines. |
| Art test | Dart | Needs a wider, bolder chevron to count quickly in swarms; a white dot on an enemy reads as a bullet. | **Saved** | Wider silhouette; no white centre dots on enemies (the current Dart has one too). |
| Art test | Comparison sheet | The Hive Carrier's wingtips were cut off by the frame. | **Discarded** | My crop on the sheet, not the art. |
| 0.4 sweep (2026-11-09) | Boss warnings | The WARNING banner showed "BOSS —" with no name. | **Fixed** (0.4) | Real bug from 0.4's warning-before-the-boss change: bosses got their name only when they spawned. They now name themselves when made; a rules check covers every boss. |
| 0.4 sweep | Boss warnings | The warning appears after the boss is already named or firing. | **Discarded** | The capture used the debug `boss=1` jump, which starts the boss fight directly. In play, the warning comes 1.6 s before the boss. |
| 0.4 sweep | Radio | "Weapons fire on their own. Just fly." while you're a walking mech, and in every scenario. | **Fixed** (0.4) | The first-mission line now matches the form ("Just move." for the mech) and the auto-fire setting. It showed everywhere only because every capture runs on a fresh save. |
| 0.4 sweep | HUD | Mid-screen banners and the objective text sit over bosses and the action. | **Fixed** (0.4.1) | In a fight, banners take the band clear of the boss and the player; wave banners are skipped mid-fight; the objective has a dark plate. |
| 0.4 sweep | Dropship transitions | The landing happens over flat ground, the diving ship reads like a falling sword, the bay shot is unclear, the dungeon mech vanishes under the arch, "Tap to skip" is faint. | **Saved** | Worth a polish pass on the transitions, ideally with the vector art overhaul. |
| 0.4 sweep | Boss prize | The prize never showed; a frozen level-up screen covered it. | **Discarded** | Capture artifact: nobody picks the cards in a screenshot run. The prize is covered by rules checks and heromedel's play. |
| 0.4 sweep | Chain mission | All four shots show the same moment; no dive captured. | **Discarded** | Capture artifact: the screenshot run doesn't play, so the nests never fall. Needs a bot-driven capture to judge. |
| 0.4 sweep | Build panel | "Lv 4/4, capped by Mk 2" beside fusion lines saying "4/5" and "both tech at level 5". | **Fixed** (0.4.1) | Fusion lines now say "(needs a higher Mk from R&D)" when the tech's cap is below 5. |
| 0.4 sweep | Star map | Node labels clipped at the right edge. | **Discarded** | heromedel checked on his iPad and it isn't cut off (the map scrolls). |
| 0.4 sweep | Needle lesson | No needles visible in the two shots. | **Saved** | Probably the swarm hadn't arrived by 14 s; check with a focused capture. |
| 0.4 sweep | Clone Projector | The white clone right above the white-tinted player is easy to mix up. | **Saved** | Tint the hologram more strongly. |
| 0.4 sweep | Dune Maw | The boss bar looked empty while "THE MAW IS FURIOUS" showed. | **Saved** | Check with a focused capture. |
| 0.4 sweep | Brood Queen | Sits bottom-left under the tech bar. | **Saved** | Keep it clear of the HUD. |
| 0.4 sweep | HUD | Off-screen markers overlap the SHIELD label; the dungeon minimap is small and the Gazer overlaps it. | **Saved** | Part of the HUD pass. |
| 0.4 sweep | Planet ground | The same craters and ribcage around the spawn in every planet capture. | **Discarded** | Every capture uses the same debug seed; real planets vary. |
| 0.4 sweep | Settings | Debug console and "-dirty" build strings are visible to players. | **Discarded** | Intentional: heromedel uses the console and version stamp while testing (GDD 3, Game Project Standards: more admin commands). |
| 0.4 sweep | Settings | Threat is ordered Standard, Veteran, Casual. | **Discarded** | Intentional: the default comes first (Labelling Guide 5). |
| 0.4 sweep | Pause, Build tab | The Build view of pause lacks the sliders the pause menu has. | **Discarded** | That capture was taken before the pause options were added; `pause_menu_0012s` shows the current screen. |
