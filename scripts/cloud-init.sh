#!/usr/bin/env bash
# ==============================================================================
# Cloud-Init / User-Data Script for Cloud VPS & GPU Instances
# ==============================================================================
# Runs on first boot for Ubuntu 22.04 / 24.04 (AWS EC2, Hetzner, DigitalOcean, Vultr)
# ==============================================================================

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "=== Hermes Agent Cloud Initialization ==="

# 1. Update and install base tools
apt-get update -qq && apt-get install -y --no-install-recommends \
  ca-certificates curl git python3 python3-pip python3-venv python3-dev \
  build-essential tini procps ffmpeg jq ripgrep

# 2. Install Astral uv
curl -fsSL https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh

# 3. Install Docker if desired
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  usermod -aG docker ubuntu || true
fi

# 4. Clone hermes-setup repo if not present
cd /opt
if [[ ! -d "/opt/hermes-setup" ]]; then
  git clone https://github.com/cheshirecode/hermes-setup.git
  cd hermes-setup
  cp .env.example .env
  chmod 0600 .env
fi

# 5. Install Hermes Agent CLI
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup

echo "=== Cloud Init Completed. SSH into machine and run ./bin/bootstrap.sh ==="
