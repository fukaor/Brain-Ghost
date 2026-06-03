# Force x86_64 — Godot headless binary is x86_64 only
FROM --platform=linux/amd64 ubuntu:24.04

# ============================================================
# System dependencies
# ============================================================
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    sudo \
    ca-certificates \
    ripgrep \
    jq \
    tree \
    unzip \
    wget \
    zip \
    gnupg \
    # Godot headless dependencies
    libfontconfig1 \
    libgl1 \
    libgl1-mesa-dri \
    libxkbcommon0 \
    libx11-6 \
    libxcursor1 \
    libxi6 \
    libxrandr2 \
    libxinerama1 \
    libvulkan1 \
    # Virtual framebuffer — required to render screens to PNG for visual
    # verification (godot --rendering-driver opengl3 via xvfb-run + Mesa swrast).
    # Headless alone cannot create a GL context; UI capture needs this.
    xvfb \
    # Android SDK dependencies
    openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Node.js 22 (LTS — required for Claude Code)
# Ubuntu 24.04's apt nodejs is v18, which is too old.
# ============================================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Timezone (Asia/Tokyo)
# ============================================================
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && echo "Asia/Tokyo" > /etc/timezone

# ============================================================
# Claude Code
# ============================================================
RUN npm install -g @anthropic-ai/claude-code

# ============================================================
# Firecrawl CLI (web scraping / research plugin dependency)
# ============================================================
RUN npm install -g firecrawl

# ============================================================
# Godot 4.6.3 (headless)
# ============================================================
ENV GODOT_VERSION="4.6.3"
ENV GODOT_RELEASE="stable"

# Download Godot editor (headless)
RUN wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64.zip" -O /tmp/godot.zip \
    && unzip /tmp/godot.zip -d /tmp \
    && mv "/tmp/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm /tmp/godot.zip

# Download export templates (Web + Android)
# The .tpz contains a "templates/" directory; actual subdir name varies by version.
RUN wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_export_templates.tpz" -O /tmp/templates.tpz \
    && mkdir -p /tmp/templates \
    && unzip /tmp/templates.tpz -d /tmp/templates \
    && TEMPLATE_DIR=$(find /tmp/templates -mindepth 1 -maxdepth 1 -type d | head -1) \
    && mkdir -p /root/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_RELEASE} \
    && mv ${TEMPLATE_DIR}/* /root/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_RELEASE}/ \
    && rm -rf /tmp/templates /tmp/templates.tpz

# NOTE: "godot --headless --version" is skipped at build time.
# On Apple Silicon, QEMU emulation may fail during docker build.
# Verify after container start: godot --headless --version

# ============================================================
# Android SDK (for Android export)
# ============================================================
ENV ANDROID_HOME="/opt/android-sdk"
ENV ANDROID_SDK_ROOT="${ANDROID_HOME}"
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"

RUN mkdir -p ${ANDROID_HOME} \
    && wget -q "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -O /tmp/cmdline-tools.zip \
    && unzip /tmp/cmdline-tools.zip -d /tmp/cmdline-tools \
    && mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && mv /tmp/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip \
    && yes | sdkmanager --licenses > /dev/null 2>&1 \
    && sdkmanager "platform-tools" "build-tools;34.0.0" "platforms;android-34" > /dev/null 2>&1

# ============================================================
# User setup
# ============================================================
ARG USERNAME=godot
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# Remove default ubuntu user (UID/GID 1000) if exists, then create godot user
RUN userdel -r ubuntu 2>/dev/null || true \
    && getent group ubuntu > /dev/null 2>&1 && groupdel ubuntu || true \
    && getent group ${USER_GID} > /dev/null 2>&1 && groupdel $(getent group ${USER_GID} | cut -d: -f1) || true \
    && groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Copy export templates to user home (with correct ownership)
RUN mkdir -p /home/${USERNAME}/.local/share/godot/export_templates \
    && cp -r /root/.local/share/godot/export_templates/* /home/${USERNAME}/.local/share/godot/export_templates/ \
    && mkdir -p /home/${USERNAME}/.config/godot \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.local \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config

# Persistent directories
RUN mkdir -p /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R ${USERNAME}:${USERNAME} /commandhistory \
    && mkdir -p /home/${USERNAME}/.claude \
    && mkdir -p /home/${USERNAME}/.claude-plugins \
    && mkdir -p /home/${USERNAME}/.config/gh \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

# ============================================================
# Workspace
# ============================================================
WORKDIR /workspace

USER ${USERNAME}

# ============================================================
# Git config
# ============================================================
RUN git config --global user.name "fukaor" \
    && git config --global user.email "hello@reigals.com" \
    && git config --global init.defaultBranch main \
    && git config --global credential.helper store \
    && git config --global pull.rebase false

# ============================================================
# Bash prompt + aliases
# ============================================================
RUN echo '' >> /home/${USERNAME}/.bashrc \
    && echo '# --- Custom prompt (dir + git branch) ---' >> /home/${USERNAME}/.bashrc \
    && echo 'parse_git_branch() { git branch 2>/dev/null | sed -e "/^[^*]/d" -e "s/* \(.*\)/ (\1)/"; }' >> /home/${USERNAME}/.bashrc \
    && echo 'PS1='"'"'\[\033[1;34m\]\W\[\033[0;33m\]$(parse_git_branch)\[\033[0m\] $ '"'"'' >> /home/${USERNAME}/.bashrc \
    && echo '' >> /home/${USERNAME}/.bashrc \
    && echo '# --- Aliases ---' >> /home/${USERNAME}/.bashrc \
    && echo 'alias ll="ls -la --color=auto"' >> /home/${USERNAME}/.bashrc \
    && echo 'alias gs="git status"' >> /home/${USERNAME}/.bashrc \
    && echo 'alias gd="git diff"' >> /home/${USERNAME}/.bashrc \
    && echo 'alias gl="git log --oneline -20"' >> /home/${USERNAME}/.bashrc \
    && echo 'alias cc="claude"' >> /home/${USERNAME}/.bashrc \
    && echo '' >> /home/${USERNAME}/.bashrc \
    && echo '# --- Godot aliases ---' >> /home/${USERNAME}/.bashrc \
    && echo 'alias godot-export-web="godot --headless --export-release Web"' >> /home/${USERNAME}/.bashrc \
    && echo 'alias godot-export-android="godot --headless --export-release Android"' >> /home/${USERNAME}/.bashrc \
    && echo 'alias godot-import="godot --headless --import"' >> /home/${USERNAME}/.bashrc