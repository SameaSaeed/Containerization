#!/bin/bash

set -e

# Configuration
CURRENT_ENV_FILE=".current-env"
DEFAULT_ENV="blue"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

get_current_env() {
    if [ -f "$CURRENT_ENV_FILE" ]; then
        cat $CURRENT_ENV_FILE
    else
        echo $DEFAULT_ENV
    fi
}

get_target_env() {
    local current=$(get_current_env)
    if [ "$current" = "blue" ]; then
        echo "green"
    else
        echo "blue"
    fi
}

health_check() {
    local env=$1
    local port
    
    if [ "$env" = "blue" ]; then
        port=3001
    else
        port=3002
    fi
    
    log_info "Performing health check for $env environment..."
    
    for i in {1..30}; do
        if curl -f -s http://localhost:$port/health > /dev/null 2>&1; then
            log_info "$env environment is healthy"
            return 0
        fi
        log_warn "Health check attempt $i/30 failed, retrying..."
        sleep 2
    done
    
    log_error "$env environment failed health check"
    return 1
}

deploy_environment() {
    local env=$1
    
    log_info "Deploying $env environment..."
    
    # Build and deploy
    docker-compose -f docker-compose.$env.yml up -d --build
    
    # Wait for deployment
    sleep 10
    
    # Health check
    if health_check $env; then
        log_info "$env environment deployed successfully"
        return 0
    else
        log_error "$env environment deployment failed"
        return 1
    fi
}

switch_traffic() {
    local target_env=$1
    
    log_info "Switching traffic to $target_env environment..."
    
    # Update nginx configuration
    cp nginx/conf/nginx-$target_env.conf nginx/conf/nginx.conf
    
    # Reload nginx
    docker exec nginx-lb nginx -s reload
    
    # Update current environment file
    echo $target_env > $CURRENT_ENV_FILE
    
    log_info "Traffic switched to $target_env environment"
}

rollback() {
    local current_env=$(get_current_env)
    local rollback_env
    
    if [ "$current_env" = "blue" ]; then
        rollback_env="green"
    else
        rollback_env="blue"
    fi
    
    log_warn "Initiating rollback to $rollback_env environment..."
    
    if health_check $rollback_env; then
        switch_traffic $rollback_env
        log_info "Rollback completed successfully"
    else
        log_error "Rollback failed - $rollback_env environment is also unhealthy"
        exit 1
    fi
}

# Main deployment pipeline
main() {
    local action=${1:-deploy}
    
    log_info "=== Blue-Green CI/CD Pipeline ==="
    log_info "Action: $action"
    log_info "Current Environment: $(get_current_env)"
    log_info "Target Environment: $(get_target_env)"
    log_info "================================="
    
    case $action in
        "deploy")
            local current_env=$(get_current_env)
            local target_env=$(get_target_env)
            
            # Deploy to target environment
            if deploy_environment $target_env; then
                # Switch traffic
                switch_traffic $target_env
                
                # Verify deployment
                sleep 5
                if health_check $target_env; then
                    log_info "Deployment completed successfully"
                    
                    # Optional: Stop old environment after successful deployment
                    log_info "Stopping old $current_env environment..."
                    docker-compose -f docker-compose.$current_env.yml down
                else
                    log_error "Post-deployment health check failed"
                    rollback
                fi
            else
                log_error "Deployment failed"
                exit 1
            fi
            ;;
        "rollback")
            rollback
            ;;
        "status")
            log_info "Current Environment: $(get_current_env)"
            ./scripts/health-monitor.sh
            ;;
        "canary")
            local percentage=${2:-10}
            local target_env=$(get_target_env)
            
            if deploy_environment $target_env; then
                log_info "Starting canary deployment with $percentage% traffic"
                ./scripts/canary-deploy.sh $target_env $percentage
            fi
            ;;
        *)
            echo "Usage: $0 {deploy|rollback|status|canary [percentage]}"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"