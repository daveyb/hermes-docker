# ─────────────────────────────────────────────────────────────────────────────
# Hermes Agent — Dockerfile (ephemeral-agent variant)
#
# Builds on the official NousResearch image and bakes in a pre-configured
# config.yaml that enables web browsing, Telegram, and Discord for the first
# iteration.  All secrets (API keys, bot tokens) are supplied at runtime via
# environment variables — nothing sensitive is stored in this image.
#
# Build:
#   docker build -t hermes-docker .
#
# Run (gateway mode — serves Telegram + Discord):
#   docker run -d --name hermes \
#     --shm-size=1g \
#     -e OPENROUTER_API_KEY=sk-or-... \
#     -e TELEGRAM_BOT_TOKEN=... \
#     -e TELEGRAM_ALLOWED_USERS=username \
#     -e DISCORD_BOT_TOKEN=... \
#     -e DISCORD_ALLOWED_USERS=123456789 \
#     hermes-docker
#
# See .env.example for the full list of supported environment variables.
# ─────────────────────────────────────────────────────────────────────────────
FROM nousresearch/hermes-agent:latest

# Override the default config template that is copied into /opt/data on first
# run.  The entrypoint checks whether /opt/data/config.yaml already exists;
# if not, it copies /opt/hermes/cli-config.yaml.example.  Replacing that file
# here ensures every fresh (ephemeral) container starts with our toolset
# configuration rather than the upstream defaults.
COPY config.yaml /opt/hermes/cli-config.yaml.example

# Default command: run the messaging gateway so Telegram and Discord are live.
# Override with "chat" for an interactive CLI session, or "setup" for first-run
# wizard (requires -it --rm).
CMD ["gateway", "run"]
