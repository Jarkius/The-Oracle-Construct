/**
 * Message Bus — ADR-019 Cross-Worktree Communication
 *
 * File-based message passing at ~/.matrix/coordination/messages/.
 * Each message is an individual JSON file — no two agents write the same file,
 * so there are zero concurrency issues.
 *
 * Why file-based, not WebSocket?
 * Agents in separate worktrees are separate Claude Code processes. They share
 * NO runtime. File I/O at ~/.matrix/coordination/ is the only reliable
 * cross-process primitive. Matrix Hub WS is for cross-PROJECT communication.
 *
 * See: docs/multi-agent-protocol.md#messages
 */

import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync, unlinkSync } from 'fs';
import { join } from 'path';
import { createLogger } from '../core/utils/logger';
import type { CoordinationMessage, MessageType, CoordinationConfig } from './types';
import { DEFAULT_COORDINATION_CONFIG } from './types';

const log = createLogger('MessageBus');

// ============================================================================
// Message Bus
// ============================================================================

export class MessageBus {
  private messagesDir: string;
  private config: CoordinationConfig;

  constructor(config?: Partial<CoordinationConfig>) {
    this.config = { ...DEFAULT_COORDINATION_CONFIG, ...config };
    this.messagesDir = join(this.config.baseDir, 'messages');
    mkdirSync(this.messagesDir, { recursive: true });
  }

  /**
   * Send a message to a specific agent or broadcast to all.
   */
  send(msg: Omit<CoordinationMessage, 'id' | 'timestamp'>): CoordinationMessage {
    const now = new Date();
    const ts = now.toISOString().replace(/[:.]/g, '-');

    const fullMsg: CoordinationMessage = {
      ...msg,
      id: `msg-${ts}-${msg.from}`,
      timestamp: now.toISOString(),
    };

    const filename = `${ts}-${msg.from}-${msg.to}.json`;
    const filepath = join(this.messagesDir, filename);

    writeFileSync(filepath, JSON.stringify(fullMsg, null, 2));
    log.info(`Message sent: ${msg.from} → ${msg.to} [${msg.type}] ${msg.subject}`);

    return fullMsg;
  }

  /**
   * Convenience: broadcast a message to all agents.
   */
  broadcast(from: string, type: MessageType, subject: string, body: string): CoordinationMessage {
    return this.send({ from, to: 'all', type, subject, body });
  }

  /**
   * Receive messages for a specific agent.
   * Includes broadcasts (to: "all") and direct messages (to: agentId).
   */
  receive(agentId: string, since?: Date): CoordinationMessage[] {
    const messages: CoordinationMessage[] = [];

    try {
      for (const file of readdirSync(this.messagesDir)) {
        if (!file.endsWith('.json')) continue;

        try {
          const raw = readFileSync(join(this.messagesDir, file), 'utf8');
          const msg = JSON.parse(raw) as CoordinationMessage;

          // Filter: addressed to this agent or broadcast
          if (msg.to !== agentId && msg.to !== 'all' && msg.to !== 'orchestrator') continue;

          // Filter: since timestamp
          if (since && new Date(msg.timestamp) <= since) continue;

          messages.push(msg);
        } catch { /* skip malformed */ }
      }
    } catch { /* dir doesn't exist yet */ }

    // Sort by timestamp (oldest first)
    return messages.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
  }

  /**
   * Receive ALL messages (for orchestrator/monitoring).
   */
  receiveAll(since?: Date): CoordinationMessage[] {
    const messages: CoordinationMessage[] = [];

    try {
      for (const file of readdirSync(this.messagesDir)) {
        if (!file.endsWith('.json')) continue;

        try {
          const raw = readFileSync(join(this.messagesDir, file), 'utf8');
          const msg = JSON.parse(raw) as CoordinationMessage;

          if (since && new Date(msg.timestamp) <= since) continue;

          messages.push(msg);
        } catch { /* skip malformed */ }
      }
    } catch { /* dir doesn't exist yet */ }

    return messages.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
  }

  /**
   * Get the most recent N messages (for display/monitoring).
   */
  recent(count: number = 10): CoordinationMessage[] {
    const all = this.receiveAll();
    return all.slice(-count);
  }

  /**
   * Count unread messages for an agent since a given time.
   */
  countUnread(agentId: string, since: Date): number {
    return this.receive(agentId, since).length;
  }

  /**
   * Purge messages older than the configured TTL.
   */
  purge(olderThan?: Date): number {
    const cutoff = olderThan || new Date(Date.now() - this.config.messageTtlMs);
    let purged = 0;

    try {
      for (const file of readdirSync(this.messagesDir)) {
        if (!file.endsWith('.json')) continue;

        try {
          const raw = readFileSync(join(this.messagesDir, file), 'utf8');
          const msg = JSON.parse(raw) as CoordinationMessage;

          if (new Date(msg.timestamp) < cutoff) {
            unlinkSync(join(this.messagesDir, file));
            purged++;
          }
        } catch {
          // Malformed — delete it
          try { unlinkSync(join(this.messagesDir, file)); } catch { /* ok */ }
          purged++;
        }
      }
    } catch { /* ok */ }

    if (purged > 0) {
      log.info(`Purged ${purged} expired messages`);
    }
    return purged;
  }

  /**
   * Get messages by type (e.g., all "blocker" messages).
   */
  getByType(type: MessageType, since?: Date): CoordinationMessage[] {
    return this.receiveAll(since).filter(m => m.type === type);
  }
}

// ============================================================================
// Singleton
// ============================================================================

let instance: MessageBus | null = null;

export function getMessageBus(config?: Partial<CoordinationConfig>): MessageBus {
  if (!instance) {
    instance = new MessageBus(config);
  }
  return instance;
}
