# Miniproject — Person Finder 🎯

AI-powered person finder using **YOLOv8 + ArcFace + OSNet + DeepSORT + Action Recognition**.

Upload a reference photo and a video — the system finds and tracks the person, recognizes their actions, and gives you an annotated output video.

---

## 🏗️ Architecture

```
Browser → Frontend (Next.js 16, port 3000)
              ↓  /api/* proxied to backend
          Backend (FastAPI, port 8000)
              └── ML Pipeline (inline)
                    ├── YOLOv8 (person detection)
                    ├── ArcFace (face matching)
                    ├── OSNet (body re-ID)
                    ├── DeepSORT (tracking)
                    └── LSTM (action recognition)

Database: MongoDB Atlas (cloud — not containerized)
```

---

## ⚡ Quick Start (One Command)

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and **running**
- Your MongoDB Atlas connection string

### Steps

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd Miniproject

# 2. Create your environment file
cp .env.example .env

# 3. Edit .env and fill in your values:
#    MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/
#    JWT_SECRET=your-long-random-secret-key
nano .env   # or open with any text editor

# 4. Build and start everything
docker compose up --build

# That's it! Open http://localhost:3000 in your browser.
```

> **First build takes 10–20 minutes** — it downloads PyTorch (~2 GB) and other ML libraries. Subsequent builds are fast (Docker caches layers).

> **First run also downloads ArcFace model (~300 MB)** — this only happens once. It's cached in a Docker volume.

---

## 🚀 Three Ways to Run on Another Laptop

### Method A — Git Clone (Recommended)

> Use this when the other laptop has internet access.

```bash
# On the other laptop:
# 1. Install Docker Desktop from https://www.docker.com/products/docker-desktop/
# 2. Clone the repo
git clone <your-repo-url>
cd Miniproject

# 3. Create .env file with your secrets
cp .env.example .env
# Edit .env with your MONGO_URI and JWT_SECRET

# 4. Build and run (takes 10-20 min first time)
docker compose up --build
```

Open **http://localhost:3000** — done!

---

### Method B — Docker Hub (No Source Code Needed)

> Use this when you don't want to share source code. Only the built images are needed.

**On your machine (push images):**

```bash
# Log in to Docker Hub
docker login

# Build production images
docker compose -f docker-compose.yml build

# Push (replace YOUR_DOCKERHUB_USERNAME with your username)
docker tag miniproject-backend:latest YOUR_DOCKERHUB_USERNAME/miniproject-backend:latest
docker tag miniproject-frontend:latest YOUR_DOCKERHUB_USERNAME/miniproject-frontend:latest
docker push YOUR_DOCKERHUB_USERNAME/miniproject-backend:latest
docker push YOUR_DOCKERHUB_USERNAME/miniproject-frontend:latest
```

**On the other laptop (no code needed):**

```bash
# 1. Install Docker Desktop
# 2. Create a folder and add just two files:

# File 1: docker-compose.yml (copy from repo, or create this minimal version)
# File 2: .env (with your MONGO_URI and JWT_SECRET)

# Then pull and run:
docker compose pull
docker compose up -d
```

For the minimal `docker-compose.yml` on the receiving laptop, replace the `build:` sections with `image:`:
```yaml
services:
  backend:
    image: YOUR_DOCKERHUB_USERNAME/miniproject-backend:latest
    # ... rest of backend config ...
  frontend:
    image: YOUR_DOCKERHUB_USERNAME/miniproject-frontend:latest
    # ... rest of frontend config ...
```

---

### Method C — Offline USB Transfer

> Use this when there's no internet on the target laptop.

**On your machine:**

```bash
# Build images first
docker compose -f docker-compose.yml build

# Save both images to one compressed file (~3-4 GB)
make save
# OR manually:
docker save miniproject-backend:latest miniproject-frontend:latest | gzip > miniproject-images.tar.gz

# Copy miniproject-images.tar.gz + docker-compose.yml + .env.example to USB drive
```

**On the other laptop:**

```bash
# 1. Install Docker Desktop
# 2. Copy files from USB to a folder

# 3. Load the images
docker load < miniproject-images.tar.gz

# 4. Create .env with your secrets
cp .env.example .env
nano .env

# 5. Start
docker compose -f docker-compose.yml up -d
```

---

## 🌐 Access from Another Device on the Same Wi-Fi

Other devices on your network can access the app using your **host machine's IP address** instead of `localhost`.

**Find your IP address:**

```bash
# macOS / Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# Windows (PowerShell)
ipconfig | findstr "IPv4"
```

**Access from another device:**
- Frontend: `http://YOUR_IP_ADDRESS:3000`
- Backend API: `http://YOUR_IP_ADDRESS:8000`

**Firewall note:** If the other device can't connect, you may need to allow ports 3000 and 8000 through your firewall:
- **macOS**: System Settings → Network → Firewall → allow incoming connections for Docker
- **Windows**: Windows Defender Firewall → Allow an app → Docker Desktop
- **Linux**: `sudo ufw allow 3000/tcp && sudo ufw allow 8000/tcp`

---

## 📋 Daily Commands

```bash
# Start everything (dev mode with hot reload)
make up
# OR: docker compose up

# Start in production mode (detached/background)
make up-prod
# OR: docker compose -f docker-compose.yml up -d

# Stop everything
make down
# OR: docker compose down

# Follow logs (all services)
make logs
# OR: docker compose logs -f

# Backend logs only
make logs-backend

# Frontend logs only
make logs-frontend

# See container status
make ps

# Force rebuild (after changing requirements.txt or package.json)
make rebuild

# Open a terminal inside the backend container
make shell-backend

# Nuclear reset — deletes everything including volumes/downloaded models
make reset
```

---

## 🌍 URLs & Ports

| Service | URL | Port |
|---------|-----|------|
| Frontend | http://localhost:3000 | 3000 |
| Backend API | http://localhost:8000 | 8000 |
| API Docs (Swagger) | http://localhost:8000/docs | 8000 |
| Health Check | http://localhost:8000/health | 8000 |
| DB Health | http://localhost:8000/db-health | 8000 |

---

## 🔑 Environment Variables (`.env`)

| Variable | Required | Description |
|----------|----------|-------------|
| `MONGO_URI` | ✅ Yes | MongoDB Atlas connection string |
| `JWT_SECRET` | ✅ Yes | Secret for signing JWT tokens (min 32 chars) |
| `DB_NAME` | No | Database name (default: `person_finder`) |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | No | Token lifetime in minutes (default: `60`) |
| `FRONTEND_PORT` | No | Frontend host port (default: `3000`) |
| `BACKEND_PORT` | No | Backend host port (default: `8000`) |

---

## 🔨 Building for Multiple CPU Architectures

> Use this to make images that work on both Intel/AMD (amd64) and Apple Silicon (arm64).

```bash
# One-time setup: create a multi-platform builder
docker buildx create --name multiplatform --use

# Build and push for both architectures at once
# (Must be pushing to a registry — can't load multi-platform into local daemon)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f backend/Dockerfile \
  -t YOUR_DOCKERHUB_USERNAME/miniproject-backend:latest \
  --push .

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f frontend/Dockerfile \
  -t YOUR_DOCKERHUB_USERNAME/miniproject-frontend:latest \
  --push ./frontend

# On the other laptop, just docker pull — Docker automatically picks the right arch
```

---

## 🐛 Troubleshooting

### ❌ "Port already in use" / "address already in use"

```bash
# Find what's using port 3000
lsof -i :3000   # macOS/Linux
netstat -ano | findstr :3000   # Windows

# Option 1: Kill the process using the port
kill -9 $(lsof -ti:3000)

# Option 2: Change the port in .env
FRONTEND_PORT=3001
BACKEND_PORT=8001
```

---

### ❌ "Docker not running" / "Cannot connect to Docker daemon"

```bash
# macOS: Open Docker Desktop from Applications
open -a Docker

# Linux:
sudo systemctl start docker

# Windows: Start Docker Desktop from the Start Menu
# Look for the Docker whale icon in the system tray
```

---

### ❌ "Permission denied" errors

```bash
# If you see permission errors on Linux:
sudo usermod -aG docker $USER
# Then log out and log back in

# If volume permission errors:
docker compose down -v   # removes volumes
docker compose up --build
```

---

### 🐢 "First build is very slow"

This is normal! The first build downloads:
- Python 3.11 base image (~150 MB)
- PyTorch 2.10 + torchvision (~2 GB)
- OpenCV, insightface, mediapipe, etc. (~500 MB)
- Node.js 20 + Next.js dependencies (~300 MB)
- ArcFace buffalo_l model (~300 MB — downloaded at first startup, not during build)

**Total: ~3-4 GB, ~15-30 minutes on a typical connection.**

After the first build, subsequent builds are very fast (Docker caches unchanged layers).

---

### ❌ MongoDB connection fails

```bash
# Check db-health endpoint
curl http://localhost:8000/db-health

# Common causes:
# 1. Wrong MONGO_URI in .env
# 2. Your IP not whitelisted in Atlas:
#    Atlas Dashboard → Network Access → Add IP → Add Current IP
# 3. Wrong username/password in the URI
```

---

### ❌ Backend is slow to start / health check fails at first

This is expected. The backend loads:
- YOLOv8 model (fast)
- OSNet model (~2-5 seconds)
- ArcFace models (first time: downloads ~300 MB, then loads)
- MediaPipe pose model (downloads on first request)

The `start_period: 90s` in the health check gives it time. Wait 2-3 minutes.

---

### 🎥 GPU / CUDA Notes

The current setup runs on **CPU only** (works everywhere). If you have an NVIDIA GPU and want to use it:

1. Install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacuda/container-toolkit/install-guide.html)
2. Add to the backend service in `docker-compose.yml`:
   ```yaml
   deploy:
     resources:
       reservations:
         devices:
           - driver: nvidia
             count: 1
             capabilities: [gpu]
   ```
3. The ML code already detects CUDA automatically (`device = "cuda" if torch.cuda.is_available() else "cpu"`)

---

### 📷 Webcam Notes

This project processes **uploaded videos** — it does not use a webcam directly. No special configuration is needed.

---

## 📁 Files Created by This Docker Setup

```
Miniproject/
├── docker-compose.yml          ← Main orchestration file (production)
├── docker-compose.override.yml ← Dev mode (hot reload) — auto-merged
├── .env.example                ← Template for secrets (commit this)
├── .env                        ← Your real secrets (NEVER commit this)
├── Makefile                    ← Shortcut commands
├── backend/
│   ├── Dockerfile              ← Backend + ML image definition
│   └── .dockerignore           ← Files excluded from backend image
└── frontend/
    ├── Dockerfile              ← Frontend image definition
    ├── .dockerignore           ← Files excluded from frontend image
    └── next.config.ts          ← Modified: BACKEND_URL is now configurable
```
