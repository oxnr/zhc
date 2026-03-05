#!/bin/bash
# Start Mission Control Dashboard
echo "📊 Starting Mission Control..."
echo "   Dashboard: http://localhost:4200"
echo ""

if [ -f dashboard/package.json ]; then
    cd dashboard
    PORT=4200 npm start
else
    echo "⚠️  Dashboard not found. Clone it first:"
    echo "   git clone https://github.com/builderz-labs/mission-control dashboard"
    echo "   cd dashboard && npm install"
    echo ""
    echo "Starting minimal fallback dashboard..."
    python3 -c "
import http.server
import json
import os

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            html = '''<!DOCTYPE html>
<html><head><title>Zero Human Corp — Dashboard</title>
<style>
body{font-family:system-ui;background:#0a0a0a;color:#e0e0e0;padding:40px;max-width:1200px;margin:0 auto}
h1{color:#00ff88}
.card{background:#1a1a1a;border:1px solid #333;border-radius:8px;padding:20px;margin:10px 0}
.status{color:#00ff88;font-weight:bold}
.warning{color:#ffaa00}
</style>
</head><body>
<h1>Zero Human Corp</h1>
<p class=\"warning\">Minimal dashboard — install Mission Control for full experience</p>
<div class=\"card\"><h3>Agent Status</h3><p>Agents starting...</p></div>
<div class=\"card\"><h3>Revenue</h3><p>$0.00</p></div>
<div class=\"card\"><h3>Costs</h3><p>$0.00</p></div>
<script>setTimeout(()=>location.reload(),30000)</script>
</body></html>'''
            self.wfile.write(html.encode())
        else:
            super().do_GET()

print('Fallback dashboard at http://localhost:4200')
http.server.HTTPServer(('', 4200), Handler).serve_forever()
"
fi
