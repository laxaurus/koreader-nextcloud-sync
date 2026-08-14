#!/bin/sh

# Kindle reading-queue sync script.
#
# Pulls files from a Nextcloud WebDAV queue folder, routes them to local
# destinations by filename prefix (NEWS_ -> News/, everything else -> Books/),
# verifies each download and deletes the remote file on success.
# Invalid formats (not epub/pdf/cbz) are removed from the queue untouched.
#
# The rclone remote and queue path are read from
# /mnt/us/rclone/sync_queue.conf (defaults below).
#
# For host-side testing without a Kindle, set KOSYNC_ROOT to the fake
# Kindle tree, e.g.: KOSYNC_ROOT=/tmp/kosync_test/mnt/us ./sync_queue.sh

BASE="/mnt/us"
[ -n "$KOSYNC_ROOT" ] && BASE="$KOSYNC_ROOT"

RCLONE="$BASE/rclone/rclone"
CONF_DIR="$BASE/rclone"
CONF_FILE="$CONF_DIR/sync_queue.conf"
RCLONE_CONF="$CONF_DIR/rclone.conf"
LOG="$CONF_DIR/sync.log"
STATUS_FILE="$CONF_DIR/.sync_status"

# Defaults (override in sync_queue.conf)
REMOTE="nextcloud_news"
QUEUE="Books Library/calibre/books/downloads/sync"
NEWS_DIR="$BASE/documents/News"
BOOKS_DIR="$BASE/documents/Books"

[ -f "$CONF_FILE" ] && . "$CONF_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
}

# --- Reset status so the KOReader plugin knows a new run has started
rm -f "$STATUS_FILE"
log "--- Starting reading queue sync ---"

# --- Wi-Fi: save current state, enable if needed, restore it when done
WIFI_CHANGED=0
if command -v lipc-get-prop >/dev/null 2>&1; then
    WIFI_STATE=$(lipc-get-prop com.lab126.cmd wirelessEnable 2>/dev/null)
    if [ "$WIFI_STATE" = "0" ]; then
        log "Wi-Fi is off, enabling (will restore after sync)"
        lipc-set-prop com.lab126.cmd wirelessEnable 1
        WIFI_CHANGED=1
        sleep 10
    elif [ "$WIFI_STATE" = "1" ]; then
        log "Wi-Fi already enabled"
    else
        log "Wi-Fi state unknown ('$WIFI_STATE'), enabling"
        lipc-set-prop com.lab126.cmd wirelessEnable 1
        sleep 10
    fi
else
    log "lipc not available (non-Kindle environment?), skipping Wi-Fi control"
fi

# --- Fetch queue listing (filenames only, one per line)
QUEUE_REMOTE="$REMOTE:$QUEUE"
LIST_TMP="/tmp/sync_queue_list.$$"
mkdir -p "$NEWS_DIR" "$BOOKS_DIR"

log "Fetching file list from $QUEUE_REMOTE"
if ! $RCLONE lsf "$QUEUE_REMOTE" --files-only --config="$RCLONE_CONF" > "$LIST_TMP" 2>>"$LOG"; then
    log "[ERROR] Failed to fetch queue listing"
    rm -f "$LIST_TMP"
    echo "done" > "$STATUS_FILE"
    exit 1
fi

# --- Process each file: validate, route, download, verify, delete
while IFS= read -r FILE; do
    [ -z "$FILE" ] && continue

    EXT=$(printf '%s' "${FILE##*.}" | tr 'A-Z' 'a-z')
    case "$EXT" in
        epub|pdf|cbz) ;;
        *)
            log "[ERROR] Invalid format '$FILE', removing from queue"
            $RCLONE deletefile "$QUEUE_REMOTE/$FILE" --config="$RCLONE_CONF" >>"$LOG" 2>&1
            continue
            ;;
    esac

    case "$FILE" in
        NEWS_*) DEST="$NEWS_DIR" ;;
        *)      DEST="$BOOKS_DIR" ;;
    esac

    log "[DOWNLOAD] $FILE -> $DEST"
    if $RCLONE copy "$QUEUE_REMOTE/$FILE" "$DEST" --config="$RCLONE_CONF" >>"$LOG" 2>&1 \
       && [ -f "$DEST/$FILE" ]; then
        log "[SUCCESS] $FILE downloaded to $DEST"
        if $RCLONE deletefile "$QUEUE_REMOTE/$FILE" --config="$RCLONE_CONF" >>"$LOG" 2>&1; then
            log "[SUCCESS] $FILE removed from queue"
        else
            log "[ERROR] Failed to remove $FILE from queue"
        fi
    else
        log "[ERROR] Failed to download $FILE (kept in queue)"
    fi
done < "$LIST_TMP"
rm -f "$LIST_TMP"

# --- Restore Wi-Fi to its previous state
if [ "$WIFI_CHANGED" = "1" ]; then
    log "Restoring Wi-Fi to off"
    lipc-set-prop com.lab126.cmd wirelessEnable 0
fi

log "--- Finished reading queue sync ---"

# --- Signal completion to KOReader
echo "done" > "$STATUS_FILE"
