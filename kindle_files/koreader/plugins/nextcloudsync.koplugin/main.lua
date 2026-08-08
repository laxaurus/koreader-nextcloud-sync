local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

-- 1. Inherit from WidgetContainer
local NextcloudSync = WidgetContainer:extend{
    name = "nextcloudsync",
}

-- 2. Initialize and register the menu
function NextcloudSync:init()
    self.ui.menu:registerToMainMenu(self)

    -- Register the action for Dispatcher (Profiles & Gestures)
    Dispatcher:registerAction("sync_nextcloud_news", {
        category = "none",
        event = "SyncNextcloudNews",
        title = _("Sync Nextcloud News"),
        general = true,
    })
end

-- 3. The core sync function
function NextcloudSync:triggerSync()
    UIManager:show(InfoMessage:new{
        text = _("Fetching news in background..."),
        timeout = 3,
    })

    -- Execute the shell script asynchronously (non-blocking)
    os.execute("/mnt/us/rclone/sync_news.sh > /dev/null 2>&1 &")

    -- Schedule a completion popup 35 seconds later
    UIManager:scheduleIn(35, function()
        UIManager:show(InfoMessage:new{
            text = _("News sync complete!"),
            timeout = 3,
        })
    end)
end

-- 4. Event handler for Dispatcher actions
function NextcloudSync:onSyncNextcloudNews()
    self:triggerSync()
    return true
end

-- 5. Add the menu item to the KOReader UI
function NextcloudSync:addToMainMenu(menu_items)
    menu_items.nextcloud_sync = {
        text = _("Sync Nextcloud News"),
        sorting_hint = "network", -- Places it in the Network tab of the Gear menu
        callback = function()
            self:triggerSync()
        end,
    }
end

