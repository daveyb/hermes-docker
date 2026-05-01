# hermes-docker

A minimal, opinionated Docker image for deploying
[Hermes Agent](https://hermes-agent.nousresearch.com/docs) as an ephemeral
container.  Secrets and platform credentials are kept entirely in the
environment — nothing sensitive is baked into the image.

**First-iteration capabilities:**
- 🌐 Web browsing (`web` + `browser` toolsets — Playwright/Chromium included)
- 💬 Telegram bot gateway
- 🎮 Discord bot gateway
- 🧠 Persistent memory + task planning

Additional toolsets (terminal, file, vision, image generation, TTS, cron jobs,
…) can be enabled iteratively by editing `config.yaml` and rebuilding.

---

## Prerequisites

- Docker 24+ (or Podman 4+)
- An API key for at least one supported LLM provider (see below)
- A Telegram bot token and/or a Discord bot token

---

## Quick Start

### 1. Clone and build

```bash
git clone https://github.com/daveyb/hermes-docker.git
cd hermes-docker
docker build -t hermes-docker .
```

### 2. Configure secrets

```bash
cp .env.example .env
# Edit .env and fill in your API key(s) and bot token(s)
```

At minimum you need:

| Variable | Where to get it |
|---|---|
| `OPENROUTER_API_KEY` (or another LLM key) | [openrouter.ai/keys](https://openrouter.ai/keys) |
| `TELEGRAM_BOT_TOKEN` | [@BotFather](https://t.me/BotFather) on Telegram |
| `TELEGRAM_ALLOWED_USERS` | Your Telegram username (no @) or numeric user ID |
| `DISCORD_BOT_TOKEN` | [discord.com/developers](https://discord.com/developers/applications) |
| `DISCORD_ALLOWED_USERS` | Your Discord user ID (enable Developer Mode → right-click your name → Copy User ID) |

You only need the tokens for the platforms you actually want to use.

### 3. Start the gateway

```bash
docker compose up -d
docker compose logs -f   # watch for "gateway started"
```

The container runs `hermes gateway run` by default, which connects all
configured messaging platforms simultaneously.

---

## Telegram Bot Setup

1. Open Telegram and message [@BotFather](https://t.me/BotFather).
2. Send `/newbot`, follow the prompts, and copy the token into `.env`:
   ```
   TELEGRAM_BOT_TOKEN=123456789:AAF...
   TELEGRAM_ALLOWED_USERS=your_username
   ```
3. Start the container and send a message to your bot.

---

## Discord Bot Setup

1. Go to the [Discord Developer Portal](https://discord.com/developers/applications)
   and click **New Application**.
2. In the left sidebar, click **Bot**.
3. Scroll to **Privileged Gateway Intents** and enable:
   - **Server Members Intent** ✅
   - **Message Content Intent** ✅  *(required — without this the bot can't read messages)*
4. Click **Reset Token**, copy the token, and save it:
   ```
   DISCORD_BOT_TOKEN=MTI3N...
   DISCORD_ALLOWED_USERS=284102345871466496
   ```
5. Generate an invite URL (OAuth2 → URL Generator → scopes: `bot`,
   `applications.commands`; permissions: Send Messages, Read Message History,
   Embed Links, Attach Files, Add Reactions) and invite the bot to your server.
6. Start (or restart) the container.

In server channels the bot only responds when @mentioned.  In DMs it responds
to every message.

---

## Adding More Toolsets

Edit `config.yaml` and add toolset names to `platform_toolsets`, then rebuild:

```yaml
platform_toolsets:
  telegram: [web, browser, todo, memory, skills, terminal, file, tts, vision]
  discord:  [web, browser, todo, memory, skills, terminal, file, tts, vision]
```

Available toolsets (excerpt):

| Toolset | What it adds | Extra key needed? |
|---|---|---|
| `terminal` | Shell command execution | — |
| `file` | Read / write / patch files | — |
| `vision` | Image analysis | `OPENROUTER_API_KEY` or `GOOGLE_API_KEY` |
| `image_gen` | Image generation (FLUX) | `FAL_KEY` |
| `tts` | Text-to-speech (Edge TTS free) | optional `ELEVENLABS_API_KEY` |
| `cronjob` | Scheduled / cron tasks | — |
| `code_execution` | Sandboxed code execution | — |
| `delegation` | Parallel sub-agents | — |
| `session_search` | Search past conversations | `OPENROUTER_API_KEY` or `GOOGLE_API_KEY` |

Run `hermes chat --list-toolsets` inside the container for the authoritative list.

---

## Persistent Storage (optional)

By default every container starts fresh (ephemeral — no state between runs).
To persist sessions, memory, and skills across restarts, mount a host directory:

```bash
mkdir -p ~/.hermes
docker run -d --name hermes \
  --shm-size=1g \
  -v ~/.hermes:/opt/data \
  -e OPENROUTER_API_KEY=sk-or-... \
  -e TELEGRAM_BOT_TOKEN=... \
  -e TELEGRAM_ALLOWED_USERS=username \
  hermes-docker
```

Or in `docker-compose.yml`:

```yaml
services:
  hermes:
    ...
    volumes:
      - ~/.hermes:/opt/data
```

> **Note:** if you mount a volume that already contains a `config.yaml`, that
> file takes precedence over the one baked into the image.  Delete it to revert
> to the image defaults.

---

## Resource Requirements

| Resource | Minimum | With browser tools |
|---|---|---|
| Memory | 1 GB | 2–4 GB |
| CPU | 1 core | 2 cores |
| Shared memory (`--shm-size`) | — | 1 GB |

The `shm_size: "1g"` entry is already set in `docker-compose.yml`.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Container exits immediately | `docker logs hermes` — likely a missing or invalid bot token |
| Bot online but never responds on Discord | Enable **Message Content Intent** in the Developer Portal |
| `DISCORD_ALLOWED_USERS` is set but still denied | Make sure you're using numeric user IDs, not display names |
| Browser tool crashes / blank pages | Add `--shm-size=1g` to `docker run` or `shm_size` in compose |
| Want to change toolsets without rebuilding | Mount a custom `config.yaml` at `/opt/data/config.yaml` |

---

## Upgrading

```bash
docker pull nousresearch/hermes-agent:latest
docker build --no-cache -t hermes-docker .
docker compose up -d
```
