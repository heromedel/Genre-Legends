# Cold Review Log

(Note) Every finding from a cold first-impressions review (GDD 4B, 4E) lands here once, with what was done about it.
Newest review first. Status is one of: **Fixed** (with the build), **Saved** (worth doing, not yet; says when or what
it waits on), **Discarded** (says why it isn't relevant, e.g. a screenshot caught mid-transition, or it conflicts with
a design point).

| Review | Subject | Finding | Status | Note |
|---|---|---|---|---|
| 0.4 sweep (2026-11-09) | Boss warnings | The WARNING banner showed "BOSS —" with no name. | **Fixed** (0.4) | Real bug from 0.4's warning-before-the-boss change: bosses got their name only when they spawned. They now name themselves when made; a rules check covers every boss. |
| 0.4 sweep | Boss warnings | The warning appears after the boss is already named or firing. | **Discarded** | The capture used the debug `boss=1` jump, which starts the boss fight directly. In play, the warning comes 1.6 s before the boss. |
| 0.4 sweep | Radio | "Weapons fire on their own. Just fly." while you're a walking mech, and in every scenario. | **Fixed** (0.4) | The first-mission line now matches the form ("Just move." for the mech) and the auto-fire setting. It showed everywhere only because every capture runs on a fresh save. |
| 0.4 sweep | HUD | Mid-screen banners and the objective text sit over bosses and the action. | **Saved** | Real, but a layout pass, not a blocker. Waits for a focused HUD review. |
| 0.4 sweep | Dropship transitions | The landing happens over flat ground, the diving ship reads like a falling sword, the bay shot is unclear, the dungeon mech vanishes under the arch, "Tap to skip" is faint. | **Saved** | Worth a polish pass on the transitions, ideally with the vector art overhaul. |
| 0.4 sweep | Boss prize | The prize never showed; a frozen level-up screen covered it. | **Discarded** | Capture artifact: nobody picks the cards in a screenshot run. The prize is covered by rules checks and heromedel's play. |
| 0.4 sweep | Chain mission | All four shots show the same moment; no dive captured. | **Discarded** | Capture artifact: the screenshot run doesn't play, so the nests never fall. Needs a bot-driven capture to judge. |
| 0.4 sweep | Build panel | "Lv 4/4, capped by Mk 2" beside fusion lines saying "4/5" and "both tech at level 5". | **Saved** (0.4.1) | Real and confusing: the fusion lines should say a higher Mk is needed when the cap is below 5. |
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
