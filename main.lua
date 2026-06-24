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

local gameState = "boot"
local bsodTimer = 0
local bsodActive = false
local malwarePopupTimer = 0
local malwarePopupDuration = 3.0
local bootSound = nil
local clickSound = nil
local startupSound = nil
local bootFont = nil
local desktopBg = nil
local shader = nil
local CURVATURE = 0.02
local mainCanvas = nil
local winamp = nil
local mypc = nil
local explorer = nil
local notepad = nil
local trabajo = nil
local email = nil
local recyclebin = nil
local personal = nil
local achievements = nil

local pcStats = {
    cpu = "Intel Pentium 75MHz",
    ram = "16 MB",
    ramNum = 16,
    disk = "850 MB HDD",
    display = "Standard PCI Graphics Adapter (VGA)",
    cooling = "Disipador basico",
    bios = "American Megatrends  12/01/94",
    os = "Microsoft Windows 95  4.00.950",
}

local bootLines = {
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
local bottomLines = {
    "Press DEL to enter SETUP , ESC to skip memory test",
    "08/06/2011-Soon-in-Tokyo-Rehab-Studio"
}

local bootLineIndex = 0
local bootCharIndex = 0
local bootDone = false
local bootLineDelay = 0.15
local bootCharDelay = 0.02
local bootTimerAccum = 0
local showAllLines = false
local showBottom = false

local countdownActive = false
local countdownValue = 3
local countdownTimer = 0

local startMenuOpen = false
local lastClickTime = 0
local doubleClickTime = 0.4
local taskbarApps = {}
local winampMusic2 = nil

local iconImages = {}
local winampMusic = nil

local desktopIcons = {
    {label = "Mi PC", icon = "mypc", x = 40, y = 40},
    {label = "Internet Explorer", icon = "explorer", x = 40, y = 140},
    {label = "Winamp", icon = "winamp", x = 40, y = 240},
    {label = "Trabajo", icon = "trabajo", x = 40, y = 340, iconScale = 1.4},
    {label = "Correo", icon = "email", x = 140, y = 40, iconScale = 1.4},
    {label = "Objetivos", icon = "text", x = 140, y = 140},
    {label = "Logros", icon = "achievements", x = 140, y = 240},
    {label = "Papelera", icon = "recyclebin", x = 240, y = 40},
}
local personalIcon = {label = "Personal", icon = "staff", x = 240, y = 240}
local downloadIcon = {label = "WinOptimizer", icon = "download", x = 340, y = 40}
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
    if clickSound then
        clickSound:stop()
        clickSound:play()
    end
end

function triggerMalware()
    gameState = "malware_popup"
    malwarePopupTimer = 0
    if trabajo then
        local loss = math.floor(trabajo.money * (0.3 + math.random() * 0.3))
        trabajo.money = math.max(0, trabajo.money - loss)
    end
end

function drawBSOD()
    local w, h = love.graphics.getDimensions()
    local margin = 80
    local colW = w - margin * 2

    love.graphics.setColor(0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("Windows", margin, h * 0.15)

    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("Un error irrecoverable ha occurrido.", margin, h * 0.25)
    love.graphics.print("Se ha producido un error y Windows", margin, h * 0.30)
    love.graphics.print("ha de cerrarse para evitar danos al equipo.", margin, h * 0.33)
    love.graphics.print("", margin, h * 0.36)
    love.graphics.print("ERROR: 0E : 016F : BFF9B3D4", margin, h * 0.40)
    love.graphics.print(" KERNEL32.DLL", margin, h * 0.43)
    love.graphics.print("", margin, h * 0.46)
    love.graphics.print("* Presione cualquier tecla para terminar", margin, h * 0.52)
    love.graphics.print("  la sesion actual.", margin, h * 0.55)
    love.graphics.print("", margin, h * 0.58)
    love.graphics.print("* Reinicie el equipo. Presione F5", margin, h * 0.62)
    love.graphics.print("  para iniciar el Modo a prueba de errores.", margin, h * 0.65)
    love.graphics.setFont(love.graphics.newFont(10))
    love.graphics.print("Informacion de depuracion:", margin, h * 0.75)
    love.graphics.print("  Filtros=00000001 Dispositivo=00000000", margin, h * 0.78)
    love.graphics.print("  Carga de la direccion de comandos no disponible", margin, h * 0.81)
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
    love.graphics.print("Windows va a cerrarse para evitar danos.", popupX + 60, popupY + 60)

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
    end
    updateTaskbar()
end

local windowOrder = {"winamp", "mypc", "explorer", "notepad", "trabajo", "email", "recyclebin", "personal", "achievements"}

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

function toggleApp(appId)
    if appId == "winamp" and winamp then
        if not winamp.window.visible then
            winamp.window.x, winamp.window.y = getNextCascadePosition(winamp.window.w, winamp.window.h)
            winamp:toggleVisible()
        elseif winamp.window.minimized then
            winamp.window.minimized = false
        else
            winamp.window.minimized = true
        end
    elseif appId == "mypc" and mypc then
        if not mypc.window.visible then
            mypc.window.x, mypc.window.y = getNextCascadePosition(mypc.window.w, mypc.window.h)
            mypc:toggleVisible()
        elseif mypc.window.minimized then
            mypc.window.minimized = false
        else
            mypc.window.minimized = true
        end
    elseif appId == "explorer" and explorer then
        if not explorer.window.visible then
            explorer.window.x, explorer.window.y = getNextCascadePosition(explorer.window.w, explorer.window.h)
            explorer:toggleVisible()
        elseif explorer.window.minimized then
            explorer.window.minimized = false
        else
            explorer.window.minimized = true
        end
    elseif appId == "notepad" and notepad then
        if not notepad.window.visible then
            notepad.window.x, notepad.window.y = getNextCascadePosition(notepad.window.w, notepad.window.h)
            notepad:toggleVisible()
        elseif notepad.window.minimized then
            notepad.window.minimized = false
        else
            notepad.window.minimized = true
        end
    elseif appId == "trabajo" and trabajo then
        if not trabajo.window.visible then
            trabajo.window.x, trabajo.window.y = getNextCascadePosition(trabajo.window.w, trabajo.window.h)
            trabajo:toggleVisible()
        elseif trabajo.window.minimized then
            trabajo.window.minimized = false
        else
            trabajo.window.minimized = true
        end
    elseif appId == "email" and email then
        if not email.window.visible then
            email.window.x, email.window.y = getNextCascadePosition(email.window.w, email.window.h)
            email:toggleVisible()
        elseif email.window.minimized then
            email.window.minimized = false
        else
            email.window.minimized = true
        end
    elseif appId == "recyclebin" and recyclebin then
        if not recyclebin.window.visible then
            recyclebin.window.x, recyclebin.window.y = getNextCascadePosition(recyclebin.window.w, recyclebin.window.h)
            recyclebin:toggleVisible()
        elseif recyclebin.window.minimized then
            recyclebin.window.minimized = false
        else
            recyclebin.window.minimized = true
        end
    elseif appId == "personal" and personal then
        if not personal.window.visible then
            personal.window.x, personal.window.y = getNextCascadePosition(personal.window.w, personal.window.h)
            personal:toggleVisible()
        elseif personal.window.minimized then
            personal.window.minimized = false
        else
            personal.window.minimized = true
        end
    elseif appId == "achievements" and achievements then
        if not achievements.window.visible then
            achievements.window.x, achievements.window.y = getNextCascadePosition(achievements.window.w, achievements.window.h)
            achievements:toggleVisible()
        elseif achievements.window.minimized then
            achievements.window.minimized = false
        else
            achievements.window.minimized = true
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
end

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setDefaultFilter("nearest", "nearest")

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
        bootSound:setVolume(0.6)
        bootSound:play()
    end

    local ok2, snd2 = pcall(love.audio.newSource, "assets/sounds/click.wav", "static")
    if ok2 then
        clickSound = snd2
        clickSound:setVolume(0.6)
    end

    local ok3, snd3 = pcall(love.audio.newSource, "assets/sounds/startupWindows.wav", "static")
    if ok3 then
        startupSound = snd3
        startupSound:setVolume(0.6)
    end

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
    bootFont = font

    CursorManager.init()

    winamp = WinampClass.new(200, 150)
    if winampMusic then
        winamp:setSource(1, winampMusic)
    end
    if winampMusic2 then
        winamp:setSource(2, winampMusic2)
    end
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
    trabajo.onWorkDone = function()
        if email then email:onWorkCompleted() end
    end

    explorer = ExplorerClass.new(80, 60)
    explorer.trabajoRef = trabajo
    explorer.pcStatsRef = pcStats
    explorer.winampRef = winamp
    explorer.window.onClose = function()
        updateTaskbar()
    end

    mypc.upgradesRef = explorer.upgrades

    notepad = NotepadClass.new(150, 100)
    notepad.trabajoRef = trabajo
    notepad.explorerRef = explorer
    notepad.emailRef = email
    notepad.window.onClose = function()
        updateTaskbar()
    end

    email = EmailClass.new(180, 90)
    email.trabajoRef = trabajo
    email.notepadRef = notepad
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
end

function love.update(dt)
    if gameState == "malware_popup" then
        malwarePopupTimer = malwarePopupTimer + dt
        if malwarePopupTimer >= malwarePopupDuration then
            gameState = "bsod"
            bsodActive = true
            bsodTimer = 5.0
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
                    if email then
                        email.window.visible = true
                        updateTaskbar()
                    end
                end
            end
        end
    end

    if winamp then winamp:update(dt) end
    if mypc then mypc:update(dt) end
    if explorer then explorer:update(dt) end
    if notepad then notepad:update(dt) end
    if trabajo then trabajo:update(dt) end
    if email then email:update(dt) end
    if recyclebin then recyclebin:update(dt) end
    if personal then personal:update(dt) end
    if achievements then achievements:update(dt) end
end

function drawAMIBIOSLogo(x, y)
    love.graphics.setColor(0.8, 0, 0)
    love.graphics.polygon("fill", x, y + 24, x + 12, y, x + 24, y + 24)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("AMI", x - 2, y + 28)
end

function drawEnergyStar(x, y)
    love.graphics.setColor(0.8, 0.8, 0)
    love.graphics.setLineWidth(2)
    love.graphics.arc("line", "open", x + 30, y + 5, 30, -math.pi * 0.8, -math.pi * 0.2)
    love.graphics.line(x + 10, y + 30, x + 20, y + 10)
    love.graphics.line(x + 20, y + 10, x + 25, y + 20)
    love.graphics.line(x + 25, y + 20, x + 35, y + 5)
    love.graphics.line(x + 35, y + 5, x + 45, y + 20)
    love.graphics.line(x + 45, y + 20, x + 50, y + 10)
    love.graphics.line(x + 50, y + 10, x + 60, y + 30)
    love.graphics.print("Energy", x + 5, y + 38)
    love.graphics.setLineWidth(1)
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

    if notepad and notepad.personalReady then
        drawDesktopIcon(personalIcon, mx, my)
        if mx >= personalIcon.x and mx <= personalIcon.x + 90 and my >= personalIcon.y and my <= personalIcon.y + 90 then
            CursorManager.set("link")
        end
    end

    if email and email.downloadIconActive then
        drawDesktopIcon(downloadIcon, mx, my)
        if mx >= downloadIcon.x and mx <= downloadIcon.x + 90 and my >= downloadIcon.y and my <= downloadIcon.y + 90 then
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
    love.graphics.setColor(W95.fieldText)
    if iconImages["taskbar"] then
        local img = iconImages["taskbar"]
        local imgW, imgH = img:getDimensions()
        local iconScale = math.min(16 / imgW, 16 / imgH)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(img, 5, taskY + (taskH - 16 * iconScale) / 2, 0, iconScale, iconScale)
        love.graphics.setColor(W95.fieldText)
        love.graphics.print("Start", 22, taskY + 12)
    else
        love.graphics.print("Start", 20, taskY + 12)
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
        local menuY = taskY - 198
        local menuW = 160
        local menuH = 198

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

        local menuItems = {
            {label = "Mi PC", action = "mypc"},
            {label = "Internet Explorer", action = "explorer"},
            {label = "Winamp", action = "winamp"},
            {label = "Trabajo Freelance", action = "trabajo"},
            {label = "Correo", action = "email"},
            {label = "Personal", action = "personal"},
            {label = "Logros", action = "achievements"},
            {label = "Papelera", action = "recyclebin"},
            {label = "Objetivos", action = "notepad"},
            {label = "---", action = "none"},
            {label = "Shut Down...", action = "quit"},
        }

        for i, item in ipairs(menuItems) do
            local itemY = menuY + (i - 1) * 22
            local hovered = mx >= menuX and mx <= menuX + menuW and my >= itemY and my <= itemY + 20

            if item.label == "---" then
                love.graphics.setColor(W95.borderDark)
                love.graphics.line(menuX + 5, itemY + 10, menuX + menuW - 5, itemY + 10)
            else
                if hovered then
                    love.graphics.setColor(W95.highlight)
                    love.graphics.rectangle("fill", menuX + 2, itemY + 1, menuW - 4, 19)
                    love.graphics.setColor(W95.highlightText)
                else
                    love.graphics.setColor(W95.fieldText)
                end
                love.graphics.print(item.label, menuX + 10, itemY + 4)
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
        drawEnergyStar(1680, 10)
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
            personal = personal, achievements = achievements,
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
    end
    CursorManager.draw()
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
        end
        return
    elseif gameState == "desktop" then
        local appMap = {
            mypc = mypc, explorer = explorer, notepad = notepad,
            winamp = winamp, trabajo = trabajo, email = email, recyclebin = recyclebin,
            personal = personal, achievements = achievements,
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

        playClick()
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
            local menuY = taskY - 110
            local menuW = 160

            if x >= menuX and x <= menuX + menuW and y >= menuY and y <= taskY then
                local clickedItem = math.floor((y - menuY) / 22) + 1
                if clickedItem == 1 then
                    toggleApp("mypc")
                elseif clickedItem == 2 then
                    toggleApp("explorer")
                elseif clickedItem == 3 then
                    toggleApp("winamp")
                elseif clickedItem == 4 then
                    toggleApp("trabajo")
                elseif clickedItem == 5 then
                    toggleApp("email")
                elseif clickedItem == 6 then
                    toggleApp("personal")
                elseif clickedItem == 7 then
                    toggleApp("achievements")
                elseif clickedItem == 8 then
                    toggleApp("recyclebin")
                elseif clickedItem == 9 then
                    toggleApp("notepad")
                elseif clickedItem == 11 then
                    love.event.quit()
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
                end
                end
                lastClickTime = currentTime
                break
            end
        end

        if notepad and notepad.personalReady then
            if x >= personalIcon.x and x <= personalIcon.x + 90 and y >= personalIcon.y and y <= personalIcon.y + 90 then
                local currentTime = love.timer.getTime()
                if currentTime - lastClickTime <= doubleClickTime then
                    toggleApp("personal")
                end
                lastClickTime = currentTime
            end
        end

        if email and email.downloadIconActive then
            if x >= downloadIcon.x and x <= downloadIcon.x + 90 and y >= downloadIcon.y and y <= downloadIcon.y + 90 then
                local currentTime = love.timer.getTime()
                if currentTime - lastClickTime <= doubleClickTime then
                    triggerMalware()
                end
                lastClickTime = currentTime
            end
        end
    end
end

function love.mousereleased(x, y, button)
    local appMap = {
        winamp = winamp, mypc = mypc, explorer = explorer,
        notepad = notepad, trabajo = trabajo, email = email, recyclebin = recyclebin,
        personal = personal, achievements = achievements,
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
        personal = personal, achievements = achievements,
    }
    for _, id in ipairs(windowOrder) do
        local app = appMap[id]
        if app then app:mousemoved(x, y) end
    end
end

function love.keypressed(key)
end

function love.wheelmoved(x, y)
    if gameState == "desktop" and email then
        email:wheelmoved(x, y)
    end
end

function love.textinput(text)
end
