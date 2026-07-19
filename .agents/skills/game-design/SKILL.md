---
name: game-design
description: Game design critique, framework application, core-loop analysis, and design documentation. Use when the user mentions game design, core loop, player verbs, MDA, mechanics/dynamics/aesthetics, encounter design, difficulty curve, onboarding, retention, game feel philosophy (not implementation), fun-factor, tuning, or asks "should the game have X" / "what should the player do" / "how do I make this fun". Also triggers on requests to write or review a game design document (GDD). Do NOT use for engine-specific implementation (use godot-development / godot-gameplay-prototyping / godot-4-ui) or QC/playtesting (use game-qc-playtest).
metadata:
  source: custom
  domain: gamedev
  agents: [codex, antigravity, claude, all]
  supersedes: []
  conflicts_with: [game-qc-playtest]
  status: active
  created: 2026-07-02
  last_audit: 2026-07-02
---

# Game Design

## Purpose

The design layer above implementation. Frameworks for reasoning about what makes a game work, structured critique of design proposals, and templates for design documentation. Distinct from engine work — this skill never writes GDScript.

## When to use

- "Should the game have X mechanic?"
- "What's the core loop of my game?"
- Writing or reviewing a Game Design Document (GDD)
- Encounter/level design proposals
- Difficulty curve and progression
- Onboarding and tutorial design
- Retention and pacing analysis
- Player verb inventory and intent

## When NOT to use

- Engine implementation questions → `godot-*` skills
- Playtesting protocol, bug checklist → `game-qc-playtest`
- UI copy or menu wording → `godot-4-ui` and general writing

## Core knowledge

### Core loop

Every game has one. State it in one sentence:
- **Vampire Survivors:** move → enemies spawn → auto-attack → collect gems → level up → new weapon → repeat with more enemies
- **Slay the Spire:** enter room → play cards → deck grows → climb tower → repeat

If you can't state the core loop in one sentence, the game doesn't have one yet. That's your first design problem.

### MDA framework (Hunicke, LeBlanc, Zubek)

- **Mechanics:** the rules (jump, shoot, gather)
- **Dynamics:** what emerges when players engage with mechanics (build order, kiting, resource curves)
- **Aesthetics:** the feelings produced (tension, mastery, discovery, social bond)

Designers write mechanics; players experience aesthetics. Dynamics are the bridge. Test proposals by asking: what aesthetic am I aiming for, and does this mechanic produce dynamics that deliver it?

### Player verbs

List every action the player can take. If the list is:
- 3+ verbs → you have variety
- 1-2 verbs → you need to expand OR you need to make those verbs *very* deep (see: chess)
- Verbs that overlap heavily → consolidate

Each verb should have distinct affordances, tradeoffs, and situations where it's optimal.

### Encounter design template

For any combat or challenge encounter:
1. **What is the player asked to do here?** (specific verb combination)
2. **What is the failure mode?** (what happens if they do it wrong)
3. **What's the tell?** (visual/audio cue the challenge is coming)
4. **What's the reward for success?** (progression, resources, feeling)
5. **How does it teach the next encounter?** (chained learning)

### Difficulty curve

Two axes: **skill demanded** (execution) and **strategy demanded** (planning). Games often ramp both, but the best designs pick one to lead:
- Skill-led: Celeste, Souls games, arcade shooters
- Strategy-led: XCOM, Into the Breach, deckbuilders

Ramp is not monotonic. Peaks and valleys — moments of high challenge followed by breathers — produce better retention than a flat climb.

### Onboarding pattern (30-second gate)

Player must understand the core verb within 30 seconds. If they don't, drop-off spikes.

Structure:
1. **Show the verb** (visible affordance, no words)
2. **Force the verb** (situation only solvable by using it)
3. **Reward the verb** (feedback that they used it well)
4. **Complicate the verb** (introduce a variation or constraint)

Repeat for each core verb. Only introduce the second verb after the first is internalized.

### Retention hooks

- **Session length hooks:** short session cadence (roguelites), long session cadence (RPGs)
- **Return hooks:** daily reward, energy timer, streak
- **Meta-progression:** unlocks between runs
- **Social hooks:** leaderboards, replay sharing, co-op scheduling

Retention is not addiction. Design for players to feel good about coming back, not compelled.

## Workflow

Typical task: critique a design proposal.

1. Restate the proposal in one sentence. If you can't, ask for clarification.
2. Identify the target aesthetic (what feeling should this produce?).
3. Trace the mechanic → dynamic → aesthetic chain. Is there a gap?
4. Identify what the proposal displaces (design has opportunity cost).
5. Check consistency with existing player verbs and core loop.
6. List failure modes: what happens if this doesn't work?
7. Suggest a cheap prototype to test the key assumption.
8. Recommend keep / cut / iterate.

Typical task: draft a core loop.

1. Ask: what does the player DO minute-to-minute?
2. Ask: what makes them want to do it again?
3. Ask: what changes each cycle?
4. Write the sentence.
5. Identify the primary verb, the primary resource, and the primary feedback.
6. Sketch the failure mode (game over) and the success mode (session end).

## Common gotchas

- **Feature soup:** stacking mechanics without checking if each earns its keep. Every new mechanic should displace an old one or deepen an existing dynamic.
- **Design by analogy:** "like Zelda but with X." Analogy is a shortcut for pitching, not designing. Return to the core loop.
- **Skipping the aesthetic question:** if you can't state what feeling you're producing, no mechanic will land right.
- **Confusing depth and complexity:** depth = many meaningful choices in simple rules. Complexity = many rules. Aim for the first.
- **Optimizing away the fun:** balance passes that flatten outlier strategies often remove the exciting moments. Preserve peaks, not just averages.

## GDD structure (short-form)

```
# <Game title>

## Elevator pitch
<one paragraph>

## Core loop
<one sentence>

## Player verbs
- <verb>: <description>
- <verb>: <description>

## Primary aesthetic
<what feeling this game produces>

## Failure mode
<what game over feels like>

## Success mode
<what winning feels like>

## Progression
<what changes across a session and across the campaign>

## Content plan
<what content types need to exist, how much, and why>

## Risks
<what could sink this>
```

## References

- Hunicke, LeBlanc, Zubek: MDA framework (search "MDA game design paper")
- Jesse Schell: The Art of Game Design (100 lenses)
- Raph Koster: A Theory of Fun
- GDC Vault talks on encounter design and player psychology
