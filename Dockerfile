FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    gcc \
    g++ \
    curl \
    iproute2 \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# RUN rm -rf /root/.kube

COPY . .

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV HOST_HOME=${HOME}

ENV K8S_TOKEN=${K8S_TOKEN}

# RUN mkdir -p /root/.kube

ENTRYPOINT [ "docker-entrypoint.sh" ]
