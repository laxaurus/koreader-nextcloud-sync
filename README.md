# KOReader Nextcloud News Sync

A custom KOReader plugin and shell script suite to automatically fetch daily news EPUBs from a Nextcloud WebDAV folder to a jailbroken Kindle Paperwhite.

## Features
- Custom KOReader plugin (`nextcloudsync.koplugin`) with a menu button.
- Integrates with KOReader Gestures and Profiles via the Dispatcher API.
- Uses `rclone` over WebDAV to pull files.
- Smart syncing: Only pulls files modified in the last 48 hours.
- Keeps a receipt log (`.downloaded_news`) to prevent re-downloading deleted files.
- Detailed timestamped logging (`sync.log`).
- KUAL extension fallback for manual execution.

## Project Structure
- `kindle_files/rclone/`: The sync script and rclone config template.
- `kindle_files/koreader/plugins/nextcloudsync.koplugin/`: The KOReader UI plugin.
- `kindle_files/extensions/news_sync/`: The KUAL menu extension.
- `server_scripts/`: Scripts used on the remote server to generate the EPUBs.

## Setup Instructions

### Step 1: Download and Install Rclone (32-bit ARM)
The Kindle Paperwhite runs a 32-bit ARM Linux environment. You cannot use the standard 64-bit PC binary.

1. On your PC, go to the official Rclone downloads page: **[https://rclone.org/downloads/](https://rclone.org/downloads/)**
2. Scroll down to the **Download** section and find the link for **OS/Arch: linux - arm**.
   *(The file will be named something like `rclone-current-linux-arm.zip`)*.
3. Download and extract the `.zip` file on your PC. Inside, you will find an executable file named `rclone`.
4. Connect your Kindle to your PC via USB.
5. Create a folder on the Kindle root named `rclone` (path: `/mnt/us/rclone/`).
6. Copy the `rclone` executable from your PC into this folder.

### Step 2: Make Rclone Executable
Files transferred via USB lose their executable permissions. 
1. Connect your Kindle to Wi-Fi.
2. SSH into your Kindle (`ssh root@<KINDLE_IP>`).
3. Run the following commands:
   ```bash
   cd /mnt/us/rclone
   chmod +x rclone
   ./rclone version
   ```
   *(Note: You may see harmless "internal error: no overview data found" messages for certain cloud providers. As long as it prints the version number at the bottom, it is working perfectly).*

### Step 3: Configure Rclone for Nextcloud
Still in your SSH terminal, configure the WebDAV connection:
```bash
./rclone config
```
Follow the prompts:
- Type `n` for **New remote**.
- Name it: `nextcloud_news`
- Storage type: Choose the number for **webdav**.
- URL: `https://your-nextcloud-domain.com/remote.php/dav/files/YOUR_USERNAME/`
- Provider: Choose **Nextcloud**.
- User: Your Nextcloud username.
- Password: Your Nextcloud password (App passwords highly recommended).
- Leave the rest blank/default and save.

### Step 4: Install the Sync Script
1. Copy `sync_news.sh` from the `kindle_files/rclone/` folder in this repo to `/mnt/us/rclone/` on your Kindle.
2. Via SSH, make it executable:
   ```bash
   chmod +x /mnt/us/rclone/sync_news.sh
   ```

### Step 5: Install the KOReader Plugin
1. Copy the entire `nextcloudsync.koplugin` folder from this repo into `/mnt/us/koreader/plugins/` on your Kindle.
2. Completely exit KOReader (back to the Kindle home screen) and reopen it.

### Step 6: Automate and Use
- **Manual Trigger:** Tap the top-center menu -> Gear icon (Settings) -> Network tab -> **Sync Nextcloud News**.
- **Automation:** Go to Settings -> Network -> Gesture Manager (or Profiles) and assign the **Sync Nextcloud News** action to a gesture (like swiping down with two fingers) or a profile.

## Optional: Server-Side Cleanup
To prevent your Nextcloud `News` folder from filling up indefinitely, add a cleanup command to the end of your daily EPUB generation script on your server:
```bash
# Delete EPUBs older than 3 days from the Nextcloud News folder
find /path/to/nextcloud/News/ -name "*.epub" -type f -mtime +3 -delete
```

