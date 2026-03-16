/**
 * Matrix Nerve — State Transition Detector
 *
 * Only emits events on state CHANGE (rising/falling edge).
 * Dramatically reduces event noise vs polling on every check.
 *
 * Pattern 7 from Oracle Nerve handoff.
 */

import { appendFile } from 'node:fs/promises';
import type { ServiceState, StateTransition, PulseEvent } from './types';

export class StateDetector {
  private previousStates = new Map<string, ServiceState>();
  private lastKeepalive = 0;
  private keepaliveIntervalMs: number;
  private eventsPath: string;

  constructor(eventsPath: string, keepaliveIntervalMs = 30 * 60_000) {
    this.eventsPath = eventsPath;
    this.keepaliveIntervalMs = keepaliveIntervalMs;
  }

  /**
   * Check state and emit event only on transition.
   * Returns the transition if one occurred, null otherwise.
   */
  async check(
    service: string,
    currentState: ServiceState,
    detail?: string
  ): Promise<StateTransition | null> {
    const prev = this.previousStates.get(service);
    this.previousStates.set(service, currentState);

    // First check — no previous state, just record
    if (prev === undefined) return null;

    // No change — skip
    if (prev === currentState) return null;

    const transition: StateTransition = {
      service,
      from: prev,
      to: currentState,
      timestamp: Date.now(),
      detail,
    };

    // Rising edge: healthy → unhealthy
    if (prev === 'healthy' && currentState !== 'healthy') {
      await this.emitEvent('heartbeat:fail', 'nerve', {
        service,
        from: prev,
        to: currentState,
        detail,
      });
    }

    // Falling edge: unhealthy → healthy
    if (prev !== 'healthy' && currentState === 'healthy') {
      await this.emitEvent('heartbeat:recover', 'nerve', {
        service,
        from: prev,
        to: currentState,
        detail,
      });
    }

    // Degraded transitions
    if (prev === 'healthy' && currentState === 'degraded') {
      await this.emitEvent('heartbeat:degraded', 'nerve', {
        service,
        detail,
      });
    }

    return transition;
  }

  /**
   * Send keepalive when all services are healthy.
   * Call this after checking all services.
   */
  async keepaliveIfStable(services: Map<string, ServiceState>): Promise<void> {
    const allHealthy = [...services.values()].every(s => s === 'healthy');
    if (!allHealthy) return;

    if (Date.now() - this.lastKeepalive > this.keepaliveIntervalMs) {
      await this.emitEvent('heartbeat:ok', 'nerve', {
        services: Object.fromEntries(services),
      });
      this.lastKeepalive = Date.now();
    }
  }

  /**
   * Get current known states.
   */
  getStates(): Map<string, ServiceState> {
    return new Map(this.previousStates);
  }

  /**
   * Emit a PULSE event via appendFile (NOT Bun.write — append flag is broken).
   */
  private async emitEvent(
    type: string,
    agent: string,
    data: Record<string, unknown> = {}
  ): Promise<void> {
    const event: PulseEvent = {
      id: `ev_${Date.now()}`,
      ts: new Date().toISOString(),
      type,
      agent,
      data,
    };
    const line = JSON.stringify(event) + '\n';
    await appendFile(this.eventsPath, line);
  }
}
