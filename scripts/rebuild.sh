#!/usr/bin/env bash
# AIos fast rebuild — wipes only the work directory, preserves all caches.
# Packages, model, and pip wheels are never re-downloaded.
set -euo pipefail

PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$PROJECT/work"
OUT="$PROJECT/build"
PROFILE="$PROJECT/archiso"

# ── Preflight checks ──────────────────────────────────────────────────────────
if ! command -v mkarchiso &>/dev/null; then
    echo "✗ mkarchiso not found. Run: sudo pacman -S archiso"
    exit 1
fi

MODEL_STORE="$PROFILE/airootfs/var/lib/ollama/manifests/registry.ollama.ai/library/qwen2.5"
if ! sudo test -d "$MODEL_STORE"; then
    echo "✗ Baked Ollama model store not found ($MODEL_STORE)."
    echo "  Run:  bash $PROJECT/scripts/fetch-deps.sh"
    exit 1
fi

# ── Safe cleanup: read live mounts from /proc/mounts and detach all ──────────
echo ""
echo "▶ Cleaning work directory..."

LIVE=$(grep "$WORK" /proc/mounts 2>/dev/null | awk '{print $2}' | sort -r) || true
if [ -n "$LIVE" ]; then
    echo "  Found live mounts — detaching..."
    echo "$LIVE" | xargs -I{} sudo umount -l {} 2>/dev/null || true
fi

sudo rm -rf "$WORK"
mkdir -p "$OUT"

# ── Build ─────────────────────────────────────────────────────────────────────
echo "▶ Building AIos ISO..."
echo "  Packages cached in:  $PROJECT/pkg-cache/"
echo "  Model:               qwen2.5:0.5b (baked into Ollama store)"
echo ""

sudo mkarchiso -v -w "$WORK" -o "$OUT" "$PROFILE"

# ── Clean old ISOs — keep only the latest ────────────────────────────────────
LATEST=$(find "$OUT" -name "aios-*.iso" | sort -t- -k2 -V | tail -1)
find "$OUT" -name "*.iso" ! -path "$LATEST" -delete 2>/dev/null || true

# ── Report ────────────────────────────────────────────────────────────────────
ISO=$(find "$OUT" -name "aios-*.iso" | sort -t- -k2 -V | tail -1)
if [ -f "$ISO" ]; then
    SIZE=$(du -sh "$ISO" | cut -f1)
    echo ""
    echo "══════════════════════════════════════════════════════"
    echo "  ✓ AIos ISO ready: $(basename "$ISO")"
    echo "  ✓ Size: $SIZE"
    echo ""
    echo "  Test in VM:"
    echo "  bash $PROJECT/scripts/test-vm.sh"
    echo ""
    echo "  Deploy to Ventoy:"
    echo "  cp $ISO /run/media/\$USER/Ventoy/"
    echo "══════════════════════════════════════════════════════"
    echo ""
else
    echo "✗ Build failed — no aios-*.iso found in $OUT"
    exit 1
fi
