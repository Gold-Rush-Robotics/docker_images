#!/bin/bash

set -e

BUILDER_NAME="multi-platform-builder"

echo "======================================"
echo "49er Robotics Development Environment Image Build Script"
echo "======================================"
echo

# Check Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is not installed or not available in PATH."
    exit 1
fi

# Check whether the required Buildx builder exists
if docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
    echo "Buildx builder '$BUILDER_NAME' already exists."
else
    echo "Creating Buildx builder '$BUILDER_NAME'..."

    docker buildx create \
        --name "$BUILDER_NAME" \
        --driver docker-container
fi

# Select the builder
docker buildx use "$BUILDER_NAME"

# Bootstrap the builder and retrieve supported platforms
echo
echo "Initializing Buildx builder..."
BUILDER_INFO=$(docker buildx inspect --bootstrap)

echo "$BUILDER_INFO"

# Check for ARM64 support
if echo "$BUILDER_INFO" | grep -q "linux/arm64"; then
    echo
    echo "ARM64 support detected."
else
    echo
    echo "ARM64 support not detected."
    echo "Installing ARM64 emulation..."

    docker run --privileged --rm tonistiigi/binfmt --install arm64

    echo
    echo "Reinitializing Buildx builder..."
    BUILDER_INFO=$(docker buildx inspect --bootstrap)

    if ! echo "$BUILDER_INFO" | grep -q "linux/arm64"; then
        echo "Error: ARM64 support is still unavailable."
        echo "The multi-platform build cannot continue."
        exit 1
    fi

    echo "ARM64 support successfully enabled."
fi

# Build using Docker Bake
echo
echo "Building development environment..."
docker buildx bake dev_env "$@"

echo
echo "Build complete."