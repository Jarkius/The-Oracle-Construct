/**
 * Security Tests — Permission Enforcement Layer
 *
 * Tests for the security module:
 * - PermissionResolver: resolvePermissions for each agent type
 * - EnforcementEngine: checkPermission with various agent/tool combinations
 * - ElevationManager: request, grant, check, expire, revoke
 * - HeartbeatWatchdog: validate, saveBackup, restore
 *
 * NOTE: The existing security.test.ts tests shell escaping (utils/shell).
 *       This file tests the permission enforcement layer (security module).
 */

import { describe, test, expect, beforeEach, afterEach } from 'bun:test';
import { mkdtempSync, mkdirSync, rmSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';
import { PermissionResolver } from '../../src/security/permission-resolver';
import { EnforcementEngine } from '../../src/security/enforcement-engine';
import { ElevationManager } from '../../src/security/elevation';
import { HeartbeatWatchdog } from '../../src/security/heartbeat-watchdog';

// ============================================================================
// Helpers
// ============================================================================

function makeTempDir(): string {
  return mkdtempSync(join(tmpdir(), 'security-test-'));
}

/**
 * Create a mock agent definition file with frontmatter.
 */
function writeAgentDef(
  agentsDir: string,
  name: string,
  frontmatter: Record<string, string | string[]>
): void {
  const lines = ['---'];
  for (const [key, value] of Object.entries(frontmatter)) {
    if (Array.isArray(value)) {
      lines.push(`${key}:`);
      for (const item of value) {
        lines.push(`  - ${item}`);
      }
    } else {
      lines.push(`${key}: ${value}`);
    }
  }
  lines.push('---');
  lines.push(`# ${name}`);
  lines.push('');

  writeFileSync(join(agentsDir, `${name}.md`), lines.join('\n'));
}

/**
 * Create a project dir with agent definitions matching the real agents.
 */
function createMockProject(): string {
  const projectDir = makeTempDir();
  const agentsDir = join(projectDir, '.claude', 'agents');
  mkdirSync(agentsDir, { recursive: true });

  // Neo: full permissions (acceptEdits)
  writeAgentDef(agentsDir, 'neo', {
    name: 'neo',
    permissionMode: 'acceptEdits',
    tools: ['Read', 'Write', 'Edit', 'Bash', 'Grep', 'Glob', 'Agent', 'Skill'],
    disallowedTools: [],
  });

  // Architect: plan mode, explicitly disallows Write/Edit/Bash
  writeAgentDef(agentsDir, 'architect', {
    name: 'architect',
    permissionMode: 'plan',
    tools: ['Read', 'Grep', 'Glob', 'Agent', 'Skill'],
    disallowedTools: ['Write', 'Edit', 'Bash'],
  });

  // Tank: dontAsk mode, disallows Write/Edit/Agent
  writeAgentDef(agentsDir, 'tank', {
    name: 'tank',
    permissionMode: 'dontAsk',
    tools: ['Read', 'Grep', 'Glob', 'Bash'],
    disallowedTools: ['Write', 'Edit', 'Agent'],
  });

  // Trinity: plan mode, disallows Write/Edit/Bash/Agent
  writeAgentDef(agentsDir, 'trinity', {
    name: 'trinity',
    permissionMode: 'plan',
    tools: ['Read', 'Grep', 'Glob'],
    disallowedTools: ['Write', 'Edit', 'Bash', 'Agent'],
  });

  return projectDir;
}

// ============================================================================
// Permission Resolver
// ============================================================================

describe('PermissionResolver', () => {
  let projectDir: string;
  let resolver: PermissionResolver;

  beforeEach(() => {
    projectDir = createMockProject();
    resolver = new PermissionResolver(projectDir);
  });

  afterEach(() => {
    rmSync(projectDir, { recursive: true, force: true });
  });

  test('resolvePermissions for neo returns full permission mode', () => {
    const perms = resolver.resolvePermissions('neo');
    expect(perms).not.toBeNull();
    expect(perms!.agentName).toBe('neo');
    expect(perms!.permissionMode).toBe('full');
  });

  test('resolvePermissions for architect returns plan permission mode', () => {
    const perms = resolver.resolvePermissions('architect');
    expect(perms).not.toBeNull();
    expect(perms!.agentName).toBe('architect');
    expect(perms!.permissionMode).toBe('plan');
    expect(perms!.disallowedTools).toContain('Write');
    expect(perms!.disallowedTools).toContain('Edit');
    expect(perms!.disallowedTools).toContain('Bash');
  });

  test('resolvePermissions for tank returns dontAsk permission mode', () => {
    const perms = resolver.resolvePermissions('tank');
    expect(perms).not.toBeNull();
    expect(perms!.agentName).toBe('tank');
    expect(perms!.permissionMode).toBe('dontAsk');
    expect(perms!.disallowedTools).toContain('Write');
    expect(perms!.disallowedTools).toContain('Edit');
    expect(perms!.disallowedTools).toContain('Agent');
  });

  test('resolvePermissions for trinity returns plan permission mode', () => {
    const perms = resolver.resolvePermissions('trinity');
    expect(perms).not.toBeNull();
    expect(perms!.agentName).toBe('trinity');
    expect(perms!.permissionMode).toBe('plan');
    expect(perms!.disallowedTools).toContain('Write');
    expect(perms!.disallowedTools).toContain('Agent');
  });

  test('resolvePermissions returns null for unknown agent', () => {
    const perms = resolver.resolvePermissions('unknown-agent');
    expect(perms).toBeNull();
  });

  test('resolvePermissions caches results', () => {
    const first = resolver.resolvePermissions('neo');
    const second = resolver.resolvePermissions('neo');
    // Same object reference due to caching
    expect(first).toBe(second);
  });

  test('clearCache allows re-parsing', () => {
    const first = resolver.resolvePermissions('neo');
    resolver.clearCache();
    const second = resolver.resolvePermissions('neo');
    // Different object after cache clear
    expect(first).not.toBe(second);
    // But same content
    expect(first!.agentName).toBe(second!.agentName);
  });

  test('resolveAll returns all agent declarations', () => {
    const all = resolver.resolveAll();
    expect(all.length).toBe(4);
    const names = all.map(d => d.agentName).sort();
    expect(names).toEqual(['architect', 'neo', 'tank', 'trinity']);
  });
});

// ============================================================================
// Enforcement Engine
// ============================================================================

describe('EnforcementEngine', () => {
  let projectDir: string;
  let engine: EnforcementEngine;

  beforeEach(() => {
    projectDir = createMockProject();
    engine = new EnforcementEngine(projectDir);
  });

  afterEach(() => {
    rmSync(projectDir, { recursive: true, force: true });
  });

  test('architect + Write = denied (explicitly disallowed)', () => {
    const result = engine.checkPermission('architect', 'Write');
    expect(result.allowed).toBe(false);
    expect(result.reason).toContain('disallowed');
  });

  test('architect + Read = allowed', () => {
    const result = engine.checkPermission('architect', 'Read');
    expect(result.allowed).toBe(true);
  });

  test('architect + Bash = denied (disallowed + mode restriction)', () => {
    const result = engine.checkPermission('architect', 'Bash');
    expect(result.allowed).toBe(false);
  });

  test('neo + Write = allowed (full mode)', () => {
    const result = engine.checkPermission('neo', 'Write');
    expect(result.allowed).toBe(true);
  });

  test('neo + Edit = allowed (full mode)', () => {
    const result = engine.checkPermission('neo', 'Edit');
    expect(result.allowed).toBe(true);
  });

  test('neo + Bash = allowed (full mode)', () => {
    const result = engine.checkPermission('neo', 'Bash');
    expect(result.allowed).toBe(true);
  });

  test('neo + Agent = allowed (full mode)', () => {
    const result = engine.checkPermission('neo', 'Agent');
    expect(result.allowed).toBe(true);
  });

  test('tank + Agent = denied (explicitly disallowed)', () => {
    const result = engine.checkPermission('tank', 'Agent');
    expect(result.allowed).toBe(false);
    expect(result.reason).toContain('disallowed');
  });

  test('tank + Write = denied (explicitly disallowed)', () => {
    const result = engine.checkPermission('tank', 'Write');
    expect(result.allowed).toBe(false);
  });

  test('tank + Read = allowed', () => {
    const result = engine.checkPermission('tank', 'Read');
    expect(result.allowed).toBe(true);
  });

  test('tank + Bash = allowed (dontAsk mode does not restrict Bash)', () => {
    const result = engine.checkPermission('tank', 'Bash');
    expect(result.allowed).toBe(true);
  });

  test('trinity + Write = denied', () => {
    const result = engine.checkPermission('trinity', 'Write');
    expect(result.allowed).toBe(false);
  });

  test('trinity + Agent = denied', () => {
    const result = engine.checkPermission('trinity', 'Agent');
    expect(result.allowed).toBe(false);
  });

  test('trinity + Read = allowed', () => {
    const result = engine.checkPermission('trinity', 'Read');
    expect(result.allowed).toBe(true);
  });

  test('unknown agent (human session, no agent ID) = allowed', () => {
    const result = engine.checkPermission('unknown-human-session', 'Write');
    expect(result.allowed).toBe(true);
  });

  test('denied result includes elevationAvailable hint', () => {
    const result = engine.checkPermission('architect', 'Write');
    expect(result.allowed).toBe(false);
    expect(result.elevationAvailable).toBe(true);
  });

  test('getRestrictedTools returns combined restrictions', () => {
    const restricted = engine.getRestrictedTools('architect');
    expect(restricted).toContain('Write');
    expect(restricted).toContain('Edit');
    expect(restricted).toContain('Bash');
  });

  test('getRestrictedTools returns empty for unknown agent', () => {
    const restricted = engine.getRestrictedTools('unknown');
    expect(restricted).toEqual([]);
  });
});

// ============================================================================
// Elevation Manager
// ============================================================================

describe('ElevationManager', () => {
  let tempDir: string;
  let elevation: ElevationManager;

  beforeEach(() => {
    tempDir = makeTempDir();
    elevation = new ElevationManager(tempDir);
  });

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });

  test('requestElevation creates a request file', () => {
    const request = elevation.requestElevation(
      'agent-1', 'architect', 'Write', ['src/docs/**'], 'Need to update ADR'
    );

    expect(request.agentId).toBe('agent-1');
    expect(request.tool).toBe('Write');
    expect(request.reason).toBe('Need to update ADR');
    expect(request.requestedAt).toBeDefined();

    // Should appear in pending requests
    const pending = elevation.listPendingRequests();
    expect(pending.length).toBe(1);
    expect(pending[0].agentId).toBe('agent-1');
  });

  test('grantElevation creates a grant file', () => {
    const grant = elevation.grantElevation(
      'agent-1', 'Write', ['src/docs/**'], 'orchestrator', 10 * 60 * 1000
    );

    expect(grant.agentId).toBe('agent-1');
    expect(grant.tool).toBe('Write');
    expect(grant.grantedBy).toBe('orchestrator');
    expect(new Date(grant.expiresAt).getTime()).toBeGreaterThan(Date.now());
  });

  test('checkElevation returns grant for valid (non-expired) grant', () => {
    elevation.grantElevation('agent-1', 'Write', ['src/**'], 'orchestrator');

    const grant = elevation.checkElevation('agent-1', 'Write');
    expect(grant).not.toBeNull();
    expect(grant!.agentId).toBe('agent-1');
    expect(grant!.tool).toBe('Write');
  });

  test('checkElevation returns null for expired grant', () => {
    // Grant with 1ms duration
    elevation.grantElevation('agent-1', 'Write', ['src/**'], 'orchestrator', 1);

    // Wait for expiry
    const start = Date.now();
    while (Date.now() - start < 10) { /* busy wait */ }

    const grant = elevation.checkElevation('agent-1', 'Write');
    expect(grant).toBeNull();
  });

  test('checkElevation returns null when no grant exists', () => {
    const grant = elevation.checkElevation('agent-1', 'Write');
    expect(grant).toBeNull();
  });

  test('revokeElevation removes the grant file', () => {
    elevation.grantElevation('agent-1', 'Write', ['src/**']);

    const revoked = elevation.revokeElevation('agent-1', 'Write');
    expect(revoked).toBe(true);

    const grant = elevation.checkElevation('agent-1', 'Write');
    expect(grant).toBeNull();
  });

  test('revokeElevation returns false when no grant exists', () => {
    const revoked = elevation.revokeElevation('agent-1', 'Write');
    expect(revoked).toBe(false);
  });

  test('revokeAllForAgent removes all grants for that agent', () => {
    elevation.grantElevation('agent-1', 'Write', ['src/**']);
    elevation.grantElevation('agent-1', 'Bash', ['*']);
    elevation.grantElevation('agent-2', 'Write', ['docs/**']);

    const revoked = elevation.revokeAllForAgent('agent-1');
    expect(revoked).toBe(2);

    // agent-2's grant should still exist
    expect(elevation.checkElevation('agent-2', 'Write')).not.toBeNull();
    expect(elevation.checkElevation('agent-1', 'Write')).toBeNull();
    expect(elevation.checkElevation('agent-1', 'Bash')).toBeNull();
  });

  test('listActiveGrants returns only non-expired grants', () => {
    elevation.grantElevation('agent-1', 'Write', ['src/**'], 'orchestrator', 60000);
    elevation.grantElevation('agent-2', 'Edit', ['src/**'], 'orchestrator', 1);

    // Wait for agent-2's grant to expire
    const start = Date.now();
    while (Date.now() - start < 10) { /* busy wait */ }

    const active = elevation.listActiveGrants();
    expect(active.length).toBe(1);
    expect(active[0].agentId).toBe('agent-1');
  });

  test('cleanup removes expired grants', () => {
    elevation.grantElevation('agent-1', 'Write', ['src/**'], 'orchestrator', 1);
    elevation.grantElevation('agent-2', 'Write', ['src/**'], 'orchestrator', 60000);

    const start = Date.now();
    while (Date.now() - start < 10) { /* busy wait */ }

    const cleaned = elevation.cleanup();
    expect(cleaned).toBe(1);
  });
});

// ============================================================================
// Heartbeat Watchdog
// ============================================================================

describe('HeartbeatWatchdog', () => {
  let tempDir: string;
  let watchdog: HeartbeatWatchdog;

  beforeEach(() => {
    tempDir = makeTempDir();
    // Create the psi/state/pulse directory structure
    mkdirSync(join(tempDir, 'psi', 'state', 'pulse'), { recursive: true });
    watchdog = new HeartbeatWatchdog(tempDir);
  });

  afterEach(() => {
    rmSync(tempDir, { recursive: true, force: true });
  });

  test('validate returns valid for a correct config', () => {
    const config = { enabled: true, auto_evolve: false, check_interval_ms: 5000 };
    writeFileSync(join(tempDir, 'psi', 'state', 'pulse', 'heartbeat.json'), JSON.stringify(config));

    const result = watchdog.validate();
    expect(result.valid).toBe(true);
    expect(result.errors.length).toBe(0);
  });

  test('validate returns valid when config file does not exist', () => {
    const result = watchdog.validate();
    expect(result.valid).toBe(true);
  });

  test('validate detects corrupt (non-JSON) config', () => {
    writeFileSync(join(tempDir, 'psi', 'state', 'pulse', 'heartbeat.json'), 'NOT VALID JSON{{{');

    const result = watchdog.validate();
    expect(result.valid).toBe(false);
    expect(result.errors.length).toBeGreaterThan(0);
  });

  test('validate detects missing required fields', () => {
    const config = { auto_evolve: false }; // missing 'enabled'
    writeFileSync(join(tempDir, 'psi', 'state', 'pulse', 'heartbeat.json'), JSON.stringify(config));

    const result = watchdog.validate();
    expect(result.valid).toBe(false);
  });

  test('validate detects wrong type for enabled field', () => {
    const config = { enabled: 'yes' }; // should be boolean
    writeFileSync(join(tempDir, 'psi', 'state', 'pulse', 'heartbeat.json'), JSON.stringify(config));

    const result = watchdog.validate();
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => e.includes('enabled'))).toBe(true);
  });

  test('validate detects wrong type for auto_evolve', () => {
    const config = { enabled: true, auto_evolve: 'maybe' };
    writeFileSync(join(tempDir, 'psi', 'state', 'pulse', 'heartbeat.json'), JSON.stringify(config));

    const result = watchdog.validate();
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => e.includes('auto_evolve'))).toBe(true);
  });

  test('validate detects wrong type for check_interval_ms', () => {
    const config = { enabled: true, check_interval_ms: 'fast' };
    writeFileSync(join(tempDir, 'psi', 'state', 'pulse', 'heartbeat.json'), JSON.stringify(config));

    const result = watchdog.validate();
    expect(result.valid).toBe(false);
    expect(result.errors.some(e => e.includes('check_interval_ms'))).toBe(true);
  });

  test('saveBackup creates a backup of valid config', () => {
    const config = { enabled: true };
    const configPath = join(tempDir, 'psi', 'state', 'pulse', 'heartbeat.json');
    writeFileSync(configPath, JSON.stringify(config));

    const saved = watchdog.saveBackup();
    expect(saved).toBe(true);
    expect(existsSync(`${configPath}.bak`)).toBe(true);
  });

  test('saveBackup returns false when config does not exist', () => {
    const saved = watchdog.saveBackup();
    expect(saved).toBe(false);
  });

  test('saveBackup does not overwrite backup with corrupt config', () => {
    const configPath = join(tempDir, 'psi', 'state', 'pulse', 'heartbeat.json');
    const backupPath = `${configPath}.bak`;

    // Create valid config and backup
    writeFileSync(configPath, JSON.stringify({ enabled: true }));
    watchdog.saveBackup();

    // Corrupt the main config
    writeFileSync(configPath, 'CORRUPT');

    // Try to backup — should not overwrite
    const saved = watchdog.saveBackup();
    expect(saved).toBe(false);

    // Original backup should still be valid
    const backupContent = JSON.parse(require('fs').readFileSync(backupPath, 'utf8'));
    expect(backupContent.enabled).toBe(true);
  });

  test('restore copies backup to config', () => {
    const configPath = join(tempDir, 'psi', 'state', 'pulse', 'heartbeat.json');

    // Create and backup valid config
    writeFileSync(configPath, JSON.stringify({ enabled: true, auto_evolve: false }));
    watchdog.saveBackup();

    // Corrupt the config
    writeFileSync(configPath, 'CORRUPT');

    // Restore
    const restored = watchdog.restore();
    expect(restored).toBe(true);

    // Validate after restore
    const result = watchdog.validate();
    expect(result.valid).toBe(true);
  });

  test('restore returns false when no backup exists', () => {
    const restored = watchdog.restore();
    expect(restored).toBe(false);
  });

  test('checkAndRestore returns ok for valid config', () => {
    const configPath = join(tempDir, 'psi', 'state', 'pulse', 'heartbeat.json');
    writeFileSync(configPath, JSON.stringify({ enabled: true }));

    const result = watchdog.checkAndRestore();
    expect(result.action).toBe('ok');
  });

  test('checkAndRestore restores from backup when corrupt', () => {
    const configPath = join(tempDir, 'psi', 'state', 'pulse', 'heartbeat.json');

    // Create valid config and backup
    writeFileSync(configPath, JSON.stringify({ enabled: true }));
    watchdog.saveBackup();

    // Corrupt the config
    writeFileSync(configPath, 'CORRUPT');

    const result = watchdog.checkAndRestore();
    expect(result.action).toBe('restored');
    expect(result.errors!.length).toBeGreaterThan(0);
  });

  test('checkAndRestore returns failed when corrupt and no backup', () => {
    const configPath = join(tempDir, 'psi', 'state', 'pulse', 'heartbeat.json');
    writeFileSync(configPath, 'CORRUPT');

    const result = watchdog.checkAndRestore();
    expect(result.action).toBe('failed');
  });
});
