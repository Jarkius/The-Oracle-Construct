/**
 * Daemon Card Partials — HTML fragments for HTMX partial responses
 *
 * These return raw HTML strings, not full pages.
 */

function esc(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export interface DaemonInfo {
  name: string;
  port: number;
  running: boolean;
  hasHttp: boolean;
}

export interface QuickStats {
  events: number;
  pendingTasks: number;
  totalTasks: number;
  sessions: number;
  learnings: number;
}

export interface MemoryOverviewData {
  sqliteSize: string;
  chromaStatus: string;
  embeddingModel: string;
}

export interface EventInfo {
  ts: string;
  type: string;
  agent: string;
  data?: string;
}

/**
 * Render all daemon status cards in a grid layout.
 */
export function renderDaemonCards(daemons: DaemonInfo[]): string {
  if (daemons.length === 0) {
    return '<div style="color: #555;">No daemons configured.</div>';
  }

  const cards = daemons.map((d) => {
    const statusClass = d.running ? "green" : "red";
    const statusText = d.running ? "running" : "stopped";
    const portText = d.port > 0 ? `:${d.port}` : "no port";

    return `
      <div class="fade-in" style="display: flex; align-items: center; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #222;">
        <div style="display: flex; align-items: center; gap: 10px;">
          <span class="status-dot ${statusClass}"></span>
          <div>
            <div style="font-size: 13px; font-weight: 600;">${esc(d.name)}</div>
            <div style="font-size: 11px; color: #555;">${esc(portText)} &middot; ${esc(statusText)}</div>
          </div>
        </div>
        <div style="display: flex; gap: 6px;">
          ${d.running
            ? `<button class="btn btn-sm btn-danger"
                       hx-post="/api/daemons/${esc(d.name)}/restart"
                       hx-confirm="Restart ${esc(d.name)}?"
                       hx-swap="none">Restart</button>`
            : `<button class="btn btn-sm btn-primary"
                       hx-post="/api/daemons/${esc(d.name)}/start"
                       hx-swap="none">Start</button>`
          }
        </div>
      </div>`;
  });

  return cards.join("");
}

/**
 * Render quick stats — a single stat value + label.
 * Called per-metric from the dashboard.
 */
export function renderQuickStats(stats: QuickStats): string {
  return `
    <div class="grid-4">
      <div>
        <div class="stat-value">${stats.events}</div>
        <div class="stat-label">Events</div>
      </div>
      <div>
        <div class="stat-value${stats.pendingTasks > 10 ? " warn" : ""}">${stats.pendingTasks}</div>
        <div class="stat-label">Pending / ${stats.totalTasks} total</div>
      </div>
      <div>
        <div class="stat-value">${stats.sessions}</div>
        <div class="stat-label">Active Sessions</div>
      </div>
      <div>
        <div class="stat-value">${stats.learnings}</div>
        <div class="stat-label">Learnings</div>
      </div>
    </div>
  `;
}

/**
 * Render a single quick stat value (used for per-metric HTMX endpoints).
 */
export function renderSingleStat(value: number | string, warn?: boolean): string {
  return `<div class="stat-value${warn ? " warn" : ""}">${esc(String(value))}</div>`;
}

/**
 * Render memory overview card content.
 */
export function renderMemoryOverview(data: MemoryOverviewData): string {
  const chromaBadgeClass = data.chromaStatus === "connected"
    ? "badge-green"
    : data.chromaStatus === "skipped"
      ? "badge-yellow"
      : "badge-red";

  return `
    <div style="display: flex; flex-direction: column; gap: 12px;">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <span style="color: #888;">SQLite Size</span>
        <span style="font-weight: 600;">${esc(data.sqliteSize)}</span>
      </div>
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <span style="color: #888;">ChromaDB</span>
        <span class="badge ${chromaBadgeClass}">${esc(data.chromaStatus)}</span>
      </div>
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <span style="color: #888;">Embedding Model</span>
        <span style="font-size: 11px;">${esc(data.embeddingModel)}</span>
      </div>
    </div>
  `;
}

/**
 * Render a single event item for SSE swap (afterbegin).
 */
export function renderEventItem(event: EventInfo): string {
  const time = event.ts?.slice(11, 19) || "";
  const typeColor = event.type.startsWith("error")
    ? "log-error"
    : event.type.startsWith("warn")
      ? "log-warn"
      : "";

  return `
    <div class="fade-in" style="padding: 4px 0; border-bottom: 1px solid #1a1a1a;">
      <span class="log-time">${esc(time)}</span>
      <span class="${typeColor}">${esc(event.type)}</span>
      <span style="color: #00ff88;">${esc(event.agent)}</span>
      ${event.data ? `<span style="color: #555;"> ${esc(event.data)}</span>` : ""}
    </div>
  `;
}
