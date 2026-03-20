/**
 * Log Viewer Partial — Renders log lines with syntax highlighting
 */

function esc(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// ISO timestamp pattern: 2026-03-20T14:30:00.000Z or similar
const TIMESTAMP_RE = /^(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}[\w.]*Z?)/;

/**
 * Render log lines with optional error/warning highlighting.
 *
 * Each line gets a class for CSS-based coloring:
 * - .log-error for lines containing "error" or "ERROR"
 * - .log-warn for lines containing "warn" or "WARN"
 * - Timestamps are wrapped in .log-time spans
 */
export function renderLogLines(lines: string[], highlight: boolean = true): string {
  if (lines.length === 0) {
    return '<div class="log-line" style="color: #555;">(no log lines)</div>';
  }

  return lines.map((line) => {
    const escaped = esc(line);
    let className = "log-line";
    let content = escaped;

    if (highlight) {
      const lower = line.toLowerCase();
      if (lower.includes("error")) {
        className += " log-error";
      } else if (lower.includes("warn")) {
        className += " log-warn";
      }

      // Wrap timestamp in a span
      const tsMatch = escaped.match(TIMESTAMP_RE);
      if (tsMatch) {
        content = `<span class="log-time">${tsMatch[1]}</span>${escaped.slice(tsMatch[1].length)}`;
      }
    }

    return `<div class="${className}">${content}</div>`;
  }).join("");
}
