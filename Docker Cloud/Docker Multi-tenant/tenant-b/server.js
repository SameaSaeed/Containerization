const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.json({
        tenant: 'Tenant B - CRM System',
        status: 'running',
        port: port,
        container_id: process.env.HOSTNAME || 'unknown',
        timestamp: new Date().toISOString()
    });
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', tenant: 'B' });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Tenant B app listening on port ${port}`);
});