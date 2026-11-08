# Genre Legends

Follow these in every session:

- @docs/GAME_PROJECT_STANDARDS.md — standard rules, elegant code principles and design philosophy.
- @docs/DESIGN_DOC_LABELLING_GUIDE.md — how design points are tagged, written, referenced and numbered.
- @docs/GAME_DESIGN.md — this game's design document. Core rules in section 1 apply to every feature.
- @docs/ROADMAP.md — the build order across all mission types.

## Project notes

- Never push to `playtest` (the branch GitHub Pages serves) without asking heromedel first (GDD 3C). Push to your own branch.
- Godot 4.6, GL Compatibility renderer, single-threaded web export into `play/` (`tools/export_web.sh`).
  Rebuild `play/` in the same commit as script changes.
- The simulation (`scripts/sim/`) must stay deterministic: only `world.rng`, fixed 60 Hz steps, input only
  through `InputFrame`. Rendering and effects may use any randomness. `tests/test_rules.gd` checks replays.
- Autoloads: `PlayLog` (play log, loads first), `Save` (single owner of persistent state), `Sound` (synthesized audio).
- All art and audio are generated in code (`scripts/view/*_art.gd`, `scripts/audio/synth.gd`).
- Testers: see README. Run the ones a change touches; the first-impressions review is done cold by a separate agent from screenshots only.
