# grill-and-verify

A task-preparation and verification suite for coding agents. Stress-test a
plan into shared understanding, model it formally, check every promise with
a model checker, draw the state flow with bug paths, and keep the proofs
true as the code changes.

Works as a **Claude Code plugin** and as a **pi package** — same `skills/`
tree, consumed by both.

## The pipeline

```
grill-me ──▶ model & check ──▶ statechart ──▶ board ──▶ hand off
(settle the   (flow-promises    (diagram +    (living    (verified plan,
 decisions)    or create-        bug paths)    board)     tests, next steps)
               formal-verification-skill)
```

## Skills

| Skill | What it does |
|---|---|
| `grill-and-verify` | The full preparation pipeline; chains the others. |
| `grill-me` | Interrogate a plan in rounds until nothing is silently assumed. |
| `flow-promises` | Design a flow pre-code: mocks, a Quint model, promises checked by TLC. |
| `statechart` | Check a TLA+ model and draw it as a Mermaid statechart with bug paths. |
| `create-formal-verification-skill` | Generate a project-local skill that formally verifies code where a bug costs most. |
| `create-verification-skill` | Generate a project-local skill that drives the real app like a user, with a feature map. |
| `maintain-formal-verification-skill` | Bring formal verification back in line with changed code; drift vs bug. |
| `maintain-verification-skill` | Keep the verification skill and feature map honest over time. |
| `verify-toolbox` | Build the Dockerized toolchain image (below). |

## Install — Claude Code

```
/plugin marketplace add aranw/grill-and-verify
/plugin install grill-and-verify@aranw
```

Skills are then available as `/grill-and-verify:grill-and-verify`,
`/grill-and-verify:grill-me`, and so on (plus auto-invocation by
description where the harness supports it).

## Install — pi

```
pi install git:github.com/aranw/grill-and-verify
```

or from a local checkout:

```
pi install ./code/grill-and-verify
```

Skills register as `/skill:grill-and-verify`, `/skill:grill-me`, etc.

## The toolchain (Docker)

The model checker (TLC), Quint, and Pele are Java/Node programs. They run
inside the `verify-toolbox` Docker image so **nothing is installed on the
host**:

```
skills/verify-toolbox/build        # one-time, ~700 MB pull
```

The check skills ship `-docker` shims (`statechart-docker`, `check-docker`,
`render-docker`, `tlc-docker`) that run the upstream scripts inside the
container. The upstream scripts also run directly on the host (they
bootstrap through `mise`) if you ever prefer that.

## Sources and credits

- `statechart`, `flow-promises`, `create-*-verification-skill`,
  `maintain-*-verification-skill` — from the
  [pstack](https://github.com/cursor/plugins/tree/main/pstack) collection
  (MIT, Copyright Lauren Tan), via the [bkase
  fork](https://github.com/bkase/plugins) which adds `flow-promises`.
  Adapted: Docker shims, harness-portable paths.
- `grill-me` — from [mattpocock/skills](https://github.com/mattpocock/skills)
  (MIT, Copyright Matt Pocock). Renamed from `grilling`.
- `grill-and-verify`, `verify-toolbox` — original to this repo.
