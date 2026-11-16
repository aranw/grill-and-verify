---
name: verify-toolbox
description: "Containerized toolchain (Java, TLC, Quint, Pele) for the verification skills: /statechart, /flow-promises, /create-formal-verification-skill, /maintain-formal-verification-skill. Build or rebuild the verify-toolbox Docker image. Use for /verify-toolbox, when a docker shim says the image is not built, or when the verification tools need updating."
disable-model-invocation: true
---

# Verify toolbox

The verification skills check models with TLC (the TLA+ model checker, a Java
program), compile Quint with Apalache (Java 21+), and render Mermaid charts
with Pele. This toolbox keeps all of that inside one Docker image,
`verify-toolbox:latest`, so none of it is installed on the host.

## Build

```sh
<skill dir>/build
```

Needs the network the first time (about 700 MB pulled). The Dockerfile pins:
- node 24 (runs the statechart TypeScript scripts),
- Temurin 25 JRE (runs TLC and Apalache),
- tla2tools.jar v1.7.4, checksum-pinned to the version the statechart skill expects,
- Quint 0.33.0 with its Apalache download warmed into `/root/.quint`,
- Pele 1.9.0 baked at the cache path `flow-promises/scripts/render.mjs` expects.

## Shims

Each verification skill ships docker shims next to its upstream scripts. They
mount this plugin's `skills/` directory read-only at `/skills` and the current
folder at `/work`, so pass **paths relative to the folder you run from**:

- `statechart/scripts/statechart-docker SPEC.tla [--config FILE] [--view FILE] [--out DIR]`
- `statechart/scripts/render-docker CHART.mmd CHART.svg`
- `statechart/scripts/tlc-docker [TLC options...] SPEC.tla` (raw TLC, for ad-hoc runs)
- `flow-promises/scripts/check-docker FLOW.qnt [--config FILE] [--view FILE] [--out DIR]`

The upstream scripts run unmodified inside the container: the image sets
`TLA2TOOLS=/opt/tla/tla2tools.jar`, which the statechart scripts honor before
ever trying `mise`.

## When to rebuild

- A shim printed `The verify-toolbox image is not built`.
- The statechart or flow-promises skill updated its pinned TLC or Quint version
  (check the version numbers in the skill's scripts, then update the
  Dockerfile to match).
- `docker image inspect verify-toolbox:latest` fails.

## Without Docker

The upstream scripts also run directly on the host: they bootstrap TLC and
Java through `mise` (or honor `TLA2TOOLS` and `JAVA` env vars) and need a
TypeScript-capable runtime (bun and node 23.6+ are both installed). Use
`scripts/statechart` and `scripts/check` instead of the `-docker` shims.
