# =============================================================================
# Miniproject — Backend + ML Service Dockerfile
# =============================================================================
# This single image runs both FastAPI and the ML pipeline (YOLOv8, ArcFace,
# OSNet, DeepSORT, MediaPipe LSTM). They share one Python process.
#
# Build context: project root (Miniproject/)
#   docker build -f backend/Dockerfile -t miniproject-backend .
# =============================================================================

# ─── Stage 1: dependency installer ──────────────────────────────────────────
# We use a full Debian image (not alpine) because PyTorch, OpenCV, and
# insightface need glibc and many system C libraries that musl (alpine) breaks.
FROM python:3.11-slim AS deps

# System packages needed to compile Python wheels and run CV/ML code
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install wheel for faster installs
RUN pip install --upgrade pip setuptools wheel

WORKDIR /build

# ── Copy only the requirements file first (layer cache trick) ────────────────
# We use a Docker-specific requirements file (requirements.docker.txt) that:
#   - Uses mediapipe>=0.10.13,<1.0 (no arm64 wheel for exact 0.10.33)
#   - Uses opencv-python-headless (no display server needed in Docker)
#   - Removes pytorchvideo (only used in demo.py, not production pipeline)
COPY backend/requirements.docker.txt ./requirements.txt

# Install all Python dependencies into /install so we can copy them cleanly
# --no-cache-dir keeps the image smaller
# torch is large (~2GB); this layer will be cached after the first build
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ─── Stage 2: runtime image ──────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

# Same runtime system libraries (no build tools needed here)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from deps stage
COPY --from=deps /install /usr/local

# ── Create a non-root user for security ──────────────────────────────────────
RUN groupadd -r appuser && useradd -r -g appuser -m -d /home/appuser appuser

# ── Set working directory ─────────────────────────────────────────────────────
WORKDIR /app

# ── Copy application code ─────────────────────────────────────────────────────
# Copy in this order so changing app code doesn't invalidate dependency layers.

# 1. ML model weights
COPY yolov8n.pt ./yolov8n.pt
COPY ml_pipeline/slowfast_model/ ./ml_pipeline/slowfast_model/

# 2. Local torchreid source (used as a library — not on PyPI)
COPY ml_pipeline/torchreid/ ./ml_pipeline/torchreid/

# 3. Rest of ML pipeline
COPY ml_pipeline/__init__.py       ./ml_pipeline/__init__.py
COPY ml_pipeline/config.py         ./ml_pipeline/config.py
COPY ml_pipeline/arcface.py        ./ml_pipeline/arcface.py
COPY ml_pipeline/osnet_reid.py     ./ml_pipeline/osnet_reid.py
COPY ml_pipeline/action_recognition.py ./ml_pipeline/action_recognition.py
COPY ml_pipeline/pipeline.py       ./ml_pipeline/pipeline.py

# 4. Backend application
COPY backend/ ./backend/

# ── Data directories ──────────────────────────────────────────────────────────
# These are empty at image build time. Real data is mounted via Docker volumes.
RUN mkdir -p ./data/inputs ./data/outputs

# ── PYTHONPATH ────────────────────────────────────────────────────────────────
# The project expects to be imported from /app (i.e., `from backend.xxx import ...`
# and `from ml_pipeline.xxx import ...`)
# Also add ml_pipeline/ so local torchreid source is importable.
ENV PYTHONPATH=/app:/app/ml_pipeline

# ── ArcFace model cache directory ─────────────────────────────────────────────
# insightface downloads buffalo_l model here on first run.
# We point it to /models which is mounted as a named volume so
# the ~300MB model survives container restarts.
ENV INSIGHTFACE_HOME=/models

# ── Runtime environment defaults ─────────────────────────────────────────────
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# ── Transfer ownership to non-root user ──────────────────────────────────────
RUN chown -R appuser:appuser /app
# /models will be a volume; we need the user to be able to write there too
RUN mkdir -p /models && chown -R appuser:appuser /models

USER appuser

# ── Port ─────────────────────────────────────────────────────────────────────
EXPOSE 8000

# ── Health check ─────────────────────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:8000/health || exit 1

# ── Start command ─────────────────────────────────────────────────────────────
# Run uvicorn from /app. backend.app:app refers to /app/backend/app.py → app object.
CMD ["uvicorn", "backend.app:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
