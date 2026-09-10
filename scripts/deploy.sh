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

set -a
source "$ENV_FILE"
set +a


echo "Deploying image tag: $IMAGE_TAG"

echo "Pulling application images..."
docker compose --env-file "$ENV_FILE" pull frontend backend

echo "Starting application stack..."
docker compose --env-file "$ENV_FILE" up -d
echo "Waiting for MySQL to become ready..."

for i in {1..30}; do
    if docker compose --env-file "$ENV_FILE" exec -T mysql \
        mysqladmin ping -h 127.0.0.1 --silent >/dev/null 2>&1; then
        echo "MySQL is ready."
        break
    fi

    if [ "$i" -eq 30 ]; then
        echo "ERROR: MySQL did not become ready in time."
        exit 1
    fi

    sleep 2
done



echo "Applying database schema..."

docker compose --env-file "$ENV_FILE" exec -T \
    -e MYSQL_PWD="$MYSQL_PASSWORD" \
    mysql \
    mysql -u"$MYSQL_USER" "$MYSQL_DATABASE" \
    < db/create_tables.sql

echo "Database schema applied."

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
