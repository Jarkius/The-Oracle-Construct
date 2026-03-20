/**
 * Elevation Manager — Sudo Permission Escalation
 *
 * Agents can request temporary elevated permissions when they need to
 * perform operations outside their normal permission scope. Grants are
 * time-scoped (default 10 minutes) and scope-limited.
 *
 * Flow:
 *   1. Agent requests elevation: writes .request.json to elevation dir
 *   2. Orchestrator/human approves: writes .grant.json
 *   3. Enforcement engine checks for valid grants before denying
 *   4. Grants auto-expire after the time window
 *
 * See: docs/permission-model.md#elevation
 */

import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync, unlinkSync } from 'fs';
import { join } from 'path';
import { createLogger } from '../utils/logger';
import type { ElevationRequest, ElevationGrant } from './types';

const log = createLogger('Elevation');

const DEFAULT_GRANT_DURATION_MS = 10 * 60 * 1000; // 10 minutes

// ============================================================================
// Elevation Manager
// ============================================================================

export class ElevationManager {
  private elevationDir: string;

  constructor(baseDir?: string) {
    const coordDir = baseDir || `${process.env.HOME || process.env.USERPROFILE}/.matrix/coordination`;
    this.elevationDir = join(coordDir, 'elevation');
    mkdirSync(this.elevationDir, { recursive: true });
  }

  /**
   * Request elevated permissions.
   * Writes a .request.json file for the orchestrator/human to approve.
   */
  requestElevation(agentId: string, agentName: string, tool: string, scope: string[], reason: string): ElevationRequest {
    const request: ElevationRequest = {
      agentId,
      agentName,
      tool,
      scope,
      reason,
      requestedAt: new Date().toISOString(),
    };

    const filename = `${agentId}-${Date.now()}.request.json`;
    writeFileSync(join(this.elevationDir, filename), JSON.stringify(request, null, 2));
    log.info(`Elevation requested: ${agentName} wants "${tool}" — ${reason}`);

    return request;
  }

  /**
   * Grant elevated permissions.
   * Called by orchestrator or human to approve a request.
   */
  grantElevation(
    agentId: string,
    tool: string,
    scope: string[],
    grantedBy: string = 'orchestrator',
    durationMs: number = DEFAULT_GRANT_DURATION_MS
  ): ElevationGrant {
    const now = new Date();
    const grant: ElevationGrant = {
      agentId,
      tool,
      scope,
      grantedBy,
      grantedAt: now.toISOString(),
      expiresAt: new Date(now.getTime() + durationMs).toISOString(),
    };

    const filename = `${agentId}-${tool}.grant.json`;
    writeFileSync(join(this.elevationDir, filename), JSON.stringify(grant, null, 2));
    log.info(`Elevation granted: ${agentId} → "${tool}" by ${grantedBy} (expires ${grant.expiresAt})`);

    return grant;
  }

  /**
   * Check if an agent has an active elevation grant for a tool.
   * Returns the grant if valid, null if not.
   */
  checkElevation(agentId: string, tool: string): ElevationGrant | null {
    const filename = `${agentId}-${tool}.grant.json`;
    const grantPath = join(this.elevationDir, filename);

    try {
      if (!existsSync(grantPath)) return null;

      const grant = JSON.parse(readFileSync(grantPath, 'utf8')) as ElevationGrant;

      // Check expiry
      if (new Date(grant.expiresAt) < new Date()) {
        // Expired — clean up
        try { unlinkSync(grantPath); } catch { /* ok */ }
        log.info(`Elevation expired: ${agentId} → "${tool}"`);
        return null;
      }

      return grant;
    } catch {
      return null;
    }
  }

  /**
   * Revoke an elevation grant.
   */
  revokeElevation(agentId: string, tool: string): boolean {
    const filename = `${agentId}-${tool}.grant.json`;
    const grantPath = join(this.elevationDir, filename);

    try {
      if (existsSync(grantPath)) {
        unlinkSync(grantPath);
        log.info(`Elevation revoked: ${agentId} → "${tool}"`);
        return true;
      }
    } catch { /* ok */ }
    return false;
  }

  /**
   * Revoke all grants for an agent.
   */
  revokeAllForAgent(agentId: string): number {
    let revoked = 0;
    try {
      for (const file of readdirSync(this.elevationDir)) {
        if (file.startsWith(`${agentId}-`) && file.endsWith('.grant.json')) {
          unlinkSync(join(this.elevationDir, file));
          revoked++;
        }
      }
    } catch { /* ok */ }

    if (revoked > 0) {
      log.info(`Revoked ${revoked} elevation grants for ${agentId}`);
    }
    return revoked;
  }

  /**
   * List all pending elevation requests.
   */
  listPendingRequests(): ElevationRequest[] {
    const requests: ElevationRequest[] = [];
    try {
      for (const file of readdirSync(this.elevationDir)) {
        if (!file.endsWith('.request.json')) continue;
        try {
          const raw = readFileSync(join(this.elevationDir, file), 'utf8');
          requests.push(JSON.parse(raw));
        } catch { /* skip malformed */ }
      }
    } catch { /* ok */ }
    return requests;
  }

  /**
   * List all active grants (non-expired).
   */
  listActiveGrants(): ElevationGrant[] {
    const grants: ElevationGrant[] = [];
    const now = new Date();

    try {
      for (const file of readdirSync(this.elevationDir)) {
        if (!file.endsWith('.grant.json')) continue;
        try {
          const raw = readFileSync(join(this.elevationDir, file), 'utf8');
          const grant = JSON.parse(raw) as ElevationGrant;

          if (new Date(grant.expiresAt) > now) {
            grants.push(grant);
          } else {
            // Clean expired
            unlinkSync(join(this.elevationDir, file));
          }
        } catch { /* skip malformed */ }
      }
    } catch { /* ok */ }

    return grants;
  }

  /**
   * Clean up all expired grants and processed requests.
   */
  cleanup(): number {
    let cleaned = 0;
    const now = new Date();

    try {
      for (const file of readdirSync(this.elevationDir)) {
        const filePath = join(this.elevationDir, file);

        if (file.endsWith('.grant.json')) {
          try {
            const grant = JSON.parse(readFileSync(filePath, 'utf8')) as ElevationGrant;
            if (new Date(grant.expiresAt) < now) {
              unlinkSync(filePath);
              cleaned++;
            }
          } catch {
            unlinkSync(filePath);
            cleaned++;
          }
        }
      }
    } catch { /* ok */ }

    if (cleaned > 0) {
      log.info(`Cleaned ${cleaned} expired elevation files`);
    }
    return cleaned;
  }
}

// ============================================================================
// Singleton
// ============================================================================

let instance: ElevationManager | null = null;

export function getElevationManager(baseDir?: string): ElevationManager {
  if (!instance) {
    instance = new ElevationManager(baseDir);
  }
  return instance;
}
