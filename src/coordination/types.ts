/**
 * Coordination Types — ADR-019 Cross-Worktree Safety
 *
 * Type definitions for the coordination layer that enables safe parallel
 * agent work across git worktrees. All coordination state lives at
 * ~/.matrix/coordination/ (external to git, visible to all worktrees).
 *
 * See: docs/multi-agent-protocol.md
 */

// ============================================================================
// Session & Handshake
// ============================================================================

export type SessionPhase = 'planning' | 'spawning' | 'working' | 'merging' | 'complete' | 'failed';

export interface TaskDecomposition {
  taskId: string;
  assignee: string;        // e.g. "Neo (agent-3)"
  scope: string[];         // file/dir patterns this agent owns
  branch: string;          // e.g. "agent-3/feature-auth"
  status: 'planned' | 'working' | 'blocked' | 'complete' | 'error';
  dependsOn: string[];     // taskIds that must complete first
}

export interface HandshakeSession {
  sessionId: string;       // e.g. "session-20260318-100000"
  orchestrator: string;    // e.g. "Oracle"
  startedAt: string;       // ISO 8601
  phase: SessionPhase;
  plan: {
    description: string;
    decomposition: TaskDecomposition[];
    mergeOrder: string[];  // taskIds in merge sequence
    sharedReadOnly: string[]; // patterns all agents can read but none can write
  };
  lastHeartbeat: string;   // ISO 8601
}

// ============================================================================
// Agent Status
// ============================================================================

export type AgentStatus = 'starting' | 'idle' | 'working' | 'blocked' | 'complete' | 'error';

export interface AgentStatusRecord {
  agentId: string;
  name: string;
  worktree: string;
  branch: string;
  status: AgentStatus;
  currentTask: string;
  progress: number;        // 0.0 to 1.0
  filesOwned: string[];
  blockedBy: string | null;
  lastUpdate: string;      // ISO 8601
}

// ============================================================================
// File Locking
// ============================================================================

export interface FileLock {
  path: string;            // relative file path
  owner: string;           // agent ID
  worktree: string;        // worktree path
  claimedAt: string;       // ISO 8601
  expiresAt: string;       // ISO 8601
  task: string;            // description of work
}

export interface LockResult {
  acquired: boolean;
  holder?: string;         // who holds the lock if not acquired
  lockPath?: string;       // path to the lock file
}

// ============================================================================
// Messages
// ============================================================================

export type MessageType = 'completion' | 'discovery' | 'request' | 'broadcast' | 'dependency-resolved' | 'blocker';

export interface CoordinationMessage {
  id: string;
  from: string;            // agent ID or "orchestrator"
  to: string;              // agent ID, "orchestrator", or "all"
  type: MessageType;
  subject: string;
  body: string;
  timestamp: string;       // ISO 8601
}

// ============================================================================
// Merge Queue
// ============================================================================

export interface MergeQueueEntry {
  agentId: string;
  taskId: string;
  branch: string;
  worktree: string;
  completedAt: string;     // ISO 8601
  priority: number;        // lower = merge first
}

export interface MergeQueueResult {
  agentId: string;
  branch: string;
  success: boolean;
  commitHash?: string;
  conflictFiles?: string[];
  error?: string;
}

// ============================================================================
// Configuration
// ============================================================================

export interface CoordinationConfig {
  baseDir: string;         // default: ~/.matrix/coordination
  lockExpiryMs: number;    // default: 3600000 (1 hour)
  messageTtlMs: number;    // default: 3600000 (1 hour)
  statusPollMs: number;    // default: 2000 (2 seconds)
}

export const DEFAULT_COORDINATION_CONFIG: CoordinationConfig = {
  baseDir: `${process.env.HOME || process.env.USERPROFILE}/.matrix/coordination`,
  lockExpiryMs: 60 * 60 * 1000,      // 1 hour
  messageTtlMs: 60 * 60 * 1000,      // 1 hour
  statusPollMs: 2000,                 // 2 seconds
};
