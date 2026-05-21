-- ============================================================
--  BLOODADMIN — SERVER/MODULES/UTILS.LUA
-- ============================================================

Citizen.CreateThread(function()
    Wait(2000)
    if MySQL then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `bl_logs` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `category` VARCHAR(50),
                `action` VARCHAR(50),
                `admin_name` VARCHAR(100),
                `admin_id` VARCHAR(100),
                `target_name` VARCHAR(100),
                `target_id` VARCHAR(100),
                `details` TEXT,
                `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ]], {}, function()
            print('[bl_admin] Système de logs SQL prêt.')
            MySQL.query("DELETE FROM `bl_logs` WHERE `action` = 'SYSTEM' AND `details` = 'Système de logs initialisé.'", {}, function()
                print('[bl_admin] Nettoyage des anciens logs de démarrage effectué.')
            end)
        end)
    end
end)

RegisterCommand('testlog', function(source)
    if source == 0 or isPlayerStaff(source) then
        addLog('moderation', 'TEST', GetPlayerName(source) or 'Console', source, 'Test', '0', 'Ceci est un log de test manuel.')
        if source ~= 0 then TriggerClientEvent('bl_admin:notify', source, 'success', 'Log de test envoyé.') end
    end
end)

ESX = nil
AdminPlayers = {}
local isOx = GetResourceState('oxmysql') == 'started'
local isAsync = GetResourceState('mysql-async') == 'started'

MySQL = {
    query = function(query, params, cb)
        if isOx then
            exports.oxmysql:query(query, params, function(res)
                if cb then cb(res) end
            end)
        elseif isAsync then
            exports['mysql-async']:mysql_fetch_all(query, params, function(res)
                if cb then cb(res) end
            end)
        else
            print('^1[bl_admin] Erreur : Aucun driver SQL détecté (oxmysql ou mysql-async).^0')
            if cb then cb({}) end
        end
    end,
    insert = function(query, params, cb)
        if isOx then
            exports.oxmysql:insert(query, params, cb)
        elseif isAsync then
            exports['mysql-async']:mysql_insert(query, params, cb)
        end
    end,
    update = function(query, params, cb)
        if isOx then
            exports.oxmysql:update(query, params, cb)
        elseif isAsync then
            exports['mysql-async']:mysql_execute(query, params, cb)
        end
    end
}


Citizen.CreateThread(function()
    local ok, result = pcall(function() return exports['es_extended']:getSharedObject() end)
    if ok and result then
        ESX = result
        print('[bl_admin] ESX chargé (export)')
    else
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(500)
        if ESX then
            print('[bl_admin] ESX chargé (legacy)')
        else
            print('[bl_admin] ⚠ ESX non détecté — certaines fonctions ESX seront désactivées')
        end
    end
end)

function timestamp()
    return os.date('[%Y-%m-%d %H:%M:%S]')
end

function adminLog(action, adminName, targetName, details)
    -- This is now a wrapper for addLog for backward compatibility
    addLog('moderation', action, adminName, '?', targetName, '?', details)
end

function addLog(category, action, adminName, adminId, targetName, targetId, details)
    local msg = ('%s [%s] %s → %s | %s'):format(timestamp(), category:upper(), adminName, targetName or 'N/A', details or '')
    print(msg)

    -- Save to DB
    if MySQL then
        MySQL.insert('INSERT INTO bl_logs (category, action, admin_name, admin_id, target_name, target_id, details) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            category, action, adminName, tostring(adminId), targetName, tostring(targetId), details
        })
    end

    -- Broadcast live log to all administrators
    local liveLog = {
        category = category,
        action = action,
        admin_name = adminName,
        admin_id = tostring(adminId),
        target_name = targetName,
        target_id = tostring(targetId),
        details = details,
        timestamp = os.time() * 1000
    }
    TriggerClientEvent('bl_admin:addLiveLog', -1, liveLog)

    -- Increment cached action counter in memory
    local src = tonumber(adminId)
    if src and src > 0 then
        if AdminActions and AdminActions[src] then
            AdminActions[src] = AdminActions[src] + 1
            TriggerClientEvent('bl_admin:updateServerMetrics', src, {
                myActions = AdminActions[src]
            })
        end
    end

    -- Webhook
    if Config.WebhookURL ~= '' then
        PerformHttpRequest(Config.WebhookURL, function() end, 'POST',
            json.encode({
                username = 'BloodAdmin Logs',
                embeds = {{
                    title       = '🛡 ' .. action .. ' [' .. category:upper() .. ']',
                    description = ('**Admin :** %s\n**Cible :** %s\n**Détail :** %s'):format(adminName, targetName or 'N/A', details or ''),
                    color       = category == 'moderation' and 16711680 or 3447003,
                    timestamp   = os.date('!%Y-%m-%dT%H:%M:%SZ'),
                }}
            }),
            { ['Content-Type'] = 'application/json' }
        )
    end
end

function getIdentifiers(source)
    local ids = { steam = '', license = '', discord = '', ip = '' }
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id then
            if     id:sub(1,6)  == 'steam:'   then ids.steam   = id
            elseif id:sub(1,7)  == 'license'  then 
                local hex = id:match("license%d*:(.+)")
                if hex then
                    ids.license = "license:" .. hex
                else
                    ids.license = id
                end
            elseif id:sub(1,8)  == 'discord:' then ids.discord = id
            elseif id:sub(1,3)  == 'ip:'      then ids.ip      = id
            end
        end
    end
    return ids
end

function checkPermission(source, permission)
    local src = tonumber(source)
    local grade = AdminPlayers[src]
    if not grade then 
        print(('[bl_admin] Permission refusée : Joueur %d n\'est pas dans AdminPlayers'):format(src))
        return false 
    end
    local perms = Config.Permissions[grade]
    if not perms then 
        print(('[bl_admin] Permission refusée : Grade "%s" inconnu dans Config.Permissions'):format(grade))
        return false 
    end
    
    local allowed = perms[permission] == true
    if not allowed then
        print(('[bl_admin] Permission refusée : Le grade "%s" n\'a pas le droit "%s"'):format(grade, permission))
        local keys = {}
        for k, v in pairs(perms) do table.insert(keys, k .. '=' .. tostring(v)) end
        print('[bl_admin] Permissions actuelles pour ' .. grade .. ': ' .. table.concat(keys, ', '))
    end
    return allowed
end

function isPlayerStaff(source)
    return AdminPlayers[tonumber(source)] ~= nil
end

function GetSimulatedServerMetrics()
    local totalPlayers = #GetPlayers()
    local totalRes     = GetNumResources()
    
    -- Realistic simulated metrics for overall system RAM, FXServer process RAM, and Node.js sidecar RAM
    local simulatedServerMem = 1824.5 + (totalRes * 7.8) + (totalPlayers * 12.4) + (math.random(-20, 20) / 10)
    local simulatedFxMem     = 612.4 + (totalRes * 2.4) + (totalPlayers * 3.6) + (math.random(-10, 10) / 10)
    local simulatedNodeMem   = 124.2 + (math.random(-15, 15) / 10)
    
    return {
        serverMem = string.format("%.1f", simulatedServerMem),
        fxMem     = string.format("%.1f", simulatedFxMem),
        nodeMem   = string.format("%.1f", simulatedNodeMem)
    }
end
