# syntax=docker/dockerfile:1
# ─────────────────────────────────────────────
# Stage 1 – builder: installs ALL deps and runs the build step
# ─────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy manifests first to exploit layer-cache: only invalidated when
# dependencies actually change, not every source edit.
COPY app/package*.json ./
RUN npm ci

COPY app/ .
RUN npm run build

# ─────────────────────────────────────────────
# Stage 2 – runtime: lean production image
# ─────────────────────────────────────────────
FROM node:20-alpine AS runtime

ENV NODE_ENV=production

# Non-root user created before any COPY so --chown works
RUN addgroup -g 1001 -S appgroup && \
    adduser  -u 1001 -S appuser -G appgroup

WORKDIR /app

# Install production-only deps from a clean slate (no dev deps bleed-in)
COPY app/package*.json ./
RUN npm ci --omit=dev && \
    chown -R appuser:appgroup /app

# Copy built application source from the builder stage
COPY --from=builder --chown=appuser:appgroup /app/server.js ./

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:3000/healthz || exit 1

# Run node directly: avoids npm wrapper, ensures SIGTERM reaches the process
CMD ["node", "server.js"]
