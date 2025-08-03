#!/bin/bash

# Script to validate required secrets are available
set -e

echo "🔍 Validating required secrets and environment variables..."

# Function to check if variable is set and not empty
check_var() {
    local var_name=$1
    local var_value=${!var_name}

    if [ -z "$var_value" ]; then
        echo "❌ ERROR: $var_name is not set or empty."
        exit 1
    else
        echo "✅ $var_name is set."
    fi
}

# List of required environment variables
required_vars=(
    MONGO_USERNAME
    MONGO_PASSWORD
)

# Loop through and check each variable
for var in "${required_vars[@]}"; do
    check_var "$var"
done

echo "✅ All required secrets and environment variables are set."
