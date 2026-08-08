#!/bin/sh

# Paths and variables
RCLONE=/mnt/us/rclone/rclone
REMOTE=nc_calibre_news:"Books Library"/calibre/books/news
LOCAL_DIR="/mnt/us/documents/News"
INDEX="/mnt/us/rclone/.downloaded_news"
LOG="/mnt/us/rclone/sync.log"


NOW=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$NOW] --- Starting News Sync ---" >> "$LOG"

# 1. Network Setup
echo "[$NOW] [STAGE 1] Enabling Wi-Fi..." >> "$LOG"
lipc-set-prop com.lab126.cmd wirelessEnable 1
sleep 5

# 2. Fetching File List
echo "[$NOW] [STAGE 2] Fetching file list from Nextcloud (max age 48h)..." >> "$LOG"
mkdir -p "$LOCAL_DIR"
touch "$INDEX"
FILES=$($RCLONE lsf "$REMOTE" --files-only --max-age 48h 2>/dev/null)

# 3. Downloading Loop
echo "[$NOW] [STAGE 3] Checking files for download..." >> "$LOG"
for FILE in $FILES; do
    if grep -Fxq "$FILE" "$INDEX"; then
        echo "[$NOW]   -> [SKIP] $FILE (already downloaded)" >> "$LOG"
        continue
    fi

    echo "[$NOW]   -> [DOWNLOAD] $FILE" >> "$LOG"
    $RCLONE copy "$REMOTE/$FILE" "$LOCAL_DIR" 2>/dev/null

    if [ -f "$LOCAL_DIR/$FILE" ]; then
        echo "$FILE" >> "$INDEX"
        echo "[$NOW]   -> [SUCCESS] $FILE downloaded and indexed" >> "$LOG"
    else
        echo "[$NOW]   -> [ERROR] Failed to download $FILE" >> "$LOG"
    fi
done

# 4. Cleanup
#NOW=$(date '+%Y-%m-%d %H:%M:%S')
#echo "[$NOW] [STAGE 4] Sync complete. Disabling Wi-Fi." >> "$LOG"
#lipc-set-prop com.lab126.cmd wirelessEnable 0
echo "[$NOW] --- Finished ---" >> "$LOG"
