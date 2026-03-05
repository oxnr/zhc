FROM node:22-slim

RUN apt-get update && apt-get install -y \
    python3 python3-pip git curl wget procps \
    && rm -rf /var/lib/apt/lists/*

# Install gh CLI (GitHub)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh && rm -rf /var/lib/apt/lists/*

# Install OpenClaw (agent gateway + orchestration)
RUN npm install -g openclaw@latest

# Install Claude Code + Codex CLIs (agent backends)
RUN npm install -g @anthropic-ai/claude-code codex-cli

WORKDIR /zhc

# Dashboard dependencies (cached layer)
COPY dashboard/package*.json dashboard/
RUN cd dashboard && npm install --production

# Copy entire project
COPY . .
RUN chmod +x entrypoint.sh scripts/*.sh

# OpenClaw gateway + Mission Control dashboard
EXPOSE 18789 4200

ENV OPENCLAW_CONFIG_PATH=/zhc/openclaw.json
ENV OPENCLAW_HOME=/zhc/.openclaw
ENV ZHC_ROOT=/zhc

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:4200/api/state || exit 1

ENTRYPOINT ["/zhc/entrypoint.sh"]
