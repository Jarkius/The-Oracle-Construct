/**
 * Status Writer — ADR-019 Agent Status Protocol
 *
 * Each agent writes its status to ~/.matrix/coordination/agents/{agent-id}.status.json
 * Other agents and the orchestrator poll these files for cross-worktree visibility.
 *
 * Status format matches docs/multi-agent-protocol.md exactly.
 */

import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync, unlinkSync } from 'fs';
import { join } from 'path';
import { createLogger } from '../utils/logger';
import type { AgentStatusRecord, AgentStatus, CoordinationConfig } from './types';
import { DEFAULT_COORDINATION_CONFIG } from './types';

const log = createLogger('StatusWriter');

// ============================================================================
// Status Writer
// ============================================================================

export class StatusWriter {
  private agentsDir: string;

  constructor(config?: Partial<CoordinationConfig>) {
    const cfg = { ...DEFAULT_COORDINATION_CONFIG, ...config };
    this.agentsDir = join(cfg.baseDir, 'agents');
    mkdirSync(this.agentsDir, { recursive: true });
  }

  /**
   * Write or update an agent's status file.
   */
  writeStatus(agentId: string, status: Partial<AgentStatusRecord> & { agentId: string }): void {
    const statusPath = this.statusFileFor(agentId);

    // Merge with existing if present
    const existing = this.readStatus(agentId);
    const record: AgentStatusRecord = {
      agentId,
      name: status.name || existing?.name || agentId,
      worktree: status.worktree || existing?.worktree || '',
      branch: status.branch || existing?.branch || '',
      status: status.status || existing?.status || 'idle',
      currentTask: status.currentTask || existing?.currentTask || '',
      progress: status.progress ?? existing?.progress ?? 0,
      filesOwned: status.filesOwned || existing?.filesOwned || [],
      blockedBy: status.blockedBy !== undefined ? status.blockedBy : (existing?.blockedBy ?? null),
      lastUpdate: new Date().toISOString(),
    };

    writeFileSync(statusPath, JSON.stringify(record, null, 2));
  }

  /**
   * Read a specific agent's status.
   */
  readStatus(agentId: string): AgentStatusRecord | null {
    const statusPath = this.statusFileFor(agentId);
    try {
      if (!existsSync(statusPath)) return null;
      return JSON.parse(readFileSync(statusPath, 'utf8')) as AgentStatusRecord;
    } catch {
      return null;
    }
  }

  /**
   * Read all agent statuses.
   */
  readAllStatuses(): AgentStatusRecord[] {
    const statuses: AgentStatusRecord[] = [];
    try {
      for (const file of readdirSync(this.agentsDir)) {
        if (!file.endsWith('.status.json')) continue;
        try {
          const raw = readFileSync(join(this.agentsDir, file), 'utf8');
          statuses.push(JSON.parse(raw));
        } catch { /* skip malformed */ }
      }
    } catch { /* dir doesn't exist yet */ }
    return statuses;
  }

  /**
   * Quick status transition — updates status field and lastUpdate only.
   */
  transition(agentId: string, status: AgentStatus): void {
    this.writeStatus(agentId, { agentId, status });
  }

  /**
   * Update progress for an agent.
   */
  updateProgress(agentId: string, progress: number, currentTask?: string): void {
    const update: Partial<AgentStatusRecord> & { agentId: string } = {
      agentId,
      progress: Math.max(0, Math.min(1, progress)),
    };
    if (currentTask !== undefined) update.currentTask = currentTask;
    this.writeStatus(agentId, update);
  }

  /**
   * Get agents filtered by status.
   */
  getByStatus(status: AgentStatus): AgentStatusRecord[] {
    return this.readAllStatuses().filter(s => s.status === status);
  }

  /**
   * Check if all agents have reached a terminal state (complete or error).
   */
  allTerminal(): boolean {
    const statuses = this.readAllStatuses();
    if (statuses.length === 0) return false;
    return statuses.every(s => s.status === 'complete' || s.status === 'error');
  }

  /**
   * Remove a specific agent's status file.
   */
  removeStatus(agentId: string): void {
    const statusPath = this.statusFileFor(agentId);
    try {
      if (existsSync(statusPath)) {
        unlinkSync(statusPath);
      }
    } catch { /* ok */ }
  }

  // ============================================================================
  // Internal
  // ============================================================================

  private statusFileFor(agentId: string): string {
    return join(this.agentsDir, `${agentId}.status.json`);
  }
}

// ============================================================================
// Singleton
// ============================================================================

let instance: StatusWriter | null = null;

export function getStatusWriter(config?: Partial<CoordinationConfig>): StatusWriter {
  if (!instance) {
    instance = new StatusWriter(config);
  }
  return instance;
}
