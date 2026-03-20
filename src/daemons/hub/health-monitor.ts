/**
 * Hub Health Monitor - Self-monitoring for the Matrix Hub
 *
 * Tracks message throughput, connection churn, and queue depth.
 * Provides a single getHealthMetrics() call for health endpoints and dashboards.
 *
 * Singleton pattern — use getHealthMonitor() to access.
 */

import { createLogger } from '../../core/utils/logger';
import { getPendingCount, getDeliveredCount } from '../../core/db/hub-messages';

const log = createLogger('HubHealthMonitor');

// ============================================================================
// Types
// ============================================================================

export interface HealthMetrics {
  pendingMessages: number;
  messagesDelivered24h: number;
  avgLatencyMs: number;
  connectedMatrices: number;
  uptime: number;
}

// ============================================================================
// Internal state
// ============================================================================

interface MonitorState {
  startedAt: number;
  connectedMatrices: number;
  latencySamples: number[];
  connectionEvents: number[];   // timestamps of connect/disconnect events
  messageTimestamps: number[];  // timestamps of messages processed
}

let instance: MonitorState | null = null;

// Maximum number of latency samples and event timestamps to retain
const MAX_SAMPLES = 1000;
const CHURN_WINDOW_MS = 60 * 60 * 1000; // 1 hour

// ============================================================================
// Singleton access
// ============================================================================

function getState(): MonitorState {
  if (!instance) {
    instance = {
      startedAt: Date.now(),
      connectedMatrices: 0,
      latencySamples: [],
      connectionEvents: [],
      messageTimestamps: [],
    };
    log.info('Health monitor initialized');
  }
  return instance;
}

// ============================================================================
// Recording functions — called by hub internals
// ============================================================================

/**
 * Record that a message was processed, with its delivery latency in ms.
 */
export function recordMessageDelivered(latencyMs: number): void {
  const state = getState();
  state.latencySamples.push(latencyMs);
  if (state.latencySamples.length > MAX_SAMPLES) {
    state.latencySamples.shift();
  }
  state.messageTimestamps.push(Date.now());
  if (state.messageTimestamps.length > MAX_SAMPLES) {
    state.messageTimestamps.shift();
  }
}

/**
 * Record a connection event (connect or disconnect).
 * Pass the current total connected count.
 */
export function recordConnectionChange(connectedCount: number): void {
  const state = getState();
  state.connectedMatrices = connectedCount;
  state.connectionEvents.push(Date.now());
  if (state.connectionEvents.length > MAX_SAMPLES) {
    state.connectionEvents.shift();
  }
}

/**
 * Update the current connected matrices count directly.
 */
export function setConnectedMatrices(count: number): void {
  const state = getState();
  state.connectedMatrices = count;
}

// ============================================================================
// Query functions
// ============================================================================

/**
 * Get the connection churn rate (connects + disconnects per hour).
 */
export function getChurnRate(): number {
  const state = getState();
  const cutoff = Date.now() - CHURN_WINDOW_MS;
  const recentEvents = state.connectionEvents.filter(ts => ts > cutoff);
  return recentEvents.length;
}

/**
 * Get message throughput (messages per minute, last 5 minutes).
 */
export function getThroughput(): number {
  const state = getState();
  const fiveMinAgo = Date.now() - 5 * 60 * 1000;
  const recentMessages = state.messageTimestamps.filter(ts => ts > fiveMinAgo);
  // Messages per minute over the 5-minute window
  return recentMessages.length / 5;
}

/**
 * Get comprehensive health metrics for the hub.
 */
export function getHealthMetrics(): HealthMetrics {
  const state = getState();

  // Average latency from recent samples
  let avgLatencyMs = 0;
  if (state.latencySamples.length > 0) {
    const sum = state.latencySamples.reduce((a, b) => a + b, 0);
    avgLatencyMs = Math.round(sum / state.latencySamples.length);
  }

  // Pending and delivered counts from the persistent queue
  let pendingMessages = 0;
  let messagesDelivered24h = 0;
  try {
    pendingMessages = getPendingCount();
    messagesDelivered24h = getDeliveredCount(24);
  } catch {
    // DB may not be available; fall back to in-memory counts
    const oneDayAgo = Date.now() - 24 * 60 * 60 * 1000;
    messagesDelivered24h = state.messageTimestamps.filter(ts => ts > oneDayAgo).length;
  }

  const uptime = Math.round((Date.now() - state.startedAt) / 1000);

  return {
    pendingMessages,
    messagesDelivered24h,
    avgLatencyMs,
    connectedMatrices: state.connectedMatrices,
    uptime,
  };
}

/**
 * Reset the health monitor (useful for testing).
 */
export function resetHealthMonitor(): void {
  instance = null;
  log.info('Health monitor reset');
}
