/**
 * Hub Message Queue - Persistent message queue for hub resilience
 *
 * Persists in-flight hub messages to SQLite so they survive hub crashes.
 * When the hub restarts, undelivered messages can be retried.
 *
 * Table: hub_message_queue
 * - Queued messages awaiting delivery
 * - Delivered messages retained briefly for audit
 * - Expired messages purged by TTL
 */

import { db } from './core';
import { randomUUID } from 'crypto';

// ============================================================================
// Schema
// ============================================================================

db.run(`
  CREATE TABLE IF NOT EXISTS hub_message_queue (
    id TEXT PRIMARY KEY,
    from_matrix TEXT NOT NULL,
    to_matrix TEXT NOT NULL,
    content TEXT NOT NULL,
    metadata TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    delivered_at TEXT,
    expired_at TEXT
  )
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_hub_mq_to_matrix
  ON hub_message_queue (to_matrix, delivered_at)
`);

db.run(`
  CREATE INDEX IF NOT EXISTS idx_hub_mq_created_at
  ON hub_message_queue (created_at)
`);

// ============================================================================
// Types
// ============================================================================

export interface HubQueuedMessage {
  id: string;
  from_matrix: string;
  to_matrix: string;
  content: string;
  metadata: string | null;
  created_at: string;
  delivered_at: string | null;
  expired_at: string | null;
}

// ============================================================================
// Functions
// ============================================================================

/**
 * Queue a message for delivery through the hub.
 * Returns the generated message ID.
 */
export function queueMessage(
  from: string,
  to: string,
  content: string,
  metadata?: Record<string, unknown>,
): string {
  const id = randomUUID();
  const metadataJson = metadata ? JSON.stringify(metadata) : null;

  db.run(`
    INSERT INTO hub_message_queue (id, from_matrix, to_matrix, content, metadata)
    VALUES (?, ?, ?, ?, ?)
  `, [id, from, to, content, metadataJson]);

  return id;
}

/**
 * Get all undelivered messages queued for a specific matrix.
 * Returns messages in creation order (FIFO).
 */
export function getQueuedMessages(matrixId: string): HubQueuedMessage[] {
  return db.query(`
    SELECT * FROM hub_message_queue
    WHERE to_matrix = ?
      AND delivered_at IS NULL
      AND expired_at IS NULL
    ORDER BY created_at ASC
  `).all(matrixId) as HubQueuedMessage[];
}

/**
 * Mark a queued message as successfully delivered.
 */
export function markDelivered(id: string): void {
  db.run(`
    UPDATE hub_message_queue
    SET delivered_at = datetime('now')
    WHERE id = ?
  `, [id]);
}

/**
 * Purge messages that have exceeded the TTL.
 * - Delivered messages older than ttlHours are deleted.
 * - Undelivered messages older than ttlHours are marked expired then deleted.
 * Returns the number of rows removed.
 */
export function purgeExpired(ttlHours: number = 1): number {
  const cutoff = new Date(Date.now() - ttlHours * 60 * 60 * 1000).toISOString();

  // Mark undelivered old messages as expired
  db.run(`
    UPDATE hub_message_queue
    SET expired_at = datetime('now')
    WHERE delivered_at IS NULL
      AND expired_at IS NULL
      AND created_at < ?
  `, [cutoff]);

  // Delete all old messages (delivered or expired)
  const result = db.run(`
    DELETE FROM hub_message_queue
    WHERE created_at < ?
      AND (delivered_at IS NOT NULL OR expired_at IS NOT NULL)
  `, [cutoff]);

  return result.changes;
}

/**
 * Get count of pending (undelivered, unexpired) messages.
 */
export function getPendingCount(): number {
  const row = db.query(`
    SELECT COUNT(*) as count FROM hub_message_queue
    WHERE delivered_at IS NULL AND expired_at IS NULL
  `).get() as { count: number };
  return row.count;
}

/**
 * Get count of messages delivered in the last N hours.
 */
export function getDeliveredCount(hours: number = 24): number {
  const cutoff = new Date(Date.now() - hours * 60 * 60 * 1000).toISOString();
  const row = db.query(`
    SELECT COUNT(*) as count FROM hub_message_queue
    WHERE delivered_at IS NOT NULL
      AND delivered_at > ?
  `).get(cutoff) as { count: number };
  return row.count;
}
