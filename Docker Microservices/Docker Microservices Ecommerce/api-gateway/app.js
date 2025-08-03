const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const rateLimit = require('express-rate-limit');
const app = express();
const PORT = process.env.PORT || 3000;

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: {
        error: 'Too many requests from this IP, please try again later.'
    }
});

// Apply rate limiting to all requests
app.use(limiter);

// Middleware for logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - IP: ${req.ip}`);
    next();
});

// Health check for API Gateway
app.get('/health', (req, res) => {
    res.json({
        service: 'api-gateway',
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// API Gateway info
app.get('/', (req, res) => {
    res.json({
        message: 'Microservices API Gateway',
        version: '1.0.0',
        services: {
            users: '/api/users',
            products: '/api/products',
            orders: '/api/orders'
        },
        documentation: {
            health: '/health',
            users: '/api/users - User management service',
            products: '/api/products - Product catalog service',
            orders: '/api/orders - Order processing service'
        }
    });
});

// Service URLs
const services = {
    user: process.env.USER_SERVICE_URL || 'http://user-service:3001',
    product: process.env.PRODUCT_SERVICE_URL || 'http://product-service:3002',
    order: process.env.ORDER_SERVICE_URL || 'http://order-service:3003'
};

// Proxy configuration options
const proxyOptions = {
    changeOrigin: true,
    timeout: 10000,
    proxyTimeout: 10000,
    onError: (err, req, res) => {
        console.error('Proxy error:', err.message);
        res.status(503).json({
            error: 'Service temporarily unavailable',
            message: 'The requested service is currently unavailable. Please try again later.',
            timestamp: new Date().toISOString()
        });
    },
    onProxyReq: (proxyReq, req, res) => {
        console.log(`Proxying ${req.method} ${req.path} to ${proxyReq.path}`);
    }
};

// User Service Proxy
app.use('/api/users', createProxyMiddleware({
    target: services.user,
    pathRewrite: {
        '^/api/users': '/users'
    },
    ...proxyOptions
}));

// Product Service Proxy
app.use('/api/products', createProxyMiddleware({
    target: services.product,
    pathRewrite: {
        '^/api/products': '/products'
    },
    ...proxyOptions
}));

// Order Service Proxy
app.use('/api/orders', createProxyMiddleware({
    target: services.order,
    pathRewrite