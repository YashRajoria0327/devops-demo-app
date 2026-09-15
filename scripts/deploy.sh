#!/bin/bash

set -e

ENV_FILE="/home/devops/.config/devops-demo-app/.env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: Environment file not found: $ENV_FILE"
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 <image-tag>"
    exit 1
fi

export IMAGE_TAG="$1"

set -a
source "$ENV_FILE"
set +a

echo "Deploying image tag: $IMAGE_TAG"

echo "Pulling application images..."
docker compose --env-file "$ENV_FILE" pull frontend backend

echo "Starting application stack..."
docker compose --env-file "$ENV_FILE" up -d

echo "Running database migrations..."

chmod +x "$PROJECT_DIR/scripts/migrate.sh"
"$PROJECT_DIR/scripts/migrate.sh"

echo "Database migrations completed."

echo "Deployment completed."

echo "Checking service status..."
docker compose --env-file "$ENV_FILE" ps

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
