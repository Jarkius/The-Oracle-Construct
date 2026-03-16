/**
 * Matrix Nerve — Type Definitions
 *
 * Self-healing system types derived from Oracle Nerve battle-tested patterns.
 * @see psi/swarm/handoffs/2026-03-16_oracle-nerve-to-matrix_evolution-patterns.md
 */

// ============ Escalation ============

export type EscalationLevel = 0 | 1 | 2 | 3 | 4 | 5;

export type ServiceState = 'healthy' | 'unhealthy' | 'degraded' | 'unknown';

export interface DaemonState {
  name: string;
  pid: number | null;
  state: ServiceState;
  previousState: ServiceState;
  level: EscalationLevel;
  restarts: number;
  restartsThisHour: number;
  lastRestartHour: number;
  lastHealthCheck: number;
  lastStateChange: number;
  escalationTimer: ReturnType<typeof setTimeout> | null;
  standbyTimer: ReturnType<typeof setInterval> | null;
  exitHistory: number[];
  port: number;
  command: string;
  logFile: string;
}

export interface EscalationConfig {
  l2Threshold: number;        // restarts/hour to trigger L2 (default: 3)
  l3Threshold: number;        // restarts/hour to trigger L3 (default: 5)
  l1DelayMs: number;          // restart delay for L1 (default: 35000)
  l2DelayMs: number;          // restart delay for L2 (default: 70000)
  l4DelayMs: number;          // time before L4 diagnosis (default: 900000 = 15 min)
  l4MaxPerDay: number;        // circuit breaker: max Claude diagnoses/day (default: 3)
  l5RetryIntervalMs: number;  // standby retry interval (default: 300000 = 5 min)
  l5StabilityMs: number;      // how long stable before reset (default: 60000)
}

export const DEFAULT_ESCALATION_CONFIG: EscalationConfig = {
  l2Threshold: 3,
  l3Threshold: 5,
  l1DelayMs: 35_000,
  l2DelayMs: 70_000,
  l4DelayMs: 15 * 60_000,
  l4MaxPerDay: 3,
  l5RetryIntervalMs: 5 * 60_000,
  l5StabilityMs: 60_000,
};

// ============ Known Fixes ============

export interface MatchPattern {
  service?: string;
  error_contains?: string;
  exit_code?: number;
  event_type?: string;
}

export interface KnownFix {
  id: string;
  match: MatchPattern;
  fix: string;
  description: string;
  auto: boolean;
  successCount: number;
  failCount: number;
  lastUsed: number | null;
}

export interface KnownFixRegistry {
  version: number;
  fixes: KnownFix[];
}

// ============ State Detection ============

export interface StateTransition {
  service: string;
  from: ServiceState;
  to: ServiceState;
  timestamp: number;
  detail?: string;
}

// ============ PULSE Events ============

export interface PulseEvent {
  id: string;
  ts: string;
  type: string;
  agent: string;
  data: Record<string, unknown>;
}

// ============ Nerve Config ============

export interface NerveConfig {
  escalation: EscalationConfig;
  knownFixesPath: string;
  eventsPath: string;
  heartbeatPath: string;
  daemonLogsDir: string;
  servicesScript: string;
}

export const DEFAULT_NERVE_CONFIG: NerveConfig = {
  escalation: DEFAULT_ESCALATION_CONFIG,
  knownFixesPath: 'psi/pulse/known-fixes.json',
  eventsPath: 'psi/pulse/events.jsonl',
  heartbeatPath: 'psi/pulse/heartbeat.json',
  daemonLogsDir: 'psi/pulse/daemon-logs',
  servicesScript: '.claude/hooks/matrix-services.sh',
};
