const axios = require('axios');
const { Client } = require('pg');

// Configuration
const APP_URL = process.env.APP_URL || 'http://app:3000';
const DB_CONFIG = {
  host: process.env.DB_HOST || 'postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'testdb',
  user: process.env.DB_USER || 'testuser',
  password: process.env.DB_PASSWORD || 'testpass',
};

// Helper function to wait for services
const waitForService = async (url, maxAttempts = 30, delay = 2000) => {
  for (let i = 0; i < maxAttempts; i++) {
    try {
      await axios.get(url);
      console.log(`Service at ${url} is ready`);
      return true;
    } catch (error) {
      console.log(`Attempt ${i + 1}: Service not ready, waiting...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  throw new Error(`Service at ${url} did not become ready after ${maxAttempts} attempts`);
};

// Setup database
const setupDatabase = async () => {
  const client = new Client(DB_CONFIG);
  await client.connect();
  
  // Create users table if it doesn't exist
  await client.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      email VARCHAR(100) UNIQUE NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
  
  // Clear existing test data
  await client.query('DELETE FROM users WHERE email LIKE %test%');
  
  await client.end();
};

describe('Integration Tests', () => {
  beforeAll(async () => {
    console.log('Setting up integration tests...');
    
    // Wait for application to be ready
    await waitForService(`${APP_URL}/health`);
    
    // Setup database
    await setupDatabase();
    
    console.log('Integration test setup complete');
  });

  describe('Health Checks', () => {
    test('Application health endpoint should return healthy status', async () => {
      const response = await axios.get(`${APP_URL}/health`);
      
      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('status', 'healthy');
      expect(response.data).toHaveProperty('timestamp');
    });

    test('Database connection should be working', async () => {
      const response = await axios.get(`${APP_URL}/db-status`);
      
      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('status', 'connected');
      expect(response.data).toHaveProperty('timestamp');
    });
  });

  describe('User Management', () => {
    test('Should retrieve empty users list initially', async () => {
      const response = await axios.get(`${APP_URL}/users`);
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.data)).toBe(true);
    });

    test('Should create a new user successfully', async () => {
      const newUser = {
        name: 'Test User',
        email: 'test@example.com'
      };

      const response = await axios.post(`${APP_URL}/users`, newUser);
      
      expect(response.status).toBe(201);
      expect(response.data).toHaveProperty('id');
      expect(response.data).toHaveProperty('name', newUser.name);
      expect(response.data).toHaveProperty('email', newUser.email);
      expect(response.data).toHaveProperty('created_at');
    });

    test('Should retrieve the created user in users list', async () => {
      const response = await axios.get(`${APP_URL}/users`);
      
      expect(response.status).toBe(200);
      expect(Array.isArray(response.data)).toBe(true);
      expect(response.data.length).toBeGreaterThan(0);
      
      const testUser = response.data.find(user => user.email === 'test@example.com');
      expect(testUser).toBeDefined();
      expect(testUser.name).toBe('Test User');
    });

    test('Should handle duplicate email creation gracefully', async () => {
      const duplicateUser = {
        name: 'Another Test User',
        email: 'test@example.com'
      };

      try {
        await axios.post(`${APP_URL}/users`, duplicateUser);
        fail('Should have thrown an error for duplicate email');
      } catch (error) {
        expect(error.response.status).toBe(500);
        expect(error.response.data).toHaveProperty('status', 'error');
      }
    });
  });

  describe('Database Integration', () => {
    test('Database should persist data across requests', async () => {
      // Create a user
      const newUser = {
        name: 'Persistence Test User',
        email: 'persistence@test.com'
      };

      await axios.post(`${APP_URL}/users`, newUser);

      // Verify it exists
      const response = await axios.get(`${APP_URL}/users`);
      const persistedUser = response.data.find(user => user.email === 'persistence@test.com');
      
      expect(persistedUser).toBeDefined();
      expect(persistedUser.name).toBe('Persistence Test User');
    });

    test('Database connection should handle multiple concurrent requests', async () => {
      const promises = [];
      
      for (let i = 0; i < 5; i++) {
        promises.push(axios.get(`${APP_URL}/db-status`));
      }

      const responses = await Promise.all(promises);
      
      responses.forEach(response => {
        expect(response.status).toBe(200);
        expect(response.data.status).toBe('connected');
      });
    });
  });
});