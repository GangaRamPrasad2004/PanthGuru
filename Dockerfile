# ============================================================
# PanthGuru (पन्थगुरु) — Production Dockerfile (Sevalla)
# ============================================================
# Build strategy : Dockerfile
# Platform       : Sevalla (PaaS by Kinsta)
# Architecture   : linux/amd64 (required by Sevalla)
# Processes      : FastAPI (internal :8000) + Streamlit (public :$PORT)
# Process manager: supervisord
# ============================================================

# ---------- Stage 1: Builder ----------
FROM python:3.13-slim AS builder

# Prevent Python from writing .pyc files and enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install build-time system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies (layer cache optimized)
COPY requirement.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirement.txt


# ---------- Stage 2: Production ----------
FROM python:3.13-slim AS production

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install runtime system dependencies
#   - supervisor : manages FastAPI + Streamlit processes
#   - bash       : required by Sevalla Web Terminal
#   - curl       : used by Docker HEALTHCHECK
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        supervisor \
        bash \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder stage
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy entrypoint script and make it executable
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Copy the entire application source
COPY . .

# Create a non-root user for security
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 --shell /bin/bash --create-home appuser && \
    chown -R appuser:appuser /app && \
    mkdir -p /var/log/supervisor && \
    chown -R appuser:appuser /var/log/supervisor

# Sevalla provides PORT as an environment variable at runtime.
# Default to 8080 for local testing.
ENV PORT=8080

# Expose the Streamlit port (Sevalla reads this as a hint)
EXPOSE ${PORT}

# Health-check: Streamlit exposes /_stcore/health
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:${PORT}/_stcore/health || exit 1

# Run as non-root
USER appuser

# Start both services via the entrypoint script
ENTRYPOINT ["/app/start.sh"]
