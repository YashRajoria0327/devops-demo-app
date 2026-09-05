#!/bin/bash

set -e
if [ -z "$1" ]; then
  echo "Usage: $0 <image-tag>"
  exit 1
fi

IMAGE="yashrajoria0327/devops-demo-app:${1}"
CONTAINER="devops-demo-app"

echo "Pulling image: $IMAGE"
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
