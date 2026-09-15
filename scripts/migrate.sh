#!/bin/bash

set -e

ENV_FILE="/home/devops/.config/devops-demo-app/.env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MIGRATIONS_DIR="$PROJECT_DIR/db/migrations"


if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: Environment file not found: $ENV_FILE"
    exit 1
fi

if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "ERROR: Migrations directory not found: $MIGRATIONS_DIR"
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

export IMAGE_TAG="${IMAGE_TAG:-latest}"


echo "Waiting for MySQL..."

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

echo "Ensuring migration tracking table exists..."

docker compose --env-file "$ENV_FILE" exec -T \
    -e MYSQL_PWD="$MYSQL_PASSWORD" \
    mysql \
    mysql -u"$MYSQL_USER" "$MYSQL_DATABASE" \
    < "$MIGRATIONS_DIR/000_create_migrations_table.sql"

docker compose --env-file "$ENV_FILE" exec -T \
    -e MYSQL_PWD="$MYSQL_PASSWORD" \
    mysql \
    mysql -u"$MYSQL_USER" "$MYSQL_DATABASE" \
    -e "INSERT IGNORE INTO schema_migrations (version) VALUES ('000');"



for migration in "$MIGRATIONS_DIR"/[0-9][0-9][0-9]_*.sql; do

    filename=$(basename "$migration")
    version="${filename%%_*}"

    if [ "$version" = "000" ]; then
        continue
    fi

    applied=$(docker compose --env-file "$ENV_FILE" exec -T \
        -e MYSQL_PWD="$MYSQL_PASSWORD" \
        mysql \
        mysql -N -B -u"$MYSQL_USER" "$MYSQL_DATABASE" \
        -e "SELECT COUNT(*) FROM schema_migrations WHERE version='$version';")

    if [ "$applied" -eq 1 ]; then
        echo "Skipping migration $filename — already applied."
        continue
    fi

    echo "Applying migration: $filename"

    docker compose --env-file "$ENV_FILE" exec -T \
        -e MYSQL_PWD="$MYSQL_PASSWORD" \
        mysql \
        mysql -u"$MYSQL_USER" "$MYSQL_DATABASE" \
        < "$migration"

    docker compose --env-file "$ENV_FILE" exec -T \
        -e MYSQL_PWD="$MYSQL_PASSWORD" \
        mysql \
        mysql -u"$MYSQL_USER" "$MYSQL_DATABASE" \
        -e "INSERT INTO schema_migrations (version) VALUES ('$version');"

    echo "Migration $filename applied successfully."

done

echo "Database migrations completed successfully."
