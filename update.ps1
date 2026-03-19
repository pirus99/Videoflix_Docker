# ============================================
# Production Update Script (PowerShell)
# Pulls latest code and redeploys
# ============================================

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Production Update" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if .env file exists
if (-not (Test-Path .env)) {
    Write-Host "✗ .env file not found!" -ForegroundColor Red
    exit 1
}

# Load environment variables
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        Set-Variable -Name $name -Value $value -Scope Script
    }
}

Write-Host "Project: $PROJECT_NAME"
Write-Host "Domain:  $DOMAIN"
Write-Host ""

# Ask for confirmation
$response = Read-Host "This will rebuild and restart all services. Continue? (y/N)"
if ($response -ne 'y' -and $response -ne 'Y') {
    Write-Host "Update cancelled."
    exit 0
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Creating Backup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Create backup directory if it doesn't exist
if (-not (Test-Path ./backups)) {
    New-Item -ItemType Directory -Path ./backups | Out-Null
}

# Backup database
Write-Host "Backing up database..."
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFile = "./backups/db-backup-$timestamp.sql"
docker-compose exec -T db pg_dump -U $DB_USER $DB_NAME | Out-File -FilePath $backupFile -Encoding UTF8
Write-Host "✓ Database backed up to $backupFile" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Rebuilding Images" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
docker-compose build --no-cache

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Restarting Services" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
docker-compose up -d

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Running Migrations" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Start-Sleep -Seconds 5  # Wait for database to be ready
docker-compose exec backend python manage.py migrate --noinput

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Collecting Static Files" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
docker-compose exec backend python manage.py collectstatic --noinput --clear

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Update Complete!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Service Status:"
docker-compose ps
Write-Host ""
Write-Host "View logs with: docker-compose logs -f"
Write-Host ""
Write-Host "✓ Update successful!" -ForegroundColor Green
Write-Host "Your application is running at: https://$DOMAIN" -ForegroundColor Green
Write-Host ""
