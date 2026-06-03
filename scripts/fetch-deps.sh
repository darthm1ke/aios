#!/usr/bin/env bash
# Run this ONCE before your first build (or when you want to update a dep).
# Downloads TinyLlama and pip wheels into the source tree so rebuilds are fast.
set -euo pipefail

PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
AIROOTFS="$PROJECT/archiso/airootfs"
OLLAMA_DIR="$AIROOTFS/var/lib/ollama"          # baked Ollama model store
WHISPER_DIR="$AIROOTFS/root/.cache/whisper"     # baked whisper STT model
WHEELS_DIR="$AIROOTFS/usr/local/lib/archspeech/wheels"
PKG_CACHE="$PROJECT/pkg-cache"

mkdir -p "$OLLAMA_DIR" "$WHISPER_DIR" "$WHEELS_DIR" "$PKG_CACHE"

echo ""
echo "══════════════════════════════════════════"
echo "  ArchAI — one-time dependency fetch"
echo "══════════════════════════════════════════"
echo ""

# ── Qwen2.5 0.5B — baked into the ISO Ollama store (~400MB) ─────────────────
# We pull on the BUILD host via the system Ollama service (stores under
# /var/lib/ollama as the ollama user), then copy the blob store straight into
# the airootfs tree. On the live system Ollama already has the model — no pull,
# no USB mount, no RAM copy, works fully offline and survives install-to-disk.
HOST_STORE="/var/lib/ollama"
if sudo test -d "$OLLAMA_DIR/manifests/registry.ollama.ai/library/qwen2.5"; then
    echo "✓ qwen2.5:0.5b already baked into airootfs ($(sudo du -sh "$OLLAMA_DIR" | cut -f1))"
else
    echo "▶ Pulling qwen2.5:0.5b on the build host..."
    if ! command -v ollama >/dev/null; then
        echo "✗ ollama not installed on build host — install it: sudo pacman -S ollama"
        exit 1
    fi
    sudo systemctl start ollama 2>/dev/null || true
    ollama pull qwen2.5:0.5b

    if ! sudo test -d "$HOST_STORE/manifests/registry.ollama.ai/library/qwen2.5"; then
        echo "✗ Pull succeeded but model not found in $HOST_STORE — is the system ollama.service the one you pulled with?"
        exit 1
    fi

    echo "▶ Baking model store into airootfs..."
    sudo rm -rf "$OLLAMA_DIR/blobs" "$OLLAMA_DIR/manifests"
    sudo cp -r "$HOST_STORE/blobs"     "$OLLAMA_DIR/blobs"
    sudo cp -r "$HOST_STORE/manifests" "$OLLAMA_DIR/manifests"
    # readable by everyone so it survives the chroot chown in customize_airootfs.sh
    sudo chmod -R a+rX "$OLLAMA_DIR"
    echo "✓ Baked into $OLLAMA_DIR — $(sudo du -sh "$OLLAMA_DIR" | cut -f1)"
fi

# ── pip wheels (pure-Python packages only, cached as wheels) ─────────────────
echo ""
echo "▶ Downloading pip wheels (anthropic, openai)..."
pip download \
    --dest "$WHEELS_DIR" \
    --quiet \
    anthropic openai
echo "✓ Pip wheels cached ($(ls "$WHEELS_DIR" | wc -l) files)"

# evdev: installed via pacman (python-evdev) — no pip wheel needed
# llama-cpp-python: compiles from source — pip caches the build automatically

# ── Whisper base model (~142MB) — baked into the ISO ──────────────────────────
# PTT runs as root and calls `whisper --download-root /root/.cache/whisper`, so
# we stage base.pt right there in the airootfs. No internet needed at boot.
WHISPER_MODEL="$WHISPER_DIR/base.pt"
if [ -f "$WHISPER_MODEL" ]; then
    echo "✓ Whisper base model already baked ($(du -sh "$WHISPER_MODEL" | cut -f1))"
else
    echo "▶ Downloading Whisper base model (~142MB) into airootfs..."
    curl -L --progress-bar \
        "https://openaipublic.azureedge.net/main/whisper/models/ed3a0b6b1c0edf879ad9b11b1af5a0e6ab5db9205f891f668f8b0e6c6326e34e/base.pt" \
        -o "$WHISPER_MODEL"
    echo "✓ Whisper base model baked into airootfs"
fi

echo ""
echo "══════════════════════════════════════════"
echo "  All deps ready. Run rebuild.sh to build."
echo "══════════════════════════════════════════"
echo ""
