#!/bin/bash

# Paths
ORIGINAL_CONFIG="${HOME}/.kube/config"
CUSTOM_CONFIG="${HOME}/.kube/docker-config"

# Step 1: Check if the original kubeconfig exists
if [ ! -f "$ORIGINAL_CONFIG" ]; then
    echo "Error: Original kubeconfig not found at $ORIGINAL_CONFIG"
    exit 1
fi

# Step 2: Create a custom kubeconfig by copying the original
cp "$ORIGINAL_CONFIG" "$CUSTOM_CONFIG"

# Step 3: Update the paths in the custom kubeconfig
sed -i.bak "s|${HOME}/.minikube|/root/.minikube|g" "$CUSTOM_CONFIG"

# Step 4: Ensure the custom config exists
if [ -f "$CUSTOM_CONFIG" ]; then
    echo "Custom kubeconfig created at $CUSTOM_CONFIG"
else
    echo "Error: Failed to create custom kubeconfig"
    exit 1
fi

# Step 5: Start Docker Compose
docker-compose up --build
