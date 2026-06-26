local CursorManager = require("src.cursor")
local WinampClass = require("src.winamp")
local MyPCClass = require("src.mypc")
local ExplorerClass = require("src.explorer")
local NotepadClass = require("src.notepad")
local TrabajoClass = require("src.trabajo")
local EmailClass = require("src.email")
local RecycleBinClass = require("src.recyclebin")
local PersonalClass = require("src.personal")
local AchievementsClass = require("src.achievements")
local CodingClass = require("src.coding")

local gameState = "boot"
local bsodTimer = 0
local bsodActive = false
local malwarePopupTimer = 0
local malwarePopupDuration = 3.0
local installTimer = 0
local installDuration = 3.0
local installActive = false
local installSound = nil
local projectPopupActive = false
local projectPopupTimer = 0
local projectPopupDuration = 3.0
local projectPopupSound = nil
local bsodSound = nil
local bootSound = nil
local clickSounds = {}
local startupSound = nil
local errorSound = nil
local biosLogo = nil
local energyLogo = nil
local bootFont = nil
local defaultFont = nil
local desktopBg = nil
local shader = nil
local CURVATURE = 0.02
local mainCanvas = nil
winamp = nil
mypc = nil
explorer = nil
notepad = nil
trabajo = nil
email = nil
recyclebin = nil
personal = nil
achievements = nil
coding = nil

local keyboardSounds = {}
local currentKeyboard = 1
local keyboardNames = {
    "NK Cream (original by Ryan)",
}

pcStats = {
    cpu = "Intel Pentium 75MHz",
    ram = "16 MB",
    ramNum = 16,
    disk = "850 MB HDD",
    display = "Standard PCI Graphics Adapter (VGA)",
    cooling = "Disipador basico",
    bios = "American Megatrends  12/01/94",
    os = "Microsoft Windows 95  4.00.950",
}

bootLines = {
    {text = "American  Megatrends  Released: 12/01/94", x = 80, y = 20, color = {0.8, 0.8, 0.8}},
    {text = "             AMIBIOS (C)1994 American Megatrends Inc..", x = 80, y = 40, color = {0.8, 0.8, 0.8}},
    {text = "", x = 80, y = 60, color = {0.8, 0.8, 0.8}},
    {text = "BCN SIT 1989-1994 Special UC612C", x = 80, y = 80, color = {0.8, 0.8, 0.8}},
    {text = "SIT Rehab(tm) XX 115", x = 80, y = 100, color = {0.8, 0.8, 0.8}},
    {text = "CPU: " .. pcStats.cpu, x = 80, y = 120, color = {0.8, 0.8, 0.8}},
    {text = "RAM: Checking " .. pcStats.ram .. " ... OK", x = 80, y = 140, color = {0.8, 0.8, 0.8}},
    {text = "HDD: " .. pcStats.disk, x = 80, y = 160, color = {0.8, 0.8, 0.8}},
    {text = "Video: " .. pcStats.display, x = 80, y = 180, color = {0.8, 0.8, 0.8}},
    {text = "Cooling: " .. pcStats.cooling, x = 80, y = 200, color = {0.8, 0.8, 0.8}},
    {text = "", x = 80, y = 220, color = {0.8, 0.8, 0.8}},
    {text = "WAIT...", x = 80, y = 240, color = {0.8, 0.8, 0.8}},
}
bottomLines = {
    "Press DEL to enter SETUP , ESC to skip memory test",
    "08/06/2011-Soon-in-Tokyo-Rehab-Studio"
}

bootLineIndex = 0
bootCharIndex = 0
bootDone = false
bootLineDelay = 0.15
bootCharDelay = 0.02
bootTimerAccum = 0
showAllLines = false
showBottom = false

countdownActive = false
countdownValue = 3
countdownTimer = 0

startMenuOpen = false
saveMessage = ""
saveMessageTimer = 0

popupActive = false
popupType = nil
popupSelectedSlot = 1
popupConfirmStep = 0
lastClickTime = 0
doubleClickTime = 0.4
taskbarApps = {}
winampMusic2 = nil
firstBootDone = false

iconImages = {}
winampMusic = nil

dynamicIcons = {}
local dynamicIconOrder = {}

local function addDynamicIcon(id, label, icon, x, y, iconScale)
    dynamicIcons[id] = {label = label, icon = icon, x = x, y = y, iconScale = iconScale, active = false}
    table.insert(dynamicIconOrder, id)
end

local function activateDynamicIcon(id)
    if dynamicIcons[id] then
        dynamicIcons[id].active = true
    end
end

addDynamicIcon("explorer", "Internet Explorer", "explorer", 40, 140, nil)
addDynamicIcon("winamp", "Winamp", "winamp", 40, 240, nil)
addDynamicIcon("notepad", "Objetivos", "text", 140, 140, nil)
addDynamicIcon("personal", "Personal", "staff", 240, 240, nil)
addDynamicIcon("coding", "Coding", "coding", 340, 240, nil)
addDynamicIcon("download", "WinOptimizer", "download", 340, 40, nil)

baseDesktopIcons = {
    {label = "Mi PC", icon = "mypc"},
    {label = "Trabajo", icon = "trabajo", iconScale = 1.4},
    {label = "Correo", icon = "email", iconScale = 1.4},
    {label = "Papelera", icon = "recyclebin"},
}

local function getDesktopIcons()
    local all = {}
    for _, icon in ipairs(baseDesktopIcons) do
        table.insert(all, icon)
    end
    for _, id in ipairs(dynamicIconOrder) do
        local dIcon = dynamicIcons[id]
        if dIcon and dIcon.active then
            table.insert(all, {label = dIcon.label, icon = dIcon.icon, iconScale = dIcon.iconScale})
        end
    end
    local icons = {}
    for i, icon in ipairs(all) do
        local col = math.floor((i - 1) / 9)
        local row = (i - 1) % 9
        local def = {label = icon.label, icon = icon.icon, x = 40 + col * 100, y = 40 + row * 100}
        if icon.iconScale then def.iconScale = icon.iconScale end
        table.insert(icons, def)
    end
    return icons
end

local desktopIcons = getDesktopIcons()
local W95 = {
    bg = {0.75, 0.75, 0.75},
    titleActive = {0.0, 0.0, 0.5},
    highlight = {0, 0, 0.5},
    highlightText = {1, 1, 1},
    fieldBg = {1, 1, 1},
    fieldText = {0, 0, 0},
    borderLight = {1, 1, 1},
    borderDark = {0.5, 0.5, 0.5},
    borderUltra = {0.25, 0.25, 0.25},
    borderInner = {0.7, 0.7, 0.7},
    desktopBg = {0, 0, 0.5},
    iconText = {1, 1, 1},
}

function playClick()
    if #clickSounds > 0 then
        local snd = clickSounds[math.random(#clickSounds)]
        snd:stop()
        snd:play()
    end
end

function playWin95Error()
    if errorSound then
        errorSound:stop()
        errorSound:play()
    end
end

function triggerMalware()
    gameState = "malware_popup"
    malwarePopupTimer = 0
    playWin95Error()

    if winamp and winamp.music then
        winamp.music:stop()
    end

    if trabajo then
        if trabajo.activeProject then
            trabajo:failProject()
        end
        local loss = math.floor(trabajo.money * 0.8)
        trabajo.money = math.max(0, trabajo.money - loss)
        trabajo.malwareLossMessage = "Equipo danado por malware. Reparaciones: -$" .. loss
        trabajo.malwareLossTimer = 5.0
    end
end

function triggerHardwareInstall()
    installActive = true
    installTimer = 0
    if installSound then
        installSound:stop()
        installSound:play()
    end
end

function drawBSOD()
    local w, h = love.graphics.getDimensions()
    local margin = 80

    love.graphics.setColor(0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print("Windows", margin, h * 0.12)

    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.print("Un error irrecoverable ha occurrido.", margin, h * 0.22)
    love.graphics.print("Se ha producido un error y Windows", margin, h * 0.27)
    love.graphics.print("ha de cerrarse para evitar daño al equipo.", margin, h * 0.32)
    love.graphics.print(" ", margin, h * 0.37)
    love.graphics.print("ERROR: 0E : 016F : BFF9B3D4", margin, h * 0.42)
    love.graphics.print(" KERNEL32.DLL", margin, h * 0.47)
    love.graphics.print(" ", margin, h * 0.52)
    love.graphics.print("* Presione cualquier tecla para terminar", margin, h * 0.58)
    love.graphics.print("  la sesion actual.", margin, h * 0.63)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("Informacion de depuracion:", margin, h * 0.75)
    love.graphics.print("  Filtros=00000001 Dispositivo=00000000", margin, h * 0.79)
    love.graphics.print("  Carga de la direccion de comandos no disponible", margin, h * 0.83)
end

function drawMalwarePopup()
    local w, h = love.graphics.getDimensions()
    local popupW = 420
    local popupH = 180
    local popupX = (w - popupW) / 2
    local popupY = (h - popupH) / 2

    love.graphics.setColor(0.75, 0.75, 0.75)
    love.graphics.rectangle("fill", popupX, popupY, popupW, popupH)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", popupX + 2, popupY + 2, popupW - 4, popupH - 4)

    love.graphics.setColor(0, 0, 0.5)
    love.graphics.rectangle("fill", popupX + 2, popupY + 2, popupW - 4, 20)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("Error", popupX + 8, popupY + 5)

    local iconX = popupX + 25
    local iconY = popupY + 35
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", iconX + 16, iconY + 16, 14)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", iconX + 16, iconY + 16, 12)
    love.graphics.setColor(1, 0, 0)
    love.graphics.setLineWidth(3)
    love.graphics.line(iconX + 8, iconY + 8, iconX + 24, iconY + 24)
    love.graphics.line(iconX + 24, iconY + 8, iconX + 8, iconY + 24)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Su equipo ha sido infectado por malware.", popupX + 60, popupY + 40)
    love.graphics.print("Windows va a cerrarse para evitar daño.", popupX + 60, popupY + 60)

    love.graphics.setColor(0.75, 0.75, 0.75)
    love.graphics.rectangle("fill", popupX + popupW - 85, popupY + popupH - 35, 75, 23)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", popupX + popupW - 83, popupY + popupH - 33, 71, 19)

    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Aceptar", popupX + popupW - 65, popupY + popupH - 28)

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", popupX, popupY, popupW, popupH)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", popupX + 1, popupY + 1, popupW - 2, popupH - 2)
end

function triggerProjectPopup()
    projectPopupActive = true
    projectPopupTimer = 0
    if projectPopupSound then
        projectPopupSound:stop()
        projectPopupSound:play()
    end
end

function drawProjectPopup()
    local w, h = love.graphics.getDimensions()
    local popupW = 420
    local popupH = 180
    local popupX = (w - popupW) / 2
    local popupY = (h - popupH) / 2

    love.graphics.setColor(0.75, 0.75, 0.75)
    love.graphics.rectangle("fill", popupX, popupY, popupW, popupH)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", popupX + 2, popupY + 2, popupW - 4, popupH - 4)

    love.graphics.setColor(0, 0, 0.5)
    love.graphics.rectangle("fill", popupX + 2, popupY + 2, popupW - 4, 20)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("Aviso", popupX + 8, popupY + 5)

    local iconX = popupX + 25
    local iconY = popupY + 35
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", iconX + 16, iconY + 16, 14)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(3)
    love.graphics.line(iconX + 16, iconY + 6, iconX + 16, iconY + 14)
    love.graphics.circle("fill", iconX + 16, iconY + 20, 2)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Ya tiene un proyecto en curso.", popupX + 60, popupY + 40)
    love.graphics.print("Complete o cancele el proyecto actual", popupX + 60, popupY + 60)
    love.graphics.print("antes de aceptar uno nuevo.", popupX + 60, popupY + 80)

    love.graphics.setColor(0.75, 0.75, 0.75)
    love.graphics.rectangle("fill", popupX + popupW - 85, popupY + popupH - 35, 75, 23)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", popupX + popupW - 83, popupY + popupH - 33, 71, 19)

    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Aceptar", popupX + popupW - 65, popupY + popupH - 28)

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", popupX, popupY, popupW, popupH)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", popupX + 1, popupY + 1, popupW - 2, popupH - 2)
end

local function getSaveSlotPath(slot)
    return "save_slot_" .. slot .. ".lua"
end

local function getSaveSlotInfo(slot)
    local path = getSaveSlotPath(slot)
    if not love.filesystem.getInfo(path) then
        return nil
    end
    local content = love.filesystem.read(path)
    if not content then return nil end
    local chunk = load("return " .. content)
    if not chunk then return nil end
    local ok, data = pcall(chunk)
    if not ok then return nil end
    return data
end

function drawSaveLoadPopup()
    local w, h = love.graphics.getDimensions()
    local popupW = 400
    local popupH = 300
    local popupX = (w - popupW) / 2
    local popupY = (h - popupH) / 2

    love.graphics.setColor(0.75, 0.75, 0.75)
    love.graphics.rectangle("fill", popupX, popupY, popupW, popupH)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", popupX + 2, popupY + 2, popupW - 4, popupH - 4)

    love.graphics.setColor(0, 0, 0.5)
    love.graphics.rectangle("fill", popupX + 2, popupY + 2, popupW - 4, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))

    local title = "Guardar partida"
    if popupType == "load" then title = "Cargar partida"
    elseif popupType == "newgame" then title = "Nueva partida" end
    love.graphics.print(title, popupX + 8, popupY + 5)

    if popupType == "newgame" then
        love.graphics.setColor(0, 0, 0)
        if popupConfirmStep == 1 then
            love.graphics.printf("¿Estas seguro de que quieres\nempezar una nueva partida?", popupX + 20, popupY + 50, popupW - 40, "center")
            love.graphics.printf("Se perderan todos los datos\nguardados.", popupX + 20, popupY + 90, popupW - 40, "center")
        else
            love.graphics.printf("¿REALMENTE quieres empezar\nde nuevo?", popupX + 20, popupY + 50, popupW - 40, "center")
            love.graphics.printf("Esta accion no se puede deshacer.", popupX + 20, popupY + 90, popupW - 40, "center")
        end

        local btnW = 80
        local btnH = 24
        local btnY = popupY + popupH - 45

        love.graphics.setColor(0.75, 0.75, 0.75)
        love.graphics.rectangle("fill", popupX + 40, btnY, btnW, btnH)
        love.graphics.setColor(0, 0.5, 0)
        love.graphics.printf("Si", popupX + 40, btnY + 5, btnW, "center")

        love.graphics.setColor(0.75, 0.75, 0.75)
        love.graphics.rectangle("fill", popupX + popupW - 120, btnY, btnW, btnH)
        love.graphics.setColor(0.5, 0, 0)
        love.graphics.printf("No", popupX + popupW - 120, btnY + 5, btnW, "center")
    else
        love.graphics.setColor(0, 0, 0)
        love.graphics.print("Selecciona un slot:", popupX + 20, popupY + 30)

        for i = 1, 3 do
            local slotY = popupY + 55 + (i - 1) * 55
            local slotW = popupW - 40
            local slotH = 45

            if i == popupSelectedSlot then
                love.graphics.setColor(0.8, 0.85, 1.0)
            else
                love.graphics.setColor(0.9, 0.9, 0.9)
            end
            love.graphics.rectangle("fill", popupX + 20, slotY, slotW, slotH)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("line", popupX + 20, slotY, slotW, slotH)

            love.graphics.setColor(0, 0, 0)
            love.graphics.print("Slot " .. i, popupX + 30, slotY + 5)

            local info = getSaveSlotInfo(i)
            if info then
                local money = info.trabajo and info.trabajo.money or 0
                local tasks = info.trabajo and info.trabajo.tasksCompleted or 0
                love.graphics.setColor(0.3, 0.3, 0.3)
                love.graphics.print("$" .. money .. " | " .. tasks .. " tareas", popupX + 30, slotY + 22)
            else
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.print("[Vacio]", popupX + 30, slotY + 22)
            end
        end

        local btnW = 100
        local btnH = 24
        local btnY = popupY + popupH - 40

        if popupConfirmStep == 0 then
            love.graphics.setColor(0.75, 0.75, 0.75)
            love.graphics.rectangle("fill", popupX + 20, btnY, btnW, btnH)
            love.graphics.setColor(0, 0.5, 0)
            love.graphics.printf(popupType == "save" and "Guardar" or "Cargar", popupX + 20, btnY + 5, btnW, "center")

            love.graphics.setColor(0.75, 0.75, 0.75)
            love.graphics.rectangle("fill", popupX + popupW - 120, btnY, btnW, btnH)
            love.graphics.setColor(0.5, 0, 0)
            love.graphics.printf("Cancelar", popupX + popupW - 120, btnY + 5, btnW, "center")
        else
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf("¿Confirmar?", popupX + 20, btnY - 25, popupW - 40, "center")

            love.graphics.setColor(0.75, 0.75, 0.75)
            love.graphics.rectangle("fill", popupX + 20, btnY, btnW, btnH)
            love.graphics.setColor(0, 0.5, 0)
            love.graphics.printf("Si", popupX + 20, btnY + 5, btnW, "center")

            love.graphics.setColor(0.75, 0.75, 0.75)
            love.graphics.rectangle("fill", popupX + popupW - 120, btnY, btnW, btnH)
            love.graphics.setColor(0.5, 0, 0)
            love.graphics.printf("No", popupX + popupW - 120, btnY + 5, btnW, "center")
        end
    end

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", popupX, popupY, popupW, popupH)
end

function drawInstallScreen()
    local w, h = love.graphics.getDimensions()
    local alpha = 1.0
    local fadeTime = 0.4
    if installTimer < fadeTime then
        alpha = installTimer / fadeTime
    elseif installTimer > installDuration - fadeTime then
        alpha = (installDuration - installTimer) / fadeTime
    end
    alpha = math.max(0, math.min(1, alpha))

    if shader then
        shader:send("screen_size", {w, h})
        shader:send("time", love.timer.getTime())
        shader:send("curvature", CURVATURE)
        love.graphics.setShader(shader)
    end

    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1, 1, 1, alpha)
    local prevFont = love.graphics.getFont()
    local bigFont = love.graphics.newFont(24)
    love.graphics.setFont(bigFont)
    love.graphics.printf("Instalando hardware...", 0, h / 2 - 30, w, "center")
    love.graphics.setFont(prevFont)

    love.graphics.setShader(nil)
end

function openApp(appId)
    if appId == "winamp" and winamp then
        if winamp.window.visible and winamp.window.minimized then
            winamp.window.minimized = false
        elseif not winamp.window.visible then
            winamp:toggleVisible()
        end
    elseif appId == "mypc" and mypc then
        if mypc.window.visible and mypc.window.minimized then
            mypc.window.minimized = false
        elseif not mypc.window.visible then
            mypc:toggleVisible()
        end
    elseif appId == "explorer" and explorer then
        if explorer.window.visible and explorer.window.minimized then
            explorer.window.minimized = false
        elseif not explorer.window.visible then
            explorer:toggleVisible()
        end
    elseif appId == "notepad" and notepad then
        if notepad.window.visible and notepad.window.minimized then
            notepad.window.minimized = false
        elseif not notepad.window.visible then
            notepad:toggleVisible()
        end
    elseif appId == "trabajo" and trabajo then
        if trabajo.window.visible and trabajo.window.minimized then
            trabajo.window.minimized = false
        elseif not trabajo.window.visible then
            trabajo:toggleVisible()
        end
    elseif appId == "email" and email then
        if email.window.visible and email.window.minimized then
            email.window.minimized = false
        elseif not email.window.visible then
            email:toggleVisible()
        end
    elseif appId == "recyclebin" and recyclebin then
        if recyclebin.window.visible and recyclebin.window.minimized then
            recyclebin.window.minimized = false
        elseif not recyclebin.window.visible then
            recyclebin:toggleVisible()
        end
    elseif appId == "personal" and personal then
        if personal.window.visible and personal.window.minimized then
            personal.window.minimized = false
        elseif not personal.window.visible then
            personal:toggleVisible()
        end
    elseif appId == "achievements" and achievements then
        if achievements.window.visible and achievements.window.minimized then
            achievements.window.minimized = false
        elseif not achievements.window.visible then
            achievements:toggleVisible()
        end
    elseif appId == "coding" and coding then
        if coding.window.visible and coding.window.minimized then
            coding.window.minimized = false
        elseif not coding.window.visible then
            coding:toggleVisible()
        end
    end
    updateTaskbar()
end

function closeApp(appId)
    if appId == "winamp" and winamp then
        winamp.window.visible = false
    elseif appId == "mypc" and mypc then
        mypc.window.visible = false
    elseif appId == "explorer" and explorer then
        explorer.window.visible = false
    elseif appId == "notepad" and notepad then
        notepad.window.visible = false
    elseif appId == "trabajo" and trabajo then
        trabajo.window.visible = false
    elseif appId == "email" and email then
        email.window.visible = false
    elseif appId == "recyclebin" and recyclebin then
        recyclebin.window.visible = false
    elseif appId == "personal" and personal then
        personal.window.visible = false
    elseif appId == "achievements" and achievements then
        achievements.window.visible = false
    elseif appId == "coding" and coding then
        coding.window.visible = false
    end
    updateTaskbar()
end

local windowOrder = {"winamp", "mypc", "explorer", "notepad", "trabajo", "particular", "email", "recyclebin", "personal", "achievements", "coding"}

local function bringToFront(appId)
    for i, id in ipairs(windowOrder) do
        if id == appId then
            table.remove(windowOrder, i)
            table.insert(windowOrder, appId)
            break
        end
    end
end

function getNextCascadePosition(w, h)
    local cascadeOffset = 24
    local screenW, screenH = love.graphics.getDimensions()
    local taskbarH = 40
    local visibleWindows = {}

    local apps = {winamp, mypc, explorer, trabajo, email, notepad, recyclebin, personal, achievements}
    for _, app in ipairs(apps) do
        if app and app.window.visible and not app.window.minimized then
            table.insert(visibleWindows, {
                x = app.window.x,
                y = app.window.y,
                w = app.window.w,
                h = app.window.h,
            })
        end
    end

    if #visibleWindows == 0 then
        return 80, 60
    end

    local lastWin = visibleWindows[#visibleWindows]
    local newX = lastWin.x + cascadeOffset
    local newY = lastWin.y + cascadeOffset

    if newX + w > screenW - 10 then
        newX = 80
    end
    if newY + h > screenH - taskbarH - 10 then
        newY = 60
    end

    return newX, newY
end

function closeAllWindows()
    local apps = {winamp, mypc, explorer, notepad, trabajo, email, recyclebin, personal, achievements, coding}
    for _, app in ipairs(apps) do
        if app then
            app.window.visible = false
            app.window.minimized = false
        end
    end
    if trabajo and trabajo.particularWindow then
        trabajo.particularWindow.visible = false
        trabajo.particularWindow.minimized = false
    end
    startMenuOpen = false
    updateTaskbar()
end

function toggleApp(appId)
    if appId == "winamp" and winamp then
        if not winamp.window.visible then
            winamp.window.x, winamp.window.y = getNextCascadePosition(winamp.window.w, winamp.window.h)
            winamp:toggleVisible()
            bringToFront("winamp")
        elseif winamp.window.minimized then
            winamp.window.minimized = false
            bringToFront("winamp")
        else
            winamp.window.minimized = true
        end
    elseif appId == "mypc" and mypc then
        if not mypc.window.visible then
            mypc.window.x, mypc.window.y = getNextCascadePosition(mypc.window.w, mypc.window.h)
            mypc:toggleVisible()
            bringToFront("mypc")
        elseif mypc.window.minimized then
            mypc.window.minimized = false
            bringToFront("mypc")
        else
            mypc.window.minimized = true
        end
    elseif appId == "explorer" and explorer then
        if not explorer.window.visible then
            explorer.window.x, explorer.window.y = getNextCascadePosition(explorer.window.w, explorer.window.h)
            explorer:toggleVisible()
            bringToFront("explorer")
        elseif explorer.window.minimized then
            explorer.window.minimized = false
            bringToFront("explorer")
        else
            explorer.window.minimized = true
        end
    elseif appId == "notepad" and notepad then
        if not notepad.window.visible then
            notepad.window.x, notepad.window.y = getNextCascadePosition(notepad.window.w, notepad.window.h)
            notepad:toggleVisible()
            bringToFront("notepad")
        elseif notepad.window.minimized then
            notepad.window.minimized = false
            bringToFront("notepad")
        else
            notepad.window.minimized = true
        end
    elseif appId == "trabajo" and trabajo then
        if not trabajo.window.visible then
            trabajo.window.x, trabajo.window.y = getNextCascadePosition(trabajo.window.w, trabajo.window.h)
            trabajo:toggleVisible()
            bringToFront("trabajo")
        elseif trabajo.window.minimized then
            trabajo.window.minimized = false
            bringToFront("trabajo")
        else
            trabajo.window.minimized = true
        end
    elseif appId == "particular" and trabajo then
        if not trabajo.particularWindow.visible then
            trabajo.particularWindow.visible = true
            bringToFront("particular")
        elseif trabajo.particularWindow.minimized then
            trabajo.particularWindow.minimized = false
            bringToFront("particular")
        else
            trabajo.particularWindow.minimized = true
        end
    elseif appId == "email" and email then
        if not email.window.visible then
            email.window.x, email.window.y = getNextCascadePosition(email.window.w, email.window.h)
            email:toggleVisible()
            bringToFront("email")
        elseif email.window.minimized then
            email.window.minimized = false
            bringToFront("email")
        else
            email.window.minimized = true
        end
    elseif appId == "recyclebin" and recyclebin then
        if not recyclebin.window.visible then
            recyclebin.window.x, recyclebin.window.y = getNextCascadePosition(recyclebin.window.w, recyclebin.window.h)
            recyclebin:toggleVisible()
            bringToFront("recyclebin")
        elseif recyclebin.window.minimized then
            recyclebin.window.minimized = false
            bringToFront("recyclebin")
        else
            recyclebin.window.minimized = true
        end
    elseif appId == "personal" and personal then
        if not personal.window.visible then
            personal.window.x, personal.window.y = getNextCascadePosition(personal.window.w, personal.window.h)
            personal:toggleVisible()
            bringToFront("personal")
        elseif personal.window.minimized then
            personal.window.minimized = false
            bringToFront("personal")
        else
            personal.window.minimized = true
        end
    elseif appId == "achievements" and achievements then
        if not achievements.window.visible then
            achievements.window.x, achievements.window.y = getNextCascadePosition(achievements.window.w, achievements.window.h)
            achievements:toggleVisible()
            bringToFront("achievements")
        elseif achievements.window.minimized then
            achievements.window.minimized = false
            bringToFront("achievements")
        else
            achievements.window.minimized = true
        end
    elseif appId == "coding" and coding then
        if not coding.window.visible then
            coding.window.x, coding.window.y = getNextCascadePosition(coding.window.w, coding.window.h)
            coding:toggleVisible()
            bringToFront("coding")
        elseif coding.window.minimized then
            coding.window.minimized = false
            bringToFront("coding")
        else
            coding.window.minimized = true
        end
    end
    updateTaskbar()
end

function updateTaskbar()
    taskbarApps = {}
    if winamp and winamp.window.visible then
        table.insert(taskbarApps, {id = "winamp", label = "Winamp"})
    end
    if mypc and mypc.window.visible then
        table.insert(taskbarApps, {id = "mypc", label = "Mi PC"})
    end
    if explorer and explorer.window.visible then
        table.insert(taskbarApps, {id = "explorer", label = "Internet Explorer"})
    end
    if trabajo and trabajo.window.visible then
        table.insert(taskbarApps, {id = "trabajo", label = "Trabajo"})
    end
    if trabajo and trabajo.particularWindow.visible then
        table.insert(taskbarApps, {id = "particular", label = "Proyecto"})
    end
    if email and email.window.visible then
        table.insert(taskbarApps, {id = "email", label = "Correo"})
    end
    if recyclebin and recyclebin.window.visible then
        table.insert(taskbarApps, {id = "recyclebin", label = "Papelera"})
    end
    if notepad and notepad.window.visible then
        table.insert(taskbarApps, {id = "notepad", label = "Objetivos"})
    end
    if personal and personal.window.visible then
        table.insert(taskbarApps, {id = "personal", label = "Personal"})
    end
    if achievements and achievements.window.visible then
        table.insert(taskbarApps, {id = "achievements", label = "Logros"})
    end
    if coding and coding.window.visible then
        table.insert(taskbarApps, {id = "coding", label = "Coding"})
    end
end

local function serialize(o)
    if type(o) == "number" then
        return tostring(o)
    elseif type(o) == "string" then
        return string.format("%q", o)
    elseif type(o) == "boolean" then
        return tostring(o)
    elseif type(o) == "table" then
        local s = "{\n"
        for k, v in pairs(o) do
            if type(k) == "number" then
                s = s .. "[" .. k .. "] = " .. serialize(v) .. ",\n"
            else
                s = s .. "[\"" .. k .. "\"] = " .. serialize(v) .. ",\n"
            end
        end
        return s .. "}"
    else
        return "nil"
    end
end

local function saveGame(slot)
    local saveData = {
        version = 1,
        timestamp = os.time(),
        gameState = "desktop",
        
        trabajo = {
            money = trabajo.money,
            totalEarned = trabajo.totalEarned,
            tasksCompleted = trabajo.tasksCompleted,
            completedProjects = trabajo.completedProjects,
            winbatchActive = trabajo.winbatchActive,
            level = trabajo.level,
            unlockedDifficulties = trabajo.unlockedDifficulties,
        },
        
        explorer = {
            upgradeLevels = explorer.upgradeLevels,
            appStore = {},
            musicSongs = {},
            refreshAttempts = explorer.refreshAttempts,
            refreshCooldown = explorer.refreshCooldown,
        },
        
        email = {
            inbox = email.inbox,
            emailIndex = email.emailIndex,
            totalTasksDone = email.totalTasksDone,
            malwareSent = email.malwareSent,
            downloadIconActive = email.downloadIconActive,
        },
        
        notepad = {
            objectives = notepad.objectives,
        },
        
        personal = {
            employees = personal.employees,
        },
        
        achievementsData = {
            unlocked = achievements.unlocked or {},
        },
        
        codingData = {
            codingLevel = coding.codingLevel,
            codingXP = coding.codingXP,
            publishedApps = {},
            currentKeyboard = currentKeyboard,
            ownedKeyboards = {},
        },
        
        dynamicIcons = {},
        pcStats = pcStats,
    }
    
    for i, app in ipairs(explorer.appStore) do
        table.insert(saveData.explorer.appStore, {
            id = app.id,
            purchased = app.purchased,
        })
    end
    
    for i, song in ipairs(explorer.musicSongs) do
        table.insert(saveData.explorer.musicSongs, {
            name = song.name,
            purchased = song.purchased,
        })
    end
    
    for i, app in ipairs(coding.publishedApps) do
        table.insert(saveData.codingData.publishedApps, {
            name = app.name,
            typeId = app.type.id,
            revenuePerMonth = app.revenuePerMonth,
            monthsLeft = app.monthsLeft,
            totalRevenue = app.totalRevenue,
            selling = app.selling,
            successScore = app.successScore,
        })
    end

    for i, kbd in ipairs(keyboardSounds) do
        if kbd.owned then
            table.insert(saveData.codingData.ownedKeyboards, i)
        end
    end
    
    for id, icon in pairs(dynamicIcons) do
        saveData.dynamicIcons[id] = {active = icon.active}
    end
    
    local success, err = love.filesystem.write(getSaveSlotPath(slot), serialize(saveData))
    return success
end

function loadGame(slot)
    local data = getSaveSlotInfo(slot)
    if not data then return false end
    
    if data.trabajo then
        trabajo.money = data.trabajo.money or 0
        trabajo.totalEarned = data.trabajo.totalEarned or 0
        trabajo.tasksCompleted = data.trabajo.tasksCompleted or 0
        trabajo.completedProjects = data.trabajo.completedProjects or 0
        trabajo.winbatchActive = data.trabajo.winbatchActive or false
        trabajo.level = data.trabajo.level or 1
        if data.trabajo.unlockedDifficulties then
            trabajo.unlockedDifficulties = data.trabajo.unlockedDifficulties
        end
    end
    
    if data.explorer then
        if data.explorer.upgradeLevels then
            for stat, level in pairs(data.explorer.upgradeLevels) do
                explorer.upgradeLevels[stat] = level
            end
        end
        if data.explorer.appStore then
            for _, savedApp in ipairs(data.explorer.appStore) do
                for _, app in ipairs(explorer.appStore) do
                    if app.id == savedApp.id then
                        app.purchased = savedApp.purchased
                        if app.id == "winbatch" and savedApp.purchased then
                            trabajo.winbatchActive = true
                        end
                    end
                end
            end
        end
        if data.explorer.musicSongs then
            for _, savedSong in ipairs(data.explorer.musicSongs) do
                for _, song in ipairs(explorer.musicSongs) do
                    if song.name == savedSong.name then
                        song.purchased = savedSong.purchased
                    end
                end
            end
        end
        if data.explorer.refreshAttempts then
            explorer.refreshAttempts = data.explorer.refreshAttempts
        end
        if data.explorer.refreshCooldown then
            explorer.refreshCooldown = data.explorer.refreshCooldown
        end
    end
    
    if data.email then
        email.inbox = data.email.inbox or {}
        email.emailIndex = data.email.emailIndex or 1
        email.totalTasksDone = data.email.totalTasksDone or 0
        email.malwareSent = data.email.malwareSent or false
        email.downloadIconActive = data.email.downloadIconActive or false
    end
    
    if data.notepad and data.notepad.objectives then
        for i, obj in ipairs(data.notepad.objectives) do
            if notepad.objectives[i] then
                notepad.objectives[i].done = obj.done
            end
        end
    end
    
    if data.personal and data.personal.employees then
        for id, emp in pairs(data.personal.employees) do
            if personal.employees[id] then
                personal.employees[id].count = emp.count or 0
                personal.employees[id].cost = emp.cost or 0
            end
        end
    end
    
    if data.dynamicIcons then
        for id, iconData in pairs(data.dynamicIcons) do
            if dynamicIcons[id] then
                dynamicIcons[id].active = iconData.active
            end
        end
        desktopIcons = getDesktopIcons()
    end

    if data.achievementsData and data.achievementsData.unlocked and achievements then
        for id, unlocked in pairs(data.achievementsData.unlocked) do
            if achievements.unlocked then
                achievements.unlocked[id] = unlocked
            end
        end
    end

    if data.codingData and coding then
        coding.codingLevel = data.codingData.codingLevel or 1
        coding.codingXP = data.codingData.codingXP or 0
        currentKeyboard = data.codingData.currentKeyboard or 1
        if data.codingData.ownedKeyboards then
            for _, idx in ipairs(data.codingData.ownedKeyboards) do
                if keyboardSounds[idx] then
                    keyboardSounds[idx].owned = true
                end
            end
        end
        if data.codingData.publishedApps then
            for _, savedApp in ipairs(data.codingData.publishedApps) do
                local appType = nil
                if CodingClass and CodingClass.projectTypes then
                    for _, pt in ipairs(CodingClass.projectTypes) do
                    if pt.id == savedApp.typeId then
                        appType = pt
                        break
                    end
                end
                if appType then
                    table.insert(coding.publishedApps, {
                        name = savedApp.name,
                        type = appType,
                        revenuePerMonth = savedApp.revenuePerMonth,
                        monthsLeft = savedApp.monthsLeft,
                        totalRevenue = savedApp.totalRevenue,
                        selling = savedApp.selling,
                        successScore = savedApp.successScore,
                    })
                end
            end
        end
    end
    
    if data.pcStats then
        for k, v in pairs(data.pcStats) do
            pcStats[k] = v
        end
    end
    
    return true
end

local function showSaveMessage(msg)
    saveMessage = msg
    saveMessageTimer = 3.0
end

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setDefaultFilter("nearest", "nearest")

    bootLines = {
        {text = "American  Megatrends  Released: 12/01/94", x = 80, y = 200, color = {0.8, 0.8, 0.8}},
        {text = "             AMIBIOS (C)1994 American Megatrends Inc..", x = 80, y = 225, color = {0.8, 0.8, 0.8}},
        {text = "", x = 80, y = 250, color = {0.8, 0.8, 0.8}},
        {text = "BCN SIT 1989-1994 Special UC612C", x = 80, y = 275, color = {0.8, 0.8, 0.8}},
        {text = "SIT Rehab(tm) XX 115", x = 80, y = 300, color = {0.8, 0.8, 0.8}},
        {text = "CPU: " .. pcStats.cpu, x = 80, y = 325, color = {0.8, 0.8, 0.8}},
        {text = "RAM: Checking " .. pcStats.ram .. " ... OK", x = 80, y = 350, color = {0.8, 0.8, 0.8}},
        {text = "HDD: " .. pcStats.disk, x = 80, y = 375, color = {0.8, 0.8, 0.8}},
        {text = "Video: " .. pcStats.display, x = 80, y = 400, color = {0.8, 0.8, 0.8}},
        {text = "Cooling: " .. pcStats.cooling, x = 80, y = 425, color = {0.8, 0.8, 0.8}},
        {text = "", x = 80, y = 450, color = {0.8, 0.8, 0.8}},
        {text = "WAIT...", x = 80, y = 475, color = {0.8, 0.8, 0.8}},
    }
    bootLineIndex = 0
    bootCharIndex = 0
    bootDone = false
    bootTimerAccum = 0
    showAllLines = false
    showBottom = false
    countdownActive = false
    countdownValue = 3
    countdownTimer = 0

    local ok, snd = pcall(love.audio.newSource, "assets/sounds/start.wav", "static")
    if ok then
        bootSound = snd
        bootSound:setVolume(0.648)
        bootSound:play()
    end

    local ok2, snd2 = pcall(love.audio.newSource, "assets/sounds/click.wav", "static")
    if ok2 then
        snd2:setVolume(0.6)
        table.insert(clickSounds, snd2)
    end
    local ok2b, snd2b = pcall(love.audio.newSource, "assets/sounds/click2.wav", "static")
    if ok2b then
        snd2b:setVolume(0.6)
        table.insert(clickSounds, snd2b)
    end
    local ok2c, snd2c = pcall(love.audio.newSource, "assets/sounds/click3.wav", "static")
    if ok2c then
        snd2c:setVolume(0.6)
        table.insert(clickSounds, snd2c)
    end

    local ok3, snd3 = pcall(love.audio.newSource, "assets/sounds/startupWindows.wav", "static")
    if ok3 then
        startupSound = snd3
        startupSound:setVolume(0.6)
    end

    local okErr, sndErr = pcall(love.audio.newSource, "assets/sounds/errorw95.wav", "static")
    if okErr then
        errorSound = sndErr
        errorSound:setVolume(0.6)
    end

    local okInstall, sndInstall = pcall(love.audio.newSource, "assets/sounds/newbuy.wav", "static")
    if okInstall then
        installSound = sndInstall
        installSound:setVolume(0.7)
    end

    local okDing, sndDing = pcall(love.audio.newSource, "assets/sounds/ding95.wav", "static")
    if okDing then
        projectPopupSound = sndDing
        projectPopupSound:setVolume(0.7)
    end

    local okBsod, sndBsod = pcall(love.audio.newSource, "assets/sounds/BSOD_Sound.wav", "static")
    if okBsod then
        bsodSound = sndBsod
        bsodSound:setVolume(0.25)
    end

    local okBios, imgBios = pcall(love.graphics.newImage, "assets/sprites/biosiconw95.png")
    if okBios then biosLogo = imgBios end

    local okEnergy, imgEnergy = pcall(love.graphics.newImage, "assets/sprites/energy.png")
    if okEnergy then energyLogo = imgEnergy end

    local ok4, img4 = pcall(love.graphics.newImage, "assets/sprites/bg.jpg")
    if ok4 then desktopBg = img4 end

    local ok5, img5 = pcall(love.graphics.newImage, "assets/sprites/recyclebin.png")
    if ok5 then iconImages["trash"] = img5 end
    local ok6, img6 = pcall(love.graphics.newImage, "assets/sprites/notepad.png")
    if ok6 then iconImages["text"] = img6 end
    local ok7, img7 = pcall(love.graphics.newImage, "assets/sprites/winamp.png")
    if ok7 then iconImages["winamp"] = img7 end
    local ok8, img8 = pcall(love.graphics.newImage, "assets/sprites/mypc.png")
    if ok8 then iconImages["mypc"] = img8 end
    local ok9, img9 = pcall(love.graphics.newImage, "assets/sprites/explorer.png")
    if ok9 then iconImages["explorer"] = img9 end
    local ok10, img10 = pcall(love.graphics.newImage, "assets/sprites/trabajo.png")
    if ok10 then iconImages["trabajo"] = img10 end
    local ok11, img11 = pcall(love.graphics.newImage, "assets/sprites/email.png")
    if ok11 then iconImages["email"] = img11 end
    local ok12, img12 = pcall(love.graphics.newImage, "assets/sprites/recyclebin.png")
    if ok12 then iconImages["recyclebin"] = img12 end
    local ok13, img13 = pcall(love.graphics.newImage, "assets/sprites/taskbaricon.png")
    if ok13 then iconImages["taskbar"] = img13 end
    local ok14, img14 = pcall(love.graphics.newImage, "assets/sprites/staff.png")
    if ok14 then iconImages["staff"] = img14 end
    local ok15, img15 = pcall(love.graphics.newImage, "assets/sprites/achievements.png")
    if ok15 then iconImages["achievements"] = img15 end
    local ok16, img16 = pcall(love.graphics.newImage, "assets/sprites/download1.png")
    if ok16 then iconImages["download"] = img16 end
    local ok17, img17 = pcall(love.graphics.newImage, "assets/sprites/winbatch.png")
    if ok17 then iconImages["winbatch"] = img17 end
    local ok18, img18 = pcall(love.graphics.newImage, "assets/sprites/coding.png")
    if ok18 then iconImages["coding"] = img18 end

    local ok8, snd8 = pcall(love.audio.newSource, "assets/sounds/songw95_1.wav", "stream")
    if ok8 then
        winampMusic = snd8
        winampMusic:setVolume(0.7)
    end

    local ok9, snd9 = pcall(love.audio.newSource, "assets/sounds/songw95_2.wav", "stream")
    if ok9 then
        winampMusic2 = snd9
        winampMusic2:setVolume(0.7)
    end

    local okShader, s = pcall(love.graphics.newShader, "assets/shaders/crt.glsl")
    if okShader then shader = s end

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local pad = 0.15
    mainCanvas = love.graphics.newCanvas(w * (1 + pad * 2), h * (1 + pad * 2))
    mainCanvas:setWrap("repeat", "repeat")

    local font = love.graphics.newFont(16)
    love.graphics.setFont(font)
    defaultFont = font
    bootFont = love.graphics.newFont(22)
    sidebarFont = love.graphics.newFont(16)
    love.graphics.setFont(font)

    CursorManager.init()

    winamp = WinampClass.new(200, 150)
    winamp.window.onClose = function()
        if winamp.music then
            winamp.music:stop()
            winamp.playing = false
        end
        updateTaskbar()
    end

    mypc = MyPCClass.new(120, 80)
    mypc.pcStats = pcStats
    mypc.window.onClose = function()
        updateTaskbar()
    end

    trabajo = TrabajoClass.new(250, 120)
    trabajo.pcStatsRef = pcStats
    trabajo.window.onClose = function()
        updateTaskbar()
    end
    trabajo.particularWindow.onClose = function()
        updateTaskbar()
    end
    trabajo.onWorkDone = function()
        if email then email:onWorkCompleted() end
    end
    trabajo.onOpenParticular = function()
        bringToFront("particular")
    end

    particularApp = {
        window = trabajo.particularWindow,
        hitTest = function(_, mx, my)
            return trabajo.particularWindow:hitTest(mx, my)
        end,
        mousepressed = function(_, x, y, button)
            return trabajo.particularWindow:mousepressed(x, y, button)
        end,
        mousereleased = function(_, x, y, button)
            trabajo.particularWindow:mousereleased(x, y, button)
        end,
        mousemoved = function(_, x, y)
            trabajo.particularWindow:mousemoved(x, y)
        end,
        draw = function(_, mx, my)
            trabajo.particularWindow:drawFrame()
        end,
    }

    explorer = ExplorerClass.new(80, 60)
    explorer.trabajoRef = trabajo
    explorer.pcStatsRef = pcStats
    explorer.winampRef = winamp
    explorer.keyboardSoundsRef = keyboardSounds
    explorer.iconImagesRef = iconImages
    explorer.window.onClose = function()
        updateTaskbar()
    end
    explorer.onHardwarePurchase = function()
        triggerHardwareInstall()
    end
    explorer.onUpgradePurchased = function(stat, level)
        if trabajo and trabajo.activeProject then
            trabajo:recalcComponents()
        end
        if coding and coding.state == "coding" then
            coding:recalcComponents()
        end
    end
    explorer.onAppPurchased = function(appId)
        if appId == "winbatch" and trabajo then
            trabajo.winbatchActive = true
        elseif appId == "coding" then
            activateDynamicIcon("coding")
            desktopIcons = getDesktopIcons()
        end
    end

    mypc.upgradesRef = explorer.upgrades
    mypc.explorerRef = explorer

    notepad = NotepadClass.new(150, 100)
    notepad.trabajoRef = trabajo
    notepad.explorerRef = explorer
    notepad.emailRef = email
    notepad.window.onClose = function()
        updateTaskbar()
    end
    notepad.onGoalComplete = function(goalId, goalIndex)
        if goalIndex == 1 and not dynamicIcons.notepad.active then
            activateDynamicIcon("notepad")
            desktopIcons = getDesktopIcons()
            if email then
                email:addEmailToInbox({
                    subject = "Objetivos - Aplicacion desbloqueada",
                    sender = "admin@empresa.com",
                    type = "news",
                    body = "Estimado empleado:\n\nHa completado su primer objetivo!\n\nHa desbloqueado la aplicacion\n'Objetivos' para seguir su\nprogreso.\n\nEl icono aparecera en su\nescritorio automaticamente.\n\nSiga trabajando para\ndesbloquear mas cosas.",
                    handled = true,
                    read = true,
                })
            end
        elseif goalIndex == 2 and not dynamicIcons.explorer.active then
            activateDynamicIcon("explorer")
            desktopIcons = getDesktopIcons()
            if email then
                email:addEmailToInbox({
                    subject = "Internet Explorer - Tienda disponible",
                    sender = "admin@microsoft.com",
                    type = "news",
                    body = "Estimado usuario:\n\nHa desbloqueado Internet Explorer!\n\nAhora puede acceder a la Tienda\nde Hardware y Windows Update.\n\nEl icono aparecera en su\nescritorio automaticamente.\n\nDisfrute de su nueva\nexperiencia de navegacion.",
                    handled = true,
                    read = true,
                })
            end
        elseif goalIndex == 5 and not dynamicIcons.personal.active then
            activateDynamicIcon("personal")
            desktopIcons = getDesktopIcons()
            if email then
                email:addEmailToInbox({
                    subject = "Personal - Empleados disponibles",
                    sender = "admin@empresa.com",
                    type = "news",
                    body = "Estimado empleado:\n\nHa desbloqueado la aplicacion\n'Personal'!\n\nAhora puede contratar empleados\npara generar ingresos pasivos.\n\nCada empleado genera dinero\nautomaticamente con el tiempo.\n\nEl icono aparecera en su\nescritorio automaticamente.",
                    handled = true,
                    read = true,
                })
            end
        elseif goalIndex == 6 and not dynamicIcons.winamp.active then
            activateDynamicIcon("winamp")
            desktopIcons = getDesktopIcons()
            if winamp then
                winamp.playlist = {}
                winamp.sources = {}
                winamp.music = nil
                winamp.playing = false
            end
            if explorer then
                explorer:unlockPage("music")
            end
            if email then
                email:addEmailToInbox({
                    subject = "Winamp - Reproductor de musica",
                    sender = "admin@winamp.com",
                    type = "news",
                    body = "Estimado usuario:\n\nHa desbloqueado Winamp!\n\nEl reproductor de musica mas\npopular del momento.\n\nCompre su primera cancion\nen la tienda de Internet Explorer.\n\nEl icono aparecera en su\nescritorio automaticamente.",
                    handled = true,
                    read = true,
                })
            end
        elseif goalIndex == 7 and not dynamicIcons.logros then
            if not dynamicIcons.logros then
                addDynamicIcon("logros", "Logros", "achievements", 240, 140, nil)
            end
            activateDynamicIcon("logros")
            desktopIcons = getDesktopIcons()
            if email then
                email:addEmailToInbox({
                    subject = "Logros - Aplicacion desbloqueada",
                    sender = "admin@empresa.com",
                    type = "news",
                    body = "Estimado empleado:\n\nHa desbloqueado la aplicacion\n'Logros y Estadisticas'!\n\nAhora puede ver todos sus\nlogros y estadisticas de juego.\n\nEl icono aparecera en su\nescritorio automaticamente.",
                    handled = true,
                    read = true,
                })
            end
        end
    end

    email = EmailClass.new(180, 90)
    email.trabajoRef = trabajo
    email.notepadRef = notepad
    email.onProjectPopup = triggerProjectPopup
    email.canPlayChime = function()
        return gameState == "desktop"
    end
    trabajo.emailRef = email
    trabajo.explorerRef = explorer
    email.window.onClose = function()
        updateTaskbar()
    end

    recyclebin = RecycleBinClass.new(300, 150)
    recyclebin.window.onClose = function()
        updateTaskbar()
    end

    personal = PersonalClass.new(200, 100)
    personal.trabajoRef = trabajo
    personal.window.onClose = function()
        updateTaskbar()
    end

    achievements = AchievementsClass.new(160, 80)
    achievements.trabajoRef = trabajo
    achievements.explorerRef = explorer
    achievements.personalRef = personal
    trabajo.achievementsRef = achievements
    personal.achievementsRef = achievements
    achievements.window.onClose = function()
        updateTaskbar()
    end

    coding = CodingClass.new(180, 100)
    coding.trabajoRef = trabajo
    coding.explorerRef = explorer
    coding.window.onClose = function()
        updateTaskbar()
    end

    local latestSlot = nil
    local latestTimestamp = 0
    for i = 1, 3 do
        local info = getSaveSlotInfo(i)
        if info and info.timestamp and info.timestamp > latestTimestamp then
            latestTimestamp = info.timestamp
            latestSlot = i
        end
    end
    if latestSlot then
        loadGame(latestSlot)
        bootLines[6] = {text = "CPU: " .. pcStats.cpu, x = 80, y = 325, color = {0.8, 0.8, 0.8}}
        bootLines[7] = {text = "RAM: Checking " .. pcStats.ram .. " ... OK", x = 80, y = 350, color = {0.8, 0.8, 0.8}}
        bootLines[8] = {text = "HDD: " .. pcStats.disk, x = 80, y = 375, color = {0.8, 0.8, 0.8}}
        bootLines[9] = {text = "Video: " .. pcStats.display, x = 80, y = 400, color = {0.8, 0.8, 0.8}}
        bootLines[10] = {text = "Cooling: " .. pcStats.cooling, x = 80, y = 425, color = {0.8, 0.8, 0.8}}
    end

    local kbdPath = "assets/sounds/keyboard/"
    local pack = {name = keyboardNames[1], owned = true, keySounds = {}}
    local dirPath = kbdPath .. "2"
    local files = love.filesystem.getDirectoryItems(dirPath)
    
    local loveToFile = {
        a="a", b="b", c="c", d="d", e="e", f="f", g="g", h="h", i="i", j="j",
        k="k", l="l", m="m", n="n", o="o", p="p", q="q", r="r", s="s", t="t",
        u="u", v="v", w="w", x="x", y="y", z="z",
        ["1"]="1", ["2"]="2", ["3"]="3", ["4"]="4", ["5"]="5", ["6"]="6", ["7"]="7", ["8"]="8", ["9"]="9", ["0"]="0",
        ["-"]="-", ["="]="=", ["["]="[", ["]"]="]", ["\\"]="\\",
        [";"]=";", ["'"]="'", [","]=",", ["."]=".", ["/"]="/",
        ["`"]="`",
        space="space", backspace="backspace", ["return"]="enter",
        tab="tab", capslock="caps lock", lshift="shift", rshift="shift",
    }
    
    local loaded = 0
    for key, wavName in pairs(loveToFile) do
        local filename = wavName .. ".wav"
        local found = false
        for _, f in ipairs(files) do
            if f == filename then
                found = true
                break
            end
        end
        if found then
            local ok, src = pcall(love.audio.newSource, dirPath .. "/" .. filename, "static")
            if ok then
                src:setVolume(0.3)
                pack.keySounds[key] = src
                loaded = loaded + 1
            end
        end
    end
    
    if loaded > 0 then
        table.insert(keyboardSounds, pack)
    end
end

function love.update(dt)
    if saveMessageTimer > 0 then
        saveMessageTimer = saveMessageTimer - dt
    end
    
    if gameState == "boot" or gameState == "bsod" or gameState == "malware_popup" then
        love.mouse.setVisible(false)
        CursorManager.show(false)
    else
        love.mouse.setVisible(true)
        CursorManager.show(true)
    end

    if installActive then
        installTimer = installTimer + dt
        if installTimer >= installDuration then
            installActive = false
        end
        return
    end

    if gameState == "malware_popup" then
        malwarePopupTimer = malwarePopupTimer + dt
        if malwarePopupTimer >= malwarePopupDuration then
            gameState = "bsod"
            bsodActive = true
            bsodTimer = 5.0
            if bsodSound then
                bsodSound:stop()
                bsodSound:play()
            end
        end
        return
    end

    if projectPopupActive then
        projectPopupTimer = projectPopupTimer + dt
        if projectPopupTimer >= projectPopupDuration then
            projectPopupActive = false
        end
        return
    end

    if gameState == "bsod" then
        bsodTimer = bsodTimer - dt
        if bsodTimer <= 0 then
            bsodActive = false
            gameState = "boot"
            bootLineIndex = 0
            bootCharIndex = 0
            bootDone = false
            bootTimerAccum = 0
            showAllLines = false
            showBottom = false
            countdownActive = false
            countdownValue = 3
            countdownTimer = 0
            if bsodSound then bsodSound:stop() end
            if email then
                email.downloadIconActive = false
                email:addEmailToInbox({
                    subject = "Robo de fondos - Mr. M3ch",
                    sender = "mr.m3ch@darknet.com",
                    type = "news",
                    body = "Hola...\n\nAcabo de revisar tu cuenta\ny veo que tuviste un pequeño\nproblema con mi software.\n\nNo te preocupes, tu dinero\nesta a salvo... conmigo.\n\nEl 80% de tus fondos han\nsido transferidos a una cuenta\nmas segura.\n\nNos vemos pronto.\n\n- Mr. M3ch",
                    handled = true,
                    read = true,
                })
            end
            if bootSound then bootSound:stop(); bootSound:play() end
            closeAllWindows()
        end
        return
    end

    if gameState == "boot" then
        bootTimerAccum = bootTimerAccum + dt

        if not showAllLines and bootLineIndex < #bootLines then
            local currentLine = bootLines[bootLineIndex + 1]
            if currentLine and currentLine.text == "" then
                if bootTimerAccum >= bootLineDelay then
                    bootTimerAccum = 0
                    bootLineIndex = bootLineIndex + 1
                    bootCharIndex = 0
                    if bootLineIndex >= #bootLines then
                        bootDone = true
                        showAllLines = true
                        showBottom = true
                    end
                end
            elseif currentLine then
                if bootCharIndex < #currentLine.text then
                    while bootTimerAccum >= bootCharDelay and bootCharIndex < #currentLine.text do
                        bootTimerAccum = bootTimerAccum - bootCharDelay
                        bootCharIndex = bootCharIndex + 1
                    end
                else
                    if bootTimerAccum >= bootLineDelay then
                        bootTimerAccum = 0
                        bootLineIndex = bootLineIndex + 1
                        bootCharIndex = 0
                        if bootLineIndex >= #bootLines then
                            bootDone = true
                            showAllLines = true
                            showBottom = true
                        end
                    end
                end
            end
        elseif not bootDone then
            bootDone = true
            showAllLines = true
            showBottom = true
        end

        if bootDone and not countdownActive then
            countdownActive = true
            countdownValue = 3
            countdownTimer = 0
        end

        if countdownActive then
            countdownTimer = countdownTimer + dt
            if countdownTimer >= 1.0 then
                countdownTimer = countdownTimer - 1.0
                countdownValue = countdownValue - 1
                if countdownValue <= 0 then
                    gameState = "desktop"
                    if startupSound then startupSound:play() end
                    firstBootDone = true
                    if email then
                        email.window.visible = true
                        updateTaskbar()
                    end
                end
            end
        end
    end

    if gameState == "desktop" then
        if winamp then winamp:update(dt) end
        if mypc then mypc:update(dt) end
        if explorer then explorer:update(dt) end
        if notepad then notepad:update(dt) end
        if trabajo then trabajo:update(dt) end
        if email then
            email:update(dt)
            if email.downloadIconActive and not dynamicIcons.download.active then
                activateDynamicIcon("download")
                desktopIcons = getDesktopIcons()
            end
        end
        if recyclebin then recyclebin:update(dt) end
        if personal then personal:update(dt) end
        if achievements then achievements:update(dt) end
        if coding then coding:update(dt) end
    end
end

function drawAMIBIOSLogo(x, y)
    if biosLogo then
        local imgW, imgH = biosLogo:getDimensions()
        local scale = math.min(702 / imgW, 187 / imgH)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(biosLogo, x, y, 0, scale, scale)
    else
        love.graphics.setColor(0.8, 0, 0)
        love.graphics.polygon("fill", x, y + 30, x + 15, y, x + 30, y + 30)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("AMI", x - 3, y + 36)
    end
end

function drawEnergyStar(x, y)
    if energyLogo then
        local imgW, imgH = energyLogo:getDimensions()
        local scale = math.min(140 / imgW, 100 / imgH)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(energyLogo, x, y, 0, scale, scale)
    end
end

function drawDesktopIcon(icon, mx, my)
    local hovered = mx >= icon.x and mx <= icon.x + 90 and my >= icon.y and my <= icon.y + 90
    local iconX = icon.x + 10
    local iconY = icon.y + 2
    local iconW = 64
    local iconH = 64

    if hovered then
        love.graphics.setColor(0, 0, 0.8)
        love.graphics.rectangle("fill", icon.x, icon.y, 90, 88)
        love.graphics.setColor(0, 0, 0.5)
        love.graphics.rectangle("line", icon.x, icon.y, 90, 88)
    end

    if iconImages[icon.icon] then
        love.graphics.setColor(1, 1, 1)
        local img = iconImages[icon.icon]
        local imgW, imgH = img:getDimensions()
        local scale = math.min(iconW / imgW, iconH / imgH) * (icon.iconScale or 1)
        love.graphics.draw(img, iconX + (iconW - imgW * scale) / 2, iconY + (iconH - imgH * scale) / 2, 0, scale, scale)
    else
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.rectangle("fill", iconX, iconY, iconW, iconH, 2, 2)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("line", iconX, iconY, iconW, iconH)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(icon.label, icon.x, icon.y + 70, 90, "center")

    if icon.icon == "email" and email then
        local unread = 0
        for _, e in ipairs(email.inbox) do
            if not e.read then unread = unread + 1 end
        end
        if unread > 0 then
            local badge = "(" .. unread .. ")"
            local prevFont = love.graphics.getFont()
            love.graphics.setColor(1, 0, 0)
            love.graphics.print(badge, icon.x + 71, icon.y + 70)
            love.graphics.setFont(prevFont)
        end
    end
end

function drawDesktop()
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local taskH = 40
    local mx, my = love.mouse.getPosition()

    love.graphics.setFont(defaultFont)
    CursorManager.set("normal")

    if desktopBg then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(desktopBg, 0, 0, 0, winW / desktopBg:getWidth(), (winH - taskH) / desktopBg:getHeight())
    else
        love.graphics.setColor(W95.desktopBg)
        love.graphics.rectangle("fill", 0, 0, winW, winH - taskH)
    end

    for _, icon in ipairs(desktopIcons) do
        drawDesktopIcon(icon, mx, my)
        if mx >= icon.x and mx <= icon.x + 90 and my >= icon.y and my <= icon.y + 90 then
            CursorManager.set("link")
        end
    end

    local taskY = winH - taskH
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", 0, taskY, winW, taskH)

    love.graphics.setColor(W95.borderLight)
    love.graphics.line(0, taskY, winW, taskY)
    love.graphics.setColor(W95.borderUltra)
    love.graphics.line(0, taskY + 1, winW, taskY + 1)

    local startHover = mx >= 2 and mx <= 90 and my >= taskY + 2 and my <= taskY + taskH - 2
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", 2, taskY + 2, 88, taskH - 4)
    if startHover or startMenuOpen then
        love.graphics.setColor(W95.borderDark)
        love.graphics.line(2, taskY + 2, 89, taskY + 2)
        love.graphics.line(2, taskY + 2, 2, taskY + taskH - 3)
        love.graphics.setColor(W95.borderUltra)
        love.graphics.line(89, taskY + 3, 89, taskY + taskH - 3)
        love.graphics.line(3, taskY + taskH - 3, 89, taskY + taskH - 3)
    else
        love.graphics.setColor(W95.borderLight)
        love.graphics.line(2, taskY + 2, 89, taskY + 2)
        love.graphics.line(2, taskY + 2, 2, taskY + taskH - 3)
        love.graphics.setColor(W95.borderUltra)
        love.graphics.line(89, taskY + 3, 89, taskY + taskH - 3)
        love.graphics.line(3, taskY + taskH - 3, 89, taskY + taskH - 3)
    end
    if iconImages["taskbar"] then
        local img = iconImages["taskbar"]
        local imgW, imgH = img:getDimensions()
        local padding = 1
        local btnX = 2 - padding
        local btnY = taskY + 2 - padding
        local btnW = 88 + padding * 2
        local btnH = taskH - 4 + padding * 2
        local scaleX = btnW / imgW
        local scaleY = btnH / imgH
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(img, btnX, btnY, 0, scaleX, scaleY)
    else
        love.graphics.setColor(W95.fieldText)
        love.graphics.print("Start", 28, taskY + 12)
    end

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(94, taskY + 4, 94, taskY + taskH - 5)

    local taskStartX = 96
    local taskItemW = 120
    for i, app in ipairs(taskbarApps) do
        local tx = taskStartX + (i - 1) * taskItemW
        local isActive = false
        if app.id == "winamp" and winamp then
            isActive = winamp.window.visible and not winamp.window.minimized
        elseif app.id == "mypc" and mypc then
            isActive = mypc.window.visible and not mypc.window.minimized
        elseif app.id == "explorer" and explorer then
            isActive = explorer.window.visible and not explorer.window.minimized
        elseif app.id == "trabajo" and trabajo then
            isActive = trabajo.window.visible and not trabajo.window.minimized
        elseif app.id == "particular" and trabajo then
            isActive = trabajo.particularWindow.visible and not trabajo.particularWindow.minimized
        elseif app.id == "notepad" and notepad then
            isActive = notepad.window.visible and not notepad.window.minimized
        elseif app.id == "personal" and personal then
            isActive = personal.window.visible and not personal.window.minimized
        elseif app.id == "achievements" and achievements then
            isActive = achievements.window.visible and not achievements.window.minimized
        end
        local hovered = mx >= tx and mx <= tx + taskItemW - 4 and my >= taskY + 2 and my <= taskY + taskH - 2

        if isActive then
            love.graphics.setColor(W95.borderDark)
            love.graphics.rectangle("fill", tx, taskY + 2, taskItemW - 4, taskH - 4)
        else
            love.graphics.setColor(hovered and {0.85, 0.85, 0.85} or W95.bg)
            love.graphics.rectangle("fill", tx, taskY + 2, taskItemW - 4, taskH - 4)
        end

        love.graphics.setColor(W95.borderLight)
        love.graphics.line(tx, taskY + 2, tx + taskItemW - 4, taskY + 2)
        love.graphics.line(tx, taskY + 2, tx, taskY + taskH - 3)
        love.graphics.setColor(W95.borderUltra)
        love.graphics.line(tx + taskItemW - 5, taskY + 3, tx + taskItemW - 5, taskY + taskH - 3)
        love.graphics.line(tx + 1, taskY + taskH - 3, tx + taskItemW - 5, taskY + taskH - 3)

        love.graphics.setColor(W95.fieldText)
        love.graphics.printf(app.label, tx + 6, taskY + 12, taskItemW - 12, "left")
    end

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(winW - 135, taskY + 4, winW - 135, taskY + taskH - 5)

    local time = "10/24/95  " .. os.date("%I:%M %p")
    local moneyStr = "$0"
    if trabajo then
        moneyStr = "$" .. trabajo.money
    end
    local moneyW = 70
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(winW - 132, taskY + 4, winW - 132, taskY + taskH - 5)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", winW - 130, taskY + 4, moneyW, taskH - 8)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(winW - 130, taskY + 4, winW - 130 + moneyW - 1, taskY + 4)
    love.graphics.line(winW - 130, taskY + 4, winW - 130, taskY + taskH - 5)
    love.graphics.setColor(W95.borderUltra)
    love.graphics.line(winW - 130 + moneyW - 1, taskY + 5, winW - 130 + moneyW - 1, taskY + taskH - 5)
    love.graphics.line(winW - 129, taskY + taskH - 5, winW - 130 + moneyW - 2, taskY + taskH - 5)
    love.graphics.setColor({0, 0.5, 0})
    love.graphics.printf(moneyStr, winW - 126, taskY + 12, moneyW - 8, "left")

    local timeX = winW - 130 + moneyW + 2
    local timeW = winW - timeX - 5
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(timeX, taskY + 4, timeX, taskY + taskH - 5)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", timeX + 2, taskY + 4, timeW - 2, taskH - 8)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(timeX + 2, taskY + 4, timeX + timeW - 1, taskY + 4)
    love.graphics.line(timeX + 2, taskY + 4, timeX + 2, taskY + taskH - 5)
    love.graphics.setColor(W95.borderUltra)
    love.graphics.line(timeX + timeW - 1, taskY + 5, timeX + timeW - 1, taskY + taskH - 5)
    love.graphics.line(timeX + 3, taskY + taskH - 5, timeX + timeW - 1, taskY + taskH - 5)
    love.graphics.setColor(W95.fieldText)
    love.graphics.printf(time, timeX + 6, taskY + 12, timeW - 10, "right")

        if startMenuOpen then
            local menuX = 2
            local menuY = taskY - 290
            local menuW = 190
            local sidebarW = 30
            local menuH = 290

            love.graphics.setColor(W95.bg)
            love.graphics.rectangle("fill", menuX, menuY, menuW, menuH)
            love.graphics.setColor(W95.borderLight)
            love.graphics.line(menuX, menuY, menuX + menuW, menuY)
            love.graphics.line(menuX, menuY, menuX, menuY + menuH)
            love.graphics.setColor(W95.borderDark)
            love.graphics.line(menuX + menuW, menuY, menuX + menuW, menuY + menuH)
            love.graphics.line(menuX, menuY + menuH, menuX + menuW, menuY + menuH)
            love.graphics.setColor(W95.borderUltra)
            love.graphics.line(menuX + 1, menuY + menuH - 1, menuX + menuW - 1, menuY + menuH - 1)
            love.graphics.line(menuX + menuW - 1, menuY + 1, menuX + menuW - 1, menuY + menuH - 1)

            love.graphics.setColor(0.05, 0.15, 0.55)
            love.graphics.rectangle("fill", menuX + 2, menuY + 2, sidebarW, menuH - 4)
            love.graphics.setColor(W95.borderDark)
            love.graphics.line(menuX + sidebarW + 2, menuY + 2, menuX + sidebarW + 2, menuY + menuH - 2)

            love.graphics.setColor(1, 1, 1)
            love.graphics.push()
            local sidebarCenterX = menuX + 2 + sidebarW / 2
            local sidebarCenterY = menuY + 2 + (menuH - 4) / 2
            love.graphics.translate(sidebarCenterX, sidebarCenterY)
            love.graphics.rotate(-math.pi / 2)
            local prevFont = love.graphics.getFont()
            love.graphics.setFont(sidebarFont)
            local textW = sidebarFont:getWidth("Windows 95")
            local textH = sidebarFont:getHeight()
            love.graphics.print("Windows 95", -textW / 2, -textH / 2)
            love.graphics.pop()
            love.graphics.setFont(prevFont)

            local menuItems = {}
            table.insert(menuItems, {label = "Mi PC", action = "mypc", icon = "mypc"})
            table.insert(menuItems, {label = "Trabajo Freelance", action = "trabajo", icon = "trabajo"})
            if dynamicIcons.explorer and dynamicIcons.explorer.active then
                table.insert(menuItems, {label = "Internet Explorer", action = "explorer", icon = "explorer"})
            end
            table.insert(menuItems, {label = "Correo", action = "email", icon = "email"})
            if dynamicIcons.winamp and dynamicIcons.winamp.active then
                table.insert(menuItems, {label = "Winamp", action = "winamp", icon = "winamp"})
            end
            if dynamicIcons.personal and dynamicIcons.personal.active then
                table.insert(menuItems, {label = "Personal", action = "personal", icon = "staff"})
            end
            if dynamicIcons.notepad and dynamicIcons.notepad.active then
                table.insert(menuItems, {label = "Objetivos", action = "notepad", icon = "text"})
            end
            if dynamicIcons.logros and dynamicIcons.logros.active then
                table.insert(menuItems, {label = "Logros", action = "achievements", icon = "achievements"})
            end
            table.insert(menuItems, {label = "Papelera", action = "recyclebin", icon = "recyclebin"})

            table.insert(menuItems, {label = "---", action = "none"})
            table.insert(menuItems, {label = "Guardar partida", action = "save", icon = "save"})
            table.insert(menuItems, {label = "Cargar partida", action = "load", icon = "load"})
            table.insert(menuItems, {label = "Nueva partida", action = "newgame", icon = "newgame"})
            table.insert(menuItems, {label = "---", action = "none"})
            table.insert(menuItems, {label = "Shut Down...", action = "quit", icon = "power"})

            local contentX = menuX + sidebarW + 4
            local itemH = 22
            local startY = menuY + 4

            for i, item in ipairs(menuItems) do
                local itemY = startY + (i - 1) * itemH
                local hovered = mx >= contentX and mx <= menuX + menuW - 4 and my >= itemY and my <= itemY + itemH - 1

                if item.label == "---" then
                    love.graphics.setColor(W95.borderDark)
                    love.graphics.line(contentX + 2, itemY + 10, menuX + menuW - 8, itemY + 10)
                else
                    if hovered then
                        love.graphics.setColor(W95.highlight)
                        love.graphics.rectangle("fill", contentX, itemY + 1, menuX + menuW - 4 - contentX, itemH - 1)
                        love.graphics.setColor(W95.highlightText)
                    else
                        love.graphics.setColor(W95.fieldText)
                    end

                    if item.icon and iconImages[item.icon] then
                        local img = iconImages[item.icon]
                        local imgW, imgH = img:getDimensions()
                        local iconScale = math.min(16 / imgW, 16 / imgH)
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.draw(img, contentX + 2, itemY + (itemH - 16 * iconScale) / 2, 0, iconScale, iconScale)
                        if hovered then
                            love.graphics.setColor(W95.highlightText)
                        else
                            love.graphics.setColor(W95.fieldText)
                        end
                        love.graphics.print(item.label, contentX + 22, itemY + 4)
                    else
                        love.graphics.print(item.label, contentX + 4, itemY + 4)
                    end
                end
            end
        end
end

function love.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local pad = mainCanvas:getWidth() * 0.065

    love.graphics.setCanvas(mainCanvas)
    love.graphics.clear(0, 0, 0)
    love.graphics.push()
    love.graphics.translate(pad, pad)

    if gameState == "boot" then
        drawAMIBIOSLogo(80, 10)
        drawEnergyStar(1680, 30)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.setFont(bootFont)

        for i = 1, math.min(bootLineIndex, #bootLines) do
            local line = bootLines[i]
            if line.text ~= "" then
                love.graphics.setColor(line.color[1], line.color[2], line.color[3])
                love.graphics.print(line.text, line.x, line.y)
            end
        end

        if not showAllLines and bootLineIndex < #bootLines then
            local currentLine = bootLines[bootLineIndex + 1]
            if currentLine and currentLine.text ~= "" then
                local visibleText = currentLine.text:sub(1, bootCharIndex)
                love.graphics.setColor(currentLine.color[1], currentLine.color[2], currentLine.color[3])
                love.graphics.print(visibleText, currentLine.x, currentLine.y)
            end
        end

        if showBottom then
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print(bottomLines[1], 80, 1020)
            love.graphics.print(bottomLines[2], 80, 1045)
        end

    elseif gameState == "malware_popup" then
        drawMalwarePopup()

    elseif gameState == "bsod" then
        drawBSOD()

    elseif gameState == "desktop" then
        drawDesktop()

    end

    love.graphics.pop()
    love.graphics.setCanvas()

    if shader then
        shader:send("screen_size", {w, h})
        shader:send("time", love.timer.getTime())
        shader:send("curvature", CURVATURE)
        love.graphics.setShader(shader)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(mainCanvas, -pad, -pad)
    love.graphics.setShader()
    if gameState == "desktop" then
        local appDrawMap = {
            winamp = winamp, mypc = mypc, explorer = explorer,
            notepad = notepad, trabajo = trabajo, email = email, recyclebin = recyclebin,
            personal = personal, achievements = achievements, coding = coding,
            particular = particularApp,
        }
        for _, id in ipairs(windowOrder) do
            local app = appDrawMap[id]
            if app then
                local mx, my = love.mouse.getPosition()
                app:draw(mx, my)
            end
        end
        if achievements then
            achievements:drawNotifications()
            achievements:drawComboHud()
        end
        if notepad then
            notepad:drawNotifications()
        end
    end
    if projectPopupActive then
        drawProjectPopup()
    end
    if popupActive then
        drawSaveLoadPopup()
    end
    if saveMessageTimer > 0 and saveMessage ~= "" then
        local msgW = 300
        local msgH = 60
        local msgX = (love.graphics.getWidth() - msgW) / 2
        local msgY = (love.graphics.getHeight() - msgH) / 2
        love.graphics.setColor(0.75, 0.75, 0.75)
        love.graphics.rectangle("fill", msgX, msgY, msgW, msgH)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("line", msgX, msgY, msgW, msgH)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(saveMessage, msgX, msgY + 20, msgW, "center")
    end
    CursorManager.draw()
    if installActive then
        drawInstallScreen()
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end

    if gameState == "boot" then
        return
    elseif gameState == "malware_popup" then
        local w, h = love.graphics.getDimensions()
        local popupW = 420
        local popupH = 180
        local popupX = (w - popupW) / 2
        local popupY = (h - popupH) / 2
        local btnX = popupX + popupW - 85
        local btnY = popupY + popupH - 35
        if x >= btnX and x <= btnX + 75 and y >= btnY and y <= btnY + 23 then
            gameState = "bsod"
            bsodActive = true
            bsodTimer = 5.0
            if bsodSound then
                bsodSound:stop()
                bsodSound:play()
            end
        end
        return
    end

    if popupActive then
        local w, h = love.graphics.getDimensions()
        local popupW = 400
        local popupH = 300
        local popupX = (w - popupW) / 2
        local popupY = (h - popupH) / 2

        if popupType == "newgame" then
            local btnW = 80
            local btnH = 24
            local btnY = popupY + popupH - 45

            if x >= popupX + 40 and x <= popupX + 40 + btnW and y >= btnY and y <= btnY + btnH then
                if popupConfirmStep == 1 then
                    popupConfirmStep = 2
                else
                    love.filesystem.remove("save_slot_1.lua")
                    love.filesystem.remove("save_slot_2.lua")
                    love.filesystem.remove("save_slot_3.lua")
                    love.event.quit()
                end
                return
            end

            if x >= popupX + popupW - 120 and x <= popupX + popupW - 40 and y >= btnY and y <= btnY + btnH then
                popupActive = false
                return
            end
        else
            for i = 1, 3 do
                local slotY = popupY + 55 + (i - 1) * 55
                local slotW = popupW - 40
                local slotH = 45
                if x >= popupX + 20 and x <= popupX + 20 + slotW and y >= slotY and y <= slotY + slotH then
                    popupSelectedSlot = i
                    return
                end
            end

            local btnW = 100
            local btnH = 24
            local btnY = popupY + popupH - 40

            if popupConfirmStep == 0 then
                if x >= popupX + 20 and x <= popupX + 20 + btnW and y >= btnY and y <= btnY + btnH then
                    if popupType == "save" then
                        popupConfirmStep = 1
                    else
                        local info = getSaveSlotInfo(popupSelectedSlot)
                        if info then
                            popupConfirmStep = 1
                        end
                    end
                    return
                end

                if x >= popupX + popupW - 120 and x <= popupX + popupW - 20 and y >= btnY and y <= btnY + btnH then
                    popupActive = false
                    return
                end
            else
                if x >= popupX + 20 and x <= popupX + 20 + btnW and y >= btnY and y <= btnY + btnH then
                    if popupType == "save" then
                        local success = saveGame(popupSelectedSlot)
                        popupActive = false
                        if success then
                            showSaveMessage("Partida guardada en Slot " .. popupSelectedSlot)
                        else
                            showSaveMessage("Error al guardar")
                        end
                    elseif popupType == "load" then
                        local success = loadGame(popupSelectedSlot)
                        popupActive = false
                        if success then
                            showSaveMessage("Partida cargada!")
                        else
                            showSaveMessage("Error al cargar")
                        end
                    end
                    return
                end

                if x >= popupX + popupW - 120 and x <= popupX + popupW - 20 and y >= btnY and y <= btnY + btnH then
                    popupConfirmStep = 0
                    return
                end
            end
        end
        return
    end

    if projectPopupActive then
        local w, h = love.graphics.getDimensions()
        local popupW = 420
        local popupH = 180
        local popupX = (w - popupW) / 2
        local popupY = (h - popupH) / 2
        local btnX = popupX + popupW - 85
        local btnY = popupY + popupH - 35
        if x >= btnX and x <= btnX + 75 and y >= btnY and y <= btnY + 23 then
            projectPopupActive = false
        end
        return
    end

    if gameState == "desktop" then
        playClick()
        local appMap = {
            mypc = mypc, explorer = explorer, notepad = notepad,
            winamp = winamp, trabajo = trabajo, email = email, recyclebin = recyclebin,
            personal = personal, achievements = achievements, coding = coding,
            particular = particularApp,
        }
        for i = #windowOrder, 1, -1 do
            local id = windowOrder[i]
            local app = appMap[id]
            if app and app.window.visible and not app.window.minimized and app:hitTest(x, y) then
                bringToFront(id)
                app:mousepressed(x, y, button)
                return
            end
        end

        local winH = love.graphics.getHeight()
        local taskH = 40
        local taskY = winH - taskH
        local startHover = x >= 2 and x <= 90 and y >= taskY + 2 and y <= taskY + taskH - 2

        if startHover then
            startMenuOpen = not startMenuOpen
            return
        end

        if startMenuOpen then
            local menuX = 2
            local menuY = taskY - 290
            local menuW = 190
            local sidebarW = 30
            local contentX = menuX + sidebarW + 4
            local startY = menuY + 4
            local itemH = 22

            local menuItems = {}
            table.insert(menuItems, {label = "Mi PC", action = "mypc"})
            table.insert(menuItems, {label = "Trabajo Freelance", action = "trabajo"})
            if dynamicIcons.explorer and dynamicIcons.explorer.active then
                table.insert(menuItems, {label = "Internet Explorer", action = "explorer"})
            end
            table.insert(menuItems, {label = "Correo", action = "email"})
            if dynamicIcons.winamp and dynamicIcons.winamp.active then
                table.insert(menuItems, {label = "Winamp", action = "winamp"})
            end
            if dynamicIcons.personal and dynamicIcons.personal.active then
                table.insert(menuItems, {label = "Personal", action = "personal"})
            end
            if dynamicIcons.notepad and dynamicIcons.notepad.active then
                table.insert(menuItems, {label = "Objetivos", action = "notepad"})
            end
            if dynamicIcons.logros and dynamicIcons.logros.active then
                table.insert(menuItems, {label = "Logros", action = "achievements"})
            end
            table.insert(menuItems, {label = "Papelera", action = "recyclebin"})
            table.insert(menuItems, {label = "---", action = "none"})
            table.insert(menuItems, {label = "Guardar partida", action = "save"})
            table.insert(menuItems, {label = "Cargar partida", action = "load"})
            table.insert(menuItems, {label = "Nueva partida", action = "newgame"})
            table.insert(menuItems, {label = "---", action = "none"})
            table.insert(menuItems, {label = "Shut Down...", action = "quit"})

            if x >= contentX and x <= menuX + menuW - 4 and y >= startY and y <= startY + #menuItems * itemH then
                local clickedIndex = math.floor((y - startY) / itemH) + 1
                local item = menuItems[clickedIndex]
                if item and item.action ~= "none" then
                    if item.action == "quit" then
                        love.event.quit()
                    elseif item.action == "save" then
                        popupActive = true
                        popupType = "save"
                        popupSelectedSlot = 1
                        popupConfirmStep = 0
                    elseif item.action == "load" then
                        popupActive = true
                        popupType = "load"
                        popupSelectedSlot = 1
                        popupConfirmStep = 0
                    elseif item.action == "newgame" then
                        popupActive = true
                        popupType = "newgame"
                        popupConfirmStep = 1
                    else
                        toggleApp(item.action)
                    end
                end
                startMenuOpen = false
                return
            else
                startMenuOpen = false
            end
        end

        local taskStartX = 96
        local taskItemW = 120
        for i, app in ipairs(taskbarApps) do
            local tx = taskStartX + (i - 1) * taskItemW
            if x >= tx and x <= tx + taskItemW - 4 and y >= taskY + 2 and y <= taskY + taskH - 2 then
                toggleApp(app.id)
                return
            end
        end

        for _, icon in ipairs(desktopIcons) do
            if x >= icon.x and x <= icon.x + 90 and y >= icon.y and y <= icon.y + 90 then
                local currentTime = love.timer.getTime()
                if currentTime - lastClickTime <= doubleClickTime then
                if icon.icon == "winamp" then
                    toggleApp("winamp")
                elseif icon.icon == "mypc" then
                    toggleApp("mypc")
                elseif icon.icon == "explorer" then
                    toggleApp("explorer")
                elseif icon.icon == "trabajo" then
                    toggleApp("trabajo")
                elseif icon.icon == "email" then
                    toggleApp("email")
                elseif icon.icon == "recyclebin" then
                    toggleApp("recyclebin")
                elseif icon.icon == "text" then
                    toggleApp("notepad")
                elseif icon.icon == "achievements" then
                    toggleApp("achievements")
                elseif icon.icon == "staff" then
                    toggleApp("personal")
                elseif icon.icon == "coding" then
                    toggleApp("coding")
                elseif icon.icon == "download" then
                    triggerMalware()
                    if dynamicIcons.download then dynamicIcons.download.active = false end
                    desktopIcons = getDesktopIcons()
                    if email then email.downloadIconActive = false end
                end
                end
                lastClickTime = currentTime
                break
            end
        end


    end
end

function love.mousereleased(x, y, button)
    local appMap = {
        winamp = winamp, mypc = mypc, explorer = explorer,
        notepad = notepad, trabajo = trabajo, email = email, recyclebin = recyclebin,
        personal = personal, achievements = achievements, coding = coding,
        particular = particularApp,
    }
    for _, id in ipairs(windowOrder) do
        local app = appMap[id]
        if app then app:mousereleased(x, y, button) end
    end
end

function love.mousemoved(x, y)
    local appMap = {
        winamp = winamp, mypc = mypc, explorer = explorer,
        notepad = notepad, trabajo = trabajo, email = email, recyclebin = recyclebin,
        personal = personal, achievements = achievements, coding = coding,
        particular = particularApp,
    }
    for _, id in ipairs(windowOrder) do
        local app = appMap[id]
        if app then app:mousemoved(x, y) end
    end
end

function love.keypressed(key)
    if key == "f1" and trabajo then
        trabajo.money = trabajo.money + 1000
        trabajo.totalEarned = trabajo.totalEarned + 1000
    elseif key == "f2" and explorer then
        for _, app in ipairs(explorer.appStore) do
            app.purchased = true
            if app.id == "winbatch" and trabajo then
                trabajo.winbatchActive = true
            elseif app.id == "coding" then
                activateDynamicIcon("coding")
            end
        end
        desktopIcons = getDesktopIcons()
    end

    if gameState == "desktop" then
        local skipKeys = {lshift=true, rshift=true, lctrl=true, rctrl=true, lalt=true, ralt=true, escape=true, tab=true, capslock=true}
        if not skipKeys[key] then
            local pack = keyboardSounds[currentKeyboard]
            if pack and pack.owned then
                local src = pack.keySounds[key] or pack.keySounds["default"]
                if src then
                    src:stop()
                    src:play()
                end
            end
        end
    end

    if coding and coding.window.visible and not coding.window.minimized then
        coding:keypressed(key)
    end
end

function love.wheelmoved(x, y)
    if gameState == "desktop" then
        if email then email:wheelmoved(x, y) end
        if explorer then explorer:wheelmoved(x, y) end
    end
end

function love.textinput(text)
    if coding and coding.window.visible and not coding.window.minimized then
        coding:textinput(text)
    end
end
