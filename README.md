# Production Deployment with Docker and Traefik

This is a generic production deployment setup for Django + JavaScript + PostgreSQL projects with Traefik as a reverse proxy and automatic SSL certificates via Let's Encrypt.

## Features

- 🚀 **Production-ready** Docker setup
- 🔒 **Automatic SSL** certificates with Let's Encrypt (configurable)
- 🔧 **Flexible SSL configuration** - enable/disable ACME certificate requests for different environments
- 🔄 **Reverse proxy** with Traefik
- 🐘 **PostgreSQL** database
- 🎬 **FFMPEG** support for media processing
- 📦 **Git-based deployment** - pull code directly from repositories
- 🔧 **Generic and reusable** - works with any similar stack
- 🏷️ **Project name isolation** - run multiple projects on the same server

## Prerequisites

- Docker and Docker Compose installed
- Domain name pointing to your server (or use IP address)
- Ports 80 and 443 available
- Git repositories for frontend and backend (publicly accessible)

## Quick Start

### 1. Create Traefik Network

Before deploying, create the external Traefik network:

```bash
docker network create traefik-public
```

### 2. Configure Environment Variables

Copy the example environment file and configure it:

```bash
cd production_Docker
cp .env.example .env
nano .env  # or use your preferred editor
```

**Required configurations:**

- `PROJECT_NAME` - Unique name for your project (no spaces, lowercase)
- `DOMAIN` - Your domain name or IP address
- `BACKEND_REPO_URL` - Git URL for backend repository
- `FRONTEND_REPO_URL` - Git URL for frontend repository
- `SECRET_KEY` - Django secret key
- `DB_PASSWORD` - Secure database password
- `LETSENCRYPT_EMAIL` - Your email for SSL certificates
- `LETSENCRYPT_CERTRESOLVER` - Set to `letsencrypt` to enable SSL, or leave empty to disable

> **Note**: For local development with localhost, set `LETSENCRYPT_CERTRESOLVER=` (empty) to disable automatic SSL certificate requests.

**Generate Django secret key:**

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### 3. Build and Deploy

Build the Docker images:

```bash
docker-compose build
```

Start the services:

```bash
docker-compose up -d
```

### 4. Verify Deployment

Check if all services are running:

```bash
docker-compose ps
```

View logs:

```bash
docker-compose logs -f
```

Check specific service logs:

```bash
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f traefik
```

## Configuration Guide

### Environment Variables

#### Project Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `PROJECT_NAME` | Unique project identifier | `videoflix` |
| `DOMAIN` | Domain or IP address | `example.com` |
| `TZ` | Timezone | `Europe/Berlin` |

#### Repository URLs

| Variable | Description |
|----------|-------------|
| `BACKEND_REPO_URL` | Backend Git repository URL |
| `BACKEND_BRANCH` | Backend branch to deploy (default: main) |
| `FRONTEND_REPO_URL` | Frontend Git repository URL |
| `FRONTEND_BRANCH` | Frontend branch to deploy (default: main) |

#### Database

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_NAME` | Database name | Project specific |
| `DB_USER` | Database user | Project specific |
| `DB_PASSWORD` | Database password | **REQUIRED** |
| `DB_HOST` | Database host | `db` |
| `DB_PORT` | Database port | `5432` |

#### Django Backend

| Variable | Description | Production Value |
|----------|-------------|------------------|
| `SECRET_KEY` | Django secret key | **REQUIRED** |
| `DEBUG` | Debug mode | `False` |
| `ALLOWED_HOSTS` | Allowed hostnames | Your domain(s) |
| `CSRF_TRUSTED_ORIGINS` | CSRF trusted origins | `https://yourdomain.com` |
| `CORS_ALLOWED_ORIGINS` | CORS allowed origins | `https://yourdomain.com` |

#### Email Configuration

Configure SMTP for email functionality (password resets, notifications):

```env
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
DEFAULT_FROM_EMAIL=noreply@example.com
```

#### SSL/TLS and Let's Encrypt

| Variable | Description | Default |
|----------|-------------|---------|
| `ENABLE_LETSENCRYPT` | Enable/disable automatic SSL certificates | `true` |
| `LETSENCRYPT_CERTRESOLVER` | Certificate resolver name (use `letsencrypt` to enable, empty to disable) | `letsencrypt` |
| `LETSENCRYPT_EMAIL` | Email for Let's Encrypt notifications | **REQUIRED** when enabled |
| `LETSENCRYPT_CA_SERVER` | CA server URL (use staging for testing, empty for production) | Empty (production) |

**Production setup** (automatic SSL certificates):
```env
ENABLE_LETSENCRYPT=true
LETSENCRYPT_CERTRESOLVER=letsencrypt
LETSENCRYPT_EMAIL=admin@example.com
LETSENCRYPT_CA_SERVER=
```

**Local development** (no SSL certificate requests):
```env
ENABLE_LETSENCRYPT=false
LETSENCRYPT_CERTRESOLVER=
LETSENCRYPT_EMAIL=admin@example.com
LETSENCRYPT_CA_SERVER=
```

**Testing with Let's Encrypt staging** (avoid rate limits):
```env
ENABLE_LETSENCRYPT=true
LETSENCRYPT_CERTRESOLVER=letsencrypt
LETSENCRYPT_EMAIL=admin@example.com
LETSENCRYPT_CA_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory
```

> **Note**: When `LETSENCRYPT_CERTRESOLVER` is empty, Traefik will not request SSL certificates from Let's Encrypt. This is useful for local development or when using custom certificates.

## Managing the Application

### Start Services

```bash
docker-compose up -d
```

### Stop Services

```bash
docker-compose down
```

### Restart Services

```bash
docker-compose restart
```

### Rebuild After Code Changes

When you update your repositories, rebuild and restart:

```bash
docker-compose build --no-cache
docker-compose up -d
```

### View Logs

All services:
```bash
docker-compose logs -f
```

Specific service:
```bash
docker-compose logs -f backend
```

Last 100 lines:
```bash
docker-compose logs --tail=100 backend
```

### Access Django Shell

```bash
docker-compose exec backend python manage.py shell
```

### Run Django Management Commands

```bash
docker-compose exec backend python manage.py <command>
```

Examples:
```bash
# Create superuser
docker-compose exec backend python manage.py createsuperuser

# Run migrations
docker-compose exec backend python manage.py migrate

# Collect static files
docker-compose exec backend python manage.py collectstatic
```

### Database Backup

```bash
docker-compose exec db pg_dump -U ${DB_USER} ${DB_NAME} > backup.sql
```

### Database Restore

```bash
cat backup.sql | docker-compose exec -T db psql -U ${DB_USER} -d ${DB_NAME}
```

## Accessing the Application

After deployment, your application will be available at:

- **Frontend**: `https://yourdomain.com`
- **Backend API**: `https://yourdomain.com/api/`
- **Django Admin**: `https://yourdomain.com/admin/`
- **Media Files**: `https://yourdomain.com/media/`
- **Static Files**: `https://yourdomain.com/static/`

### Traefik Dashboard (Optional)

If enabled in `.env` (`TRAEFIK_DASHBOARD=true`), access at:
- `https://traefik.yourdomain.com`

**Important**: Protect the dashboard with authentication in production!

## Architecture

```
┌─────────────────────────────────────────────┐
│              Internet/Users                 │
└─────────────────┬───────────────────────────┘
                  │
         ┌────────▼────────┐
         │   Traefik       │
         │ (Reverse Proxy) │
         │   + SSL/TLS     │
         └────┬────────┬───┘
              │        │
    ┌─────────▼──┐  ┌─▼──────────┐
    │  Frontend  │  │  Backend   │
    │  (Nginx)   │  │  (Django)  │
    └────────────┘  └─────┬──────┘
                          │
                    ┌─────▼──────┐
                    │ PostgreSQL │
                    └────────────┘
```

## Volumes and Data Persistence

The following Docker volumes are created for data persistence:

- `{PROJECT_NAME}_postgres_data` - Database data
- `{PROJECT_NAME}_backend_media` - Uploaded media files
- `{PROJECT_NAME}_backend_static` - Static files
- `{PROJECT_NAME}_traefik_certs` - SSL certificates

### Backup Volumes

To backup all volumes:

```bash
docker run --rm \
  -v ${PROJECT_NAME}_postgres_data:/data/postgres \
  -v ${PROJECT_NAME}_backend_media:/data/media \
  -v ${PROJECT_NAME}_backend_static:/data/static \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/volumes-backup-$(date +%Y%m%d-%H%M%S).tar.gz /data
```

## Troubleshooting

### Check Service Health

```bash
docker-compose ps
```

### View Real-time Logs

```bash
docker-compose logs -f --tail=100
```

### SSL Certificate Issues

Check Traefik logs:
```bash
docker-compose logs traefik | grep -i acme
```

Ensure:
- `ENABLE_LETSENCRYPT=true` in your `.env` file
- `LETSENCRYPT_CERTRESOLVER=letsencrypt` is set (not empty)
- Domain DNS is pointing to your server
- Ports 80 and 443 are accessible from the internet
- Email in `LETSENCRYPT_EMAIL` is valid
- Not hitting Let's Encrypt rate limits (use staging server for testing)

**For local development**, disable ACME certificate requests:
```env
ENABLE_LETSENCRYPT=false
LETSENCRYPT_CERTRESOLVER=
```

**To test certificate requests without rate limits**, use Let's Encrypt staging:
```env
LETSENCRYPT_CA_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory
```

**Clear certificate cache** if you need to force new certificate requests:
```bash
docker-compose down
docker volume rm ${PROJECT_NAME}_traefik_certs
docker-compose up -d
```

### Database Connection Issues

Test database connectivity:
```bash
docker-compose exec backend python manage.py dbshell
```

### Permission Issues

If you encounter permission errors with volumes:

```bash
docker-compose down
docker volume rm ${PROJECT_NAME}_backend_media ${PROJECT_NAME}_backend_static
docker-compose up -d
```

### Reset Everything

⚠️ **Warning**: This will delete all data!

```bash
docker-compose down -v
docker-compose up -d
```

## Security Considerations

1. **Always use HTTPS** in production (configured by default)
2. **Use strong passwords** for database and admin accounts
3. **Keep SECRET_KEY secure** and never commit it to Git
4. **Set DEBUG=False** in production
5. **Regularly update** Docker images
6. **Backup regularly** - automate database and volume backups
7. **Limit exposed ports** - only 80 and 443 should be public
8. **Use firewall rules** to restrict access where needed

## Customization

### Custom Nginx Configuration

Edit `Dockerfile.frontend` to customize the Nginx configuration.

### Custom Backend Configuration

Modify environment variables in `.env` or edit `Dockerfile.backend`.

### Add More Services

Add new services to `docker-compose.yml` following the same pattern.

## Running Multiple Projects

To run multiple projects on the same server:

1. Use different `PROJECT_NAME` for each project
2. Use different domains or subdomains
3. Share the same `traefik-public` network
4. Each project will have isolated routes based on `PROJECT_NAME`

Example:
```yaml
# Project 1: videoflix
PROJECT_NAME=videoflix
DOMAIN=videoflix.com

# Project 2: another-app
PROJECT_NAME=anotherapp
DOMAIN=anotherapp.com
```

Both will share Traefik but have isolated routes and containers.

## Updates and Maintenance

### Update to Latest Code

```bash
# Rebuild with latest code from Git
docker-compose build --no-cache

# Restart services
docker-compose up -d

# Run migrations if needed
docker-compose exec backend python manage.py migrate
```

### Update Docker Images

```bash
# Pull latest base images
docker-compose pull

# Rebuild
docker-compose build --no-cache

# Restart
docker-compose up -d
```

## Support

For issues specific to:
- **Docker/Traefik**: Check official documentation
- **Django**: See Django documentation
- **This setup**: Review logs and configuration

## License

This deployment configuration is generic and can be used for any project.
