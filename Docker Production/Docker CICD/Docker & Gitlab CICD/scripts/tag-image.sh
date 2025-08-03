#!/bin/bash

# Advanced Docker image tagging script
set -e

# Variables
IMAGE_NAME=${1:-$CI_REGISTRY_IMAGE}
COMMIT_SHA=${2:-$CI_COMMIT_SHORT_SHA}
BRANCH_NAME=${3:-$CI_COMMIT_REF_NAME}
BUILD_NUMBER=${4:-$CI_PIPELINE_ID}

# Function to create semantic version tag
create_semantic_tag() {
    local version_file="VERSION"
    if [ -f "$version_file" ]; then
        VERSION=$(cat $version_file)
    else
        VERSION="1.0.0"
    fi
    
    # Increment patch version for main branch
    if [ "$BRANCH_NAME" = "main" ]; then
        MAJOR=$(echo $VERSION | cut -d. -f1)
        MINOR=$(echo $VERSION | cut -d. -f2)
        PATCH=$(echo $VERSION | cut -d. -f3)
        PATCH=$((PATCH + 1))
        NEW_VERSION="$MAJOR.$MINOR.$PATCH"
        echo $NEW_VERSION > $version_file
        echo $NEW_VERSION
    else
        echo "$VERSION-$BRANCH_NAME"
    fi
}

# Create tags
SEMANTIC_TAG=$(create_semantic_tag)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "Creating multiple tags for image: $IMAGE_NAME"

# Tag with commit SHA
docker tag $IMAGE_NAME:latest $IMAGE_NAME:$COMMIT_SHA
echo "Tagged with commit SHA: $COMMIT_SHA"

# Tag with semantic version
docker tag $IMAGE_NAME:latest $IMAGE_NAME:$SEMANTIC_TAG
echo "Tagged with semantic version: $SEMANTIC_TAG"

# Tag with branch name
docker tag $IMAGE_NAME:latest $IMAGE_NAME:$BRANCH_NAME
echo "Tagged with branch name: $BRANCH_NAME"

# Tag with timestamp
docker tag $IMAGE_NAME:latest $IMAGE_NAME:$TIMESTAMP
echo "Tagged with timestamp: $TIMESTAMP"

# Tag with build number
docker tag $IMAGE_NAME:latest $IMAGE_NAME:build-$BUILD_NUMBER
echo "Tagged with build number: build-$BUILD_NUMBER"

# Push all tags
echo "Pushing all tags..."
docker push $IMAGE_NAME:$COMMIT_SHA
docker push $IMAGE_NAME:$SEMANTIC_TAG
docker push $IMAGE_NAME:$BRANCH_NAME
docker push $IMAGE_NAME:$TIMESTAMP
docker push $IMAGE_NAME:build-$BUILD_NUMBER

echo "All tags pushed successfully!"