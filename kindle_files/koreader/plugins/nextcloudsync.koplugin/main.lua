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
    
    Dispatcher:registerAction("sync_nextcloud_news", {
        category = "none",
        event = "SyncNextcloudNews",
        title = _("Sync Nextcloud News"),
        general = true,
    })
end

function NextcloudSync:triggerSync()
    local status_file = "/mnt/us/rclone/.sync_status"
    
    -- Show initial popup
    UIManager:show(InfoMessage:new{
        text = _("Fetching news in background..."),
        timeout = 3,
    })

    -- Execute the shell script asynchronously
    os.execute("/mnt/us/rclone/sync_news.sh > /dev/null 2>&1 &")

    -- Polling variables
    local poll_interval = 5 -- Check every 5 seconds
    local max_polls = 12    -- Safety net: stop after 60 seconds (12 * 5s)
    local poll_count = 0

    -- Define the polling function
    local function checkSyncStatus()
        poll_count = poll_count + 1
        
        -- Check if the status file exists and contains "done"
        local f = io.open(status_file, "r")
        if f then
            local status = f:read("*l")
            f:close()
            
            if status == "done" then
                -- Clean up the status file for next time
                os.remove(status_file)
                
                -- Show completion popup immediately!
                UIManager:show(InfoMessage:new{
                    text = _("News sync complete!"),
                    timeout = 3,
                })
                return true -- Stop polling
            end
        end
        
        -- If timeout reached, show error and stop polling
        if poll_count >= max_polls then
            UIManager:show(InfoMessage:new{
                text = _("Sync timed out. Check sync.log."),
                timeout = 3,
            })
            return true
        end
        
        -- If not done and not timed out, schedule another check
        UIManager:scheduleIn(poll_interval, checkSyncStatus)
    end

    -- Start the polling loop after giving the script a moment to delete the old status file
    UIManager:scheduleIn(2, checkSyncStatus)
end

function NextcloudSync:onSyncNextcloudNews()
    self:triggerSync()
    return true
end

function NextcloudSync:addToMainMenu(menu_items)
    menu_items.nextcloud_sync = {
        text = _("Sync Nextcloud News"),
        sorting_hint = "network",
        callback = function()
            self:triggerSync()
        end,
    }
end

return NextcloudSync