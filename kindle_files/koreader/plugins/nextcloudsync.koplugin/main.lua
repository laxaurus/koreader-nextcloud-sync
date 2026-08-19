local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local NextcloudSync = WidgetContainer:extend{
    name = "nextcloudsync",
}

function NextcloudSync:init()
    self.ui.menu:registerToMainMenu(self)

    Dispatcher:registerAction("sync_reading_queue", {
        category = "none",
        event = "SyncReadingQueue",
        title = _("Sync Reading Queue"),
        general = true,
    })
end

function NextcloudSync:triggerSync()
    local status_file = "/mnt/us/rclone/.sync_status"

    -- Show initial toast; refreshed below as progress arrives.
    UIManager:show(InfoMessage:new{
        text = _("Checking queue..."),
        timeout = 8,
    })

    -- Execute the shell script asynchronously
    os.execute("/mnt/us/rclone/sync_queue.sh > /dev/null 2>&1 &")

    local poll_interval = 3     -- check every 3 seconds
    local stall_timeout = 300   -- give up only after 5 min with NO status change
    local last_status = nil     -- last line seen (nil until the first one)
    local last_change_time = os.time()

    local function showTerminal(text)
        UIManager:show(InfoMessage:new{ text = text, timeout = 8 })
    end

    -- Define the polling function
    local function checkSyncStatus()
        local status = nil
        local f = io.open(status_file, "r")
        if f then
            status = f:read("*l")
            f:close()
        end

        -- Terminal states.
        if status == "done" then
            os.remove(status_file)
            showTerminal(_("Queue sync complete!"))
            return true
        end
        if status == "empty" then
            os.remove(status_file)
            showTerminal(_("Queue is empty — nothing to sync."))
            return true
        end

        -- Progress line (e.g. "3/5 Book.epub"): refresh the toast when it changes.
        if status and status ~= last_status then
            last_status = status
            last_change_time = os.time()
            UIManager:show(InfoMessage:new{
                text = string.format(_("Transferring %s"), status),
                timeout = 8,
            })
        end

        -- Stall detection: only give up if nothing has changed for a long time.
        if os.time() - last_change_time >= stall_timeout then
            showTerminal(_("Sync appears stalled. Check sync.log."))
            return true
        end

        -- Not done and not stalled, schedule another check
        UIManager:scheduleIn(poll_interval, checkSyncStatus)
    end

    -- Start the polling loop after giving the script a moment to delete the old status file
    UIManager:scheduleIn(2, checkSyncStatus)
end

function NextcloudSync:onSyncReadingQueue()
    self:triggerSync()
    return true
end

function NextcloudSync:addToMainMenu(menu_items)
    menu_items.nextcloud_sync = {
        text = _("Sync Reading Queue"),
        sorting_hint = "network",
        callback = function()
            self:triggerSync()
        end,
    }
end

return NextcloudSync
