/**
 * Layout — Full page shell for Matrix Control Center v2
 *
 * Returns a complete HTML document with sidebar nav, header, and content area.
 * All CSS is inlined — no external stylesheet needed.
 */

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

const NAV_ITEMS = [
  { href: "/", label: "Dashboard", icon: "&#9632;" },
  { href: "/memory", label: "Memory", icon: "&#9670;" },
  { href: "/services", label: "Services", icon: "&#9654;" },
  { href: "/logs", label: "Logs", icon: "&#9776;" },
];

export function layout(
  title: string,
  content: string,
  activePage: string = "dashboard",
): string {
  const navLinks = NAV_ITEMS.map((item) => {
    const isActive = item.label.toLowerCase() === activePage.toLowerCase();
    return `<a href="${item.href}" class="nav-link${isActive ? " active" : ""}">${item.icon} ${escapeHtml(item.label)}</a>`;
  }).join("\n        ");

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(title)} — Matrix Control Center</title>
  <script src="/static/htmx.min.js"></script>
  <script src="/static/sse.js"></script>
  <style>
    /* ── Reset ──────────────────────────────────────────────── */
    *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

    /* ── Base ───────────────────────────────────────────────── */
    body {
      font-family: 'SF Mono', 'Cascadia Code', 'Fira Code', 'Menlo', 'Consolas', monospace;
      background: #0a0a0a;
      color: #e0e0e0;
      font-size: 13px;
      line-height: 1.5;
    }
    a { color: #00ff88; text-decoration: none; }
    a:hover { text-decoration: underline; }

    /* ── Sidebar ────────────────────────────────────────────── */
    .sidebar {
      position: fixed;
      top: 0;
      left: 0;
      width: 220px;
      height: 100vh;
      background: #111;
      border-right: 1px solid #222;
      display: flex;
      flex-direction: column;
      z-index: 100;
    }
    .sidebar-logo {
      padding: 20px 16px 12px;
      font-size: 18px;
      font-weight: bold;
      color: #00ff88;
      letter-spacing: 4px;
      border-bottom: 1px solid #222;
    }
    .sidebar-nav {
      flex: 1;
      padding: 12px 0;
    }
    .nav-link {
      display: block;
      padding: 10px 20px;
      color: #888;
      font-size: 13px;
      transition: color 0.2s, background 0.2s;
    }
    .nav-link:hover {
      color: #e0e0e0;
      background: #1a1a1a;
      text-decoration: none;
    }
    .nav-link.active {
      color: #00ff88;
      background: #0a1a10;
      border-left: 3px solid #00ff88;
      padding-left: 17px;
    }
    .sidebar-footer {
      padding: 12px 16px;
      border-top: 1px solid #222;
      font-size: 10px;
      color: #444;
    }

    /* ── Content ────────────────────────────────────────────── */
    .content {
      margin-left: 220px;
      padding: 24px;
      min-height: 100vh;
    }
    .page-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 24px;
      padding-bottom: 16px;
      border-bottom: 1px solid #222;
    }
    .page-title {
      font-size: 18px;
      font-weight: bold;
      color: #e0e0e0;
    }
    .header-meta {
      display: flex;
      align-items: center;
      gap: 16px;
    }
    .sse-indicator {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 11px;
      color: #666;
    }
    .sse-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #ff4444;
      transition: background 0.3s;
    }
    .sse-dot.connected { background: #00ff88; }
    .platform-badge {
      font-size: 10px;
      padding: 3px 8px;
      border-radius: 10px;
      background: #1a1a1a;
      border: 1px solid #333;
      color: #888;
    }

    /* ── Cards ──────────────────────────────────────────────── */
    .card {
      background: #1a1a1a;
      border: 1px solid #333;
      border-radius: 8px;
      padding: 16px;
    }
    .card-title {
      font-size: 11px;
      font-weight: 600;
      color: #666;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 12px;
    }
    .card-full { grid-column: 1 / -1; }

    /* ── Grid ───────────────────────────────────────────────── */
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
      gap: 16px;
    }
    .grid-2 {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
    }
    .grid-4 {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 16px;
    }

    /* ── Status ─────────────────────────────────────────────── */
    .status-dot {
      display: inline-block;
      width: 10px;
      height: 10px;
      border-radius: 50%;
      transition: background 0.3s;
    }
    .status-dot.green  { background: #00ff88; box-shadow: 0 0 6px #00ff8844; }
    .status-dot.red    { background: #ff4444; box-shadow: 0 0 6px #ff444444; }
    .status-dot.yellow { background: #ffaa00; box-shadow: 0 0 6px #ffaa0044; }
    .status-dot.gray   { background: #666; }

    /* ── Stats ──────────────────────────────────────────────── */
    .stat-value {
      font-size: 28px;
      font-weight: bold;
      color: #00ff88;
    }
    .stat-value.warn { color: #ffaa00; }
    .stat-value.error { color: #ff4444; }
    .stat-label {
      font-size: 11px;
      color: #666;
      margin-top: 4px;
    }

    /* ── Badges ─────────────────────────────────────────────── */
    .badge {
      display: inline-block;
      font-size: 10px;
      padding: 2px 8px;
      border-radius: 10px;
      font-weight: 600;
    }
    .badge-green  { background: #0a2a15; color: #00ff88; border: 1px solid #00ff8833; }
    .badge-red    { background: #2a0a0a; color: #ff4444; border: 1px solid #ff444433; }
    .badge-yellow { background: #2a2a0a; color: #ffaa00; border: 1px solid #ffaa0033; }
    .badge-gray   { background: #1a1a1a; color: #888; border: 1px solid #33333366; }

    /* ── Buttons ────────────────────────────────────────────── */
    .btn {
      background: #333;
      color: #ddd;
      border: 1px solid #555;
      padding: 6px 12px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 12px;
      font-family: inherit;
      transition: background 0.2s;
    }
    .btn:hover { background: #444; }
    .btn:active { background: #555; }
    .btn-sm { padding: 3px 8px; font-size: 11px; }
    .btn-danger { background: #3a1a1a; border-color: #633; color: #ff6666; }
    .btn-danger:hover { background: #4a2020; }
    .btn-primary { background: #0a2a15; border-color: #00ff8844; color: #00ff88; }
    .btn-primary:hover { background: #0f3a1f; }

    /* ── Tables ─────────────────────────────────────────────── */
    table {
      width: 100%;
      border-collapse: collapse;
    }
    th {
      text-align: left;
      padding: 8px 12px;
      font-size: 11px;
      color: #666;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      border-bottom: 1px solid #333;
    }
    td {
      padding: 8px 12px;
      border-bottom: 1px solid #1a1a1a;
      font-size: 12px;
    }
    tr:nth-child(even) td { background: #151515; }
    tr:hover td { background: #1e1e1e; }

    /* ── Log output ────────────────────────────────────────── */
    .log-output {
      background: #111;
      color: #0f0;
      font-family: inherit;
      font-size: 11px;
      line-height: 1.6;
      padding: 12px;
      border-radius: 6px;
      border: 1px solid #222;
      overflow-x: auto;
      overflow-y: auto;
      max-height: 600px;
      white-space: pre-wrap;
      word-break: break-all;
    }
    .log-error { color: #ff4444; }
    .log-warn  { color: #ffaa00; }
    .log-time  { color: #555; }

    /* ── Forms ──────────────────────────────────────────────── */
    select, input[type="text"] {
      background: #1a1a1a;
      color: #e0e0e0;
      border: 1px solid #333;
      padding: 6px 10px;
      border-radius: 4px;
      font-family: inherit;
      font-size: 12px;
    }
    select:focus, input:focus {
      outline: none;
      border-color: #00ff88;
    }

    /* ── Animations ────────────────────────────────────────── */
    @keyframes pulse-glow {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.5; }
    }
    .pulse { animation: pulse-glow 2s ease-in-out infinite; }

    @keyframes fade-in {
      from { opacity: 0; transform: translateY(-4px); }
      to { opacity: 1; transform: translateY(0); }
    }
    .fade-in { animation: fade-in 0.3s ease-out; }

    /* HTMX loading indicator */
    .htmx-indicator { opacity: 0; transition: opacity 0.2s; }
    .htmx-request .htmx-indicator { opacity: 1; }
    .htmx-request.htmx-indicator { opacity: 1; }

    /* ── Responsive ────────────────────────────────────────── */
    @media (max-width: 768px) {
      .sidebar {
        width: 60px;
      }
      .sidebar-logo {
        font-size: 12px;
        letter-spacing: 0;
        padding: 16px 8px;
        text-align: center;
      }
      .nav-link {
        padding: 10px;
        text-align: center;
        font-size: 16px;
      }
      .sidebar-footer { display: none; }
      .content { margin-left: 60px; padding: 16px; }
      .grid-2, .grid-4 { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <nav class="sidebar">
    <div class="sidebar-logo">MATRIX</div>
    <div class="sidebar-nav">
        ${navLinks}
    </div>
    <div class="sidebar-footer">Control Center v2</div>
  </nav>
  <main class="content">
    <header class="page-header">
      <h1 class="page-title">${escapeHtml(title)}</h1>
      <div class="header-meta">
        <div class="sse-indicator">
          <span class="sse-dot" id="sse-status"></span>
          <span id="sse-label">Disconnected</span>
        </div>
        <span class="platform-badge" id="platform-badge">--</span>
      </div>
    </header>
    ${content}
  </main>
  <script>
    // Detect platform
    (function() {
      var ua = navigator.userAgent;
      var os = 'Unknown';
      if (ua.indexOf('Win') !== -1) os = 'Windows';
      else if (ua.indexOf('Mac') !== -1) os = 'macOS';
      else if (ua.indexOf('Linux') !== -1) os = 'Linux';
      document.getElementById('platform-badge').textContent = os;
    })();

    // SSE connection tracking
    document.body.addEventListener('htmx:sseOpen', function() {
      var dot = document.getElementById('sse-status');
      var label = document.getElementById('sse-label');
      if (dot) dot.classList.add('connected');
      if (label) label.textContent = 'Connected';
    });
    document.body.addEventListener('htmx:sseError', function() {
      var dot = document.getElementById('sse-status');
      var label = document.getElementById('sse-label');
      if (dot) dot.classList.remove('connected');
      if (label) label.textContent = 'Disconnected';
    });
    document.body.addEventListener('htmx:sseClose', function() {
      var dot = document.getElementById('sse-status');
      var label = document.getElementById('sse-label');
      if (dot) dot.classList.remove('connected');
      if (label) label.textContent = 'Disconnected';
    });
  </script>
</body>
</html>`;
}
