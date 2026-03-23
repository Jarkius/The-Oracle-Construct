/**
 * Dashboard Page — Main overview of Matrix system status
 *
 * Uses HTMX for live-updating daemon cards, stats, memory overview,
 * and SSE for real-time event streaming.
 */

import { layout } from "./layout";

export function dashboardPage(): string {
  const content = `
    <!-- Daemon Status — full width -->
    <div class="card card-full" style="margin-bottom: 16px;">
      <div class="card-title">
        Daemon Status
        <span class="htmx-indicator" style="margin-left: 8px; color: #00ff88;">refreshing...</span>
      </div>
      <div id="daemon-summary"
           hx-get="/partials/daemon-summary"
           hx-trigger="load, every 5s"
           hx-swap="innerHTML"
           hx-indicator="closest .card">
        <span style="color: #555;">Loading daemons...</span>
      </div>
    </div>

    <!-- Quick Stats — row of 4 -->
    <div class="grid-4" style="margin-bottom: 16px;">
      <div class="card">
        <div class="card-title">Events</div>
        <div hx-get="/partials/quick-stats?metric=events"
             hx-trigger="load, every 10s"
             hx-swap="innerHTML">
          <div class="stat-value">-</div>
        </div>
      </div>
      <div class="card">
        <div class="card-title">Pending Tasks</div>
        <div hx-get="/partials/quick-stats?metric=pendingTasks"
             hx-trigger="load, every 10s"
             hx-swap="innerHTML">
          <div class="stat-value">-</div>
        </div>
      </div>
      <div class="card">
        <div class="card-title">Active Sessions</div>
        <div hx-get="/partials/quick-stats?metric=sessions"
             hx-trigger="load, every 10s"
             hx-swap="innerHTML">
          <div class="stat-value">-</div>
        </div>
      </div>
      <div class="card">
        <div class="card-title">Learnings</div>
        <div hx-get="/partials/quick-stats?metric=learnings"
             hx-trigger="load, every 10s"
             hx-swap="innerHTML">
          <div class="stat-value">-</div>
        </div>
      </div>
    </div>

    <!-- Bottom row — Memory + Events -->
    <div class="grid-2">
      <div class="card">
        <div class="card-title">Memory Overview</div>
        <div hx-get="/partials/memory-overview"
             hx-trigger="load, every 30s"
             hx-swap="innerHTML">
          <span style="color: #555;">Loading memory stats...</span>
        </div>
      </div>

      <div class="card">
        <div class="card-title">Recent Events</div>
        <div hx-ext="sse" sse-connect="/api/stream/events">
          <div id="event-list"
               sse-swap="new-event"
               hx-swap="afterbegin"
               style="max-height: 400px; overflow-y: auto; font-size: 11px;">
            <span style="color: #555;">Waiting for events...</span>
          </div>
        </div>
      </div>
    </div>
  `;

  return layout("Dashboard", content, "dashboard");
}
