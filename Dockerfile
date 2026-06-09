FROM node:20-alpine AS builder
WORKDIR /app
COPY app/package*.json ./
RUN npm ci
COPY app/ .
RUN npm run build

FROM node:20-alpine
ENV NODE_ENV=production
RUN addgroup -g 1001 -S appgroup && \
    adduser  -u 1001 -S appuser -G appgroup
WORKDIR /app
COPY app/package*.json ./
RUN npm ci --omit=dev && \
    chown -R appuser:appgroup /app
COPY --from=builder --chown=appuser:appgroup /app/server.js ./
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:3000/healthz || exit 1
CMD ["node", "server.js"]
