#!/usr/bin/env bun
/**
 * Skill Loader Daemon — HTTP API for skill registry
 * Port: SKILL_LOADER_PORT env or 37891
 */
import { Hono } from 'hono';
import { getSkillHotLoader } from './hot-loader';
import { getSkillRegistry } from './registry';
import { createLogger } from '../core/utils/logger';

const log = createLogger('SkillLoaderDaemon');
const PORT = parseInt(process.env.SKILL_LOADER_PORT || '37891');
const startTime = Date.now();

const app = new Hono();
const registry = getSkillRegistry();
const hotLoader = getSkillHotLoader();

// Sync hot-loader discoveries into registry
hotLoader.on((event, manifest) => {
  if (event === 'skill:added' || event === 'skill:updated') {
    registry.register(manifest, manifest.entrypoint);
  }
});

hotLoader.start();
log.info('Skill hot-loader started');

// ============================================================================
// Routes
// ============================================================================

app.get('/skills', (c) => {
  const skills = registry.listAll();
  return c.json(skills.map((s) => s.manifest));
});

app.get('/skills/:id', (c) => {
  const id = c.req.param('id');
  const resolution = registry.resolve(id);
  if (!resolution) {
    return c.json({ error: `Skill not found: ${id}` }, 404);
  }
  return c.json(resolution.manifest);
});

app.post('/reload', (c) => {
  const found = hotLoader.scan();
  for (const manifest of found) {
    registry.register(manifest, manifest.entrypoint);
  }
  log.info(`Reloaded: ${found.length} skills`);
  return c.json({ reloaded: found.length });
});

app.get('/health', (c) => {
  const skills = registry.listAll();
  return c.json({
    status: 'ok',
    skillCount: skills.length,
    uptime: Math.floor((Date.now() - startTime) / 1000),
  });
});

// ============================================================================
// Start
// ============================================================================

log.info(`Skill Loader Daemon listening on port ${PORT}`);

export default {
  port: PORT,
  fetch: app.fetch,
};
