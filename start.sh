#!/usr/bin/env bash
# ============================================================
# PanthGuru (पन्थगुरु) — Container Entrypoint
# ============================================================
# Sevalla injects the PORT env var at runtime.
# This script ensures PORT has a default, then starts supervisord.
# ============================================================

set -e

# Default to 8080 if Sevalla hasn't set PORT (e.g. local testing)
export PORT="${PORT:-8080}"

echo "=========================================="
echo " 🕉️  PanthGuru (पन्थगुरु) — Starting up"
echo " Streamlit  → 0.0.0.0:${PORT} (public)"
echo " FastAPI    → 127.0.0.1:8000  (internal)"
echo "=========================================="

# Launch supervisord (manages both processes)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
