# Use Node.js 18 Alpine image as base
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm ci --only=development

# Copy application code
COPY . .

# Expose port 3000
EXPOSE 3000

# Default command to run tests
CMD ["npm", "test"]