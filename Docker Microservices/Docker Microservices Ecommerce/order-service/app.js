const express = require('express');
const axios = require('axios');
const app = express();
const PORT = process.env.PORT || 3003;

// Service URLs (will be resolved by Docker networking)
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://user-service:3001';
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://product-service:3002';

// Middleware
app.use(express.json());

// In-memory order storage
let orders = [
    {
        id: 1,
        userId: 1,
        products: [
            { productId: 1, quantity: 1, price: 999.99 }
        ],
        total: 999.99,
        status: 'completed',
        createdAt: new Date('2024-01-15').toISOString()
    }
];

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        service: 'order-service', 
        status: 'healthy', 
        timestamp: new Date().toISOString() 
    });
});

// Get all orders
app.get('/orders', (req, res) => {
    res.json({
        success: true,
        data: orders,
        count: orders.length
    });
});

// Get orders by user ID
app.get('/orders/user/:userId', (req, res) => {
    const userId = parseInt(req.params.userId);
    const userOrders = orders.filter(o => o.userId === userId);
    
    res.json({
        success: true,
        data: userOrders,
        count: userOrders.length
    });
});

// Get order by ID
app.get('/orders/:id', (req, res) => {
    const orderId = parseInt(req.params.id);
    const order = orders.find(o => o.id === orderId);
    
    if (!order) {
        return res.status(404).json({
            success: false,
            message: 'Order not found'
        });
    }
    
    res.json({
        success: true,
        data: order
    });
});

// Create new order
app.post('/orders', async (req, res) => {
    try {
        const { userId, products } = req.body;
        
        if (!userId || !products || !Array.isArray(products) || products.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'User ID and products array are required'
            });
        }
        
        // Verify user exists
        try {
            const userResponse = await axios.get(`${USER_SERVICE_URL}/users/${userId}`);
            if (!userResponse.data.success) {
                return res.status(404).json({
                    success: false,
                    message: 'User not found'
                });
            }
        } catch (error) {
            console.log('User service unavailable, proceeding without verification');
        }
        
        // Calculate total and verify products
        let total = 0;
        const orderProducts = [];
        
        for (const item of products) {
            try {
                const productResponse = await axios.get(`${PRODUCT_SERVICE_URL}/products/${item.productId}`);
                if (productResponse.data.success) {
                    const product = productResponse.data.data;
                    const itemTotal = product.price * item.quantity;
                    total += itemTotal;
                    
                    orderProducts.push({
                        productId: item.productId,
                        quantity: item.quantity,
                        price: product.price,
                        name: product.name
                    });
                }
            } catch (error) {
                console.log(`Product ${item.productId} service unavailable, using provided data`);
                orderProducts.push({
                    productId: item.productId,
                    quantity: item.quantity,
                    price: item.price || 0
                });
                total += (item.price || 0) * item.quantity;
            }
        }
        
        const newOrder = {
            id: orders.length + 1,
            userId,
            products: orderProducts,
            total: Math.round(total * 100) / 100, // Round to 2 decimal places
            status: 'pending',
            createdAt: new Date().toISOString()
        };
        
        orders.push(newOrder);
        
        res.status(201).json({
            success: true,
            data: newOrder,
            message: 'Order created successfully'
        });
        
    } catch (error) {
        console.error('Error creating order:', error.message);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

// Update order status
app.patch('/orders/:id/status', (req, res) => {
    const orderId = parseInt(req.params.id);
    const { status } = req.body;
    
    const order = orders.find(o => o.id === orderId);
    
    if (!order) {
        return res.status(404).json({
            success: false,
            message: 'Order not found'
        });
    }
    
    const validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status)) {
        return res.status(400).json({
            success: false,
            message: 'Invalid status. Valid statuses: ' + validStatuses.join(', ')
        });
    }
    
    order.status = status;
    order.updatedAt = new Date().toISOString();
    
    res.json({
        success: true,
        data: order,
        message: 'Order status updated successfully'
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Order Service running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
    console.log(`User Service URL: ${USER_SERVICE_URL}`);
    console.log(`Product Service URL: ${PRODUCT_SERVICE_URL}`);
});