const express = require('express');
const app = express();
const PORT = process.env.PORT || 3002;

// Middleware
app.use(express.json());

// In-memory product storage
let products = [
    { id: 1, name: 'Laptop', price: 999.99, category: 'Electronics', stock: 50 },
    { id: 2, name: 'Smartphone', price: 699.99, category: 'Electronics', stock: 100 },
    { id: 3, name: 'Book', price: 19.99, category: 'Education', stock: 200 },
    { id: 4, name: 'Headphones', price: 149.99, category: 'Electronics', stock: 75 }
];

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        service: 'product-service', 
        status: 'healthy', 
        timestamp: new Date().toISOString() 
    });
});

// Get all products
app.get('/products', (req, res) => {
    const { category, minPrice, maxPrice } = req.query;
    let filteredProducts = [...products];
    
    if (category) {
        filteredProducts = filteredProducts.filter(p => 
            p.category.toLowerCase() === category.toLowerCase()
        );
    }
    
    if (minPrice) {
        filteredProducts = filteredProducts.filter(p => p.price >= parseFloat(minPrice));
    }
    
    if (maxPrice) {
        filteredProducts = filteredProducts.filter(p => p.price <= parseFloat(maxPrice));
    }
    
    res.json({
        success: true,
        data: filteredProducts,
        count: filteredProducts.length
    });
});

// Get product by ID
app.get('/products/:id', (req, res) => {
    const productId = parseInt(req.params.id);
    const product = products.find(p => p.id === productId);
    
    if (!product) {
        return res.status(404).json({
            success: false,
            message: 'Product not found'
        });
    }
    
    res.json({
        success: true,
        data: product
    });
});

// Create new product
app.post('/products', (req, res) => {
    const { name, price, category, stock } = req.body;
    
    if (!name || !price || !category) {
        return res.status(400).json({
            success: false,
            message: 'Name, price, and category are required'
        });
    }
    
    const newProduct = {
        id: products.length + 1,
        name,
        price: parseFloat(price),
        category,
        stock: parseInt(stock) || 0
    };
    
    products.push(newProduct);
    
    res.status(201).json({
        success: true,
        data: newProduct,
        message: 'Product created successfully'
    });
});

// Update product stock
app.patch('/products/:id/stock', (req, res) => {
    const productId = parseInt(req.params.id);
    const { quantity } = req.body;
    
    const product = products.find(p => p.id === productId);
    
    if (!product) {
        return res.status(404).json({
            success: false,
            message: 'Product not found'
        });
    }
    
    if (quantity !== undefined) {
        product.stock = parseInt(quantity);
    }
    
    res.json({
        success: true,
        data: product,
        message: 'Stock updated successfully'
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Product Service running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
});