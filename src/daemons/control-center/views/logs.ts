/**
 * Logs Page — Log viewer with source switching, search, and live tail
 *
 * Supports multiple log sources, line count control, and SSE-based live tailing.
 */

import { layout } from "./layout";

export function logsPage(): string {
  const content = `
    <!-- Controls -->
    <div class="card" style="margin-bottom: 16px;">
      <div style="display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
        <div>
          <label style="font-size: 11px; color: #666; display: block; margin-bottom: 4px;">Source</label>
          <select id="log-source" onchange="switchLogSource()">
            <option value="events">PULSE Events</option>
            <option value="memory-errors">Memory Errors</option>
            <option value="heartbeat">Heartbeat</option>
            <option value="gateway">Gateway</option>
            <option value="hub">Hub</option>
            <option value="indexer">Indexer</option>
            <option value="matrix-daemon">Matrix Daemon</option>
          </select>
        </div>
        <div>
          <label style="font-size: 11px; color: #666; display: block; margin-bottom: 4px;">Search</label>
          <input type="text" id="log-search" placeholder="Filter lines..."
                 onkeyup="filterLogs()" style="width: 200px;">
        </div>
        <div>
          <label style="font-size: 11px; color: #666; display: block; margin-bottom: 4px;">Lines</label>
          <select id="log-lines" onchange="switchLogSource()">
            <option value="50">50</option>
            <option value="100" selected>100</option>
            <option value="500">500</option>
          </select>
        </div>
        <div style="margin-left: auto; align-self: flex-end;">
          <button class="btn btn-sm" id="tail-btn" onclick="toggleTail()">
            Start Live Tail
          </button>
          <button class="btn btn-sm" onclick="switchLogSource()">
            Refresh
          </button>
        </div>
      </div>
    </div>

    <!-- Log Output -->
    <div class="card">
      <div class="card-title">
        Output
        <span id="log-status" style="margin-left: 8px; font-size: 10px; color: #555;"></span>
      </div>
      <div id="log-output"
           class="log-output"
           hx-get="/partials/logs?source=events&lines=100"
           hx-trigger="load"
           hx-swap="innerHTML"
           style="min-height: 300px;">
        <span style="color: #555;">Loading logs...</span>
      </div>
    </div>

    <script>
      var tailEventSource = null;

      function switchLogSource() {
        var source = document.getElementById('log-source').value;
        var lines = document.getElementById('log-lines').value;
        var output = document.getElementById('log-output');
        var url = '/partials/logs?source=' + encodeURIComponent(source) + '&lines=' + encodeURIComponent(lines);
        output.setAttribute('hx-get', url);
        htmx.trigger(output, 'htmx:load');
        htmx.ajax('GET', url, { target: '#log-output', swap: 'innerHTML' });
        document.getElementById('log-status').textContent = 'Loaded ' + source;

        // Stop tail if running
        if (tailEventSource) {
          stopTail();
        }
      }

      function filterLogs() {
        var query = document.getElementById('log-search').value.toLowerCase();
        var lines = document.getElementById('log-output').querySelectorAll('.log-line');
        for (var i = 0; i < lines.length; i++) {
          var text = lines[i].textContent.toLowerCase();
          lines[i].style.display = (!query || text.indexOf(query) !== -1) ? '' : 'none';
        }
      }

      function toggleTail() {
        if (tailEventSource) {
          stopTail();
        } else {
          startTail();
        }
      }

      function startTail() {
        var source = document.getElementById('log-source').value;
        var btn = document.getElementById('tail-btn');
        tailEventSource = new EventSource('/api/stream/logs?source=' + encodeURIComponent(source));
        tailEventSource.addEventListener('log-line', function(e) {
          var output = document.getElementById('log-output');
          var div = document.createElement('div');
          div.className = 'log-line fade-in';
          div.textContent = e.data;
          // Highlight
          var lower = e.data.toLowerCase();
          if (lower.indexOf('error') !== -1) div.classList.add('log-error');
          else if (lower.indexOf('warn') !== -1) div.classList.add('log-warn');
          output.appendChild(div);
          output.scrollTop = output.scrollHeight;
        });
        tailEventSource.onerror = function() {
          stopTail();
        };
        btn.textContent = 'Stop Live Tail';
        btn.classList.add('btn-danger');
        document.getElementById('log-status').textContent = 'Live tail: ' + source;
      }

      function stopTail() {
        if (tailEventSource) {
          tailEventSource.close();
          tailEventSource = null;
        }
        var btn = document.getElementById('tail-btn');
        btn.textContent = 'Start Live Tail';
        btn.classList.remove('btn-danger');
        document.getElementById('log-status').textContent = '';
      }
    </script>
  `;

  return layout("Logs", content, "logs");
}
