#!/bin/bash

# Backup base directory
BACKUP_DIR="/backup/server_backup"

echo "Starting backup..."

# Create base directory (overwrite old backup)
rm -rf $BACKUP_DIR
mkdir -p $BACKUP_DIR

# -----------------------------
# 1. System Info
# -----------------------------
echo "Saving system info..."
uname -a > $BACKUP_DIR/system_info.txt
df -h > $BACKUP_DIR/disk_usage.txt

# -----------------------------
# 2. Installed Packages
# -----------------------------
echo "Saving installed packages..."

if command -v apt >/dev/null 2>&1; then
    dpkg --get-selections > $BACKUP_DIR/packages_list.txt
elif command -v yum >/dev/null 2>&1; then
    yum list installed > $BACKUP_DIR/packages_list.txt
fi

# Save important binaries info
which git docker unzip > $BACKUP_DIR/important_tools.txt 2>/dev/null

# -----------------------------
# 3. Backup Important Directories
# -----------------------------
echo "Backing up important directories..."

tar --exclude=/proc \
    --exclude=/tmp \
    --exclude=/sys \
    --exclude=/dev \
    --exclude=/run \
    --exclude=/mnt \
    --exclude=/media \
    --exclude=/lost+found \
    --exclude=/var/cache \
    --exclude=/var/log \
    --exclude=/var/tmp \
    -czf $BACKUP_DIR/files_backup.tar.gz \
    /etc /home /opt /var/www 2>/dev/null

# -----------------------------
# 4. Docker Backup
# -----------------------------
if command -v docker >/dev/null 2>&1; then
    echo "Backing up Docker data..."

    mkdir -p $BACKUP_DIR/docker

    # Docker images list
    docker images > $BACKUP_DIR/docker/images_list.txt

    # Running containers
    docker ps -a > $BACKUP_DIR/docker/containers_list.txt

    # Save container inspect data
    for container in $(docker ps -aq); do
        docker inspect $container > $BACKUP_DIR/docker/container_$container.json
    done

    # Save images (compressed)
    docker save $(docker images -q) | gzip > $BACKUP_DIR/docker/images_backup.tar.gz 2>/dev/null

    # Backup volumes (IMPORTANT)
    VOLUME_DIR="/var/lib/docker/volumes"
    if [ -d "$VOLUME_DIR" ]; then
        tar -czf $BACKUP_DIR/docker/volumes_backup.tar.gz $VOLUME_DIR 2>/dev/null
    fi
fi

# -----------------------------
# 5. Cleanup (Optional)
# -----------------------------
echo "Cleaning unnecessary temp files..."
find $BACKUP_DIR -type f -name "*.log" -delete

echo "Backup completed successfully!"
echo "Backup location: $BACKUP_DIR"
