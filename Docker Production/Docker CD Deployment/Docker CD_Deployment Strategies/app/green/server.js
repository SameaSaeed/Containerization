const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({
    version: 'green',
    environment: 'GREEN Environment',
    timestamp: new Date().toISOString(),
    message: 'Welcome to Green Environment - Version 2.0',
    color: '#00CC66'
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    environment: 'green',
    uptime: process.uptime()
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Green app listening at http://0.0.0.0:${port}`);
});