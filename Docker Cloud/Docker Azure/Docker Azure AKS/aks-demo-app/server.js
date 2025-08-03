const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.send(\`
        <h1>Hello from AKS Demo App!</h1>
        <p>This application is running in Azure Kubernetes Service</p>
        <p>Hostname: \${require('os').hostname()}</p>
        <p>Timestamp: \${new Date().toISOString()}</p>
    \`);
});

app.get('/health', (req, res) => {
    res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
    console.log(\`Server running on port \${port}\`);
});