const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3001;
const SERVICE_NAME = process.env.SERVICE_NAME || 'backend-api';
const NODE_ENV = process.env.NODE_ENV || 'development';

// Enable CORS for all routes
app.use(cors());
app.use(express.json());

// Sample data
const users = [
  { id: 1, name: 'Alice Johnson', email: 'alice@example.com' },
  { id: 2, name: 'Bob Smith', email: 'bob@example.com' },
  { id: 3, name: 'Charlie Brown', email: 'charlie@example.com' }
];

// Routes
app.get('/health', (req, res) => {
  res.json({ 
    status: 'Backend API is running!', 
    service: SERVICE_NAME,
    environment: NODE_ENV,
    timestamp: new Date().toISOString(),
    port: PORT
  });
});

app.get('/api/users', (req, res) => {
  res.json({ 
    users: users,
    service: SERVICE_NAME,
    timestamp: new Date().toISOString()
  });
});

app.get('/api/users/:id', (req, res) => {
  const userId = parseInt(req.params.id);
  const user = users.find(u => u.id === userId);
  
  if (user) {
    res.json({ 
      user: user,
      service: SERVICE_NAME,
      timestamp: new Date().toISOString()
    });
  } else {
    res.status(404).json({ 
      error: 'User not found',
      service: SERVICE_NAME,
      timestamp: new Date().toISOString()
    });
  }
});

// Environment info endpoint
app.get('/api/env', (req, res) => {
  res.json({
    service: SERVICE_NAME,
    environment: NODE_ENV,
    port: PORT,
    frontend_url: process.env.FRONTEND_URL || 'not set',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`${SERVICE_NAME} running on port ${PORT}`);
  console.log(`Environment: ${NODE_ENV}`);
  console.log(`Frontend URL: ${process.env.FRONTEND_URL || 'not set'}`);
});