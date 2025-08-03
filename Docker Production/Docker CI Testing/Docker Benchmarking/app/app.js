const express = require('express');
const app = express();
const port = 3000;

// Simulate different response times
const simulateDelay = (min, max) => {
    return Math.floor(Math.random() * (max - min + 1)) + min;
};

// Root endpoint
app.get('/', (req, res) => {
    setTimeout(() => {
        res.json({
            message: 'Hello from Docker Performance Lab!',
            timestamp: new Date().toISOString(),
            server: 'node-app'
        });
    }, simulateDelay(10, 50));
});

// CPU intensive endpoint
app.get('/cpu-intensive', (req, res) => {
    const start = Date.now();
    let result = 0;
    
    // Simulate CPU work
    for (let i = 0; i < 1000000; i++) {
        result += Math.sqrt(i);
    }
    
    setTimeout(() => {
        res.json({
            message: 'CPU intensive task completed',
            duration: Date.now() - start,
            result: result,
            timestamp: new Date().toISOString()
        });
    }, simulateDelay(100, 200));
});

// Memory endpoint
app.get('/memory', (req, res) => {
    const memoryUsage = process.memoryUsage();
    res.json({
        message: 'Memory usage information',
        memory: memoryUsage,
        timestamp: new Date().toISOString()
    });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Test app listening at http://0.0.0.0:${port}`);
});