#!/bin/bash

# ============================================
# Django Production Entrypoint Script
# ============================================

set -e  # Exit on error

echo "=========================================="
echo "Starting Django Application"
echo "=========================================="

# Wait for database to be ready
echo "Waiting for database..."
max_attempts=30
attempt=0
until pg_isready -h "${DB_HOST}" -p "${DB_PORT:-5432}" -U "${DB_USER}" > /dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "✗ Database connection timeout after $max_attempts attempts"
        exit 1
    fi
    echo "Database is unavailable (attempt $attempt/$max_attempts) - sleeping"
    sleep 2
done
echo "✓ Database is ready"

# Run migrations
echo "Running migrations..."
python manage.py migrate --noinput
echo "✓ Migrations complete"

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput --clear
echo "✓ Static files collected"

# Create superuser if credentials are provided
if [ -n "$DJANGO_SUPERUSER_USERNAME" ] && [ -n "$DJANGO_SUPERUSER_PASSWORD" ]; then
    echo "Checking superuser..."
    python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
username = '$DJANGO_SUPERUSER_USERNAME'
email = '${DJANGO_SUPERUSER_EMAIL:-admin@example.com}'
password = '$DJANGO_SUPERUSER_PASSWORD'

if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username=username, email=email, password=password)
    print('✓ Superuser created successfully')
else:
    print('✓ Superuser already exists')
EOF
else
    echo "⚠ Skipping superuser creation (credentials not provided)"
fi

echo "=========================================="
echo "Starting Gunicorn Server"
echo "=========================================="

python manage.py rqworker high default low &
python manage.py rqworker high default low &
python manage.py rqworker high default low &
python manage.py rqworker high default low &
python manage.py rqworker high default low &

# Start Gunicorn
exec gunicorn \
    --bind 0.0.0.0:8000 \
    --workers ${GUNICORN_WORKERS:-4} \
    --timeout ${GUNICORN_TIMEOUT:-120} \
    --access-logfile - \
    --error-logfile - \
    --log-level info \
    core.wsgi:application
