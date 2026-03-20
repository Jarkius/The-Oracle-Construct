/**
 * Matrix Nerve — L1→L5 Escalation Engine
 *
 * Graduated self-healing: errors are expected, panic is not.
 * Each level escalates intervention until the problem resolves
 * or a human takes over.
 *
 * Pattern 1 from Oracle Nerve handoff.
 *
 * L1: Simple restart (< threshold/hour)           → 35s delay
 * L2: Clear state + restart (3-4 restarts/hour)    → 70s delay
 * L3: Notify human (Telegram) + schedule L4        → immediate
 * L4: Spawn Claude to diagnose (circuit breaker)   → 15 min delay
 * L5: Standby: retry every 5 min, auto-recover     → 5 min interval
 */

import { appendFile } from 'node:fs/promises';
import type {
  DaemonState,
  EscalationConfig,
  EscalationLevel,
  PulseEvent,
} from './types';
import { DEFAULT_ESCALATION_CONFIG } from './types';

export class EscalationEngine {
  private config: EscalationConfig;
  private eventsPath: string;
  private l4CountToday = 0;
  private l4LastReset = 0;
  private notifyFn: ((message: string) => Promise<void>) | null = null;
  private diagnoseFn: ((daemon: DaemonState) => Promise<string>) | null = null;
  private restartFn: ((daemon: DaemonState) => Promise<void>) | null = null;

  constructor(eventsPath: string, config?: Partial<EscalationConfig>) {
    this.eventsPath = eventsPath;
    this.config = { ...DEFAULT_ESCALATION_CONFIG, ...config };
  }

  /**
   * Wire external functions for notification, diagnosis, and restart.
   */
  wire(options: {
    notify?: (message: string) => Promise<void>;
    diagnose?: (daemon: DaemonState) => Promise<string>;
    restart?: (daemon: DaemonState) => Promise<void>;
  }): void {
    if (options.notify) this.notifyFn = options.notify;
    if (options.diagnose) this.diagnoseFn = options.diagnose;
    if (options.restart) this.restartFn = options.restart;
  }

  /**
   * Handle a daemon failure. Determines escalation level and acts.
   */
  async handleFailure(daemon: DaemonState): Promise<EscalationLevel> {
    // Reset hourly counter
    const currentHour = Math.floor(Date.now() / 3_600_000);
    if (currentHour !== daemon.lastRestartHour) {
      daemon.restartsThisHour = 0;
      daemon.lastRestartHour = currentHour;
    }

    // Reset daily L4 counter
    const currentDay = Math.floor(Date.now() / 86_400_000);
    if (currentDay !== Math.floor(this.l4LastReset / 86_400_000)) {
      this.l4CountToday = 0;
      this.l4LastReset = Date.now();
    }

    daemon.restarts++;
    daemon.restartsThisHour++;

    // L1: Simple restart
    if (daemon.restartsThisHour < this.config.l2Threshold) {
      return this.escalateL1(daemon);
    }

    // L2: Clear state + restart
    if (daemon.restartsThisHour < this.config.l3Threshold) {
      return this.escalateL2(daemon);
    }

    // L3: Notify human, schedule L4
    return this.escalateL3(daemon);
  }

  private async escalateL1(daemon: DaemonState): Promise<EscalationLevel> {
    daemon.level = 1;
    await this.emitEvent('nerve:escalation', {
      daemon: daemon.name,
      level: 1,
      restartsThisHour: daemon.restartsThisHour,
      action: 'restart',
    });

    setTimeout(async () => {
      if (this.restartFn) await this.restartFn(daemon);
    }, this.config.l1DelayMs);

    return 1;
  }

  private async escalateL2(daemon: DaemonState): Promise<EscalationLevel> {
    daemon.level = 2;
    await this.emitEvent('nerve:escalation', {
      daemon: daemon.name,
      level: 2,
      restartsThisHour: daemon.restartsThisHour,
      action: 'clear-state-restart',
    });

    // Clear temp state (log file)
    try {
      await appendFile(daemon.logFile, `[${new Date().toISOString()}] L2 reset\n`);
    } catch {}

    setTimeout(async () => {
      if (this.restartFn) await this.restartFn(daemon);
    }, this.config.l2DelayMs);

    return 2;
  }

  private async escalateL3(daemon: DaemonState): Promise<EscalationLevel> {
    daemon.level = 3;
    const msg = `[Nerve L3] ${daemon.name} exceeded restart budget (${daemon.restartsThisHour} restarts this hour)`;

    await this.emitEvent('nerve:escalation', {
      daemon: daemon.name,
      level: 3,
      restartsThisHour: daemon.restartsThisHour,
      action: 'notify-human',
    });

    // Notify via gateway/Telegram
    if (this.notifyFn) {
      await this.notifyFn(msg);
    }

    // Schedule L4 diagnosis
    if (this.l4CountToday < this.config.l4MaxPerDay) {
      daemon.escalationTimer = setTimeout(
        () => this.escalateL4(daemon),
        this.config.l4DelayMs
      );
    } else {
      // Circuit breaker: skip to L5
      await this.escalateL5(daemon);
    }

    return 3;
  }

  private async escalateL4(daemon: DaemonState): Promise<void> {
    // Already recovered? Cancel
    if (daemon.state === 'healthy') {
      daemon.level = 0;
      return;
    }

    daemon.level = 4;
    this.l4CountToday++;

    await this.emitEvent('nerve:escalation', {
      daemon: daemon.name,
      level: 4,
      l4CountToday: this.l4CountToday,
      action: 'claude-diagnosis',
    });

    // Spawn Claude for diagnosis
    if (this.diagnoseFn) {
      try {
        const diagnosis = await this.diagnoseFn(daemon);
        await this.emitEvent('nerve:diagnosis', {
          daemon: daemon.name,
          diagnosis: diagnosis.slice(0, 3000),
        });

        if (this.notifyFn) {
          await this.notifyFn(`[Nerve L4] Diagnosis for ${daemon.name}:\n${diagnosis.slice(0, 1000)}`);
        }
      } catch (err) {
        await this.emitEvent('nerve:diagnosis-failed', {
          daemon: daemon.name,
          error: String(err),
        });
      }
    }

    // Move to L5 standby
    await this.escalateL5(daemon);
  }

  private async escalateL5(daemon: DaemonState): Promise<void> {
    daemon.level = 5;

    await this.emitEvent('nerve:escalation', {
      daemon: daemon.name,
      level: 5,
      action: 'standby',
    });

    // Clear any existing standby timer
    if (daemon.standbyTimer) clearInterval(daemon.standbyTimer);

    daemon.standbyTimer = setInterval(async () => {
      // Try restart
      if (this.restartFn) {
        await this.restartFn(daemon);
      }

      // Check if it stays alive
      setTimeout(async () => {
        if (daemon.state === 'healthy') {
          daemon.level = 0;
          daemon.restartsThisHour = 0;
          if (daemon.standbyTimer) clearInterval(daemon.standbyTimer);
          daemon.standbyTimer = null;

          await this.emitEvent('nerve:recovered', {
            daemon: daemon.name,
            fromLevel: 5,
          });

          if (this.notifyFn) {
            await this.notifyFn(`[Nerve] ${daemon.name} recovered from L5 standby`);
          }
        }
      }, this.config.l5StabilityMs);
    }, this.config.l5RetryIntervalMs);
  }

  /**
   * Reset escalation for a daemon (e.g., after manual intervention).
   */
  reset(daemon: DaemonState): void {
    daemon.level = 0;
    daemon.restartsThisHour = 0;
    if (daemon.escalationTimer) {
      clearTimeout(daemon.escalationTimer);
      daemon.escalationTimer = null;
    }
    if (daemon.standbyTimer) {
      clearInterval(daemon.standbyTimer);
      daemon.standbyTimer = null;
    }
  }

  /**
   * Get current L4 usage for circuit breaker visibility.
   */
  getL4Usage(): { used: number; max: number } {
    return { used: this.l4CountToday, max: this.config.l4MaxPerDay };
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
    await appendFile(this.eventsPath, JSON.stringify(event) + '\n');
  }
}
