#!/bin/bash

# wait-for-services.sh - Advanced service dependency checker

set -e

# Configuration
MAX_ATTEMPTS=30
SLEEP_INTERVAL=2

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Function to check if a service is ready
check_service() {
    local service_name=$1
    local host=$2
    local port=$3
    local endpoint=${4:-""}
    
    log "Checking $service_name at $host:$port"
    
    for i in $(seq 1 $MAX_ATTEMPTS); do
        if nc -z "$host" "$port" 2>/dev/null; then
            if [ -n "$endpoint" ]; then
                # Additional HTTP health check
                if curl -f "http://$host:$port$endpoint" >/dev/null 2>&1; then
                    log "$service_name is ready (attempt $i/$MAX_ATTEMPTS)"
                    return 0
                else
                    warn "$service_name port is open but health check failed (attempt $i/$MAX_ATTEMPTS)"
                fi
            else
                log "$service_name is ready (attempt $i/$MAX_ATTEMPTS)"
                return 0
            fi
        else
            warn "$service_name is not ready (attempt $i/$MAX_ATTEMPTS)"
        fi
        
        if [ $i -lt $MAX_ATTEMPTS ]; then
            sleep $SLEEP_INTERVAL
        fi
    done
    
    error "$service_name failed to become ready after $MAX_ATTEMPTS attempts"
    return 1
}

# Function to check database readiness
check_database() {
    local host=$1
    local port=$2
    local user=$3
    local database=$4
    
    log "Checking database connectivity"
    
    for i in $(seq 1 $MAX_ATTEMPTS); do
        if PGPASSWORD="$DB_PASSWORD" psql -h "$host" -p "$port" -U "$user" -d "$database" -c "SELECT 1;" >/dev/null 2>&1; then
            log "Database is ready and accepting connections (attempt $i/$MAX_ATTEMPTS)"
            return 0
        else
            warn "Database is not ready (attempt $i/$MAX_ATTEMPTS)"
        fi
        
        if [ $i -lt $MAX_ATTEMPTS ]; then
            sleep $SLEEP_INTERVAL
        fi
    done
    
    error "Database failed to become ready after $MAX_ATTEMPTS attempts"
    return 1
}

# Function to check Redis readiness
check_redis() {
    local host=$1
    local port=$2
    
    log "Checking Redis connectivity"
    
    for i in $(seq 1 $MAX_ATTEMPTS); do
        if redis-cli -h "$host" -p "$port" ping | grep -q "PONG"; then
            log "Redis is ready (attempt $i/$MAX_ATTEMPTS)"
            return 0
        else
            warn "Redis is not ready (attempt $i/$MAX_ATTEMPTS)"
        fi
        
        if [ $i -lt $MAX_ATTEMPTS ]; then
            sleep $SLEEP_INTERVAL
        fi
    done
    
    error "Redis failed to become ready after $MAX_ATTEMPTS attempts"
    return 1
}

# Main execution
main() {
    log "Starting service dependency checks..."
    
    # Check all required services based on arguments
    case "$1" in
        "webapp")
            check_service "PostgreSQL" "postgres" "5432"
            check_database "postgres" "5432" "$DB_USER" "$DB_NAME"
            check_service "Redis" "redis" "6379"
            check_redis "redis" "6379"
            ;;
        "nginx")
            check_service "Web Application" "webapp" "3000" "/health"
            ;;
        *)
            error "Unknown service type: $1"
            echo "Usage: $0 {webapp|nginx}"
            exit 1
            ;;
    esac
    
    log "All dependency checks passed! Starting $1..."
    
    # Execute the original command
    shift
    exec "$@"
}

# Install required tools if not present
if ! command -v nc &> /dev/null; then
    log "Installing netcat..."
    apk add --no-cache netcat-openbsd
fi

if ! command -v curl &> /dev/null; then
    log "Installing curl..."
    apk add --no-cache curl
fi

# Run main function with all arguments
main "$@"