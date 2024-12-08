#!/bin/bash

# Paths
ORIGINAL_CONFIG="${HOME}/.kube/config"
CUSTOM_CONFIG="${HOME}/.kube/docker-config"

# Step 1: Check if Minikube is running and get its IP
echo "Checking Minikube status..."
MINIKUBE_STATUS=$(minikube status --format '{{.Host}}')

if [ "$MINIKUBE_STATUS" != "Running" ]; then
    echo "Error: Minikube is not running. Please start Minikube first."
    exit 1
fi

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
if [ -z "$MINIKUBE_IP" ]; then
    echo "Error: Could not get Minikube IP"
    exit 1
fi
echo "Minikube is running at IP: $MINIKUBE_IP"

# Step 2: Check if the original kubeconfig exists
if [ ! -f "$ORIGINAL_CONFIG" ]; then
    echo "Error: Original kubeconfig not found at $ORIGINAL_CONFIG"
    exit 1
fi

# Step 3: Create a custom kubeconfig by copying the original
cp "$ORIGINAL_CONFIG" "$CUSTOM_CONFIG"

# Step 4: Update the paths in the custom kubeconfig
sed -i.bak "s|${HOME}/.minikube|/root/.minikube|g" "$CUSTOM_CONFIG"
sed -i.bak "s|server: https://127.0.0.1:[0-9]*|server: https://${MINIKUBE_IP}:51767|g" "$CUSTOM_CONFIG"

# Step 5: Ensure the custom config exists
if [ -f "$CUSTOM_CONFIG" ]; then
    echo "Custom kubeconfig created at $CUSTOM_CONFIG"
else
    echo "Error: Failed to create custom kubeconfig"
    exit 1
fi

# Step 6: Export the Minikube IP as an environment variable
export MINIKUBE_IP

# Step 7: Start Docker Compose
MINIKUBE_IP=$MINIKUBE_IP docker-compose up --build
