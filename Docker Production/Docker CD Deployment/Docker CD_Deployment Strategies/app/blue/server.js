const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({
    version: 'blue',
    environment: 'BLUE Environment',
    timestamp: new Date().toISOString(),
    message: 'Welcome to Blue Environment - Version 1.0',
    color: '#0066CC'
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    environment: 'blue',
    uptime: process.uptime()
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Blue app listening at http://0.0.0.0:${port}`);
});