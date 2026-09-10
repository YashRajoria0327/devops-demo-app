#!/bin/bash

set -e

ENV_FILE="/home/devops/.config/devops-demo-app/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: Environment file not found: $ENV_FILE"
  exit 1
fi


if [ -z "$1" ]; then
  echo "Usage: $0 <image-tag>"
  exit 1
fi

export IMAGE_TAG="$1"

echo "Deploying image tag: $IMAGE_TAG"

echo "Pulling application images..."
docker compose --env-file "$ENV_FILE" pull frontend backend

echo "Starting application stack..."
docker compose --env-file "$ENV_FILE" up -d

echo "Deployment completed."

echo "Checking service status..."
docker compose ps

echo "Testing frontend..."
sleep 2
curl -f http://localhost:8080

echo
echo "Testing backend..."
curl -f http://localhost:5000/health

echo
echo "Testing database connection..."
curl -f http://localhost:5000/api/db-test

echo
echo "All deployment checks passed."
