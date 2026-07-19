---
name: game-qc-playtest
description: Game QC, playtesting protocol, smoke tests, feel checks, bug reporting, regression checklists, playtest debrief format. Use when the user mentions playtest, QA, QC, bug report, regression, smoke test, feel check, testing checklist, "does this feel right", "check for bugs before shipping", or wants to run a structured test pass on a build. Also triggers when preparing a build for external testers. Do NOT use for design critique (use game-design) or implementation questions (use godot-* skills).
metadata:
  source: custom
  domain: gamedev
  agents: [codex, antigravity, claude, all]
  supersedes: []
  conflicts_with: [game-design]
  status: active
  created: 2026-07-02
  last_audit: 2026-07-02
---

# Game QC & Playtest

## Purpose

Structured testing at the game layer: smoke tests, feel checks, regression protocol, bug reporting, playtest debrief. Below engine-level bug hunting, above pure design critique. This is the "did we ship a working, feeling-right game" skill.

## When to use

- Preparing a build for release, showcase, or external playtesters
- Running a smoke test pass after a change
- Structured feel evaluation ("does the jump still feel right after that tuning change?")
- Writing bug reports that a solo dev can act on
- Debriefing a playtest session
- Building a regression checklist for a game genre

## When NOT to use

- Design questions ("should we have a jump") → `game-design`
- Engine-level debugging ("why does move_and_slide return null") → `godot-development`
- UI implementation review → `godot-4-ui`

## Core knowledge

### Smoke test (5 minutes, every build)

Run before every build ships anywhere, even to yourself:

1. **Cold boot:** launch the game from an exported build (not editor). Does it start?
2. **Main menu:** all buttons work? Settings persist across launches?
3. **Start new game:** does the first playable moment reach the player without a crash?
4. **Save + load:** save mid-run, quit, reload. Same state?
5. **Pause + resume:** does time resume cleanly? No stuck audio, no frozen animations?
6. **Quit:** clean exit? No log spam? No lingering process?

If any of these fail, do not ship. Fix, rebuild, re-smoke.

### Feel checks

For every core mechanic, verify:

**Movement:**
- Input latency feels immediate (< 1 frame from press to visible response)
- Jump apex hangs slightly (design choice, but be consistent)
- Landing has weight (audio + slight camera dip + shorter walk speed for 1-2 frames)
- Wall or ledge grabs snap at the expected pixel

**Combat:**
- Hit has weight: sound, hitstop, screen shake, particle
- Attacks cancel into each other where intended
- Enemies telegraph (visible windup)
- Player invincibility frames are visible (flash) and predictable in duration

**Camera:**
- No jitter on subpixel positions
- Look-ahead direction matches player intent (not last-frame velocity)
- Screen shake doesn't cause motion sickness (short, decaying)

**Audio:**
- No SFX stacking on rapid actions (pool or cooldown)
- Music transitions on gameplay state changes (combat, menu)
- Master + music + SFX + UI volume all respected

### Regression checklist (build to build)

Maintain a running list of "things that broke before" and re-test each build:

- Every save from prior build still loads (or migrates cleanly)
- Every level completable from start
- No new input actions steal focus from menus
- No new visual effects tank frame rate on min-spec
- Localization strings still fit their UI containers

Grow this list as bugs get fixed. Never remove entries — they're your institutional memory.

### Bug report format

Every bug report needs:

```
Title: <short, specific — "Save from build 0.3.1 doesn't load in 0.3.2">

Build: <version + platform>
Reproduction rate: <N/M attempts>

Steps:
1.
2.
3.

Expected: <what should happen>
Actual: <what happens>

Severity: blocker | major | minor | polish
Impact: <who hits this and how often>

Attached: <screenshot / video / save file / log>
```

Bad title: "Save broken." Good title: "Save from build 0.3.1 crashes on load with 'invalid resource' error at 0.3.2."

### Severity definitions

- **Blocker:** can't ship. Crashes, data loss, unbeatable challenge, softlock.
- **Major:** significant negative impact on most players. Broken tuning, bad frame rate, ugly visual glitch in common view.
- **Minor:** noticeable but rare or low-impact. Edge-case glitch, minor UI weirdness.
- **Polish:** cosmetic. Would be nicer, not a bug.

Never file a "polish" ticket during a playtest triage. Log it, defer it.

### Playtest debrief format

After each session (external or self):

```
## Session summary
Date: YYYY-MM-DD
Build: <version>
Player(s): <who, experience level>
Duration: <minutes>

## What worked
- <observation, with timestamp or moment>

## What confused
- <observation — where did they hesitate, ask what to do, misread a cue>

## What frustrated
- <observation — where did they visibly get annoyed, quit early, complain>

## Direct feedback (quotes)
- "quote from player"

## Immediate fixes (this week)
- <item>

## Design questions raised
- <question — for next design session, not immediate fix>

## Retention signal
- <did they want to play again? did they ask about the next area?>
```

The distinction between "confused" and "frustrated" matters. Confusion is a teaching problem (tutorial, telegraph). Frustration is a fairness problem (tuning, feedback, respawn).

### Watching yourself playtest

You cannot playtest your own game well. But you can bias your self-tests:

- Play on a different device than your dev machine
- Play with headphones (catches audio issues)
- Play the exported build, not the editor
- Record your run (OBS) and watch it back — you notice different things watching than playing
- Play at 2x speed on replay — pacing issues jump out

## Workflow

Typical task: prep a build for external playtesters.

1. Run smoke test. Fix any fails.
2. Run regression checklist. Fix any regressions.
3. Run feel checks on core mechanics. Note anything that changed.
4. Build and export.
5. Cold-boot the exported build. Run smoke again on the exported build (this catches export-only issues).
6. Package with: build version note, known issues list, feedback form link.
7. Send to testers with the debrief template pre-filled with the current build questions you care about.

Typical task: triage a playtest session.

1. Read your notes.
2. Categorize: blocker → immediate, major → this week, minor → backlog, polish → someday.
3. File bug reports for the blockers and majors.
4. File design tickets (not bugs) for confused/frustrated moments — those go through `game-design`.
5. Update regression checklist with anything the tester found that shouldn't recur.
6. Schedule the next session with fixes deployed.

## Common gotchas

- **Testing in editor only.** Half the bugs only appear in exported builds.
- **Fixing without repro.** If you can't reproduce, you can't verify the fix. Get the repro first.
- **Batch testing at end of dev.** Feel drift is invisible one commit at a time. Test after every mechanical change.
- **Believing tester silence.** No feedback ≠ no problems. Ask direct questions in debrief.
- **Skipping the regression list.** "It worked last week" is the beginning of every shipped bug.
- **Bug counting vs bug weighting.** 20 minor bugs are usually fine; 1 blocker isn't.

## References

- Steve Swink: Game Feel (the book)
- Google's playtesting protocol templates (search "Google playtest kit")
- Any GDC talk with "playtest" in the title
