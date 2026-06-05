#!/usr/bin/env bash
# Runs inside the airootfs chroot at build time.
set -uo pipefail

# ── Python venv + AI SDKs ─────────────────────────────────────────────────────
# --system-site-packages gives the venv access to python-evdev from pacman
python -m venv --system-site-packages /opt/archspeech
WHEELS="/usr/local/lib/archspeech/wheels"

if [ -d "$WHEELS" ] && [ "$(ls -A "$WHEELS")" ]; then
    /opt/archspeech/bin/pip install --quiet --no-index --find-links "$WHEELS" \
        anthropic openai
else
    /opt/archspeech/bin/pip install --quiet anthropic openai
fi

# No llama-cpp-python - Ollama handles local inference with automatic
# GPU detection (Vulkan, CPU). Pre-compiled, no chroot build issues.
#
# The qwen2.5:1.5b model store is baked into /var/lib/ollama at build time
# (fetch-deps.sh pulls it on the build host and copies the blob store in), so
# the live system needs ZERO network to run the AI.

# ── Enable core services ──────────────────────────────────────────────────────
systemctl enable ollama.service
systemctl enable aios-model-init.service     # offline warmup - no network, no pull
systemctl enable archspeech.service
systemctl enable archspeech-ptt.service       # Caps Lock push-to-talk (evdev + espeak-ng)
systemctl enable keyd.service
systemctl enable NetworkManager.service

# ── Offline-first: never block boot waiting for a network ─────────────────────
# On a machine with no internet, network-online.target would otherwise stall
# boot until systemd-networkd-wait-online times out - delaying the AI by up to
# two minutes. We don't need synchronous network for the local model, so mask
# the wait. Cloud backends still work: the daemon connects lazily once NM is up.
systemctl mask systemd-networkd-wait-online.service 2>/dev/null || true

# ── Bake-in Ollama model store ownership ──────────────────────────────────────
# The qwen2.5:1.5b store is copied into /var/lib/ollama at build time (see
# fetch-deps.sh). Make sure the ollama service user can read it.
if [ -d /var/lib/ollama ]; then
    chown -R ollama:ollama /var/lib/ollama 2>/dev/null || true
    chmod -R u+rwX,go+rX /var/lib/ollama 2>/dev/null || true
fi

# ── File permissions ──────────────────────────────────────────────────────────
chmod 440 /etc/sudoers.d/archspeech
chmod +x /usr/local/lib/archspeech/installer/profiles/*.sh
chmod +x /usr/local/lib/archspeech/installer/log.sh

echo "ArchAI airootfs customization complete."
