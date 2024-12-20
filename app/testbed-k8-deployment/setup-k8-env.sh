#!/bin/bash

# Apply ServiceAccount, Role, and RoleBinding
kubectl apply -f k8chat-serviceaccount.yaml
kubectl apply -f read-role-k8chat.yaml
kubectl apply -f k8chat-cluster-rolebinding.yaml

# Check if the token secret already exists
SECRET_NAME=$(kubectl get secret -n default | grep default-token | awk '{print $1}')
if [ -z "$SECRET_NAME" ]; then
  # Create a token for the ServiceAccount
  kubectl apply -f k8chat-test-token.yaml
  while ! kubectl describe secret default-token | grep -E '^token' >/dev/null; do
    echo "waiting for token..." >&2
    sleep 1
  done
  SECRET_NAME=$(kubectl get secret -n default | grep default-token | awk '{print $1}')
fi

# Retrieve the ServiceAccount token
K8S_TOKEN=$(kubectl get secret $SECRET_NAME -n default -o jsonpath='{.data.token}' | base64 --decode)

if [ -z "$K8S_TOKEN" ]; then
  echo "Error: Failed to create or retrieve ServiceAccount token." >&2
  exit 1
fi

# Export the token to bashrc or profile
if ! grep -q "K8S_TOKEN" ~/.bashrc; then
  echo "export K8S_TOKEN=$TOKEN" >> ~/.bashrc
  echo "Token added to .bashrc. Run 'source ~/.bashrc' to refresh your environment."
  source ~/.bashrc
fi

# Deploy test Nginx and Redis clusters or you can modify this to put your custom deployments, pods, services
kubectl apply -f nginx-sample.yaml
kubectl apply -f redis-sample.yaml
