---
name: grill-and-verify
disable-model-invocation: true
description: "Task-preparation pipeline that stress-tests a plan or feature idea, then turns the settled understanding into a formal model, checks it with a model checker, draws the state flow with bug paths, and puts it all on a live visual board. Use for /grill-and-verify, when preparing a task or plan of action, or when a feature design or re-architecture needs to be verified before building."
---

# Grill and verify

Turn a task, plan, or feature idea into a **verified design you can build from**:
every decision interrogated, every promise the system makes checked against a
formal model, every broken promise visible as a path through the states, and
the whole thing on a living board you can watch take shape.

The pipeline has six stages. Each stage ends at a decision that belongs to
the user; do not start the next stage until the current one is settled. The
formal check comes before generating reusable project-local skills. Skill
generation is the final work stage, and only happens after the verification
has produced a useful result and behaved as intended.

```
grill-me ──▶ model & check ──▶ statechart ──▶ board ──▶ validate ──▶ package skills + hand off
(settle the   (formal model     (diagram +    (living    (useful,      (only after validation; verified plan,
 decisions)    and promises)     bug paths)    board)     trustworthy?)  skills are last)    tests, next steps)
```

Each stage names a sibling skill in this plugin. Load and follow its
`SKILL.md`; the paths below are relative to this skill's directory. Load only
the skill for the active stage, just before entering it; do not preload every
sibling skill.

## Keep phase and context visible

As soon as the task scope is clear, create or identify one concise
`WORKFLOW_STATUS.md` beside the workflow's working artifacts. For a pre-code
flow, keep it with the flow seed; for existing code, keep it in the temporary
model/report workspace. Do not turn it into a transcript or commit it by
default. Keep detailed models, charts, and checker output in their own files
and reference those paths from the status file.

Use the six stage names and announce the current phase when entering it and
when it changes. At a phase boundary, tell the user only: what completed, the
gate result, the next phase/action, and anything waiting on them. Use statuses
`IN PROGRESS`, `WAITING FOR USER`, `BLOCKED`, `DONE`, or `SKIPPED`. Do not emit
repetitive progress narration for every tool call. Do not move to the next
phase until the current phase's gate is satisfied.

Keep `WORKFLOW_STATUS.md` to a compact current snapshot, not a running diary.
It should record the one-sentence scope, current phase/status, settled
user decisions, promises and their current status, unresolved findings or
user decisions, artifact paths, and one concrete next action. Preserve the
user's exact promise wording, but link to full reports instead of copying
them. Update it after meaningful decisions, check results, and phase changes.
If the context is getting large, save this checkpoint first, then use the
harness's compaction/resume mechanism if available. On resume, read this file
and the referenced active artifacts; do not reconstruct the whole history or
rerun completed checks without a reason. Never reduce verification coverage
or omit an important assumption just to save context.

## Toolchain check first

The model checker runs inside the `verify-toolbox` Docker container. Before
the first check, confirm the image exists:

```sh
docker image inspect verify-toolbox:latest >/dev/null 2>&1 \
  || ../verify-toolbox/build
```

## Stage 1 — Grill the plan (grill-me)

Load and follow `../grill-me/SKILL.md`. Interview the user in rounds until
the design tree's frontier is empty. During the rounds, two questions always
belong on the tree for this pipeline:

- **What does the system promise?** For every rule the user states, write it
  in the user's words. These become the invariants/promises the model checks.
- **What can happen without the user?** Failing requests, timers, other
  devices, the app closing. These become the world actions of the model.

Keep the settled decisions and promises in a running list — they are the
input to stage 2.

## Stage 2 — Model and check

Pick the branch by whether the code exists:

- **Nothing built yet** (a new feature, flow, or re-architecture): load and
  follow `../flow-promises/SKILL.md`. Its Quint model, mocks, and promises
  ARE the formal verification model. Run its check with
  `scripts/check-docker`.
- **Code exists** (verify where a bug costs the most and tests reach the
  least): use the target-selection and tool-selection guidance in
  `../create-formal-verification-skill/SKILL.md`, but do not generate its
  project-local skill yet. Build and run the formal verification in a
  temporary working area first. TLA+ is the default for orderings and state
  machines. Package the verified check as a reusable project-local skill only
  in stage 6.

Both branches end the same way: a model, a config, and rules in the user's
words — each rule either **holds** or **breaks**, with a counterexample path
for every break. Never weaken a rule to make it hold; the user changes
promises, not you.

## Stage 3 — Draw the state flow (statechart)

Load and follow `../statechart/SKILL.md`. Run its check with
`scripts/statechart-docker` (or it already ran as part of flow-promises).
You get `chart.mmd` + `report.md`: the state flow as the user reads it, each
state that breaks a rule marked, and the shortest path to each break. Show
the chart as a Mermaid block in the conversation, and render it to SVG with
`scripts/render-docker` for the board.

## Stage 4 — Put it on the board

If this harness has a live-visual-board skill (pi: `show-me`), load and
follow it, and update the board after every check round, not only at the
end. The board shows, from top to bottom:

1. **The task** — one sentence, and the settled decisions from stage 1.
2. **Promises** — each in the user's words, with holds/breaks status and the
   counterexample path for each break.
3. **The statechart** — the rendered SVG (or Mermaid fallback), with a
   legend in the user's words.
4. **Bug paths** — each broken rule as a numbered step list the user can
   replay.
5. **Open questions** — whatever the frontier still holds.

Without such a skill, present the same five sections inline in the
conversation and write them to a markdown file beside the design seed.

## Stage 5 — Validate the result

Before creating reusable skills, make sure the formal verification did what
was intended:

- Every selected promise has a clear result: it holds, or it breaks with a
  counterexample path. No selected promise is left unchecked or unexplained.
- The model or harness matches the settled design or the code it claims to
  describe; investigate any mismatch rather than treating a model-only path
  as a code bug.
- The checker has demonstrated that it can catch a violation. If there was no
  natural counterexample, test it against a deliberately broken model for a
  pre-code flow, or a deliberately broken code variant when code exists (as
  `create-formal-verification-skill` requires).
- Resolve each actionable finding, or have the user explicitly accept the
  remaining break. Recheck after changes.

A useful result includes either an actionable finding that changed the design
or code, or confirmation of an important promise with a check that has shown
it can fail when that promise is violated. If the check did not run, did not
catch the intended break, or cannot be trusted to represent the system, fix
that first; do not package a reusable skill yet.

## Stage 6 — Package skills and hand off

This is the final work stage. Only package skills for checks that passed the
stage 5 gate, and only where a reusable skill applies:

- **Code exists:** load and follow
  `../create-formal-verification-skill/SKILL.md` to turn the already validated
  property and check into a project-local skill. Keep the target and promise
  consistent with the verified result, and prove the generated skill against
  a deliberately broken variant as its instructions require.
- **The real app exists:** use `../create-verification-skill/SKILL.md` when a
  reusable, user-facing app-driving check is useful. It must be run end to
  end and leave evidence, as that skill requires. Do not create it for a
  pre-code design; defer it until the app can actually be driven.
- **Nothing useful was verified, or verification is still uncertain:** skip
  skill generation and report why. Keep the design model and findings as
  appropriate; do not create skills merely to complete the pipeline.

Then hand off in plain words: what was verified, with which tool and bounds,
what the model leaves out, the result of the validation gate, any skills
created (or why not), and the command that re-checks the formal result. Each
promise becomes an **acceptance test**; each path that changed the design
becomes a **test that replays it**, one step per action. After later changes
that skip the checks, `maintain-formal-verification-skill` and
`maintain-verification-skill` bring the verification back in line and say
whether each failure is drift or a bug.

## If the user only wants part of the pipeline

Enter at any stage: grill-me alone to stress-test thinking, statechart alone
to show a bug as a path through states, flow-promises alone to settle edge
cases before a build. This skill is the full preparation loop; each piece
stands on its own.
