#!/bin/bash

# ============================================
# Production Deployment Setup Script
# ============================================

set -e  # Exit on error

echo "=========================================="
echo "  Production Deployment Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠ .env file not found!${NC}"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo -e "${GREEN}✓ Created .env file${NC}"
    echo ""
    echo -e "${YELLOW}Please edit .env file with your configuration before continuing!${NC}"
    echo ""
    echo "Required configurations:"
    echo "  - PROJECT_NAME"
    echo "  - DOMAIN"
    echo "  - BACKEND_REPO_URL"
    echo "  - FRONTEND_REPO_URL"
    echo "  - SECRET_KEY"
    echo "  - DB_PASSWORD"
    echo "  - LETSENCRYPT_EMAIL"
    echo ""
    read -p "Press Enter after you've configured .env file, or Ctrl+C to exit..."
fi

# Load environment variables
echo "Loading configuration..."
source .env

# Validate required variables
REQUIRED_VARS=("PROJECT_NAME" "DOMAIN" "BACKEND_REPO_URL" "FRONTEND_REPO_URL" "SECRET_KEY" "DB_PASSWORD" "LETSENCRYPT_EMAIL")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${RED}✗ Missing required variables in .env:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

echo -e "${GREEN}✓ Configuration validated${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is installed${NC}"

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose is installed${NC}"
echo ""

# Create Traefik network if it doesn't exist
echo "Checking Traefik network..."
if ! docker network inspect traefik-public &> /dev/null; then
    echo "Creating traefik-public network..."
    docker network create traefik-public
    echo -e "${GREEN}✓ Created traefik-public network${NC}"
else
    echo -e "${GREEN}✓ traefik-public network exists${NC}"
fi
echo ""

# Display configuration summary
echo "=========================================="
echo "  Deployment Configuration"
echo "=========================================="
echo "Project Name:    $PROJECT_NAME"
echo "Domain:          $DOMAIN"
echo "Backend Repo:    $BACKEND_REPO_URL"
echo "Backend Branch:  ${BACKEND_BRANCH:-main}"
echo "Frontend Repo:   $FRONTEND_REPO_URL"
echo "Frontend Branch: ${FRONTEND_BRANCH:-main}"
echo "Database:        $DB_NAME"
echo "Let's Encrypt:   $LETSENCRYPT_EMAIL"
echo ""
echo "The application will be available at:"
echo "  https://$DOMAIN"
echo ""

read -p "Continue with deployment? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo "=========================================="
echo "  Building Docker Images"
echo "=========================================="
docker-compose build

echo ""
echo "=========================================="
echo "  Starting Services"
echo "=========================================="
docker-compose up -d

echo ""
echo "=========================================="
echo "  Waiting for Services"
echo "=========================================="
echo "This may take a few minutes..."
sleep 10

# Check service status
echo ""
echo "Service Status:"
docker-compose ps

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Your application should be available at:"
echo -e "${GREEN}https://$DOMAIN${NC}"
echo ""
echo "Useful commands:"
echo "  View logs:           docker-compose logs -f"
echo "  Stop services:       docker-compose down"
echo "  Restart services:    docker-compose restart"
echo "  View status:         docker-compose ps"
echo ""
echo "Django Admin:"
echo "  URL: https://$DOMAIN/admin/"
if [ -n "$DJANGO_SUPERUSER_USERNAME" ]; then
    echo "  Username: $DJANGO_SUPERUSER_USERNAME"
fi
echo ""
echo "Note: SSL certificates may take a few minutes to be issued."
echo "Check Traefik logs if you encounter issues:"
echo "  docker-compose logs traefik"
echo ""
