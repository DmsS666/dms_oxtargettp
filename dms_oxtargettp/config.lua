Config = {}

-- 傳送點設置 (作為 PED 傳送的參考)
Config.TeleportLocations = {
    -- Location 1 (上層電梯)
    {
        coords = vector3(198.7041, -899.8041, 31.1167),
        heading = 148.3687,
        label = "傳送到暗區"
    }, 
    -- Location 2 (下層電梯)
    {
        coords = vector3(1148.5723, 3065.0576, 40.8898),
        heading = 298.8948,
        label = "傳送到公停"
    },

}

-- PED 設置 (NPC)
Config.Peds = {
    -- 電梯操作員配置
    anqu = {
        {
            model = "patrick", -- PED 模型
            coords = vector3(199.2195, -899.1182, 31.1168), -- PED 位置
            heading = 142.8444, -- PED 朝向
            scenario = "WORLD_HUMAN_CLIPBOARD", -- PED 動作場景
            teleportTo = 2, -- 傳送到第幾個位置索引 (對應 Config.TeleportLocations)
            label = "請求傳送", -- 互動選項標籤
            icon = "fas fa-arrow-up", -- 互動選項圖標
            items = { -- 需要的物品列表（可選）-- {name = "elevator_key", label = "電梯鑰匙", count = 1}
            },
            headerText = "傳送到暗區", -- PED 頭頂主標題
            subText = "" -- PED 頭頂副標題
        },
        {
            model = "patrick",
            coords = vector3(1147.7371, 3064.7043, 40.8840),
            heading = 277.1641,
            scenario = "WORLD_HUMAN_CLIPBOARD",
            teleportTo = 1,
            label = "請求傳送",
            icon = "fas fa-arrow-down",
            items = {},
            headerText = "傳送到公停",
            subText = ""
        }
    }
}

-- 頭頂文本設置
Config.HeaderText = {
    enable = true, -- 是否啟用頭頂文本顯示
    font = 0, -- 字體
    scale = 1.3, -- 文本大小
    distance = 10.0, -- 可見距離
    headerColor = {255, 0, 0, 255}, -- 主標題顏色 (R,G,B,A)
    subTextColor = {255, 0, 0, 200}, -- 副標題顏色
    offset = 1.1, -- 文本高度偏移 (相對於 PED 頭部)
    shadow = true, -- 是否啟用文本陰影
    backGround = {enabled = false, color = {0, 0, 0, 150}}, -- 文本背景
    backGroundMargin = {0.02, 0.08}, -- 背景邊緣 (X,Y)
}

-- 地圖標記設置
Config.UseBlips = false -- 是否在地圖上顯示標記
Config.BlipSprite = 280 -- NPC 圖標
Config.BlipColor = 3 -- 黃色
Config.BlipScale = 0.8

-- 動畫設置
Config.AnimDict = "mini@repair" -- 傳送時播放的動畫
Config.AnimName = "fixing_a_ped"
Config.AnimTime = 50 -- 動畫播放時間 (毫秒)

-- 畫面過渡設置
Config.FadeOutTime = 350 -- 畫面淡出時間 (ms)
Config.FadeInTime = 850 -- 畫面淡入時間 (ms)
Config.TeleportDelay = 50 -- 傳送前等待時間 (ms)
Config.AfterTeleportDelay = 600 -- 傳送後等待時間 (ms)

-- 通知設置
Config.Notifications = {
    teleported = {
        title = "已傳送",
        description = "您已成功傳送到目的地",
        type = "success"
    },
    accessDenied = {
        title = "拒絕訪問",
        description = "您沒有使用此傳送點的權限",
        type = "error"
    },
    itemRequired = {
        title = "需要物品",
        description = "您需要 %s 才能使用此傳送點",
        type = "error"
    }
}

-- 日誌格式
Config.LogFormat = "[傳送系統] 玩家 %s (ID: %s) 從 %s 傳送到 %s"



-- 新增截圖相關配置
Config.UseScreenshot = true -- 是否在傳送時截圖
Config.CustomScreenshotURL = nil -- 自定義截圖上傳URL，設置為nil則使用默認值

Config.Discord = {
    UseWebhook = true,
    WebhookURL = "https://discord.com/api/webhooks/1370344572260974623/bMRALPpZ3w3yXyIVj7llTBQQ9SQBQ9M8tg-hV21vgba1KVl4zm5slfXmGpOTaZ1YtDar",
    BotName = "傳送日誌",
    BotAvatar = "https://i.imgur.com/ZDgIOU9.png",
    LogTitle = "玩家傳送記錄",
    LogDescription = "玩家進行了傳送",
    ShowCoords = true,
    ShowPlayerID = true,
    Color = 3447003, -- Discord嵌入顏色代碼 (藍色)
    Footer = "FiveM伺服器 - 傳送系統",
    ShowScreenshotInfo = true -- 當有截圖時在標題中顯示"(帶截圖)"
}


--Config.TeleportLocations 是一个定义了所有可能的传送目标位置的表（类似于数组）。这是一个集中存储所有传送位置的地方，而不是将这些位置信息直接写入每个 PED 的设置中。
--具体来说，它的作用是：
--
--集中管理：将所有传送位置集中在一个地方定义，使得配置更整洁、更易于管理
--减少重复：避免在每个 PED 的配置中重复写入相同的坐标信息
--简化引用：PED 配置只需要通过 teleportTo 属性指定一个索引（例如 1、2、3），而不需要直接写入完整的坐标信息