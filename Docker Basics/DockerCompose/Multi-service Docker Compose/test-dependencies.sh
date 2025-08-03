#!/bin/bash

# test-dependencies.sh - Comprehensive dependency testing script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    
    log "Waiting for $service_name to be ready..."
    
    for i in $(seq 1 $max_attempts); do
        if curl -f "$url" >/dev/null 2>&1; then
            log "$service_name is ready!"
            return 0
        fi
        sleep 2
    done
    
    error "$service_name failed to become ready"
    return 1
}

# Function to test API endpoints
test_api_endpoints() {
    log "Testing API endpoints..."
    
    # Test root endpoint
    info "Testing root endpoint..."
    curl -s http://localhost/
    echo
    
    # Test health endpoint
    info "Testing health endpoint..."
    curl -s http://localhost/health | jq .
    echo
    
    # Test users endpoint
    info "Testing users endpoint..."
    curl -s http://localhost/api/users | jq .
    echo
    
    # Test posts endpoint
    info "Testing posts endpoint..."
    curl -s http://localhost/api/posts | jq .
    echo
    
    # Test creating a new user
    info "Testing user creation..."
    curl -s -X POST http://localhost/api/users \
        -H "Content-Type: application/json" \
        -d '{"username":"testuser","email":"test@example.com"}' | jq .
    echo
}

# Function to simulate database failure
test_database_failure() {
    log "Testing database failure scenario..."
    
    # Stop database
    info "Stopping PostgreSQL container..."
    docker-compose stop postgres
    
    # Wait a moment
    sleep 5
    
    # Test API response during database failure
    info "Testing API during database failure..."
    curl -s http://localhost/health | jq .
    echo
    
    # Restart database
    info "Restarting PostgreSQL container..."
    docker-compose start postgres
    
    # Wait for database to be ready
    wait_for_service "Database" "http://localhost/health"
    
    # Test API after database recovery
    info "Testing API after database recovery..."
    curl -s http://localhost/api/users | jq .
    echo
}

# Function to simulate Redis failure
test_redis_failure() {
    log "Testing Redis failure scenario..."
    
    # Stop Redis
    info "Stopping Redis container..."
    docker-compose stop redis
    
    # Wait a moment
    sleep 5
    
    # Test API response during Redis failure
    info "Testing API during Redis failure..."
    curl -s http://localhost/api/users
    echo
    
    # Restart Redis
    info "Restarting Redis container..."
    docker-compose start redis
    
    # Wait for Redis to be ready
    wait_for_service "Redis" "http://localhost/health"
    
    # Test API after Redis recovery
    info "Testing API after Redis recovery..."
    curl -s http://localhost/api/users | jq .
    echo
}

# Function to simulate webapp failure
test_webapp_failure() {
    log "Testing webapp failure scenario..."
    
    # Stop webapp
    info "Stopping webapp container..."
    docker-compose stop webapp
    
    # Wait a moment
    sleep 5
    
    # Test Nginx response during webapp failure
    info "Testing Nginx during webapp failure..."
    curl -s -w "%{http_code}" http://localhost/ || true
    echo
    
    # Restart webapp
    info "Restarting webapp container..."
    docker-compose start webapp
    
    # Wait for webapp to be ready
    wait_for_service "Web Application" "http://localhost/health"
    
    # Test API after webapp recovery
    info "Testing API after webapp recovery..."
    curl -s http://localhost/ | jq .
    echo
}

# Function to test complete restart
test_complete_restart() {
    log "Testing complete application restart..."
    
    # Stop all services
    info "Stopping all services..."
    docker-compose down
    
    # Wait a moment
    sleep 5
    
    # Start all services
    info "Starting all services..."
    docker-compose up -d
    
    # Wait for all services to be ready
    wait_for_service "Application" "http://localhost/health"
    
    # Test all endpoints
    test_api_endpoints
}

# Function to check service dependencies
check_service_dependencies() {
    log "Checking service dependencies..."
    
    # Check container status
    info "Container status:"
    docker-compose ps
    echo
    
    # Check service logs
    info "Recent logs from webapp:"
    docker-compose logs --tail=10 webapp
    echo
    
    # Check health status
    info "Health check status:"
    curl -s http://localhost/health | jq .
    echo
}

# Main test execution
main() {
    log "Starting comprehensive dependency testing..."
    
    # Ensure application is running
    if ! curl -f http://localhost/health >/dev/null 2>&1; then
        warn "Application not running, starting it..."
        docker-compose up -d
        wait_for_service "Application" "http://localhost/health"
    fi
    
    # Run all tests
    check_service_dependencies
    test_api_endpoints
    test_database_failure
    test_redis_failure
    test_webapp_failure
    test_complete_restart
    
    log "All dependency tests completed successfully!"
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    warn "jq not found, installing..."
    sudo apt-get update && sudo apt-get install -y jq
fi

# Run main function
main "$@"