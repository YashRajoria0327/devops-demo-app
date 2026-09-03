#!/bin/bash

set -e

IMAGE="yashrajoria0327/devops-demo-app:latest"
CONTAINER="devops-demo-app"

echo "Pulling latest image..."
docker pull "$IMAGE"

echo "Stopping old container..."
docker stop "$CONTAINER" 2>/dev/null || true

echo "Removing old container..."
docker rm "$CONTAINER" 2>/dev/null || true

echo "Starting new container..."
docker run -d \
  --name "$CONTAINER" \
  --restart unless-stopped \
  -p 8080:80 \
  "$IMAGE"

echo "Deployment completed."

echo "Testing application..."
sleep 2
curl -f http://localhost:8080
