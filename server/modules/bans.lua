-- ============================================================
--  BLOODADMIN — SERVER/MODULES/BANS.LUA
-- ============================================================

BanList = {}
WarnList = {}

function loadBans()
    if not MySQL then return end
    local now = os.time()
    
    -- Automatic cleanup of already expired bans on startup
    MySQL.update('DELETE FROM bl_bans WHERE expires_at > 0 AND expires_at <= ?', {now}, function()
        MySQL.query('SELECT * FROM bl_bans', {}, function(results)
            BanList = {}
            for _, row in ipairs(results or {}) do
                table.insert(BanList, {
                    id          = row.id,
                    identifiers = {
                        license = row.license,
                        steam   = row.identifier,
                        ip      = row.ip
                    },
                    name        = row.name,
                    reason      = row.reason,
                    admin       = row.admin,
                    expires     = row.expires_at
                })
            end
            print(('[bl_admin] %d bans chargés.'):format(#BanList))
        end)
    end)
end

function loadWarns()
    if not MySQL then return end
    MySQL.query('SELECT * FROM bl_warns ORDER BY created_at DESC', {}, function(results)
        WarnList = {}
        for _, row in ipairs(results or {}) do
            table.insert(WarnList, {
                id        = row.id,
                name      = row.player_name or 'Inconnu',
                reason    = row.reason,
                admin     = row.admin,
                timestamp = row.created_at
            })
        end
        print(('[bl_admin] %d warns chargés.'):format(#WarnList))
    end)
end

Citizen.CreateThread(function()
    Wait(1000)
    if MySQL then
        -- Ensure bl_warns has name field
        MySQL.query([[
            ALTER TABLE `bl_warns` ADD COLUMN IF NOT EXISTS `player_name` VARCHAR(100) DEFAULT 'Inconnu';
        ]])

        loadBans()
        loadWarns()
    end
end)

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(10)

    local ids = getIdentifiers(src)
    local now = os.time()
    local isBanned = false
    local activeBan = nil

    for i = #BanList, 1, -1 do
        local ban = BanList[i]
        local match = false
        if ban.identifiers.license ~= '' and (ban.identifiers.license == ids.license or ban.identifiers.license == ids.steam) then match = true end
        if ban.identifiers.steam   ~= '' and (ban.identifiers.steam   == ids.steam   or ban.identifiers.steam   == ids.license) then match = true end
        if ban.identifiers.ip      ~= '' and ban.identifiers.ip      == ids.ip      then match = true end

        if match then
            if ban.expires == 0 or ban.expires > now then
                isBanned = true
                activeBan = ban
                break
            else
                -- Ban has expired! Let's delete it from database and memory list
                MySQL.update('DELETE FROM bl_bans WHERE id = ?', {ban.id})
                table.remove(BanList, i)
                -- Sync to all admins
                for adminSrc, _ in pairs(AdminPlayers) do
                    TriggerClientEvent('bl_admin:updateBans', adminSrc, BanList)
                end
            end
        end
    end

    if isBanned and activeBan then
        local expireStr = activeBan.expires == 0 and 'Permanent' or os.date('%d/%m/%Y %H:%M', activeBan.expires)
        deferrals.done(('\n🚫 Vous êtes banni de ce serveur.\n\nRaison : %s\nExpire : %s\nAdmin : %s'):format(activeBan.reason, expireStr, activeBan.admin))
        return
    end

    deferrals.done()
end)

RegisterNetEvent('bl_admin:banPlayer')
AddEventHandler('bl_admin:banPlayer', function(targetId, reason, durationSeconds)
    local src = source
    if not checkPermission(src, 'bl.ban') then return end

    local ids = getIdentifiers(targetId)
    local targetName = GetPlayerName(targetId)
    local adminName = GetPlayerName(src)
    local expires = 0
    if durationSeconds and durationSeconds > 0 then expires = os.time() + durationSeconds end

    -- Insert into DB
    MySQL.insert('INSERT INTO bl_bans (identifier, license, ip, name, reason, admin, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        ids.steam, ids.license, ids.ip, targetName, reason, adminName, expires
    }, function(id)
        if loadBans then
            loadBans()
            Wait(100)
            for adminSrc, _ in pairs(AdminPlayers) do
                TriggerClientEvent('bl_admin:updateBans', adminSrc, BanList)
            end
        else
            table.insert(BanList, {
                id          = id or 999,
                identifiers = ids,
                name        = targetName,
                reason      = reason,
                admin       = adminName,
                expires     = expires
            })
            for adminSrc, _ in pairs(AdminPlayers) do
                TriggerClientEvent('bl_admin:updateBans', adminSrc, BanList)
            end
        end
    end)

    addLog('moderation', 'BAN', adminName, src, targetName, targetId, reason)
    DropPlayer(targetId, ('[BAN] %s\nExpire : %s\nAdmin : %s'):format(reason, (expires == 0 and 'Permanent' or os.date('%d/%m/%Y %H:%M', expires)), adminName))
    TriggerClientEvent('bl_admin:notify', src, 'success', 'Joueur banni avec succès.')
end)

RegisterNetEvent('bl_admin:unbanPlayer')
AddEventHandler('bl_admin:unbanPlayer', function(id)
    local src = source
    if not checkPermission(src, 'bl.ban') then return end

    MySQL.update('DELETE FROM bl_bans WHERE id = ?', {id}, function(rowsChanged)
        if rowsChanged > 0 then
            for i, ban in ipairs(BanList) do
                if ban.id == id then
                    table.remove(BanList, i)
                    break
                end
            end
            
            -- Sync to all admins
            for adminSrc, _ in pairs(AdminPlayers) do
                TriggerClientEvent('bl_admin:updateBans', adminSrc, BanList)
            end
            
            addLog('moderation', 'UNBAN', GetPlayerName(src), src, 'Banni ID: ' .. id, 0, 'Joueur débanni manuellement')
            TriggerClientEvent('bl_admin:notify', src, 'success', 'Joueur débanni.')
        end
    end)
end)

RegisterNetEvent('bl_admin:revokeWarn')
AddEventHandler('bl_admin:revokeWarn', function(warnId)
    local src = source
    if not checkPermission(src, 'bl.warn') then return end

    MySQL.update('DELETE FROM bl_warns WHERE id = ?', {warnId}, function(rowsChanged)
        if rowsChanged > 0 then
            loadWarns() -- Reload
            Wait(100)
            -- Sync to all admins
            for adminSrc, _ in pairs(AdminPlayers) do
                TriggerClientEvent('bl_admin:updateWarns', adminSrc, WarnList)
            end
            addLog('moderation', 'REVOKE_WARN', GetPlayerName(src), src, 'Warn ID: ' .. warnId, 0, 'Avertissement révoqué')
            TriggerClientEvent('bl_admin:notify', src, 'success', 'Avertissement révoqué.')
        end
    end)
end)

RegisterNetEvent('bl_admin:requestSanctions')
AddEventHandler('bl_admin:requestSanctions', function()
    local src = source
    if not AdminPlayers[src] then return end
    TriggerClientEvent('bl_admin:updateBans', src, BanList)
    TriggerClientEvent('bl_admin:updateWarns', src, WarnList)
    if ActiveJails then TriggerClientEvent('bl_admin:updateJails', src, ActiveJails) end
    if ActiveGhosts then TriggerClientEvent('bl_admin:updateGhosts', src, ActiveGhosts) end
end)

RegisterNetEvent('bl_admin:banOfflinePlayer')
AddEventHandler('bl_admin:banOfflinePlayer', function(data)
    local src = source
    if not checkPermission(src, 'bl.ban') or not checkPermission(src, 'bl.offlinemod') then return end

    local targetIdentifier = data.identifier
    local playerName = data.playerName or 'Joueur Hors-ligne'
    local reason = data.reason or 'Aucun motif'
    local durationSeconds = tonumber(data.duration) or 0
    
    local adminName = GetPlayerName(src)
    local expires = 0
    if durationSeconds and durationSeconds > 0 then expires = os.time() + durationSeconds end

    local ids = { steam = '', license = '', ip = '' }
    if string.sub(targetIdentifier, 1, 8) == 'license:' then
        ids.license = targetIdentifier
    elseif string.sub(targetIdentifier, 1, 6) == 'steam:' then
        ids.steam = targetIdentifier
    else
        ids.steam = targetIdentifier
        ids.license = targetIdentifier
    end

    -- Insert into DB
    MySQL.insert('INSERT INTO bl_bans (identifier, license, ip, name, reason, admin, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        ids.steam, ids.license, '', playerName, reason, adminName, expires
    }, function(id)
        if loadBans then
            loadBans()
            Wait(100)
            for adminSrc, _ in pairs(AdminPlayers) do
                TriggerClientEvent('bl_admin:updateBans', adminSrc, BanList)
            end
        else
            table.insert(BanList, {
                id          = id or 999,
                identifiers = ids,
                name        = playerName,
                reason      = reason,
                admin       = adminName,
                expires     = expires
            })
            for adminSrc, _ in pairs(AdminPlayers) do
                TriggerClientEvent('bl_admin:updateBans', adminSrc, BanList)
            end
        end
    end)

    addLog('moderation', 'OFFLINE_BAN', adminName, src, playerName, 'OFFLINE', reason)
    TriggerClientEvent('bl_admin:notify', src, 'success', 'Joueur hors-ligne banni avec succès.')
end)
