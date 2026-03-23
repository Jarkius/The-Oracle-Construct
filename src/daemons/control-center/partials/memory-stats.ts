/**
 * Memory Stats Partials — HTML fragments for memory subsystem details
 */

function esc(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export interface TableInfo {
  name: string;
  count: number;
}

export interface CollectionInfo {
  name: string;
  count: number;
}

export interface EmbeddingConfig {
  model: string;
  dimensions: number;
  batchSize: number;
}

export interface PlatformInfo {
  os: string;
  arch: string;
  bun: string;
  python3: string;
  sharp: string;
  chromaSkip: boolean;
}

/**
 * Render SQLite stats table with row counts and file size.
 */
export function renderSqliteStats(tables: TableInfo[], fileSize: number): string {
  const totalRows = tables.reduce((sum, t) => sum + t.count, 0);
  const sizeStr = fileSize < 1024 * 1024
    ? `${(fileSize / 1024).toFixed(1)} KB`
    : `${(fileSize / (1024 * 1024)).toFixed(2)} MB`;

  const rows = tables.map((t) => `
    <tr>
      <td>${esc(t.name)}</td>
      <td style="text-align: right;">${t.count.toLocaleString()}</td>
    </tr>
  `).join("");

  return `
    <div style="margin-bottom: 12px; display: flex; justify-content: space-between;">
      <span style="color: #888;">File size</span>
      <span style="font-weight: 600;">${esc(sizeStr)}</span>
    </div>
    <table>
      <thead>
        <tr>
          <th>Table</th>
          <th style="text-align: right;">Rows</th>
        </tr>
      </thead>
      <tbody>
        ${rows}
      </tbody>
      <tfoot>
        <tr style="border-top: 1px solid #333;">
          <td style="font-weight: 600; color: #00ff88;">Total</td>
          <td style="text-align: right; font-weight: 600; color: #00ff88;">${totalRows.toLocaleString()}</td>
        </tr>
      </tfoot>
    </table>
  `;
}

/**
 * Render ChromaDB status and optional collection table.
 */
export function renderChromaStats(
  status: string,
  collections?: CollectionInfo[],
): string {
  const badgeClass = status === "connected"
    ? "badge-green"
    : status === "skipped"
      ? "badge-yellow"
      : "badge-red";

  const isDisabled = status === "skipped";
  const toggleLabel = isDisabled ? "Enable" : "Disable";
  const toggleBtnClass = isDisabled ? "btn btn-primary" : "btn btn-danger";

  let html = `
    <div style="margin-bottom: 12px; display: flex; justify-content: space-between; align-items: center;">
      <span style="color: #888;">Status</span>
      <div style="display: flex; align-items: center; gap: 8px;">
        <span class="badge ${badgeClass}">${esc(status)}</span>
        <button class="${toggleBtnClass}" style="font-size: 10px; padding: 2px 8px;"
                hx-post="/api/vectordb/toggle"
                hx-swap="none"
                hx-on::after-request="htmx.trigger('#chromadb-container', 'refresh')">
          ${toggleLabel}
        </button>
      </div>
    </div>
  `;

  if (collections && collections.length > 0) {
    const rows = collections.map((col) => `
      <tr>
        <td>${esc(col.name)}</td>
        <td style="text-align: right;">${col.count.toLocaleString()}</td>
      </tr>
    `).join("");

    html += `
      <table>
        <thead>
          <tr>
            <th>Collection</th>
            <th style="text-align: right;">Documents</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    `;
  } else if (status === "connected") {
    html += '<div style="color: #555; font-size: 11px;">No collections found.</div>';
  }

  return html;
}

/**
 * Render embedding model configuration.
 */
export function renderEmbeddingInfo(config: EmbeddingConfig): string {
  return `
    <div style="display: flex; flex-direction: column; gap: 10px;">
      <div style="display: flex; justify-content: space-between;">
        <span style="color: #888;">Model</span>
        <span style="font-weight: 600;">${esc(config.model)}</span>
      </div>
      <div style="display: flex; justify-content: space-between;">
        <span style="color: #888;">Dimensions</span>
        <span>${config.dimensions}</span>
      </div>
      <div style="display: flex; justify-content: space-between;">
        <span style="color: #888;">Batch Size</span>
        <span>${config.batchSize}</span>
      </div>
    </div>
  `;
}

/**
 * Render platform dependencies status.
 */
export function renderPlatformInfo(info: PlatformInfo): string {
  function statusBadge(value: string, ok: boolean): string {
    return `<span class="badge ${ok ? "badge-green" : "badge-red"}">${esc(value)}</span>`;
  }

  return `
    <div style="display: flex; flex-direction: column; gap: 10px;">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <span style="color: #888;">OS / Arch</span>
        <span>${esc(info.os)} / ${esc(info.arch)}</span>
      </div>
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <span style="color: #888;">Bun</span>
        ${statusBadge(info.bun, info.bun !== "not found")}
      </div>
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <span style="color: #888;">Python3</span>
        ${statusBadge(info.python3, info.python3 !== "not found")}
      </div>
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <span style="color: #888;">Sharp</span>
        ${statusBadge(info.sharp, info.sharp !== "not found")}
      </div>
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <span style="color: #888;">ChromaDB</span>
        ${statusBadge(info.chromaSkip ? "skipped" : "enabled", !info.chromaSkip)}
      </div>
    </div>
  `;
}
