# k8-optimizer-chatbot

# FastAPI Kubernetes Integration

This project demonstrates how to integrate a FastAPI application with a Kubernetes cluster running on Minikube. The FastAPI app queries Kubernetes resources (e.g., pods) using the Kubernetes Python client. The setup involves loading the kubeconfig file from the host into the Docker container running FastAPI and securely handling Kubernetes ServiceAccount tokens.

---

## Features

- Query Kubernetes resources like pods, nodes, and namespaces from a FastAPI app.
- Securely handle Kubernetes authentication using ServiceAccount tokens.
- Integration with Minikube for local Kubernetes development.
- Simplified deployment using Docker Compose.
- For now only two test features are there, either enquiring the resource usage or analyzing the resource usage to provide suggestions

---

## Prerequisites

1. **Minikube** installed and running running in WSL or MAC host
2. **Docker** installed and configured to run in your environment. (if running minikube in WSL, use WSL integrated with Docker desktop)
3. **kubectl** installed and configured to interact with your Minikube cluster.

---

## Setup Instructions

### 1. Start Minikube

Start Minikube and ensure the API server is accessible:

```bash
minikube start
```

Get the Minikube IP:
```bash
minikube ip
```

### 2. Automate Kubernetes Resource Creation

#### Script for Automation

To simplify the setup process, create a shell script (`setup-k8s.sh`) to automate the deployment of roles, bindings, and test clusters:

**`setup-k8s.sh`**:
```bash
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
```

Make the script executable:
```bash
chmod +x setup-k8s.sh
```

Run the script from the app/testbed-k8-deployment :
```bash
./setup-k8-env.sh
```

---

### 3. Configure and analyze the Project

#### or can go to step 4

#### Docker Compose

**`docker-compose.yml`**:
```yaml
services:
  chatbot:
    build: .
    ports:
      - "8201:8201"
    volumes:
      - ${HOME}/.kube/config:/root/.kube/config:ro
      - ${HOME}/.minikube:/root/.minikube:ro
    environment:
      - HOST_HOME=${HOME}
      - KUBERNETES_HOST=https://192.168.49.2:8443
      - K8S_TOKEN=${K8S_TOKEN}
```

Ensure the kubeconfig and Minikube certificates are mounted correctly.

#### Python Code

Ensure your FastAPI app uses the token:

```python
from kubernetes import client, config
import os

# Load kubeconfig
config.load_kube_config(config_file="/root/.kube/config")

# Retrieve token from environment variable
token = os.getenv("K8S_TOKEN")
if not token:
    raise ValueError("K8S_TOKEN environment variable is not set")

# Configure Kubernetes API client
configuration = client.Configuration()
configuration.host = os.getenv("KUBERNETES_HOST")
configuration.verify_ssl = False
configuration.api_key = {"authorization": f"Bearer {token}"}
client.Configuration.set_default(configuration)

v1 = client.CoreV1Api()

@app.get("/pods")
def list_pods():
    pods = v1.list_pod_for_all_namespaces()
    return [pod.metadata.name for pod in pods.items]
```

### 4. Start the Application

Run the following command to start the application:

```bash
bash start.sh
```

To stop run the command sudo docker-compose down

**`start.sh`**:
```bash
#!/bin/bash
MINIKUBE_IP=$(minikube ip)
export K8S_TOKEN=<your-token>
MINIKUBE_IP=$MINIKUBE_IP docker-compose up --build
```

---

## Testing the Setup

1. **Test Kubernetes API with `curl`:**
   ```bash
   curl -k -H "Authorization: Bearer $K8S_TOKEN" https://192.168.49.2:8443/api/v1/namespaces/default/pods
   ```

2. **Access FastAPI Endpoints:**
   Open the FastAPI Swagger UI at:
   ```
   http://localhost:8201/docs
   ```

---

## Troubleshooting

1. **Token Issues**:
   Ensure the `K8S_TOKEN` is valid and the ServiceAccount has the correct permissions.

2. **Certificate Errors**:
   Verify the Minikube certificates are mounted properly in the container.

3. **Connectivity Issues**:
   Check that the Minikube API server is accessible from the Docker container.

---

## Future Enhancements

- Deploy the FastAPI app inside Kubernetes using a Deployment and Service.
- Integrate Prometheus and Grafana for monitoring.
- Use Kubernetes Secrets to manage sensitive tokens securely.
- Use scapy NLP to assess questions
- Use AI models to perform analysis


