#!/bin/bash
# deploy.sh — backup the Kindle's current sync files, then push updates via dropbear SSH.
# Usage: KINDLE_IP=192.168.x.x ./deploy.sh   (dropbear listens on port 2222)
set -euo pipefail

KINDLE_IP="${KINDLE_IP:?set KINDLE_IP env var}"
PORT="${KINDLE_PORT:-2222}"
HOST="root@$KINDLE_IP"
SSH="ssh -p $PORT $HOST"
SCP="scp -P $PORT"
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="backups/kindle-$STAMP"

# 1. BACKUP current device files (before anything is overwritten)
mkdir -p "$BACKUP/rclone" "$BACKUP/plugins" "$BACKUP/extensions"
$SCP -q  "$HOST":/mnt/us/rclone/sync_queue.sh   "$BACKUP/rclone/" 2>/dev/null || true
$SCP -q  "$HOST":/mnt/us/rclone/sync_queue.conf "$BACKUP/rclone/" 2>/dev/null || true
$SCP -q  "$HOST":/mnt/us/rclone/rclone.conf     "$BACKUP/rclone/" 2>/dev/null || true  # contains credentials — backed up locally, never pushed
$SCP -qr "$HOST":/mnt/us/koreader/plugins/nextcloudsync.koplugin "$BACKUP/plugins/" 2>/dev/null || true
$SCP -qr "$HOST":/mnt/us/extensions/news_sync   "$BACKUP/extensions/" 2>/dev/null || true
echo "Backed up device state to $BACKUP"

# 2. PUSH new files (rclone.conf is NEVER pushed — it is device-local)
$SSH "mkdir -p /mnt/us/rclone /mnt/us/koreader/plugins /mnt/us/extensions"
$SCP -q  kindle_files/rclone/sync_queue.sh   "$HOST":/mnt/us/rclone/
$SCP -q  kindle_files/rclone/sync_queue.conf "$HOST":/mnt/us/rclone/
$SCP -qr kindle_files/koreader/plugins/nextcloudsync.koplugin "$HOST":/mnt/us/koreader/plugins/
$SCP -qr kindle_files/extensions/news_sync   "$HOST":/mnt/us/extensions/

# 3. Fix permissions (transfers can drop the exec bit)
$SSH "chmod +x /mnt/us/rclone/sync_queue.sh"

echo "Deployed. Restart KOReader to load the plugin."
echo "Roll back with: scp -P $PORT -r $BACKUP/* root@$KINDLE_IP:/mnt/us/"
