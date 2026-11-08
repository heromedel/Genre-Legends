# Genre Legends — Roadmap

(Note) Everything here is Ai-Generated-Proposal (2026-11-08) unless a line cites a GDD point, in which case it carries that point's tag. heromedel asked for a roadmap covering all 8 mission types, with 3 built in depth first and depth and width added each update (GDD 3A). Plans are letters, steps are numbers.

## The 8 mission types

| # | Mission type | Frame form | Source |
|---|---|---|---|
| 1 | Star Cluster: formation shooter | Ship | GDD 6A |
| 2 | Corridor Run: scrolling corridor shooter | Ship | GDD 6A |
| 3 | Planet Exploration: open-area bullet hell | Mech | GDD 6C |
| 4 | Dungeon: room-by-room bullet hell crawler | Mech | GDD 6D |
| 5 | Planetary Defense: bottom-of-screen defense | Turret / tank | GDD 6B |
| 6 | Tank Assault: top-down tank commander | Tank | GDD 6E |
| 7 | Horde Siege: survive the swarm | Mech | Ai-Generated-Proposal |
| 8 | Titan Hunt: one giant set-piece boss | Combined super-robot | Ai-Generated-Proposal (GDD 5E proposal) |

## Plan A: Foundation and the first three

1. Godot project, single-threaded web export, GitHub Pages deploy, iPad touch controls, tap to start (GDD 2A, 2B).
2. Core systems: the frame and its forms, combat, a fixed-step simulation with seeded randomness, mission hand-off support (GDD 6G proposal), play log and replay (GDD 4C), admin console and debug log.
3. Command center and star map with forking routes and planet info (GDD 5A–5D).
4. Planet Exploration, Star Cluster with Corridor Run, and Dungeon, each with its own enemies, a set-piece boss and its genre's tropes (GDD 1B, 6H).
5. Equipment: blueprints, loadout, in-mission upgrades that fork, the starter weapon (GDD 7A–7F).
6. Testers: test harness, QA bots, blind, break-it and first-impressions playtesters (GDD 4A, 4B).
7. First playable build on GitHub Pages.

## Plan B: First chained mission

1. Planet Exploration that dives into a Corridor Run mid-mission (GDD 6G, heromedel's first example).
2. More depth for the first three: more enemies, bosses, branch themes and fusions.

## Plan C: Defense and tanks

1. Planetary Defense and Tank Assault, sharing the tank form.
2. heromedel's second chain: Planetary Defense turns into an invader wave, then launches into a Star Cluster boss fight (GDD 6G).

## Plan D: Remaining mission types

1. Horde Siege.
2. Titan Hunt and the combined super-robot form.

## Plan E: Co-op and trading

1. Controller support (GDD 2D).
2. Device-to-device co-op and trade codes (GDD 8C, 8D).

## Plan F: Rewards layer

1. Mock mobile-game rewards with no ads and no real money (GDD 8A, 8B).
