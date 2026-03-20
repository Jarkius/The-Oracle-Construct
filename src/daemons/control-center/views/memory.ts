/**
 * Memory Page — SQLite, ChromaDB, embedding, and platform status
 *
 * Displays memory subsystem health and provides admin actions.
 */

import { layout } from "./layout";

export function memoryPage(): string {
  const content = `
    <!-- Top row: SQLite + ChromaDB -->
    <div class="grid-2" style="margin-bottom: 16px;">
      <div class="card">
        <div class="card-title">SQLite Database</div>
        <div hx-get="/partials/sqlite-stats"
             hx-trigger="load, every 30s"
             hx-swap="innerHTML">
          <span style="color: #555;">Loading SQLite stats...</span>
        </div>
      </div>

      <div class="card">
        <div class="card-title">ChromaDB Vector Store</div>
        <div hx-get="/partials/chromadb-stats"
             hx-trigger="load, every 30s"
             hx-swap="innerHTML">
          <span style="color: #555;">Loading ChromaDB status...</span>
        </div>
      </div>
    </div>

    <!-- Second row: Embedding + Platform -->
    <div class="grid-2" style="margin-bottom: 16px;">
      <div class="card">
        <div class="card-title">Embedding Model</div>
        <div hx-get="/partials/embedding-info"
             hx-trigger="load"
             hx-swap="innerHTML">
          <span style="color: #555;">Loading embedding info...</span>
        </div>
      </div>

      <div class="card">
        <div class="card-title">Platform Status</div>
        <div hx-get="/partials/platform-info"
             hx-trigger="load"
             hx-swap="innerHTML">
          <span style="color: #555;">Loading platform info...</span>
        </div>
      </div>
    </div>

    <!-- Actions -->
    <div class="card">
      <div class="card-title">Actions</div>
      <div style="display: flex; gap: 12px; flex-wrap: wrap;">
        <button class="btn btn-primary"
                hx-post="/api/memory/reindex"
                hx-confirm="Reindex all memory? This may take a while."
                hx-swap="none"
                hx-indicator="this">
          Reindex Memory
        </button>
        <button class="btn"
                hx-post="/api/memory/export"
                hx-confirm="Export memory database?"
                hx-swap="none"
                hx-indicator="this">
          Export Database
        </button>
        <button class="btn btn-danger"
                hx-post="/api/memory/vacuum"
                hx-confirm="Vacuum SQLite database? This reclaims space."
                hx-swap="none"
                hx-indicator="this">
          Vacuum DB
        </button>
      </div>
      <div id="action-result" style="margin-top: 12px; font-size: 11px; color: #888;"></div>
    </div>
  `;

  return layout("Memory", content, "memory");
}
