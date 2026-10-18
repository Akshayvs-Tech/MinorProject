# =============================================================================
# Miniproject — Frontend Dockerfile (Next.js 16 / React 19)
# =============================================================================
# Build context: frontend/ directory
#   docker build -f frontend/Dockerfile -t miniproject-frontend frontend/
# =============================================================================

# ─── Stage 1: install dependencies ──────────────────────────────────────────
FROM node:20-slim AS deps

WORKDIR /app

# Copy package files first (layer cache: npm ci only re-runs if these change)
COPY package.json package-lock.json ./

# Install all dependencies (including devDependencies needed for build)
RUN npm ci

# ─── Stage 2: build the Next.js app ─────────────────────────────────────────
FROM node:20-slim AS builder

WORKDIR /app

# Copy node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy source code
COPY . .

# BACKEND_URL is used at build time in next.config.ts rewrites.
# Default: backend service name in Docker Compose network.
# Override with --build-arg BACKEND_URL=http://my-backend:8000
ARG BACKEND_URL=http://backend:8000
ENV BACKEND_URL=${BACKEND_URL}

# Build the production Next.js app
# Output is .next/ folder
RUN npm run build

# ─── Stage 3: production runtime ────────────────────────────────────────────
FROM node:20-slim AS runtime

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser -m -d /home/appuser appuser

WORKDIR /app

# Copy only what's needed to run the app (not node_modules source, not src)
COPY --from=builder /app/public        ./public
COPY --from=builder /app/.next         ./.next
COPY --from=builder /app/node_modules  ./node_modules
COPY --from=builder /app/package.json  ./package.json
COPY --from=builder /app/next.config.ts ./next.config.ts

# Runtime env — passed at container start via docker-compose
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000', (r) => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["npm", "start"]
