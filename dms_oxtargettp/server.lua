-- server.lua

-- 更新的發送到Discord的函數，現在支持截圖URL
function SendToDiscord(playerName, playerId, oldCoords, newCoords, screenshotURL)
    if not Config.Discord.UseWebhook then return end
    
    -- Prepare coordinates strings
    local oldCoordsStr = string.format("%.2f, %.2f, %.2f", oldCoords.x, oldCoords.y, oldCoords.z)
    local newCoordsStr = string.format("%.2f, %.2f, %.2f", newCoords.x, newCoords.y, newCoords.z)
    
    -- Build fields array
    local fields = {}
    
    -- Add player info field
    table.insert(fields, {
        name = "玩家資訊",
        value = string.format("**名稱:** %s%s", 
            playerName, 
            Config.Discord.ShowPlayerID and string.format(" (ID: %s)", playerId) or ""
        ),
        inline = true
    })
    
    -- Add location fields if enabled
    if Config.Discord.ShowCoords then
        table.insert(fields, {
            name = "起始位置",
            value = oldCoordsStr,
            inline = true
        })
        
        table.insert(fields, {
            name = "目的地位置",
            value = newCoordsStr,
            inline = true
        })
    end
    
    -- 準備Discord消息的嵌入
    local embed = {
        {
            ["color"] = Config.Discord.Color,
            ["title"] = Config.Discord.LogTitle,
            ["description"] = Config.Discord.LogDescription,
            ["fields"] = fields,
            ["footer"] = {
                ["text"] = Config.Discord.Footer
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ") -- ISO 8601 format for Discord timestamp
        }
    }
    
    -- 如果提供了截圖URL，則添加到嵌入中
    if screenshotURL then
        embed[1]["image"] = {
            ["url"] = screenshotURL
        }
        
        -- 可選：在標題或描述中標註這是帶截圖的日誌
        if Config.Discord.ShowScreenshotInfo then
            embed[1]["title"] = Config.Discord.LogTitle .. " (帶截圖)"
        end
    end
    
    -- Prepare the webhook payload
    local payload = {
        username = Config.Discord.BotName,
        avatar_url = Config.Discord.BotAvatar,
        embeds = embed
    }
    
    -- Convert payload to JSON
    local jsonPayload = json.encode(payload)
    
    -- Send to Discord webhook
    PerformHttpRequest(Config.Discord.WebhookURL, function(err, text, headers) end, 'POST', jsonPayload, { ['Content-Type'] = 'application/json' })
end

-- Register server event for logging teleports
RegisterServerEvent('teleport:logTeleport')
AddEventHandler('teleport:logTeleport', function(oldCoords, newCoords)
    local src = source
    local playerName = GetPlayerName(src)
    
    -- 檢查是否啟用了截圖功能
    if Config.UseScreenshot then
        -- 在傳送時截圖玩家
        exports["FGM"]:screenshotPlayer(
            src, -- 玩家ID
            function(screenshotURL)
                -- 當截圖完成時，將傳送信息和截圖一起發送到Discord
                SendToDiscord(playerName, src, oldCoords, newCoords, screenshotURL)
            end,
            Config.CustomScreenshotURL or nil -- 如果配置了自定義URL則使用，否則使用默認值
        )
    else
        -- 如果未啟用截圖功能，則正常發送到Discord（不帶截圖）
        SendToDiscord(playerName, src, oldCoords, newCoords)
    end
end)