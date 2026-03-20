/**
 * Coordination Module — ADR-019 Cross-Worktree Safety
 *
 * Barrel exports for the coordination layer.
 */

// Types
export type {
  SessionPhase,
  TaskDecomposition,
  HandshakeSession,
  AgentStatus,
  AgentStatusRecord,
  FileLock,
  LockResult,
  MessageType,
  CoordinationMessage,
  MergeQueueEntry,
  MergeQueueResult,
  CoordinationConfig,
} from './types';

export { DEFAULT_COORDINATION_CONFIG } from './types';

// Lock Manager
export { LockManager, getLockManager } from './lock-manager';

// Coordinator
export { Coordinator, getCoordinator } from './coordinator';

// Status Writer
export { StatusWriter, getStatusWriter } from './status-writer';

// Message Bus
export { MessageBus, getMessageBus } from './message-bus';

// Merge Queue
export { MergeQueue, getMergeQueue } from './merge-queue';
