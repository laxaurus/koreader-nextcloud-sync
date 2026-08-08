KOReader Nextcloud News Sync

A custom KOReader plugin and shell script suite to automatically fetch daily news EPUBs from a Nextcloud WebDAV folder to a jailbroken Kindle Paperwhite.
Features

    Custom KOReader plugin (nextcloudsync.koplugin) with a menu button.
    Integrates with KOReader Gestures and Profiles via the Dispatcher API.
    Uses rclone over WebDAV to pull files.
    Smart syncing: Only pulls files modified in the last 48 hours.
    Keeps a receipt log (.downloaded_news) to prevent re-downloading deleted files.
    Detailed timestamped logging (sync.log).
    KUAL extension fallback for manual execution.

Project Structure

    kindle_files/rclone/: The sync script and rclone config template.
    kindle_files/koreader/plugins/nextcloudsync.koplugin/: The KOReader UI plugin.
    kindle_files/extensions/news_sync/: The KUAL menu extension.
    server_scripts/: Scripts used on the remote server to generate the EPUBs.

Setup Instructions

    Download the ARM 32-bit rclone binary and place it in /mnt/us/rclone/.
    Configure rclone with your Nextcloud WebDAV credentials.
    Copy the KOReader plugin to /mnt/us/koreader/plugins/.
    Copy the shell script to /mnt/us/rclone/.
    Restart KOReader and map the "Sync Nextcloud News" action to a gesture!


