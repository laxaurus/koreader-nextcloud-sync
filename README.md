# KOReader Nextcloud Reading Queue Sync

A custom KOReader plugin and shell script suite to automatically fetch books and news EPUBs from a Nextcloud WebDAV queue folder to a jailbroken Kindle Paperwhite.

The queue folder acts as a **pull-and-delete message queue**: the Kindle script downloads each file into the matching local folder and removes it from Nextcloud after a successful download.

## How routing works
Files placed in the queue folder are routed by filename prefix:
- `NEWS_<filename>.epub` -> `/mnt/us/documents/News/`
- everything else (`BOOK_*` or unprefixed) -> `/mnt/us/documents/Books/`

Allowed extensions: `.epub`, `.pdf`, `.cbz` — anything else is logged and removed from the queue.

The queue folder is the same location calibre-web uploads books to; it is configured in `sync_queue.conf` on the Kindle (see Step 4).

## Features
- Custom KOReader plugin (`nextcloudsync.koplugin`) with a menu button.
- Integrates with KOReader Gestures and Profiles via the Dispatcher API.
- Uses `rclone` over WebDAV to pull files.
- Pull-and-delete queue: downloaded files are removed from Nextcloud; failed downloads stay in the queue for retry.
- Wi-Fi state aware: enables Wi-Fi if off, restores the previous state when done.
- Detailed timestamped logging (`sync.log`).
- KUAL extension fallback for manual execution.

## Project Structure
- `kindle_files/rclone/`: The sync script (`sync_queue.sh`), its config file (`sync_queue.conf`) and the rclone config template.
- `kindle_files/koreader/plugins/nextcloudsync.koplugin/`: The KOReader UI plugin.
- `kindle_files/extensions/news_sync/`: The KUAL menu extension.

## Setup Instructions

### Step 1: Download and Install Rclone (32-bit ARM)
The Kindle Paperwhite runs a 32-bit ARM Linux environment. You cannot use the standard 64-bit PC binary.

1. On your PC, go to the official Rclone downloads page: **[https://rclone.org/downloads/](https://rclone.org/downloads/)**
2. Scroll down to the **Download** section and find the link for **OS/Arch: linux - arm**.
   *(The file will be named something like `rclone-current-linux-arm.zip`.)*
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

Alternatively, copy `rclone.conf.template` from this repo to `/mnt/us/rclone/rclone.conf` and fill in your credentials.

### Step 4: Install the Sync Script and its Config
1. Copy `sync_queue.sh` from the `kindle_files/rclone/` folder in this repo to `/mnt/us/rclone/` on your Kindle.
2. Copy `sync_queue.conf` to `/mnt/us/rclone/` and adjust `QUEUE` to the Nextcloud folder used as the queue (the same location calibre-web uploads books to).
3. Via SSH, make the script executable:
   ```bash
   chmod +x /mnt/us/rclone/sync_queue.sh
   ```

### Step 5: Install the KOReader Plugin
1. Copy the entire `nextcloudsync.koplugin` folder from this repo into `/mnt/us/koreader/plugins/` on your Kindle.
2. Completely exit KOReader (back to the Kindle home screen) and reopen it.

### Step 6: Use
- **Manual Trigger:** Tap the top-center menu -> Gear icon (Settings) -> Network tab -> **Sync Reading Queue**.
- **Automation:** Go to Settings -> Network -> Gesture Manager (or Profiles) and assign the **Sync Reading Queue** action to a gesture or a profile.
- **KUAL fallback:** Install `kindle_files/extensions/news_sync/` into `/mnt/us/extensions/` to trigger the sync from KUAL.
