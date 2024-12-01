#!/bin/bash

# mkdir -p /root/.kube

echo "Checking for kubeconfig..."


if [ -f "/root/.kube/config" ]; then
    # Replace the home directory path with /root in the kubeconfig
    # sed "s|${HOST_HOME}|/root|g" /tmp/kubeconfig/config > /root/.kube/config
    
    # Ensure proper permissions
    chmod 600 /root/.kube/config
    
    echo "Successfully configured Kubernetes credentials"
else
    echo "Warning: No kubeconfig file found at /root/.kube"
fi

exec uvicorn app.main:app --host 0.0.0.0 --port 8201

