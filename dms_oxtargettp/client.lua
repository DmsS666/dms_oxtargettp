-- client.lua
local ox_target = exports.ox_target
local ox_inventory = nil
local pedEntities = {} -- 儲存所有創建的 PED 實體

-- 檢查是否有 ox_inventory
Citizen.CreateThread(function()
    if GetResourceState('ox_inventory') == 'started' then
        ox_inventory = exports.ox_inventory
    end
end)

-- 設置地圖標記
Citizen.CreateThread(function()
    if not Config.UseBlips then return end
    
    -- 為每個 PED 位置創建地圖標記
    for pedType, peds in pairs(Config.Peds) do
        for _, ped in ipairs(peds) do
            local blip = AddBlipForCoord(ped.coords)
            SetBlipSprite(blip, Config.BlipSprite)
            SetBlipColour(blip, Config.BlipColor)
            SetBlipScale(blip, Config.BlipScale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(ped.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- 建立 PEDs 作為傳送點
Citizen.CreateThread(function()
    -- 遍歷所有 PED 類型
    for pedType, peds in pairs(Config.Peds) do
        for pedIndex, ped in ipairs(peds) do
            -- 載入 PED 模型
            local pedHash = GetHashKey(ped.model)
            RequestModel(pedHash)
            while not HasModelLoaded(pedHash) do
                Citizen.Wait(1)
            end
            
            -- 建立 PED
            local npc = CreatePed(4, pedHash, ped.coords.x, ped.coords.y, ped.coords.z - 1.0, ped.heading, false, true)
            
            -- 設置 PED 屬性
            SetEntityAsMissionEntity(npc, true, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            SetPedDiesWhenInjured(npc, false)
            SetPedCanPlayAmbientAnims(npc, true)
            SetPedCanRagdollFromPlayerImpact(npc, false)
            SetEntityInvincible(npc, true)
            FreezeEntityPosition(npc, true)
            
            -- 如果有指定場景，則播放該場景
            if ped.scenario then
                TaskStartScenarioInPlace(npc, ped.scenario, 0, true)
            end
            
            -- 儲存 PED 資訊
            pedEntities[#pedEntities+1] = {
                entity = npc,
                headerText = ped.headerText or "NPC",
                subText = ped.subText or "",
                type = pedType,
                index = pedIndex
            }
            
            -- 設置 PED 的 ox_target 選項
            local targetOptions = {
                {
                    name = 'teleport_ped_' .. pedType .. '_' .. pedIndex,
                    icon = ped.icon or "fas fa-arrow-up",
                    label = ped.label,
                    onSelect = function()
                        -- 檢查是否需要物品
                        if #(ped.items or {}) > 0 and ox_inventory then
                            local hasAllItems = true
                            local missingItem = nil
                            
                            for _, item in ipairs(ped.items) do
                                local count = ox_inventory:GetItemCount(item.name)
                                if count < item.count then
                                    hasAllItems = false
                                    missingItem = item.label
                                    break
                                end
                            end
                            
                            if not hasAllItems then
                                -- 通知玩家缺少物品
                                TriggerEvent('ox_lib:notify', {
                                    title = Config.Notifications.itemRequired.title,
                                    description = string.format(Config.Notifications.itemRequired.description, missingItem),
                                    type = Config.Notifications.itemRequired.type
                                })
                                return
                            end
                        end
                        
                        -- 確定傳送目標
                        local teleportIndex = ped.teleportTo
                        if not teleportIndex or not Config.TeleportLocations[teleportIndex] then 
                            print("[ERROR] 未找到傳送位置索引: " .. tostring(teleportIndex))
                            return 
                        end
                        
                        local targetLocation = Config.TeleportLocations[teleportIndex]
                        local targetCoords = targetLocation.coords
                        local targetHeading = targetLocation.heading
                        
                        -- 執行傳送
                        TeleportPlayer(ped.coords, targetCoords, targetHeading)
                    end
                }
            }
            
            ox_target:addLocalEntity(npc, targetOptions)
        end
    end
end)

-- 處理傳送邏輯
function TeleportPlayer(fromCoords, toCoords, heading)
    -- 通知伺服器以記錄傳送
    TriggerServerEvent('teleport:logTeleport', fromCoords, toCoords)
    
    -- 播放傳送前動畫
    local playerPed = PlayerPedId()
    if Config.AnimDict and Config.AnimName then
        RequestAnimDict(Config.AnimDict)
        while not HasAnimDictLoaded(Config.AnimDict) do
            Citizen.Wait(10)
        end
        
        TaskPlayAnim(playerPed, Config.AnimDict, Config.AnimName, 8.0, -8.0, -1, 0, 0, false, false, false)
        
        -- 等待動畫播放
        Citizen.Wait(Config.AnimTime)
        ClearPedTasks(playerPed)
    end
    
    -- 畫面淡出
    DoScreenFadeOut(Config.FadeOutTime)
    Citizen.Wait(Config.TeleportDelay)
    
    -- 傳送玩家
    SetEntityCoords(playerPed, toCoords.x, toCoords.y, toCoords.z, false, false, false, false)
    SetEntityHeading(playerPed, heading)
    
    -- 等待一會後淡入畫面
    Citizen.Wait(Config.AfterTeleportDelay)
    DoScreenFadeIn(Config.FadeInTime)
    
    -- 顯示傳送通知
    TriggerEvent('ox_lib:notify', {
        title = Config.Notifications.teleported.title,
        description = Config.Notifications.teleported.description,
        type = Config.Notifications.teleported.type
    })
end

-- 繪製 3D 文字函數
function Draw3DText(x, y, z, header, text, settings)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    
    if onScreen then
        local dist = #(GetGameplayCamCoords() - vector3(x, y, z))
        
        if dist < settings.distance then
            local scale = (1 / dist) * settings.scale
            local fov = (1 / GetGameplayCamFov()) * 100
            local scale = scale * fov
            
            -- 設置文字樣式
            SetTextScale(0.0 * scale, settings.scale * scale)
            SetTextFont(settings.font)
            SetTextColour(settings.headerColor[1], settings.headerColor[2], settings.headerColor[3], settings.headerColor[4])
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextDropShadow()
            if settings.shadow then
                SetTextOutline()
            end
            SetTextCentre(true)
            
            -- 計算文字寬度和高度
            BeginTextCommandGetWidth("STRING")
            AddTextComponentString(header)
            local headerWidth = EndTextCommandGetWidth(true)
            
            BeginTextCommandGetWidth("STRING")
            AddTextComponentString(text)
            local textWidth = EndTextCommandGetWidth(true)
            
            -- 決定背景寬度
            local bgWidth = math.max(headerWidth, textWidth) + settings.backGroundMargin[1]
            
            -- 繪製背景
            if settings.backGround.enabled then
                DrawRect(_x, _y, bgWidth, 0.028 + settings.backGroundMargin[2], 
                    settings.backGround.color[1], 
                    settings.backGround.color[2], 
                    settings.backGround.color[3], 
                    settings.backGround.color[4]
                )
            end
            
            -- 繪製標題文字
            BeginTextCommandDisplayText("STRING")
            AddTextComponentString(header)
            EndTextCommandDisplayText(_x, _y - 0.007)
            
            -- 設置子文字樣式
            SetTextScale(0.0 * scale, (settings.scale - 0.1) * scale)
            SetTextColour(settings.subTextColor[1], settings.subTextColor[2], settings.subTextColor[3], settings.subTextColor[4])
            
            -- 繪製子文字
            BeginTextCommandDisplayText("STRING")
            AddTextComponentString(text)
            EndTextCommandDisplayText(_x, _y + 0.008)
        end
    end
end

-- 預加載動畫字典
Citizen.CreateThread(function()
    RequestAnimDict(Config.AnimDict)
end)

-- 顯示頭頂文本的循環
Citizen.CreateThread(function()
    if not Config.HeaderText.enable then return end
    
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local sleep = 1000 -- 默認睡眠時間
        local nearPed = false
        
        for _, pedData in ipairs(pedEntities) do
            if DoesEntityExist(pedData.entity) then
                local pedCoords = GetEntityCoords(pedData.entity)
                local distance = #(playerCoords - pedCoords)
                
                if distance < Config.HeaderText.distance then
                    nearPed = true
                    sleep = 0
                    Draw3DText(
                        pedCoords.x, 
                        pedCoords.y, 
                        pedCoords.z + Config.HeaderText.offset, 
                        pedData.headerText, 
                        pedData.subText,
                        Config.HeaderText
                    )
                end
            end
        end
        
        if nearPed then
            sleep = 0
        end
        
        Citizen.Wait(sleep)
    end
end)