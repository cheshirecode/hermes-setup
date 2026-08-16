# ⚕ hermes-setup

Portable, version-controlled repository for configuring and managing [Nous Research Hermes Agent](https://hermes-agent.nousresearch.com/) across local machines (macOS, WSL, Linux) and cloud VPS / GPU instances.

---

## Features

- **Portability Across Machines**: Clone and run `./bin/bootstrap.sh` anywhere to synchronize your persona, custom skills, workspace instructions, and model preferences.
- **Strict Secrets Isolation**: All live credentials (`.env`, `credentials.json`, `auth.json`, `tokens.json`, SQLite memory databases, session transcripts) are strictly gitignored. Only non-sensitive templates and declarative instructions are committed.
- **Dual Execution Modes**:
  - **Native**: Ultra-fast install and execution via Astral's `uv`.
  - **Docker Compose**: Containerized execution with persistent volumes for config, memories, and skills.
- **Model Routing**: Pre-configured for OpenRouter (`openrouter/google/gemini-3.7-flash` with 1M context, multimodal tool calling, and fast reasoning) alongside Nous Portal, Anthropic, and OpenAI fallbacks.
- **Messaging Gateway Support**: Ready-to-use configs for running unattended bots on Telegram, Discord, Slack, Signal, and WhatsApp.

---

## Directory Structure

```
hermes-setup/
├── config/
│   ├── config.template.json    # Base config template (models, tools, memory, subagents)
│   ├── SOUL.md                 # Operating persona & engineering invariants
│   ├── AGENTS.md               # Multi-agent role delegation guidelines
│   └── cron-tasks.example.json # Scheduled automation examples
├── skills/                     # Reusable, portable agent skills
│   ├── code-analysis/SKILL.md
│   └── research-summary/SKILL.md
├── bin/
│   ├── bootstrap.sh            # Universal 1-command installer
│   ├── doctor.sh               # Health check and environment diagnostics
│   ├── run.sh                  # Interactive CLI runner
│   ├── gateway.sh              # Messaging gateway launcher
│   └── sync.sh                 # Syncs repo persona & skills to ~/.hermes/
├── scripts/
│   └── cloud-init.sh           # 1-click bootstrapper for AWS/Hetzner/DigitalOcean VPS
├── Dockerfile                  # Production container definition
├── docker-compose.yml          # Containerized deployment orchestration
├── .env.example                # Documented environment template
└── .gitignore                  # Robust multi-layer secret exclusion rules
```

---

## Quickstart (Local Machine / WSL)

### 1. Clone & Bootstrap

```bash
git clone https://github.com/cheshirecode/hermes-setup.git
cd hermes-setup

# Run the bootstrap installer (auto-probes OpenRouter key if present)
./bin/bootstrap.sh
```

### 2. Configure API Keys

Edit `.env` to set your model provider credentials:

```bash
cp .env.example .env
chmod 0600 .env
# Edit .env and set OPENROUTER_API_KEY (or NOUS_API_KEY / OPENAI_API_KEY)
```

### 3. Verify & Run

```bash
# Check system and credential diagnostics
./bin/doctor.sh

# Start an interactive conversation with Hermes
./bin/run.sh
```

---

## Docker Quickstart

To run Hermes Agent isolated in Docker with persistent memory:

```bash
# 1. Ensure .env is populated with your API keys
cp .env.example .env

# 2. Build and run via Docker Compose
docker compose up -d

# 3. Attach to the interactive Hermes CLI
docker compose exec hermes-agent hermes

# 4. Or start the messaging gateway
docker compose exec hermes-agent hermes gateway
```

---

## Deploying on Cloud VPS / GPU Instances

For fresh cloud VMs (Ubuntu 22.04 / 24.04 on Hetzner, AWS EC2, DigitalOcean, Vultr):

```bash
# As root or sudo user on the remote server:
git clone https://github.com/cheshirecode/hermes-setup.git /opt/hermes-setup
cd /opt/hermes-setup
./bin/bootstrap.sh
```

---

## Synchronizing Changes Across Machines

When you update `config/SOUL.md`, `config/AGENTS.md`, or add new skills to `skills/`:

```bash
# Commit and push from your primary machine
git add config/ skills/
git commit -m "feat: add new custom skill"
git push origin main

# Pull on other machines
git pull origin main
./bin/sync.sh
```

---

## License

[MIT](./LICENSE)
