# verify-toolbox — containerized verification toolchain for the
# statechart / flow-promises / formal-verification skills.
#
# Keeps Java, TLC, Quint, and Pele entirely off the host machine.
# Build with: skills/verify-toolbox/build
FROM node:24-slim

# Java (Temurin 25 JRE) — runs TLC and Apalache
COPY --from=eclipse-temurin:25-jre /opt/java/openjdk /opt/java/openjdk
ENV PATH="/opt/java/openjdk/bin:${PATH}" \
    TLA2TOOLS=/opt/tla/tla2tools.jar

RUN apt-get update \
  && apt-get install -y --no-install-recommends unzip ca-certificates curl \
  && rm -rf /var/lib/apt/lists/*

# TLC — the TLA+ model checker (version and checksum pinned by upstream statechart skill)
RUN mkdir -p /opt/tla \
  && curl -fsSL -o /opt/tla/tla2tools.jar \
       https://github.com/tlaplus/tlaplus/releases/download/v1.7.4/tla2tools.jar \
  && echo "936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88  /opt/tla/tla2tools.jar" \
       | sha256sum -c - \
  && rm -f /opt/tla/tla2tools.jar.sha256

# Quint — modeling language; compiles to TLA+ through Apalache (pinned by upstream flow-promises skill)
COPY warmup.qnt /tmp/warm/warm.qnt
RUN npm install -g --no-audit --no-fund @informalsystems/quint@0.33.0 \
  && quint compile --target tlaplus --main warm /tmp/warm/warm.qnt >/dev/null \
  && rm -rf /tmp/warm

# Pele — Mermaid renderer, baked at the cache path flow-promises' render.mjs expects
RUN mkdir -p /root/.cache/flow-promises/pele@1.9.0 \
  && npm install --prefix /root/.cache/flow-promises/pele@1.9.0 \
       --no-audit --no-fund pele@1.9.0
