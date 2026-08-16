FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/home/hermes \
    SHELL=/bin/bash \
    PATH="/home/hermes/.local/bin:/usr/local/bin:${PATH}"

# Install base system tools, python development libraries, and browser headless dependencies
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg sudo git \
      python3 python3-pip python3-yaml python3-venv python3-dev \
      build-essential bash less procps tini ffmpeg \
      libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
      libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
      libgbm1 libpango-1.0-0 libcairo2 libasound2t64 \
    && rm -rf /var/lib/apt/lists/*

# Install Astral uv (ultra-fast Python package installer)
RUN curl -fsSL https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh \
    && uv --version

# Install Node.js 20 LTS for JavaScript/TypeScript tooling
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create non-root hermes user with sudo privileges
ARG HOST_UID=1000
ARG HOST_GID=1000
RUN groupadd -g "$HOST_GID" hermes 2>/dev/null || groupmod -n hermes "$(getent group $HOST_GID | cut -d: -f1)" \
    && useradd -m -u "$HOST_UID" -g hermes -s /bin/bash -d /home/hermes hermes \
    && echo "hermes ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/hermes \
    && chmod 0440 /etc/sudoers.d/hermes

# Install Hermes Agent globally into /usr/local/lib/hermes-agent
RUN uv venv /usr/local/lib/hermes-agent --python python3 \
    && /usr/local/lib/hermes-agent/bin/pip install --no-cache-dir hermes-agent \
    && ln -sf /usr/local/lib/hermes-agent/bin/hermes /usr/local/bin/hermes \
    || true

# Create data and workspace directories
RUN mkdir -p /home/hermes/.hermes /workspace \
    && chown -R hermes:hermes /home/hermes /workspace

USER hermes
WORKDIR /workspace

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["hermes"]
