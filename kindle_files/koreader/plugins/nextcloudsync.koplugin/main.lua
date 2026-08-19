local Device = require("device")
local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local ProgressWidget = require("ui/widget/progresswidget")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local Screen = Device.screen

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

-- Show a thin, non-blocking progress strip pinned to the top edge of the screen.
-- toast = true means it stacks above everything and never consumes input,
-- so the page behind stays fully readable and tappable while it is shown.
function NextcloudSync:showProgress()
    local bar_height = Screen:scaleBySize(8)
    self.progressbar = ProgressWidget:new{
        width = Screen:getWidth(),
        height = bar_height,
        percentage = 0,
        toast = true,
    }
    UIManager:show(self.progressbar, nil, nil, 0, 0)
end

function NextcloudSync:updateProgress(percent)
    if self.progressbar then
        self.progressbar:setPercentage(percent)
        UIManager:setDirty(self.progressbar)
    end
end

function NextcloudSync:hideProgress()
    if self.progressbar then
        UIManager:close(self.progressbar)
        self.progressbar = nil
    end
end

function NextcloudSync:triggerSync()
    -- Re-entrancy guard: one sync at a time.
    if self.sync_in_progress then
        return
    end
    self.sync_in_progress = true

    local status_file = "/mnt/us/rclone/.sync_status"

    self:showProgress()

    -- Execute the shell script asynchronously
    os.execute("/mnt/us/rclone/sync_queue.sh > /dev/null 2>&1 &")

    local poll_interval = 3     -- check every 3 seconds
    local stall_timeout = 300   -- give up only after 5 min with NO status change
    local last_status = nil     -- last line seen (nil until the first one)
    local last_change_time = os.time()

    local function finish(text)
        self:hideProgress()
        self.sync_in_progress = false
        -- Terminal toast is fine here: sync has ended, and a tap dismisses it.
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
            finish(_("Queue sync complete!"))
            return
        end
        if status == "empty" then
            os.remove(status_file)
            finish(_("Queue is empty — nothing to sync."))
            return
        end

        -- Progress line (e.g. "3/5 Book.epub"): advance the top strip when it changes.
        if status and status ~= last_status then
            last_status = status
            last_change_time = os.time()
            local i, n = status:match("^(%d+)/(%d+)")
            if i and n and tonumber(n) > 0 then
                self:updateProgress(tonumber(i) / tonumber(n))
            end
        end

        -- Stall detection: only give up if nothing has changed for a long time.
        if os.time() - last_change_time >= stall_timeout then
            finish(_("Sync appears stalled. Check sync.log."))
            return
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
