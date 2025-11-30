#!/bin/bash
# Скрипт для автоматического применения миграций
# Используется в отдельном сервисе db-migrate

set -e

POSTGRES_USER="${POSTGRES_USER:-admin}"
POSTGRES_DB="${POSTGRES_DB:-video_platform}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-password123}"
POSTGRES_HOST="${POSTGRES_HOST:-postgres}"

export PGPASSWORD="$POSTGRES_PASSWORD"

echo "Waiting for PostgreSQL to be ready..."
until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" -h "$POSTGRES_HOST"; do
  echo "Waiting for PostgreSQL..."
  sleep 1
done

echo "PostgreSQL is ready. Applying migrations..."

# Применяем все миграции из папки migrations в порядке
MIGRATIONS_DIR="/migrations"
if [ -d "$MIGRATIONS_DIR" ]; then
  for migration in $(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | sort); do
    if [ -f "$migration" ]; then
      echo "Applying migration: $(basename $migration)"
      if psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -h "$POSTGRES_HOST" -f "$migration"; then
        echo "Migration $(basename $migration) applied successfully"
      else
        echo "ERROR: Migration $(basename $migration) failed!"
        exit 1
      fi
    fi
  done
fi

echo "Migrations completed successfully"

