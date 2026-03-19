# Quick Reference Guide

## Initial Setup

```bash
# 1. Create Traefik network
docker network create traefik-public

# 2. Copy and configure .env
cp .env.example .env
nano .env

# 3. Deploy (Linux/Mac)
bash deploy.sh

# OR Deploy (Windows PowerShell)
.\deploy.ps1

# OR Deploy manually
docker-compose build
docker-compose up -d
```

## Common Commands

### Service Management
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart backend

# View service status
docker-compose ps

# Remove all services and volumes (⚠️ destructive)
docker-compose down -v
```

### Logs
```bash
# View all logs (real-time)
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f db
docker-compose logs -f traefik

# View last 100 lines
docker-compose logs --tail=100 backend

# View logs without following
docker-compose logs backend
```

### Updates
```bash
# Update to latest code (Linux/Mac)
bash update.sh

# OR Update (Windows PowerShell)
.\update.ps1

# OR Update manually
docker-compose build --no-cache
docker-compose up -d
docker-compose exec backend python manage.py migrate
docker-compose exec backend python manage.py collectstatic --noinput
```

## Django Management

### Execute Commands in Backend Container
```bash
# Access Django shell
docker-compose exec backend python manage.py shell

# Create superuser
docker-compose exec backend python manage.py createsuperuser

# Run migrations
docker-compose exec backend python manage.py migrate

# Create new migration
docker-compose exec backend python manage.py makemigrations

# Collect static files
docker-compose exec backend python manage.py collectstatic

# Run custom management command
docker-compose exec backend python manage.py <your_command>

# Access bash shell
docker-compose exec backend bash
```

### Database Operations
```bash
# Access database shell
docker-compose exec backend python manage.py dbshell

# OR access PostgreSQL directly
docker-compose exec db psql -U ${DB_USER} -d ${DB_NAME}

# Backup database
docker-compose exec db pg_dump -U ${DB_USER} ${DB_NAME} > backup.sql

# Restore database
cat backup.sql | docker-compose exec -T db psql -U ${DB_USER} -d ${DB_NAME}

# Reset database (⚠️ destructive)
docker-compose down
docker volume rm ${PROJECT_NAME}_postgres_data
docker-compose up -d
```

## Monitoring and Debugging

### Check Container Health
```bash
# View container status
docker-compose ps

# Inspect specific container
docker inspect ${PROJECT_NAME}_backend

# View container resource usage
docker stats

# Check container logs for errors
docker-compose logs backend | grep -i error
docker-compose logs backend | grep -i warning
```

### Network Troubleshooting
```bash
# List networks
docker network ls

# Inspect traefik network
docker network inspect traefik-public

# Test DNS resolution
docker-compose exec backend nslookup ${DOMAIN}

# Test backend connectivity from frontend
docker-compose exec frontend wget -O- http://backend:8000/api/
```

### SSL Certificate Issues
```bash
# Check Traefik logs for certificate issues
docker-compose logs traefik | grep -i acme
docker-compose logs traefik | grep -i certificate

# Check certificate file
docker-compose exec traefik ls -la /letsencrypt/

# Force certificate renewal (remove old certs)
docker-compose down
docker volume rm ${PROJECT_NAME}_traefik_certs
docker-compose up -d
```

## File and Volume Management

### Access Files
```bash
# Copy file from container
docker cp ${PROJECT_NAME}_backend:/app/file.txt ./local-file.txt

# Copy file to container
docker cp ./local-file.txt ${PROJECT_NAME}_backend:/app/file.txt

# List files in container
docker-compose exec backend ls -la /app/
```

### Volume Operations
```bash
# List volumes
docker volume ls | grep ${PROJECT_NAME}

# Inspect volume
docker volume inspect ${PROJECT_NAME}_postgres_data

# Backup volumes
docker run --rm \
  -v ${PROJECT_NAME}_postgres_data:/data/postgres \
  -v ${PROJECT_NAME}_backend_media:/data/media \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/volumes-backup-$(date +%Y%m%d-%H%M%S).tar.gz /data

# Remove specific volume (⚠️ destructive)
docker volume rm ${PROJECT_NAME}_backend_media
```

## Environment and Configuration

### Update Environment Variables
```bash
# 1. Edit .env file
nano .env

# 2. Rebuild and restart
docker-compose up -d --force-recreate
```

### View Current Configuration
```bash
# View loaded environment variables
docker-compose config

# View specific service environment
docker-compose exec backend env

# Check Django settings
docker-compose exec backend python manage.py diffsettings
```

## Performance

### Scale Services
```bash
# Run multiple backend workers
docker-compose up -d --scale backend=3

# Check scaled instances
docker-compose ps
```

### Resource Limits
Edit docker-compose.yml and add:
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

## Security

### Update Secrets
```bash
# 1. Generate new secret key
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

# 2. Update .env file
nano .env

# 3. Restart services
docker-compose restart backend
```

### View Running Processes
```bash
# List processes in container
docker-compose exec backend ps aux

# Check for security updates
docker-compose pull
```

## Troubleshooting Common Issues

### Issue: Services won't start
```bash
# Check logs
docker-compose logs

# Check disk space
df -h

# Check Docker daemon
systemctl status docker  # Linux
```

### Issue: Database connection errors
```bash
# Check if postgres is running
docker-compose ps db

# Check postgres logs
docker-compose logs db

# Test database connection
docker-compose exec db psql -U ${DB_USER} -d ${DB_NAME} -c "SELECT 1;"
```

### Issue: Permission errors
```bash
# Fix ownership (Linux)
docker-compose exec backend chown -R appuser:appuser /app/media

# Check current permissions
docker-compose exec backend ls -la /app/
```

### Issue: Out of memory
```bash
# Check memory usage
docker stats

# Restart services to free memory
docker-compose restart

# Or prune unused resources
docker system prune -a
```

### Issue: Port conflicts
```bash
# Check what's using port 80/443
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Or use lsof
sudo lsof -i :80
sudo lsof -i :443
```

## Maintenance

### Clean Up
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Full cleanup (⚠️ careful!)
docker system prune -a --volumes
```

### Backup Strategy
```bash
# Create backup script (example)
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
docker-compose exec -T db pg_dump -U ${DB_USER} ${DB_NAME} > ./backups/db-$DATE.sql
docker run --rm -v ${PROJECT_NAME}_backend_media:/data -v $(pwd)/backups:/backup alpine tar czf /backup/media-$DATE.tar.gz /data
```

### Automated Backups with Cron
```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /path/to/production_Docker && bash backup.sh
```

## URLs

After deployment, access:
- **Frontend**: https://yourdomain.com
- **API**: https://yourdomain.com/api/
- **Admin**: https://yourdomain.com/admin/
- **Media**: https://yourdomain.com/media/
- **Static**: https://yourdomain.com/static/
- **Traefik Dashboard** (if enabled): https://traefik.yourdomain.com

## Getting Help

1. Check logs: `docker-compose logs -f`
2. Check service status: `docker-compose ps`
3. Check container health: `docker inspect ${PROJECT_NAME}_backend`
4. Review README.md for detailed documentation
5. Check official documentation for Django, Docker, and Traefik
