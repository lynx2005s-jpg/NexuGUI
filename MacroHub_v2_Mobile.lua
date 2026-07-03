--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║    DELTA MACRO & REPLAY HUB v2.0 - MOBILE OPTIMIZED           ║
    ║    Professional Macro Recorder with Modern Hub UI              ║
    ║    File: MacroHub_v2_Mobile.lua                               ║
    ║    Platform: Delta Executor (PC & Mobile)                     ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

-- CORE SERVICES
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

-- DEVICE DETECTION
local IsMobile = UserInputService.TouchEnabled
local ScreenSize = Camera.ViewportSize

print("[MacroHub] Platform: " .. (IsMobile and "📱 MOBILE" or "🖥️ PC"))

-- CONFIG
local CONFIG = {
    RECORD_FPS = 100,
    FOLDER_NAME = "workspace Delta",
    IDLE_INTERVAL = 15 * 60,
    RECONNECT_DELAY = 5,
    MOVEMENT_THRESHOLD = 0.1,
    SAFE_POS_MIN_HEIGHT = 5,
}

local COLORS = {
    BG_PRIMARY = Color3.fromRGB(15, 15, 25),
    BG_SECONDARY = Color3.fromRGB(25, 25, 40),
    NEON_PURPLE = Color3.fromRGB(147, 51, 234),
    NEON_BLUE = Color3.fromRGB(59, 130, 246),
    TEXT_PRIMARY = Color3.fromRGB(255, 255, 255),
    TEXT_SECONDARY = Color3.fromRGB(180, 180, 200),
    SUCCESS = Color3.fromRGB(34, 197, 94),
    ERROR = Color3.fromRGB(239, 68, 68),
    WARNING = Color3.fromRGB(251, 146, 60),
}

-- GLOBAL STATE
local State = {
    isRecording = false,
    isPaused = false,
    isReplaying = false,
    currentRecording = {},
    lastFramePosition = RootPart.Position,
    lastSafePosition = RootPart.Position,
    recordStartTime = 0,
    replaySpeed = 1,
    timerElapsed = 0,
    macroData = {},
    connections = {},
}

-- ════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ════════════════════════════════════════════════════════════════

local function GenerateID()
    return tostring(math.floor(os.time() * 1000) % 1000000)
end

local function FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    local ms = math.floor((seconds % 1) * 100)
    return string.format("%02d:%02d:%02d.%02d", hours, minutes, secs, ms)
end

local function HasPlayerMoved()
    local currentPos = RootPart.Position
    local distance = (currentPos - State.lastFramePosition).Magnitude
    State.lastFramePosition = currentPos
    return distance > CONFIG.MOVEMENT_THRESHOLD
end

local function UpdateSafePosition()
    if Humanoid.State ~= Enum.HumanoidStateType.Dead and
       Humanoid.State ~= Enum.HumanoidStateType.Falling and
       Humanoid.State ~= Enum.HumanoidStateType.Swimming and
       RootPart.Position.Y > CONFIG.SAFE_POS_MIN_HEIGHT then
        State.lastSafePosition = RootPart.Position
    end
end

local function EnsureDirectory()
    if not isfolder(CONFIG.FOLDER_NAME) then
        makefolder(CONFIG.FOLDER_NAME)
    end
end

-- ════════════════════════════════════════════════════════════════
-- RECORDER MODULE
-- ════════════════════════════════════════════════════════════════

local Recorder = {}

function Recorder:Start()
    if State.isRecording then return end
    
    State.isRecording = true
    State.isPaused = false
    State.currentRecording = {}
    State.recordStartTime = tick()
    State.timerElapsed = 0
    
    print("[Recorder] ▶ Recording started!")
    
    local recordConnection
    recordConnection = RunService.Heartbeat:Connect(function()
        if not State.isRecording then
            recordConnection:Disconnect()
            return
        end
        
        local hasMoved = HasPlayerMoved()
        
        if hasMoved and State.isPaused then
            State.isPaused = false
            State.recordStartTime = tick() - State.timerElapsed
        elseif not hasMoved and not State.isPaused then
            State.isPaused = true
            return
        end
        
        if not State.isPaused then
            State.timerElapsed = tick() - State.recordStartTime
        end
        
        UpdateSafePosition()
        
        local frameData = {
            timestamp = State.timerElapsed,
            position = RootPart.Position,
            cframe = RootPart.CFrame,
            lookVector = Camera.CFrame.LookVector,
            humanoidState = Humanoid:GetState(),
            walkSpeed = Humanoid.WalkSpeed,
            velocity = RootPart.AssemblyLinearVelocity,
            isJumping = Humanoid:GetState() == Enum.HumanoidStateType.Jumping,
        }
        
        table.insert(State.currentRecording, frameData)
    end)
    
    table.insert(State.connections, recordConnection)
end

function Recorder:Stop()
    if not State.isRecording then return end
    
    State.isRecording = false
    State.isPaused = false
    
    print("[Recorder] ⏹ Recording stopped!")
    
    if #State.currentRecording > 0 then
        self:SaveRecording()
    end
end

function Recorder:SaveRecording()
    EnsureDirectory()
    
    local id = GenerateID()
    local filename = CONFIG.FOLDER_NAME .. "/" .. id .. ".json"
    
    local saveData = {
        id = id,
        duration = State.timerElapsed,
        frameCount = #State.currentRecording,
        createdAt = os.time(),
        frames = State.currentRecording,
    }
    
    local jsonString = self:TableToJson(saveData)
    writefile(filename, jsonString)
    
    State.macroData[id] = {
        id = id,
        duration = State.timerElapsed,
        frameCount = #State.currentRecording,
        createdAt = os.time(),
        filename = filename,
    }
    
    print("[Recorder] ✓ Macro saved! ID: " .. id)
    return id
end

function Recorder:TableToJson(tbl)
    local function serialize(val)
        if type(val) == "string" then
            return '"' .. val:gsub('"', '\\"') .. '"'
        elseif type(val) == "number" then
            return tostring(val)
        elseif type(val) == "boolean" then
            return val and "true" or "false"
        elseif type(val) == "table" then
            if val.x and val.y and val.z then
                return '{"x":' .. val.x .. ',"y":' .. val.y .. ',"z":' .. val.z .. '}'
            end
            local items = {}
            for k, v in pairs(val) do
                table.insert(items, '"' .. tostring(k) .. '":' .. serialize(v))
            end
            return "{" .. table.concat(items, ",") .. "}"
        end
        return "null"
    end
    return serialize(tbl)
end

-- ════════════════════════════════════════════════════════════════
-- REPLAY MODULE
-- ════════════════════════════════════════════════════════════════

local Replay = {}

function Replay:Start(macroId)
    if State.isReplaying then return end
    if not State.macroData[macroId] then return end
    
    State.isReplaying = true
    
    print("[Replay] ▶ Starting replay...")
    
    local macro = State.macroData[macroId]
    local fileContent = readfile(macro.filename)
    local frames = self:JsonToTable(fileContent).frames
    
    local replayConnection
    local lastFrameTime = tick()
    
    replayConnection = RunService.Heartbeat:Connect(function()
        if not State.isReplaying then
            replayConnection:Disconnect()
            print("[Replay] ✓ Replay finished!")
            return
        end
        
        local currentTime = tick() - lastFrameTime
        local targetIndex = math.ceil(currentTime * CONFIG.RECORD_FPS / State.replaySpeed)
        
        if targetIndex > #frames then
            State.isReplaying = false
            replayConnection:Disconnect()
            return
        end
        
        local frame1 = frames[math.max(1, targetIndex)]
        
        if frame1 then
            RootPart.CFrame = frame1.cframe
            pcall(function()
                RootPart.AssemblyLinearVelocity = frame1.velocity
            end)
            
            if frame1.isJumping and Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                Humanoid:Jump()
            end
            
            Humanoid.WalkSpeed = frame1.walkSpeed
        end
    end)
    
    table.insert(State.connections, replayConnection)
end

function Replay:Stop()
    if State.isReplaying then
        State.isReplaying = false
        print("[Replay] ⏹ Replay stopped!")
    end
end

function Replay:SetSpeed(speed)
    State.replaySpeed = speed
    print("[Replay] Speed: " .. speed .. "x")
end

function Replay:JsonToTable(jsonString)
    local function parse(str)
        local chunk = loadstring("return " .. str)
        if chunk then return chunk() end
        return {}
    end
    return parse(jsonString)
end

-- ════════════════════════════════════════════════════════════════
-- AUTO RECONNECT
-- ════════════════════════════════════════════════════════════════

local AutoReconnect = {}

function AutoReconnect:Initialize()
    local errorConnection
    errorConnection = GuiService.ErrorMessageChanged:Connect(function()
        local errorMessage = GuiService:GetErrorMessage()
        if errorMessage:match("Lost Connection") or errorMessage:match("Connection") then
            warn("[AutoReconnect] Reconnecting...")
            wait(CONFIG.RECONNECT_DELAY)
            pcall(function()
                TeleportService:Teleport(game.PlaceId, Player)
            end)
        end
    end)
    table.insert(State.connections, errorConnection)
end

-- ════════════════════════════════════════════════════════════════
-- SESSION KEEPER
-- ════════════════════════════════════════════════════════════════

local SessionKeeper = {}
local lastActivityTime = tick()

function SessionKeeper:Start()
    local keepAliveConnection
    keepAliveConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if (currentTime - lastActivityTime) >= CONFIG.IDLE_INTERVAL then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(math.random(100, 500), math.random(100, 500)))
                lastActivityTime = currentTime
                print("[SessionKeeper] ✓ Activity sent!")
            end)
        end
    end)
    table.insert(State.connections, keepAliveConnection)
end

-- ════════════════════════════════════════════════════════════════
-- ROLLBACK
-- ════════════════════════════════════════════════════════════════

local Rollback = {}

function Rollback:Execute()
    print("[Rollback] ↻ Rolling back...")
    RootPart.CFrame = CFrame.new(State.lastSafePosition)
    RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    Humanoid.Health = Humanoid.MaxHealth
end

-- ════════════════════════════════════════════════════════════════
-- STORAGE
-- ════════════════════════════════════════════════════════════════

local Storage = {}

function Storage:LoadAllMacros()
    EnsureDirectory()
    State.macroData = {}
    
    local success, files = pcall(function()
        return listfiles(CONFIG.FOLDER_NAME)
    end)
    
    if success then
        for _, filepath in ipairs(files) do
            if filepath:match("%.json$") then
                pcall(function()
                    local id = filepath:match("([%w]+)%.json$")
                    if id then
                        State.macroData[id] = {
                            id = id,
                            filepath = filepath,
                        }
                    end
                end)
            end
        end
    end
    
    print("[Storage] Loaded " .. table.getn(State.macroData) .. " macros")
end

function Storage:DeleteMacro(macroId)
    if State.macroData[macroId] then
        pcall(function()
            delfile(State.macroData[macroId].filepath)
            State.macroData[macroId] = nil
            print("[Storage] ✓ Macro deleted")
        end)
    end
end

-- ════════════════════════════════════════════════════════════════
-- GUI MODULE (MOBILE OPTIMIZED)
-- ════════════════════════════════════════════════════════════════

local GUI = {}
GUI.mainFrame = nil
GUI.isOpen = true
GUI.tabButtons = {}
GUI.currentTab = "Record"

function GUI:Create()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MacroHubGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = Player:WaitForChild("PlayerGui")
    
    local width = IsMobile and 400 or 500
    local height = IsMobile and 550 or 600
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, width, 0, height)
    mainFrame.Position = UDim2.new(0.5, -width/2, 0.5, -height/2)
    mainFrame.BackgroundColor3 = COLORS.BG_PRIMARY
    mainFrame.BorderSizePixel = 0
    mainFrame.CornerRadius = UDim.new(0, 15)
    mainFrame.Parent = screenGui
    
    -- TOP BAR
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 50)
    topBar.BackgroundColor3 = COLORS.BG_SECONDARY
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "MACRO HUB"
    title.TextColor3 = COLORS.NEON_PURPLE
    title.TextSize = IsMobile and 14 or 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar
    
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 40, 0, 40)
    minimizeBtn.Position = UDim2.new(1, -90, 0.5, -20)
    minimizeBtn.BackgroundColor3 = COLORS.BG_PRIMARY
    minimizeBtn.TextColor3 = COLORS.TEXT_PRIMARY
    minimizeBtn.Text = "−"
    minimizeBtn.TextSize = 20
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.CornerRadius = UDim.new(0, 8)
    minimizeBtn.AutoButtonColor = false
    minimizeBtn.Parent = topBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -20)
    closeBtn.BackgroundColor3 = COLORS.ERROR
    closeBtn.TextColor3 = COLORS.TEXT_PRIMARY
    closeBtn.Text = "✕"
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.CornerRadius = UDim.new(0, 8)
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = topBar
    
    -- TAB BAR
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 50)
    tabBar.Position = UDim2.new(0, 0, 0, 50)
    tabBar.BackgroundColor3 = COLORS.BG_SECONDARY
    tabBar.BorderSizePixel = 0
    tabBar.Parent = mainFrame
    
    local tabs = {"Record", "Replay", "Storage", "Shortcut", "Settings"}
    local tabWidth = width / #tabs - 2
    
    for i, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName .. "Tab"
        tabBtn.Size = UDim2.new(0, tabWidth, 1, 0)
        tabBtn.Position = UDim2.new(0, (i-1) * (tabWidth + 2), 0, 0)
        tabBtn.BackgroundColor3 = (i == 1) and COLORS.NEON_PURPLE or COLORS.BG_PRIMARY
        tabBtn.TextColor3 = COLORS.TEXT_PRIMARY
        tabBtn.Text = IsMobile and tabName:sub(1, 3) or tabName
        tabBtn.TextSize = IsMobile and 9 or 12
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabBar
        
        GUI.tabButtons[tabName] = tabBtn
        
        tabBtn.MouseButton1Click:Connect(function()
            GUI:SelectTab(tabName)
        end)
    end
    
    -- CONTENT FRAME
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -100)
    contentFrame.Position = UDim2.new(0, 0, 0, 100)
    contentFrame.BackgroundColor3 = COLORS.BG_PRIMARY
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = mainFrame
    
    self:CreateRecordTab(contentFrame)
    self:CreateReplayTab(contentFrame)
    self:CreateStorageTab(contentFrame)
    self:CreateShortcutTab(contentFrame)
    self:CreateSettingsTab(contentFrame)
    
    self:MakeDraggable(mainFrame, topBar)
    
    minimizeBtn.MouseButton1Click:Connect(function()
        self:Minimize()
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    self.mainFrame = mainFrame
    Storage:LoadAllMacros()
end

function GUI:CreateButton(text, width, height, bgColor)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, width, 0, height)
    button.BackgroundColor3 = bgColor
    button.TextColor3 = COLORS.TEXT_PRIMARY
    button.Text = text
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.CornerRadius = UDim.new(0, 6)
    button.AutoButtonColor = false
    
    if not IsMobile then
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.15)
        end)
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = bgColor
        end)
    end
    
    return button
end

function GUI:CreateRecordTab(parent)
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "RecordTab"
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = true
    tabFrame.Parent = parent
    
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "Timer"
    timerLabel.Size = UDim2.new(1, -20, 0, 40)
    timerLabel.Position = UDim2.new(0, 10, 0, 10)
    timerLabel.BackgroundColor3 = COLORS.BG_SECONDARY
    timerLabel.TextColor3 = COLORS.NEON_BLUE
    timerLabel.Text = "00:00:00.00"
    timerLabel.TextSize = 22
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.BorderSizePixel = 0
    timerLabel.CornerRadius = UDim.new(0, 8)
    timerLabel.Parent = tabFrame
    
    local timerConnection
    timerConnection = RunService.Heartbeat:Connect(function()
        if State.isRecording then
            timerLabel.Text = FormatTime(State.timerElapsed)
            timerLabel.TextColor3 = State.isPaused and COLORS.WARNING or COLORS.NEON_BLUE
        end
    end)
    table.insert(State.connections, timerConnection)
    
    local startBtn = self:CreateButton("START", 80, 45, COLORS.SUCCESS)
    startBtn.Position = UDim2.new(0, 20, 0, 70)
    startBtn.Parent = tabFrame
    startBtn.TextSize = 11
    
    local stopBtn = self:CreateButton("STOP", 80, 45, COLORS.BG_SECONDARY)
    stopBtn.Position = UDim2.new(0, IsMobile and 110 or 130, 0, 70)
    stopBtn.Parent = tabFrame
    stopBtn.TextSize = 11
    
    startBtn.MouseButton1Click:Connect(function()
        if not State.isRecording then
            Recorder:Start()
            startBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            stopBtn.BackgroundColor3 = COLORS.ERROR
        end
    end)
    
    stopBtn.MouseButton1Click:Connect(function()
        if State.isRecording then
            Recorder:Stop()
            startBtn.BackgroundColor3 = COLORS.SUCCESS
            stopBtn.BackgroundColor3 = COLORS.BG_SECONDARY
        end
    end)
    
    local speedoLabel = Instance.new("TextLabel")
    speedoLabel.Size = UDim2.new(1, -20, 0, 30)
    speedoLabel.Position = UDim2.new(0, 10, 0, 135)
    speedoLabel.BackgroundColor3 = COLORS.BG_SECONDARY
    speedoLabel.TextColor3 = COLORS.TEXT_PRIMARY
    speedoLabel.Text = "Speed: 0.0 Stud/s"
    speedoLabel.TextSize = 11
    speedoLabel.Font = Enum.Font.Gotham
    speedoLabel.BorderSizePixel = 0
    speedoLabel.CornerRadius = UDim.new(0, 8)
    speedoLabel.Parent = tabFrame
    
    local speedConnection
    speedConnection = RunService.Heartbeat:Connect(function()
        local speed = Humanoid.Velocity.Magnitude
        speedoLabel.Text = string.format("Speed: %.1f", speed)
    end)
    table.insert(State.connections, speedConnection)
end

function GUI:CreateReplayTab(parent)
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "ReplayTab"
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false
    tabFrame.Parent = parent
    
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(1, -20, 0, 20)
    speedLabel.Position = UDim2.new(0, 10, 0, 10)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextColor3 = COLORS.TEXT_PRIMARY
    speedLabel.Text = "Speed:"
    speedLabel.TextSize = 11
    speedLabel.Font = Enum.Font.GothamBold
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = tabFrame
    
    local speeds = {0.5, 1, 1.5, 2, 5}
    local speedButtons = {}
    
    for i, speed in ipairs(speeds) do
        local speedBtn = self:CreateButton(tostring(speed) .. "x", IsMobile and 55 or 50, 28, COLORS.BG_SECONDARY)
        speedBtn.Position = UDim2.new(0, 10 + (i-1) * (IsMobile and 72 or 60), 0, 40)
        speedBtn.Parent = tabFrame
        speedBtn.TextSize = 9
        
        speedBtn.MouseButton1Click:Connect(function()
            Replay:SetSpeed(speed)
            for _, btn in ipairs(speedButtons) do
                btn.BackgroundColor3 = COLORS.BG_SECONDARY
            end
            speedBtn.BackgroundColor3 = COLORS.NEON_BLUE
        end)
        
        table.insert(speedButtons, speedBtn)
    end
    
    local startReplayBtn = self:CreateButton("START", 80, 45, COLORS.SUCCESS)
    startReplayBtn.Position = UDim2.new(0, 20, 0, 85)
    startReplayBtn.Parent = tabFrame
    startReplayBtn.TextSize = 11
    
    local stopReplayBtn = self:CreateButton("STOP", 80, 45, COLORS.ERROR)
    stopReplayBtn.Position = UDim2.new(0, IsMobile and 110 or 130, 0, 85)
    stopReplayBtn.Parent = tabFrame
    stopReplayBtn.TextSize = 11
    
    startReplayBtn.MouseButton1Click:Connect(function()
        if next(State.macroData) then
            local firstId = next(State.macroData)
            Replay:Start(firstId)
        end
    end)
    
    stopReplayBtn.MouseButton1Click:Connect(function()
        Replay:Stop()
    end)
end

function GUI:CreateStorageTab(parent)
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "StorageTab"
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false
    tabFrame.Parent = parent
    
    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, -20, 1, -60)
    listFrame.Position = UDim2.new(0, 10, 0, 50)
    listFrame.BackgroundColor3 = COLORS.BG_SECONDARY
    listFrame.BorderSizePixel = 0
    listFrame.CornerRadius = UDim.new(0, 8)
    listFrame.Parent = tabFrame
    
    local listScroll = Instance.new("ScrollingFrame")
    listScroll.Size = UDim2.new(1, 0, 1, 0)
    listScroll.BackgroundTransparency = 1
    listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 6
    listScroll.ScrollBarImageColor3 = COLORS.NEON_PURPLE
    listScroll.Parent = listFrame
    
    local refreshBtn = self:CreateButton("REFRESH", 70, 28, COLORS.NEON_BLUE)
    refreshBtn.Position = UDim2.new(1, -80, 1, -40)
    refreshBtn.Parent = tabFrame
    refreshBtn.TextSize = 9
    
    refreshBtn.MouseButton1Click:Connect(function()
        Storage:LoadAllMacros()
        for _, child in ipairs(listScroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        GUI:PopulateMacroList(listScroll)
    end)
    
    GUI:PopulateMacroList(listScroll)
end

function GUI:PopulateMacroList(parent)
    local yOffset = 0
    
    for macroId, macroData in pairs(State.macroData) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -10, 0, 45)
        itemFrame.Position = UDim2.new(0, 5, 0, yOffset)
        itemFrame.BackgroundColor3 = COLORS.BG_PRIMARY
        itemFrame.BorderSizePixel = 0
        itemFrame.CornerRadius = UDim.new(0, 6)
        itemFrame.Parent = parent
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, -10, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = COLORS.TEXT_PRIMARY
        nameLabel.Text = macroId:sub(1, 8)
        nameLabel.TextSize = 10
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = itemFrame
        
        local loadBtn = self:CreateButton("LOAD", IsMobile and 40 or 45, 32, COLORS.NEON_BLUE)
        loadBtn.Position = UDim2.new(1, IsMobile and -100 or -150, 0.5, -16)
        loadBtn.Parent = itemFrame
        loadBtn.TextSize = 8
        
        loadBtn.MouseButton1Click:Connect(function()
            Replay:Start(macroId)
        end)
        
        local delBtn = self:CreateButton("DEL", IsMobile and 40 or 45, 32, COLORS.ERROR)
        delBtn.Position = UDim2.new(1, IsMobile and -50 or -100, 0.5, -16)
        delBtn.Parent = itemFrame
        delBtn.TextSize = 8
        
        delBtn.MouseButton1Click:Connect(function()
            Storage:DeleteMacro(macroId)
            itemFrame:Destroy()
        end)
        
        yOffset = yOffset + 55
    end
    
    parent.CanvasSize = UDim2.new(0, 0, 0, math.max(yOffset, 200))
end

function GUI:CreateShortcutTab(parent)
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "ShortcutTab"
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false
    tabFrame.Parent = parent
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -20, 1, 0)
    infoLabel.Position = UDim2.new(0, 10, 0, 10)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = COLORS.TEXT_PRIMARY
    infoLabel.Text = "🎯 SHORTCUT BAR\n\nVisible at bottom-left\n\n● = Record\n⏹ = Stop Record\n▶ = Replay\n⟲ = Rollback\n⏻ = Stop Replay\n\n✋ Drag & Drop\n📱 Full Mobile Support"
    infoLabel.TextSize = 11
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextWrapped = true
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.Parent = tabFrame
end

function GUI:CreateSettingsTab(parent)
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "SettingsTab"
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Visible = false
    tabFrame.Parent = parent
    
    local settingsLabel = Instance.new("TextLabel")
    settingsLabel.Size = UDim2.new(1, -20, 0, 30)
    settingsLabel.Position = UDim2.new(0, 10, 0, 10)
    settingsLabel.BackgroundTransparency = 1
    settingsLabel.TextColor3 = COLORS.NEON_PURPLE
    settingsLabel.Text = "ℹ️ INFORMATION"
    settingsLabel.TextSize = 13
    settingsLabel.Font = Enum.Font.GothamBold
    settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
    settingsLabel.Parent = tabFrame
    
    local aboutLabel = Instance.new("TextLabel")
    aboutLabel.Size = UDim2.new(1, -20, 1, -60)
    aboutLabel.Position = UDim2.new(0, 10, 0, 50)
    aboutLabel.BackgroundTransparency = 1
    aboutLabel.TextColor3 = COLORS.TEXT_SECONDARY
    aboutLabel.Text = "DELTA MACRO HUB v2.0\n━━━━━━━━━━━━━━━\n✨ Features:\n• 100 FPS Recording\n• Smooth Replay\n• Auto Reconnect\n• Session Keeper\n• Rollback System\n• Mobile Optimized\n\n📱 Device: " .. (IsMobile and "MOBILE" or "PC") .. "\n📂 Folder: workspace Delta\n⌨️ Unload: Alt+Q"
    aboutLabel.TextSize = 9
    aboutLabel.Font = Enum.Font.Gotham
    aboutLabel.TextWrapped = true
    aboutLabel.TextXAlignment = Enum.TextXAlignment.Left
    aboutLabel.TextYAlignment = Enum.TextYAlignment.Top
    aboutLabel.Parent = tabFrame
end

function GUI:SelectTab(tabName)
    if self.currentTab == tabName then return end
    
    local screenGui = self.mainFrame.Parent
    local contentFrame = screenGui:FindFirstChild("MainFrame"):FindFirstChild("ContentFrame")
    
    for _, tab in ipairs(contentFrame:GetChildren()) do
        if tab:IsA("Frame") and tab.Name:match("Tab$") then
            tab.Visible = false
        end
    end
    
    local selectedTab = contentFrame:FindFirstChild(tabName .. "Tab")
    if selectedTab then
        selectedTab.Visible = true
    end
    
    for name, btn in pairs(self.tabButtons) do
        btn.BackgroundColor3 = (name == tabName) and COLORS.NEON_PURPLE or COLORS.BG_PRIMARY
    end
    
    self.currentTab = tabName
end

function GUI:MakeDraggable(frame, dragPart)
    local dragging = false
    local dragStart = Vector2.new()
    local frameStart = UDim2.new()
    
    dragPart.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or (IsMobile and input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
            dragStart = IsMobile and input.Position or UserInputService:GetMouseLocation()
            frameStart = frame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local currentMouse = UserInputService:GetMouseLocation()
            local delta = currentMouse - dragStart
            frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or (IsMobile and input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
        end
    end)
end

function GUI:Minimize()
    if self.mainFrame then
        self.mainFrame:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.3, true)
        self.mainFrame.Visible = false
        self.isOpen = false
        self:ShowFloatingIcon()
    end
end

function GUI:Close()
    self:Minimize()
end

function GUI:ShowFloatingIcon()
    local screenGui = self.mainFrame.Parent
    local floatingFrame = Instance.new("Frame")
    floatingFrame.Name = "FloatingIcon"
    floatingFrame.Size = UDim2.new(0, 60, 0, 60)
    floatingFrame.Position = UDim2.new(1, -75, 1, -75)
    floatingFrame.BackgroundColor3 = COLORS.NEON_PURPLE
    floatingFrame.BorderSizePixel = 0
    floatingFrame.CornerRadius = UDim.new(0, 30)
    floatingFrame.Parent = screenGui
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "⚙"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.TextSize = 32
    icon.Font = Enum.Font.GothamBold
    icon.Parent = floatingFrame
    
    self:MakeDraggable(floatingFrame, floatingFrame)
    
    local clickConnection
    clickConnection = floatingFrame.InputBegan:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or (IsMobile and input.UserInputType == Enum.UserInputType.Touch) then
            self:Restore(floatingFrame)
            clickConnection:Disconnect()
        end
    end)
end

function GUI:Restore(floatingIcon)
    if self.mainFrame then
        floatingIcon:Destroy()
        self.mainFrame.Visible = true
        self.mainFrame:TweenSize(UDim2.new(0, IsMobile and 400 or 500, 0, IsMobile and 550 or 600), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.3, true)
        self.isOpen = true
    end
end

-- ════════════════════════════════════════════════════════════════
-- SHORTCUT BAR
-- ════════════════════════════════════════════════════════════════

local ShortcutBar = {}

function ShortcutBar:Create()
    local screenGui = Player:WaitForChild("PlayerGui"):FindFirstChild("MacroHubGui")
    if not screenGui then return end
    
    local shortcutFrame = Instance.new("Frame")
    shortcutFrame.Name = "ShortcutBar"
    shortcutFrame.Size = UDim2.new(0, IsMobile and 290 or 210, 0, 60)
    shortcutFrame.Position = UDim2.new(0, 10, 1, -80)
    shortcutFrame.BackgroundColor3 = COLORS.BG_SECONDARY
    shortcutFrame.BorderSizePixel = 0
    shortcutFrame.CornerRadius = UDim.new(0, 10)
    shortcutFrame.Parent = screenGui
    
    GUI:MakeDraggable(shortcutFrame, shortcutFrame)
    
    local btnSize = IsMobile and 45 or 40
    local spacing = IsMobile and 8 or 5
    
    local recordBtn = GUI:CreateButton("●", btnSize, btnSize, COLORS.SUCCESS)
    recordBtn.Position = UDim2.new(0, spacing, 0.5, -btnSize/2)
    recordBtn.Parent = shortcutFrame
    recordBtn.MouseButton1Click:Connect(function()
        if not State.isRecording then Recorder:Start() end
    end)
    
    local stopRecordBtn = GUI:CreateButton("⏹", btnSize, btnSize, COLORS.ERROR)
    stopRecordBtn.Position = UDim2.new(0, btnSize + spacing * 2, 0.5, -btnSize/2)
    stopRecordBtn.Parent = shortcutFrame
    stopRecordBtn.MouseButton1Click:Connect(function()
        if State.isRecording then Recorder:Stop() end
    end)
    
    local replayBtn = GUI:CreateButton("▶", btnSize, btnSize, COLORS.NEON_BLUE)
    replayBtn.Position = UDim2.new(0, (btnSize + spacing) * 2, 0.5, -btnSize/2)
    replayBtn.Parent = shortcutFrame
    replayBtn.MouseButton1Click:Connect(function()
        if next(State.macroData) and not State.isReplaying then
            local firstId = next(State.macroData)
            Replay:Start(firstId)
        end
    end)
    
    local rollbackBtn = GUI:CreateButton("⟲", btnSize, btnSize, COLORS.WARNING)
    rollbackBtn.Position = UDim2.new(0, (btnSize + spacing) * 3, 0.5, -btnSize/2)
    rollbackBtn.Parent = shortcutFrame
    rollbackBtn.MouseButton1Click:Connect(function()
        Rollback:Execute()
    end)
    
    local stopReplayBtn = GUI:CreateButton("⏻", btnSize, btnSize, COLORS.BG_PRIMARY)
    stopReplayBtn.Position = UDim2.new(0, (btnSize + spacing) * 4, 0.5, -btnSize/2)
    stopReplayBtn.Parent = shortcutFrame
    stopReplayBtn.MouseButton1Click:Connect(function()
        if State.isReplaying then Replay:Stop() end
    end)
end

-- ════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════

local function Initialize()
    print(" ")
    print("╔════════════════════════════════════════╗")
    print("║   DELTA MACRO HUB v2.0 MOBILE          ║")
    print("║   Platform: " .. (IsMobile and "📱 MOBILE" or "🖥️ PC ") .. "              ║")
    print("╚════════════════════════════════════════╝")
    print(" ")
    
    GUI:Create()
    ShortcutBar:Create()
    AutoReconnect:Initialize()
    SessionKeeper:Start()
    Storage:LoadAllMacros()
    
    print("[MacroHub] ✓ Ready!")
    print("[MacroHub] Alt+Q = Unload")
    print(" ")
end

Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    
    if State.isRecording then Recorder:Stop() end
    if State.isReplaying then Replay:Stop() end
    
    State.lastFramePosition = RootPart.Position
    State.lastSafePosition = RootPart.Position
end)

local closeConnection
closeConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
        for _, conn in ipairs(State.connections) do
            pcall(function() conn:Disconnect() end)
        end
        closeConnection:Disconnect()
        local playerGui = Player:WaitForChild("PlayerGui")
        local macroGui = playerGui:FindFirstChild("MacroHubGui")
        if macroGui then macroGui:Destroy() end
        print("[MacroHub] ✓ Script unloaded!")
    end
end)

Initialize()
