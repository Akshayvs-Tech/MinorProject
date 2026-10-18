## ── Makefile for Miniproject Docker ──────────────────────────────────────────
## Simple shortcuts so you don't have to remember docker compose commands.
## Usage:   make up        (start everything)
##          make down      (stop everything)
##          make logs      (see all logs)
##          make help      (list all commands)

.PHONY: help up up-prod down logs logs-backend logs-frontend rebuild reset \
        build shell-backend shell-frontend ps push save load

## ─── Default target ──────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  Miniproject Docker Commands"
	@echo "  ────────────────────────────────────────────────────"
	@echo "  make up              Start in DEV mode (hot reload)"
	@echo "  make up-prod         Start in PRODUCTION mode"
	@echo "  make down            Stop and remove containers"
	@echo "  make logs            Follow logs from all services"
	@echo "  make logs-backend    Follow backend logs only"
	@echo "  make logs-frontend   Follow frontend logs only"
	@echo "  make rebuild         Force rebuild all images then start (prod)"
	@echo "  make reset           Destroy everything including volumes (CAUTION!)"
	@echo "  make ps              List running containers and their status"
	@echo "  make shell-backend   Open a bash shell inside the backend container"
	@echo "  make shell-frontend  Open a shell inside the frontend container"
	@echo "  make push            Push images to Docker Hub (set DOCKER_USER first)"
	@echo "  make save            Save images to .tar files for offline transfer"
	@echo ""

## ─── Start ───────────────────────────────────────────────────────────────────

# Dev mode: uses docker-compose.override.yml (hot reload, source mounts)
up:
	docker compose up --build

# Production mode: only uses docker-compose.yml (no source mounts, built image)
up-prod:
	docker compose -f docker-compose.yml up --build -d
	@echo ""
	@echo "  ✅  Services starting up..."
	@echo "  Frontend: http://localhost:$$(grep FRONTEND_PORT .env 2>/dev/null | cut -d= -f2 || echo 3000)"
	@echo "  Backend:  http://localhost:$$(grep BACKEND_PORT  .env 2>/dev/null | cut -d= -f2 || echo 8000)"
	@echo ""
	@echo "  Run 'make logs' to follow logs."

## ─── Stop ────────────────────────────────────────────────────────────────────

down:
	docker compose down

## ─── Logs ────────────────────────────────────────────────────────────────────

logs:
	docker compose logs -f

logs-backend:
	docker compose logs -f backend

logs-frontend:
	docker compose logs -f frontend

## ─── Rebuild ─────────────────────────────────────────────────────────────────

# Force a full rebuild (useful after requirements.txt changes)
rebuild:
	docker compose -f docker-compose.yml build --no-cache
	docker compose -f docker-compose.yml up -d

## ─── Reset ────────────────────────────────────────────────────────────────────
# WARNING: this deletes ALL data in volumes (outputs, model cache)
reset:
	@echo "⚠️  This will delete all containers, volumes, and downloaded models."
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read _
	docker compose down -v --remove-orphans
	docker system prune -f

## ─── Status ──────────────────────────────────────────────────────────────────

ps:
	docker compose ps

## ─── Shells ──────────────────────────────────────────────────────────────────

shell-backend:
	docker compose exec backend bash

shell-frontend:
	docker compose exec frontend sh

## ─── Docker Hub Push ─────────────────────────────────────────────────────────
# Set DOCKER_USER to your Docker Hub username before running:
#   DOCKER_USER=myusername make push

DOCKER_USER ?= yourusername

push:
	@echo "Tagging and pushing to Docker Hub as $(DOCKER_USER)..."
	docker tag miniproject-backend:latest $(DOCKER_USER)/miniproject-backend:latest
	docker tag miniproject-frontend:latest $(DOCKER_USER)/miniproject-frontend:latest
	docker push $(DOCKER_USER)/miniproject-backend:latest
	docker push $(DOCKER_USER)/miniproject-frontend:latest
	@echo "✅ Done! On another machine, run: DOCKER_USER=$(DOCKER_USER) make pull-and-run"

## ─── Offline Transfer ────────────────────────────────────────────────────────

# Save images to tar files for USB/offline transfer
save:
	@echo "Saving images to miniproject-images.tar (this may take a few minutes)..."
	docker save miniproject-backend:latest miniproject-frontend:latest \
	  | gzip > miniproject-images.tar.gz
	@echo "✅ Saved to miniproject-images.tar.gz"
	@echo "Copy this file to the other machine, then run:"
	@echo "  docker load < miniproject-images.tar.gz"
	@echo "  docker compose -f docker-compose.yml up -d"

# Load images from saved tar file
load:
	@echo "Loading images from miniproject-images.tar.gz..."
	docker load < miniproject-images.tar.gz
	@echo "✅ Images loaded. Run 'make up-prod' to start."
