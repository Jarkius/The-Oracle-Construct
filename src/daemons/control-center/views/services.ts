/**
 * Services Page — Daemon management with start/stop/restart controls
 *
 * Live-updating service cards with action buttons and Nerve escalation summary.
 */

import { layout } from "./layout";

export function servicesPage(): string {
  const content = `
    <!-- Service Cards -->
    <div class="card" style="margin-bottom: 16px;">
      <div class="card-title">
        Matrix Services
        <span class="htmx-indicator" style="margin-left: 8px; color: #00ff88;">refreshing...</span>
      </div>
      <div id="service-cards"
           hx-get="/partials/service-cards"
           hx-trigger="load, every 5s"
           hx-swap="innerHTML"
           hx-indicator="closest .card">
        <span style="color: #555;">Loading services...</span>
      </div>
    </div>

    <!-- Nerve Escalation Summary -->
    <div class="card">
      <div class="card-title">Nerve Escalation Summary</div>
      <div hx-get="/partials/nerve-summary"
           hx-trigger="load, every 10s"
           hx-swap="innerHTML">
        <span style="color: #555;">Loading escalation data...</span>
      </div>
    </div>
  `;

  return layout("Services", content, "services");
}
