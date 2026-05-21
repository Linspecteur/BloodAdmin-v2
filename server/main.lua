-- ============================================================
--  BLOODADMIN — SERVER/MAIN.LUA
-- ============================================================

-- Ce fichier sert de point d'entrée et gère les boucles globales.
-- La logique est répartie dans le dossier server/modules/

local startTime = os.time()

-- ── Boucle métriques serveur ─────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Wait(5000)
        local totalPlayers = #GetPlayers()
        local uptime       = math.floor(GetGameTimer() / 1000)
        
        -- Calculate Global Average Ping
        local avgPing = 0
        if totalPlayers > 0 then
            local totalPing = 0
            for _, pid in ipairs(GetPlayers()) do
                totalPing = totalPing + GetPlayerPing(pid)
            end
            avgPing = math.floor(totalPing / totalPlayers)
        end
        
        -- Get simulated high-fidelity metrics
        local simulated = GetSimulatedServerMetrics()
        
        -- AdminPlayers est défini globalement dans modules/utils.lua
        if AdminPlayers then
            for src, _ in pairs(AdminPlayers) do
                TriggerClientEvent('bl_admin:updateServerMetrics', src, {
                    totalPlayers = totalPlayers,
                    serverMem    = simulated.serverMem,
                    fxMem        = simulated.fxMem,
                    nodeMem      = simulated.nodeMem,
                    ping         = GetPlayerPing(src),
                    avgPing      = avgPing,
                    staffInService = getStaffInServiceCount(),
                    uptime       = uptime,
                    -- Nouvelles données
                    totalReports = totalReportsCount or 0,
                    newPlayersToday = newPlayersTodayCount or 0
                })
            end
        end
    end
end)

print('^1[bl_admin] ^0Server Core Initialized and Modules Loaded')
