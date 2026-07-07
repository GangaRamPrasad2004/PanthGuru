

set -e

# Default to 8080 if Sevalla hasn't set PORT (e.g. local testing)
export PORT="${PORT:-8080}"

echo "=========================================="
echo "  — Starting up"
echo " Streamlit  → 0.0.0.0:${PORT} (public)"
echo " FastAPI    → 127.0.0.1:8000  (internal)"
echo "=========================================="

# Launch supervisord (manages both processes)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
