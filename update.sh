#!/bin/bash

# ============================================
# Production Update Script
# Pulls latest code and redeploys
# ============================================

set -e  # Exit on error

echo "=========================================="
echo "  Production Update"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}✗ .env file not found!${NC}"
    exit 1
fi

# Load environment variables
source .env

echo "Project: $PROJECT_NAME"
echo "Domain:  $DOMAIN"
echo ""

# Ask for confirmation
read -p "This will rebuild and restart all services. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled."
    exit 0
fi

echo ""
echo "=========================================="
echo "  Creating Backup"
echo "=========================================="

# Create backup directory if it doesn't exist
mkdir -p ./backups

# Backup database
echo "Backing up database..."
BACKUP_FILE="./backups/db-backup-$(date +%Y%m%d-%H%M%S).sql"
docker-compose exec -T db pg_dump -U ${DB_USER} ${DB_NAME} > "$BACKUP_FILE"
echo -e "${GREEN}✓ Database backed up to $BACKUP_FILE${NC}"

echo ""
echo "=========================================="
echo "  Rebuilding Images"
echo "=========================================="
docker-compose build --no-cache

echo ""
echo "=========================================="
echo "  Restarting Services"
echo "=========================================="
docker-compose up -d

echo ""
echo "=========================================="
echo "  Running Migrations"
echo "=========================================="
sleep 5  # Wait for database to be ready
docker-compose exec backend python manage.py migrate --noinput

echo ""
echo "=========================================="
echo "  Collecting Static Files"
echo "=========================================="
docker-compose exec backend python manage.py collectstatic --noinput --clear

echo ""
echo "=========================================="
echo "  Update Complete!"
echo "=========================================="
echo ""
echo "Service Status:"
docker-compose ps
echo ""
echo "View logs with: docker-compose logs -f"
echo ""
echo -e "${GREEN}✓ Update successful!${NC}"
echo "Your application is running at: https://$DOMAIN"
echo ""
