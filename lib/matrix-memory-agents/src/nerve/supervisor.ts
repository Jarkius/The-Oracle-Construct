/**
 * Matrix Nerve — Process Supervisor
 *
 * Manages daemon lifecycle with L1→L5 escalation.
 * Delegates actual process management to matrix-services.sh.
 * Tracks escalation state per daemon.
 */

import { $ } from 'bun';
import { appendFile } from 'node:fs/promises';
import type { DaemonState, NerveConfig, PulseEvent } from './types';
import { DEFAULT_NERVE_CONFIG } from './types';
import { EscalationEngine } from './escalation';
import { StateDetector } from './state-detector';
import { KnownFixEngine } from './known-fixes';

export class Supervisor {
  private daemons = new Map<string, DaemonState>();
  private escalation: EscalationEngine;
  private stateDetector: StateDetector;
  private knownFixes: KnownFixEngine;
  private config: NerveConfig;
  private cwd: string;
  private running = false;
  private pollInterval: ReturnType<typeof setInterval> | null = null;

  constructor(cwd: string, config?: Partial<NerveConfig>) {
    this.cwd = cwd;
    this.config = { ...DEFAULT_NERVE_CONFIG, ...config };
    this.escalation = new EscalationEngine(
      `${cwd}/${this.config.eventsPath}`,
      this.config.escalation
    );
    this.stateDetector = new StateDetector(
      `${cwd}/${this.config.eventsPath}`
    );
    this.knownFixes = new KnownFixEngine(
      `${cwd}/${this.config.knownFixesPath}`,
      `${cwd}/${this.config.eventsPath}`
    );
  }

  /**
   * Register a daemon for supervision.
   */
  register(name: string, port: number, command: string): void {
    const daemon: DaemonState = {
      name,
      pid: null,
      state: 'unknown',
      previousState: 'unknown',
      level: 0,
      restarts: 0,
      restartsThisHour: 0,
      lastRestartHour: Math.floor(Date.now() / 3_600_000),
      lastHealthCheck: 0,
      lastStateChange: Date.now(),
      escalationTimer: null,
      standbyTimer: null,
      exitHistory: [],
      port,
      command,
      logFile: `${this.cwd}/${this.config.daemonLogsDir}/${name}.log`,
    };
    this.daemons.set(name, daemon);
  }

  /**
   * Initialize the supervisor — load fixes, wire escalation.
   */
  async init(): Promise<void> {
    await this.knownFixes.load();

    // Wire escalation to use matrix-services.sh for restarts
    this.escalation.wire({
      restart: async (daemon) => {
        await this.restartDaemon(daemon.name);
      },
      diagnose: async (daemon) => {
        return this.diagnoseDaemon(daemon);
      },
    });
  }

  /**
   * Start polling daemon health.
   */
  start(intervalMs = 30_000): void {
    if (this.running) return;
    this.running = true;

    this.pollInterval = setInterval(() => this.checkAll(), intervalMs);
    // Run first check immediately
    this.checkAll();
  }

  /**
   * Stop the supervisor.
   */
  stop(): void {
    this.running = false;
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }

    // Clear all escalation timers
    for (const daemon of this.daemons.values()) {
      this.escalation.reset(daemon);
    }
  }

  /**
   * Check all registered daemons.
   */
  async checkAll(): Promise<void> {
    for (const [name, daemon] of this.daemons) {
      await this.checkDaemon(name, daemon);
    }

    // Send keepalive if all stable
    const states = new Map<string, ServiceState>();
    for (const [name, daemon] of this.daemons) {
      states.set(name, daemon.state);
    }
    await this.stateDetector.keepaliveIfStable(states);
  }

  /**
   * Check a single daemon's health.
   */
  private async checkDaemon(name: string, daemon: DaemonState): Promise<void> {
    daemon.lastHealthCheck = Date.now();

    try {
      const response = await fetch(`http://localhost:${daemon.port}/status`, {
        signal: AbortSignal.timeout(5000),
      });
      const newState = response.ok ? 'healthy' : 'degraded';

      // Detect state transition (side effect: emits PULSE events)
      await this.stateDetector.check(name, newState);
      daemon.previousState = daemon.state;
      daemon.state = newState;

      // If recovered from escalation, reset
      if (newState === 'healthy' && daemon.level > 0) {
        this.escalation.reset(daemon);
      }
    } catch {
      const newState: ServiceState = 'unhealthy';
      await this.stateDetector.check(name, newState);
      daemon.previousState = daemon.state;
      daemon.state = newState;

      // Only escalate if not already in escalation
      if (daemon.level === 0 || transition) {
        await this.handleUnhealthy(daemon);
      }
    }
  }

  /**
   * Handle an unhealthy daemon — check known fixes first, then escalate.
   */
  private async handleUnhealthy(daemon: DaemonState): Promise<void> {
    // Check known fixes first
    const lastExitCode = daemon.exitHistory[daemon.exitHistory.length - 1];
    const fix = this.knownFixes.findFix(
      daemon.name,
      `${daemon.name} unhealthy port:${daemon.port}`,
      lastExitCode
    );

    if (fix && fix.auto) {
      const success = await this.knownFixes.executeFix(fix);
      if (success) return; // Fix worked, skip escalation
    }

    // No fix or fix failed — escalate
    await this.escalation.handleFailure(daemon);
  }

  /**
   * Restart a daemon via matrix-services.sh.
   */
  private async restartDaemon(name: string): Promise<void> {
    const script = `${this.cwd}/${this.config.servicesScript}`;
    try {
      await $`bash ${script} restart ${name}`.quiet();
    } catch (err) {
      await this.emitEvent('nerve:restart-failed', {
        daemon: name,
        error: String(err),
      });
    }
  }

  /**
   * Spawn headless Claude for L4 diagnosis.
   */
  private async diagnoseDaemon(daemon: DaemonState): Promise<string> {
    const prompt = `The daemon "${daemon.name}" keeps crashing. ` +
      `Restarted ${daemon.restartsThisHour} times this hour. ` +
      `Exit codes: ${daemon.exitHistory.slice(-5).join(', ')}. ` +
      `Check log: ${daemon.logFile}. ` +
      `Diagnose the root cause and suggest a fix.`;

    const proc = Bun.spawn([
      'claude', '-p', prompt,
      '--output-format', 'text',
      '--allowedTools', 'Bash,Read,Grep,Glob',
      '--max-turns', '5',
    ], {
      cwd: this.cwd,
      env: { ...process.env, CLAUDE_CODE_ENTRYPOINT: 'cli' },
      stdout: 'pipe',
      stderr: 'pipe',
    });

    const timeout = setTimeout(() => {
      try { proc.kill(); } catch {}
    }, 3 * 60_000);

    const stdout = await new Response(proc.stdout).text();
    await proc.exited;
    clearTimeout(timeout);

    return stdout.trim();
  }

  /**
   * Get status of all daemons.
   */
  getStatus(): Array<{
    name: string;
    state: string;
    level: number;
    restarts: number;
    restartsThisHour: number;
    port: number;
    lastCheck: number;
  }> {
    return [...this.daemons.values()].map(d => ({
      name: d.name,
      state: d.state,
      level: d.level,
      restarts: d.restarts,
      restartsThisHour: d.restartsThisHour,
      port: d.port,
      lastCheck: d.lastHealthCheck,
    }));
  }

  /**
   * Wire a notification function (e.g., Telegram gateway).
   */
  wireNotify(fn: (message: string) => Promise<void>): void {
    this.escalation.wire({ notify: fn });
  }

  /**
   * Get L4 circuit breaker usage.
   */
  getL4Usage() {
    return this.escalation.getL4Usage();
  }

  /**
   * Get known fix stats.
   */
  getFixStats() {
    return this.knownFixes.getFixStats();
  }

  private async emitEvent(
    type: string,
    data: Record<string, unknown>
  ): Promise<void> {
    const event: PulseEvent = {
      id: `ev_${Date.now()}`,
      ts: new Date().toISOString(),
      type,
      agent: 'nerve',
      data,
    };
    await appendFile(
      `${this.cwd}/${this.config.eventsPath}`,
      JSON.stringify(event) + '\n'
    );
  }
}
