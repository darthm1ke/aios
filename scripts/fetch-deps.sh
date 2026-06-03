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
# No sudo, no system service: we run a throwaway user-space Ollama with
# OLLAMA_MODELS pointed straight at the airootfs tree, so `ollama pull` writes
# the blob store EXACTLY where the ISO expects it (/var/lib/ollama). On the
# live system Ollama already has the model — no pull, no USB, works offline and
# survives install-to-disk. customize_airootfs.sh chowns it to ollama at build.
if [ -d "$OLLAMA_DIR/manifests/registry.ollama.ai/library/qwen2.5" ]; then
    echo "✓ qwen2.5:0.5b already baked into airootfs ($(du -sh "$OLLAMA_DIR" | cut -f1))"
else
    if ! command -v ollama >/dev/null; then
        echo "✗ ollama not installed on build host — install it: sudo pacman -S ollama"
        exit 1
    fi
    echo "▶ Starting a throwaway user-space Ollama (models -> airootfs)..."
    export OLLAMA_MODELS="$OLLAMA_DIR"
    ollama serve >/tmp/aios-ollama-fetch.log 2>&1 &
    FETCH_OLLAMA_PID=$!
    trap 'kill $FETCH_OLLAMA_PID 2>/dev/null || true' EXIT
    for i in $(seq 1 30); do
        curl -sf http://localhost:11434/api/version >/dev/null 2>&1 && break
        sleep 1
    done
    echo "▶ Pulling qwen2.5:0.5b..."
    ollama pull qwen2.5:0.5b
    kill $FETCH_OLLAMA_PID 2>/dev/null || true
    trap - EXIT
    if [ ! -d "$OLLAMA_DIR/manifests/registry.ollama.ai/library/qwen2.5" ]; then
        echo "✗ Pull did not land in $OLLAMA_DIR — see /tmp/aios-ollama-fetch.log"
        exit 1
    fi
    chmod -R a+rX "$OLLAMA_DIR"
    echo "✓ Baked into $OLLAMA_DIR — $(du -sh "$OLLAMA_DIR" | cut -f1)"
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
