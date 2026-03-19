# ============================================
# Production Deployment Setup Script (PowerShell)
# ============================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Production Deployment Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if .env file exists
if (-not (Test-Path .env)) {
    Write-Host "⚠ .env file not found!" -ForegroundColor Yellow
    Write-Host "Creating .env from .env.example..."
    Copy-Item .env.example .env
    Write-Host "✓ Created .env file" -ForegroundColor Green
    Write-Host ""
    Write-Host "Please edit .env file with your configuration before continuing!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Required configurations:"
    Write-Host "  - PROJECT_NAME"
    Write-Host "  - DOMAIN"
    Write-Host "  - BACKEND_REPO_URL"
    Write-Host "  - FRONTEND_REPO_URL"
    Write-Host "  - SECRET_KEY"
    Write-Host "  - DB_PASSWORD"
    Write-Host "  - LETSENCRYPT_EMAIL"
    Write-Host ""
    Read-Host "Press Enter after you've configured .env file, or Ctrl+C to exit"
}

# Load environment variables
Write-Host "Loading configuration..."
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Variable -Name $name -Value $value -Scope Script
    }
}

# Validate required variables
$requiredVars = @(
    "PROJECT_NAME", "DOMAIN", "BACKEND_REPO_URL", "FRONTEND_REPO_URL",
    "SECRET_KEY", "DB_PASSWORD", "LETSENCRYPT_EMAIL"
)

$missingVars = @()
foreach ($var in $requiredVars) {
    if (-not (Get-Variable -Name $var -ErrorAction SilentlyContinue) -or 
        -not (Get-Variable -Name $var).Value) {
        $missingVars += $var
    }
}

if ($missingVars.Count -gt 0) {
    Write-Host "✗ Missing required variables in .env:" -ForegroundColor Red
    foreach ($var in $missingVars) {
        Write-Host "  - $var"
    }
    exit 1
}

Write-Host "✓ Configuration validated" -ForegroundColor Green
Write-Host ""

# Check if Docker is installed
try {
    docker --version | Out-Null
    Write-Host "✓ Docker is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not installed" -ForegroundColor Red
    exit 1
}

# Check if Docker Compose is installed
try {
    docker-compose --version | Out-Null
    Write-Host "✓ Docker Compose is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker Compose is not installed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Create Traefik network if it doesn't exist
Write-Host "Checking Traefik network..."
$networkExists = docker network ls --format "{{.Name}}" | Select-String -Pattern "^traefik-public$"
if (-not $networkExists) {
    Write-Host "Creating traefik-public network..."
    docker network create traefik-public
    Write-Host "✓ Created traefik-public network" -ForegroundColor Green
} else {
    Write-Host "✓ traefik-public network exists" -ForegroundColor Green
}
Write-Host ""

# Display configuration summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Deployment Configuration" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Project Name:    $PROJECT_NAME"
Write-Host "Domain:          $DOMAIN"
Write-Host "Backend Repo:    $BACKEND_REPO_URL"
Write-Host "Backend Branch:  $(if($BACKEND_BRANCH){$BACKEND_BRANCH}else{'main'})"
Write-Host "Frontend Repo:   $FRONTEND_REPO_URL"
Write-Host "Frontend Branch: $(if($FRONTEND_BRANCH){$FRONTEND_BRANCH}else{'main'})"
Write-Host "Database:        $DB_NAME"
Write-Host "Let's Encrypt:   $LETSENCRYPT_EMAIL"
Write-Host ""
Write-Host "The application will be available at:"
Write-Host "  https://$DOMAIN" -ForegroundColor Green
Write-Host ""

$response = Read-Host "Continue with deployment? (y/N)"
if ($response -ne 'y' -and $response -ne 'Y') {
    Write-Host "Deployment cancelled."
    exit 0
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Building Docker Images" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
docker-compose build

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Starting Services" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
docker-compose up -d

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Waiting for Services" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "This may take a few minutes..."
Start-Sleep -Seconds 10

# Check service status
Write-Host ""
Write-Host "Service Status:"
docker-compose ps

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your application should be available at:"
Write-Host "https://$DOMAIN" -ForegroundColor Green
Write-Host ""
Write-Host "Useful commands:"
Write-Host "  View logs:           docker-compose logs -f"
Write-Host "  Stop services:       docker-compose down"
Write-Host "  Restart services:    docker-compose restart"
Write-Host "  View status:         docker-compose ps"
Write-Host ""
Write-Host "Django Admin:"
Write-Host "  URL: https://$DOMAIN/admin/"
if ($DJANGO_SUPERUSER_USERNAME) {
    Write-Host "  Username: $DJANGO_SUPERUSER_USERNAME"
}
Write-Host ""
Write-Host "Note: SSL certificates may take a few minutes to be issued."
Write-Host "Check Traefik logs if you encounter issues:"
Write-Host "  docker-compose logs traefik"
Write-Host ""
