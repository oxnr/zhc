/**
 * Zero Human Corp — Mission Control Server
 *
 * Watches memory/, economy/, symphony/ for changes and pushes
 * real-time updates to the dashboard via WebSocket.
 *
 * No secrets needed — reads only local Markdown/JSON files.
 */

const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');
const chokidar = require('chokidar');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || process.env.DASHBOARD_PORT || 4200;
const ROOT = process.env.ZHC_ROOT || path.join(__dirname, '..');

// ---- State ----

function readFileOrDefault(filePath, fallback = '') {
  try {
    return fs.readFileSync(path.join(ROOT, filePath), 'utf-8');
  } catch {
    return fallback;
  }
}

function readJsonOrDefault(filePath, fallback = {}) {
  try {
    return JSON.parse(fs.readFileSync(path.join(ROOT, filePath), 'utf-8'));
  } catch {
    return fallback;
  }
}

function parseRevenue(content) {
  const lines = content.split('\n');
  let totalRevenue = 0, totalCosts = 0;
  const revenues = [], costs = [];

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('- REVENUE:')) {
      const match = trimmed.match(/\$([0-9.]+)/);
      if (match) {
        const amount = parseFloat(match[1]);
        totalRevenue += amount;
        revenues.push({ raw: trimmed, amount });
      }
    } else if (trimmed.startsWith('- COST:')) {
      const match = trimmed.match(/\$([0-9.]+)/);
      if (match) {
        const amount = parseFloat(match[1]);
        totalCosts += amount;
        costs.push({ raw: trimmed, amount });
      }
    }
  }

  return { totalRevenue, totalCosts, netPnl: totalRevenue - totalCosts, revenues, costs };
}

function parseInterventions(content) {
  const lines = content.split('\n');
  const items = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('- [OPEN]') || trimmed.startsWith('- [RESOLVED]')) {
      const isOpen = trimmed.startsWith('- [OPEN]');
      items.push({ raw: trimmed, open: isOpen });
    }
  }
  return items;
}

function getFullState() {
  const companyState = readFileOrDefault('memory/company-state.md', '# Not initialized');
  const revenueLog = readFileOrDefault('memory/revenue-log.md', '');
  const decisions = readFileOrDefault('memory/decisions.md', '');
  const learnings = readFileOrDefault('memory/learnings.md', '');
  const interventions = readFileOrDefault('memory/intervention-queue.md', '');
  const board = readJsonOrDefault('symphony/board.json', { tasks: [] });
  const budget = readJsonOrDefault('economy/budget.json', {});
  const agentConfigs = {
    ceo: readJsonOrDefault('agents/ceo/agent.json', {}),
    cto: readJsonOrDefault('agents/cto/agent.json', {}),
    bizdev: readJsonOrDefault('agents/bizdev/agent.json', {}),
    ops: readJsonOrDefault('agents/ops/agent.json', {}),
  };

  const finance = parseRevenue(revenueLog);
  const interventionItems = parseInterventions(interventions);

  // Get latest report
  let latestReport = '';
  const reportsDir = path.join(ROOT, 'economy', 'reports');
  try {
    const reports = fs.readdirSync(reportsDir).filter(f => f.endsWith('.md')).sort();
    if (reports.length > 0) {
      latestReport = fs.readFileSync(path.join(reportsDir, reports[reports.length - 1]), 'utf-8');
    }
  } catch {}

  // Task board summary
  const taskSummary = {};
  for (const task of (board.tasks || [])) {
    taskSummary[task.status] = (taskSummary[task.status] || 0) + 1;
  }

  return {
    timestamp: new Date().toISOString(),
    companyState,
    finance,
    decisions: decisions.split('\n').filter(l => l.trim().startsWith('##')).slice(-10),
    learnings: learnings.split('\n').filter(l => l.trim()).slice(-10),
    interventions: interventionItems,
    openInterventions: interventionItems.filter(i => i.open).length,
    board: {
      summary: taskSummary,
      totalTasks: (board.tasks || []).length,
      tasks: (board.tasks || []).slice(-20),
    },
    budget,
    agents: agentConfigs,
    latestReport,
  };
}

// ---- Express + WebSocket ----

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

// Serve the dashboard HTML
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// REST API for current state
app.get('/api/state', (req, res) => {
  res.json(getFullState());
});

// REST API for specific memory files
app.get('/api/memory/:file', (req, res) => {
  const content = readFileOrDefault(`memory/${req.params.file}`, '# Not found');
  res.type('text/plain').send(content);
});

// WebSocket connections
const clients = new Set();

wss.on('connection', (ws) => {
  clients.add(ws);
  // Send initial state
  ws.send(JSON.stringify({ type: 'full-state', data: getFullState() }));
  ws.on('close', () => clients.delete(ws));
});

function broadcast(data) {
  const msg = JSON.stringify(data);
  for (const client of clients) {
    if (client.readyState === 1) {
      client.send(msg);
    }
  }
}

// ---- File Watcher ----

const watchPaths = [
  path.join(ROOT, 'memory'),
  path.join(ROOT, 'economy'),
  path.join(ROOT, 'symphony'),
].filter(p => fs.existsSync(p));

const watcher = chokidar.watch(watchPaths, {
  persistent: true,
  ignoreInitial: true,
  awaitWriteFinish: { stabilityThreshold: 500 },
});

watcher.on('change', (filePath) => {
  const relative = path.relative(ROOT, filePath);
  console.log(`[watch] ${relative} changed`);
  broadcast({ type: 'full-state', data: getFullState() });
});

watcher.on('add', (filePath) => {
  const relative = path.relative(ROOT, filePath);
  console.log(`[watch] ${relative} added`);
  broadcast({ type: 'full-state', data: getFullState() });
});

// ---- Start ----

server.listen(PORT, () => {
  console.log(`\n  Zero Human Corp — Mission Control`);
  console.log(`  Dashboard: http://localhost:${PORT}`);
  console.log(`  API:       http://localhost:${PORT}/api/state`);
  console.log(`  WebSocket: ws://localhost:${PORT}\n`);
  console.log(`  Watching: ${watchPaths.join(', ')}\n`);
});
