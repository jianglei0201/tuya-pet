const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 9528;
const DIR = __dirname;

const MIME = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.png': 'image/png',
  '.webp': 'image/webp',
  '.jpg': 'image/jpeg',
  '.json': 'application/json',
};

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const pathname = url.pathname;

  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
  res.setHeader('Access-Control-Allow-Origin', '*');

  // Weather API
  if (pathname === '/api/weather' && req.method === 'GET') {
    const https = require('https');
    try {
      const weather = await new Promise((resolve, reject) => {
        https.get('https://wttr.in/Hangzhou?format=%C+%t&lang=zh-cn', (r) => {
          let d = '';
          r.on('data', c => d += c);
          r.on('end', () => resolve(d.trim()));
        }).on('error', reject);
      });
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ weather }));
    } catch (e) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ weather: null }));
    }
    return;
  }

  // Static files
  let filePath = pathname === '/' ? '/pet-window.html' : pathname;
  const fullPath = path.join(DIR, filePath);

  if (!fs.existsSync(fullPath)) {
    res.writeHead(404);
    res.end('Not Found');
    return;
  }

  const ext = path.extname(fullPath);
  const contentType = MIME[ext] || 'application/octet-stream';
  const content = fs.readFileSync(fullPath);
  res.writeHead(200, { 'Content-Type': contentType });
  res.end(content);
});

server.listen(PORT, () => {
  console.log(`Pet server running on http://localhost:${PORT}`);
});
