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

The pipeline has five stages. Each stage ends at a decision that belongs to
the user; do not start the next stage until the current one is settled.

```
grill-me ──▶ model & check ──▶ statechart ──▶ board ──▶ hand off
(settle the   (flow-promises    (diagram +    (living    (verified plan,
 decisions)    or create-        bug paths)    board)     tests, next steps)
               formal-verification-skill)
```

Each stage names a sibling skill in this plugin. Load and follow its
`SKILL.md`; the paths below are relative to this skill's directory.

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
  least): load and follow
  `../create-formal-verification-skill/SKILL.md`. It chooses the tool (TLA+
  is the default for orderings and state machines) and leaves a project-local
  skill in the project's agent-skills directory that re-checks the property.

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

## Stage 5 — Hand off

The task is prepared when:

- every promise holds, or the user has accepted a break in writing;
- the design seed is checked in where the team keeps design docs
  (flow-promises puts it under `docs/flows/FLOW/` by default);
- the hand-off names, in plain words: what was verified, with which tool and
  bounds, what the model leaves out, and the one command that re-checks it.

Then state the follow-on work explicitly:

- Each promise becomes an **acceptance test**; each path that changed the
  design becomes a **test that replays it**, one step per action.
- Once the code exists, the create-verification-skill skill gives the repo
  a scripted way to drive the real app like a user.
- After changes that skip the checks, maintain-formal-verification-skill
  and maintain-verification-skill bring the verification back in line with
  the code and say whether each failure is drift or a bug.

## If the user only wants part of the pipeline

Enter at any stage: grill-me alone to stress-test thinking, statechart alone
to show a bug as a path through states, flow-promises alone to settle edge
cases before a build. This skill is the full preparation loop; each piece
stands on its own.
