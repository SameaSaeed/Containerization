const request = require('supertest');
const app = require('../src/app');

describe('Express App Tests', () => {
    
    describe('GET /', () => {
        it('should return hello message', async () => {
            const response = await request(app)
                .get('/')
                .expect(200);
            
            expect(response.body).toEqual({
                message: 'Hello, World!'
            });
        });
    });
    
    describe('GET /health', () => {
        it('should return health status', async () => {
            const response = await request(app)
                .get('/health')
                .expect(200);
            
            expect(response.body).toEqual({
                status: 'healthy'
            });
        });
    });
    
    describe('GET /multiply/:a/:b', () => {
        it('should multiply two positive numbers', async () => {
            const response = await request(app)
                .get('/multiply/4/5')
                .expect(200);
            
            expect(response.body).toEqual({
                result: 20
            });
        });
        
        it('should multiply negative numbers', async () => {
            const response = await request(app)
                .get('/multiply/-3/4')
                .expect(200);
            
            expect(response.body).toEqual({
                result: -12
            });
        });
        
        it('should handle zero multiplication', async () => {
            const response = await request(app)
                .get('/multiply/0/100')
                .expect(200);
            
            expect(response.body).toEqual({
                result: 0
            });
        });
        
        it('should return error for invalid numbers', async () => {
            const response = await request(app)
                .get('/multiply/abc/def')
                .expect(400);
            
            expect(response.body).toEqual({
                error: 'Invalid numbers provided'
            });
        });
    });
    
    describe('GET /nonexistent', () => {
        it('should return 404 for invalid routes', async () => {
            await request(app)
                .get('/nonexistent')
                .expect(404);
        });
    });
});