'use strict';

const express = require('express');
const pino = require('pino');
const client = require('prom-client');

const logger = pino({ level: process.env.LOG_LEVEL || 'info' });
const app = express();
const PORT = process.env.PORT || 3000;

const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests received',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

app.use((req, res, next) => {
  res.on('finish', () => {
    httpRequestsTotal.inc({ method: req.method, route: req.path, status_code: res.statusCode });
    logger.info({ method: req.method, path: req.path, status: res.statusCode }, 'request');
  });
  next();
});

app.get('/', (_req, res) => {
  res.json({ service: 'myapp', status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/healthz', (_req, res) => {
  res.json({ status: 'alive' });
});

app.get('/readyz', (_req, res) => {
  res.json({ status: 'ready' });
});

app.get('/metrics', async (_req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    res.status(500).end(err.message);
  }
});

const server = app.listen(PORT, () => {
  logger.info({ port: PORT, env: process.env.NODE_ENV }, 'server started');
});

process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logger.info('server closed');
    process.exit(0);
  });
});

module.exports = app;
