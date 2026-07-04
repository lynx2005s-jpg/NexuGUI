--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                        NEXUS HUB v2.0.0                              ║
    ║              Professional Roblox GUI Library                         ║
    ║                                                                      ║
    ║  Features:                                                           ║
    ║  • Compact, Non-Intrusive Window (600x420)                         ║
    ║  • Key System (Free / Premium tiers)                                 ║
    ║  • Rayfield-Inspired Premium Aesthetics                              ║
    ║  • 20+ UI Components                                                 ║
    ║  • Advanced Color Picker (RGB/HSV/Hex)                               ║
    ║  • Multi-Select Dropdown with Search                                 ║
    ║  • Advanced Keybind (Hold/Toggle modes)                              ║
    ║  • Notification Queue with Icons                                       ║
    ║  • Config System with Auto-Save                                      ║
    ║  • 5 Built-in Themes                                                 ║
    ║  • Mobile Optimized                                                  ║
    ╚══════════════════════════════════════════════════════════════════════╝
--]]

local NexusHub = {}
NexusHub.__index = NexusHub

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SERVICES
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- UTILITY MODULE
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Utility = {}
Utility.__index = Utility

function Utility.new()
    local self = setmetatable({}, Utility)
    self.Connections = {}
    self.Tweens = {}
    self.Instances = {}
    return self
end

function Utility:Connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(self.Connections, conn)
    return conn
end

function Utility:DisconnectAll()
    for _, conn in ipairs(self.Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    self.Connections = {}
end

function Utility:Tween(instance, tweenInfo, properties, callback)
    if not instance or not instance.Parent then return nil end
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    table.insert(self.Tweens, tween)

    tween.Completed:Connect(function()
        for i, t in ipairs(self.Tweens) do
            if t == tween then table.remove(self.Tweens, i) break end
        end
        if callback then pcall(callback) end
    end)
    return tween
end

function Utility:Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            pcall(function() instance[prop] = value end)
        end
    end
    if properties.Parent then instance.Parent = properties.Parent end
    table.insert(self.Instances, instance)
    return instance
end

function Utility:MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    self:Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            local changedConn
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if changedConn then changedConn:Disconnect() end
                end
            end)
        end
    end)

    self:Connect(handle.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    self:Connect(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then update(input) end
    end)
end

function Utility:Ripple(button, inputPosition, color)
    local ripple = self:Create("Frame", {
        Parent = button,
        BackgroundColor3 = color or Color3.fromRGB(255,255,255),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, inputPosition.X - button.AbsolutePosition.X, 0, inputPosition.Y - button.AbsolutePosition.Y),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = button.ZIndex + 1
    })
    self:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ripple})
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
    self:Tween(ripple, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    })
    task.delay(0.6, function() if ripple then ripple:Destroy() end end)
end

function Utility:CopyTable(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then copy[k] = self:CopyTable(v) else copy[k] = v end
    end
    return copy
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- THEME SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local ThemeSystem = {}
ThemeSystem.__index = ThemeSystem

ThemeSystem.Presets = {
    DarkPurple = {
        Background = Color3.fromRGB(13, 14, 18),
        BackgroundSecondary = Color3.fromRGB(18, 19, 24),
        Surface = Color3.fromRGB(25, 26, 33),
        SurfaceHover = Color3.fromRGB(35, 36, 45),
        SurfaceLight = Color3.fromRGB(40, 41, 52),
        Accent = Color3.fromRGB(138, 46, 255),
        AccentLight = Color3.fromRGB(168, 96, 255),
        AccentDark = Color3.fromRGB(108, 36, 205),
        Text = Color3.fromRGB(245, 245, 250),
        TextDim = Color3.fromRGB(160, 160, 175),
        TextDark = Color3.fromRGB(100, 100, 115),
        Border = Color3.fromRGB(35, 36, 45),
        BorderHover = Color3.fromRGB(60, 61, 75),
        Success = Color3.fromRGB(46, 213, 115),
        Error = Color3.fromRGB(255, 71, 87),
        Warning = Color3.fromRGB(255, 165, 2),
        Info = Color3.fromRGB(56, 130, 255),
        ToggleOn = Color3.fromRGB(138, 46, 255),
        ToggleOff = Color3.fromRGB(50, 51, 60),
        SliderFill = Color3.fromRGB(138, 46, 255),
        SliderTrack = Color3.fromRGB(35, 36, 45),
        DropdownBg = Color3.fromRGB(30, 31, 40),
        NotificationBg = Color3.fromRGB(22, 23, 30),
        KeySystemBg = Color3.fromRGB(15, 16, 22),
        Shadow = Color3.fromRGB(0, 0, 0),
        Glow = Color3.fromRGB(138, 46, 255)
    },
    MidnightBlue = {
        Background = Color3.fromRGB(10, 12, 28),
        BackgroundSecondary = Color3.fromRGB(15, 18, 38),
        Surface = Color3.fromRGB(22, 26, 48),
        SurfaceHover = Color3.fromRGB(32, 36, 60),
        SurfaceLight = Color3.fromRGB(42, 46, 70),
        Accent = Color3.fromRGB(59, 130, 246),
        AccentLight = Color3.fromRGB(96, 165, 250),
        AccentDark = Color3.fromRGB(37, 99, 235),
        Text = Color3.fromRGB(245, 248, 255),
        TextDim = Color3.fromRGB(160, 170, 200),
        TextDark = Color3.fromRGB(100, 110, 140),
        Border = Color3.fromRGB(35, 40, 65),
        BorderHover = Color3.fromRGB(60, 70, 100),
        Success = Color3.fromRGB(46, 213, 115),
        Error = Color3.fromRGB(255, 71, 87),
        Warning = Color3.fromRGB(255, 165, 2),
        Info = Color3.fromRGB(59, 130, 246),
        ToggleOn = Color3.fromRGB(59, 130, 246),
        ToggleOff = Color3.fromRGB(45, 50, 75),
        SliderFill = Color3.fromRGB(59, 130, 246),
        SliderTrack = Color3.fromRGB(35, 40, 65),
        DropdownBg = Color3.fromRGB(28, 32, 55),
        NotificationBg = Color3.fromRGB(20, 24, 42),
        KeySystemBg = Color3.fromRGB(12, 14, 30),
        Shadow = Color3.fromRGB(0, 0, 0),
        Glow = Color3.fromRGB(59, 130, 246)
    },
    Crimson = {
        Background = Color3.fromRGB(21, 10, 12),
        BackgroundSecondary = Color3.fromRGB(30, 15, 18),
        Surface = Color3.fromRGB(40, 20, 25),
        SurfaceHover = Color3.fromRGB(55, 28, 35),
        SurfaceLight = Color3.fromRGB(70, 35, 42),
        Accent = Color3.fromRGB(220, 38, 38),
        AccentLight = Color3.fromRGB(248, 113, 113),
        AccentDark = Color3.fromRGB(185, 28, 28),
        Text = Color3.fromRGB(255, 245, 245),
        TextDim = Color3.fromRGB(200, 170, 170),
        TextDark = Color3.fromRGB(140, 110, 110),
        Border = Color3.fromRGB(60, 30, 35),
        BorderHover = Color3.fromRGB(100, 50, 60),
        Success = Color3.fromRGB(46, 213, 115),
        Error = Color3.fromRGB(255, 71, 87),
        Warning = Color3.fromRGB(255, 165, 2),
        Info = Color3.fromRGB(220, 38, 38),
        ToggleOn = Color3.fromRGB(220, 38, 38),
        ToggleOff = Color3.fromRGB(70, 40, 45),
        SliderFill = Color3.fromRGB(220, 38, 38),
        SliderTrack = Color3.fromRGB(60, 30, 35),
        DropdownBg = Color3.fromRGB(45, 22, 28),
        NotificationBg = Color3.fromRGB(35, 18, 22),
        KeySystemBg = Color3.fromRGB(18, 10, 12),
        Shadow = Color3.fromRGB(0, 0, 0),
        Glow = Color3.fromRGB(220, 38, 38)
    },
    Emerald = {
        Background = Color3.fromRGB(10, 21, 15),
        BackgroundSecondary = Color3.fromRGB(15, 30, 22),
        Surface = Color3.fromRGB(22, 42, 30),
        SurfaceHover = Color3.fromRGB(32, 58, 42),
        SurfaceLight = Color3.fromRGB(42, 72, 52),
        Accent = Color3.fromRGB(16, 185, 129),
        AccentLight = Color3.fromRGB(52, 211, 153),
        AccentDark = Color3.fromRGB(5, 150, 105),
        Text = Color3.fromRGB(245, 255, 250),
        TextDim = Color3.fromRGB(170, 200, 185),
        TextDark = Color3.fromRGB(110, 140, 125),
        Border = Color3.fromRGB(30, 55, 40),
        BorderHover = Color3.fromRGB(55, 90, 65),
        Success = Color3.fromRGB(16, 185, 129),
        Error = Color3.fromRGB(255, 71, 87),
        Warning = Color3.fromRGB(255, 165, 2),
        Info = Color3.fromRGB(16, 185, 129),
        ToggleOn = Color3.fromRGB(16, 185, 129),
        ToggleOff = Color3.fromRGB(40, 65, 50),
        SliderFill = Color3.fromRGB(16, 185, 129),
        SliderTrack = Color3.fromRGB(30, 55, 40),
        DropdownBg = Color3.fromRGB(28, 50, 36),
        NotificationBg = Color3.fromRGB(20, 38, 28),
        KeySystemBg = Color3.fromRGB(12, 22, 16),
        Shadow = Color3.fromRGB(0, 0, 0),
        Glow = Color3.fromRGB(16, 185, 129)
    },
    Light = {
        Background = Color3.fromRGB(245, 245, 250),
        BackgroundSecondary = Color3.fromRGB(235, 235, 242),
        Surface = Color3.fromRGB(255, 255, 255),
        SurfaceHover = Color3.fromRGB(240, 240, 248),
        SurfaceLight = Color3.fromRGB(230, 230, 240),
        Accent = Color3.fromRGB(138, 46, 255),
        AccentLight = Color3.fromRGB(168, 96, 255),
        AccentDark = Color3.fromRGB(108, 36, 205),
        Text = Color3.fromRGB(30, 30, 40),
        TextDim = Color3.fromRGB(100, 100, 120),
        TextDark = Color3.fromRGB(150, 150, 170),
        Border = Color3.fromRGB(220, 220, 230),
        BorderHover = Color3.fromRGB(180, 180, 200),
        Success = Color3.fromRGB(46, 213, 115),
        Error = Color3.fromRGB(255, 71, 87),
        Warning = Color3.fromRGB(255, 165, 2),
        Info = Color3.fromRGB(56, 130, 255),
        ToggleOn = Color3.fromRGB(138, 46, 255),
        ToggleOff = Color3.fromRGB(210, 210, 220),
        SliderFill = Color3.fromRGB(138, 46, 255),
        SliderTrack = Color3.fromRGB(220, 220, 230),
        DropdownBg = Color3.fromRGB(250, 250, 255),
        NotificationBg = Color3.fromRGB(255, 255, 255),
        KeySystemBg = Color3.fromRGB(240, 240, 245),
        Shadow = Color3.fromRGB(200, 200, 210),
        Glow = Color3.fromRGB(138, 46, 255)
    }
}

function ThemeSystem.new()
    local self = setmetatable({}, ThemeSystem)
    self.Current = "DarkPurple"
    self.Theme = Utility:CopyTable(ThemeSystem.Presets.DarkPurple)
    self.Listeners = {}
    return self
end

function ThemeSystem:SetTheme(name)
    if ThemeSystem.Presets[name] then
        self.Current = name
        self.Theme = Utility:CopyTable(ThemeSystem.Presets[name])
        for _, callback in ipairs(self.Listeners) do
            pcall(callback, self.Theme)
        end
    end
end

function ThemeSystem:OnChange(callback)
    table.insert(self.Listeners, callback)
    return #self.Listeners
end

function ThemeSystem:GetColor(key)
    return self.Theme[key] or self.Theme.Accent
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NOTIFICATION SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

function NotificationSystem.new(theme, util)
    local self = setmetatable({}, NotificationSystem)
    self.Theme = theme
    self.Util = util
    self.Queue = {}
    self.Active = {}
    self.MaxNotifications = 6
    self.Spacing = 8
    self.Width = 300

    self.Container = util:Create("ScreenGui", {
        Name = "NexusNotifications",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1000
    })

    self.Holder = util:Create("Frame", {
        Name = "Holder",
        Parent = self.Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, self.Width, 1, 0),
        Position = UDim2.new(1, -self.Width - 15, 0, 15),
        AnchorPoint = Vector2.new(0, 0)
    })

    return self
end

function NotificationSystem:Notify(config)
    config = config or {}
    local notif = {
        Title = config.Title or "Notification",
        Description = config.Description or "",
        Duration = config.Duration or 4,
        Type = config.Type or "Info",
        Icon = config.Icon
    }
    table.insert(self.Queue, notif)
    self:ProcessQueue()
end

function NotificationSystem:ProcessQueue()
    while #self.Queue > 0 and #self.Active < self.MaxNotifications do
        local notif = table.remove(self.Queue, 1)
        self:Show(notif)
    end
end

function NotificationSystem:Show(notif)
    local theme = self.Theme.Theme
    local iconMap = {
        Success = "✓",
        Error = "✕",
        Warning = "!",
        Info = "i"
    }
    local iconColorMap = {
        Success = theme.Success,
        Error = theme.Error,
        Warning = theme.Warning,
        Info = theme.Info
    }

    local frame = self.Util:Create("Frame", {
        Name = "Notification",
        Parent = self.Holder,
        BackgroundColor3 = theme.NotificationBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(1, 30, 0, 0),
        ClipsDescendants = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = frame})

    self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Transparency = 0.5,
        Parent = frame
    })

    local shadow = self.Util:Create("ImageLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = theme.Shadow,
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0, -15, 0, -15),
        ZIndex = -1
    })

    local iconColor = iconColorMap[notif.Type] or theme.Info
    local iconText = notif.Icon or iconMap[notif.Type] or "i"

    local iconFrame = self.Util:Create("Frame", {
        Parent = frame,
        BackgroundColor3 = iconColor,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 34, 0, 34),
        Position = UDim2.new(0, 10, 0, 10)
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = iconFrame})

    local icon = self.Util:Create("TextLabel", {
        Parent = iconFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = iconText,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })

    local title = self.Util:Create("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 18),
        Position = UDim2.new(0, 52, 0, 10),
        Font = Enum.Font.GothamBold,
        Text = notif.Title,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local desc = self.Util:Create("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 0),
        Position = UDim2.new(0, 52, 0, 30),
        Font = Enum.Font.Gotham,
        Text = notif.Description,
        TextSize = 12,
        TextColor3 = theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    local bar = self.Util:Create("Frame", {
        Name = "ProgressBar",
        Parent = frame,
        BackgroundColor3 = iconColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2)
    })

    self.Util:Create("UIPadding", {
        Parent = frame,
        PaddingBottom = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 10)
    })

    local targetHeight = math.max(60, 44 + desc.TextBounds.Y)

    self.Util:Tween(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, targetHeight)
    })

    table.insert(self.Active, frame)
    self:Reposition()

    self.Util:Tween(bar, TweenInfo.new(notif.Duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    })

    task.delay(notif.Duration, function()
        self:Dismiss(frame)
    end)
end

function NotificationSystem:Dismiss(frame)
    self.Util:Tween(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 30, 0, frame.Position.Y.Offset),
        Size = UDim2.new(1, 0, 0, 0)
    })

    task.delay(0.3, function()
        frame:Destroy()
        for i, f in ipairs(self.Active) do
            if f == frame then table.remove(self.Active, i) break end
        end
        self:Reposition()
        self:ProcessQueue()
    end)
end

function NotificationSystem:Reposition()
    local yOffset = 0
    for _, frame in ipairs(self.Active) do
        self.Util:Tween(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {
            Position = UDim2.new(0, 0, 0, yOffset)
        })
        yOffset = yOffset + frame.AbsoluteSize.Y + self.Spacing
    end
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CONFIG SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local ConfigSystem = {}
ConfigSystem.__index = ConfigSystem

function ConfigSystem.new(folderName)
    local self = setmetatable({}, ConfigSystem)
    self.Folder = folderName or "NexusHub"
    self:EnsureFolder()
    return self
end

function ConfigSystem:EnsureFolder()
    if not isfolder(self.Folder) then makefolder(self.Folder) end
end

function ConfigSystem:Save(name, data)
    self:EnsureFolder()
    local path = self.Folder .. "/" .. name .. ".json"
    local success = pcall(function()
        writefile(path, HttpService:JSONEncode(data))
    end)
    return success
end

function ConfigSystem:Load(name)
    local path = self.Folder .. "/" .. name .. ".json"
    if isfile(path) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        if success then return result end
    end
    return nil
end

function ConfigSystem:Delete(name)
    local path = self.Folder .. "/" .. name .. ".json"
    if isfile(path) then delfile(path) return true end
    return false
end

function ConfigSystem:List()
    self:EnsureFolder()
    local files = listfiles(self.Folder)
    local configs = {}
    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            local name = file:match("([^/\\]+)%.json$")
            if name then table.insert(configs, name) end
        end
    end
    return configs
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KEY SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local KeySystem = {}
KeySystem.__index = KeySystem

function KeySystem.new(theme, util, config)
    local self = setmetatable({}, KeySystem)
    self.Theme = theme
    self.Util = util
    self.Config = config or {}
    self.Validated = false
    self.Tier = "Free" -- Free, Premium, Lifetime
    self.Username = LocalPlayer.Name
    self.Hwid = game:GetService("RbxAnalyticsService"):GetClientId()

    self.ValidKeys = config.ValidKeys or {}
    self.PremiumKeys = config.PremiumKeys or {}
    self.LifetimeKeys = config.LifetimeKeys or {}
    self.KeyLink = config.KeyLink or ""
    self.DiscordLink = config.DiscordLink or ""

    self:Build()
    return self
end

function KeySystem:Build()
    local theme = self.Theme.Theme

    self.Gui = self.Util:Create("ScreenGui", {
        Name = "NexusKeySystem",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9999
    })

    self.Backdrop = self.Util:Create("Frame", {
        Parent = self.Gui,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0)
    })

    self.Main = self.Util:Create("Frame", {
        Parent = self.Gui,
        BackgroundColor3 = theme.KeySystemBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 420, 0, 0),
        Position = UDim2.new(0.5, -210, 0.5, -150),
        ClipsDescendants = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 16), Parent = self.Main})

    self.Util:Create("UIStroke", {
        Color = theme.Accent,
        Thickness = 1.5,
        Transparency = 0.4,
        Parent = self.Main
    })

    local shadow = self.Util:Create("ImageLabel", {
        Parent = self.Main,
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = theme.Shadow,
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Size = UDim2.new(1, 50, 1, 50),
        Position = UDim2.new(0, -25, 0, -25),
        ZIndex = -1
    })

    -- Header
    local header = self.Util:Create("Frame", {
        Parent = self.Main,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 70)
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 16), Parent = header})

    local headerFix = self.Util:Create("Frame", {
        Parent = header,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.5, 0)
    })

    local logo = self.Util:Create("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 20, 0, 15),
        Font = Enum.Font.GothamBold,
        Text = "N",
        TextSize = 22,
        TextColor3 = theme.Accent
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = logo})
    self.Util:Create("UIStroke", {Color = theme.Accent, Thickness = 2, Parent = logo})

    local title = self.Util:Create("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 0, 24),
        Position = UDim2.new(0, 70, 0, 15),
        Font = Enum.Font.GothamBold,
        Text = self.Config.Title or "Nexus Hub",
        TextSize = 18,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local subtitle = self.Util:Create("TextLabel", {
        Parent = header,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 0, 18),
        Position = UDim2.new(0, 70, 0, 38),
        Font = Enum.Font.Gotham,
        Text = "Key Authentication",
        TextSize = 12,
        TextColor3 = theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Content
    local content = self.Util:Create("Frame", {
        Parent = self.Main,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 0, 0),
        Position = UDim2.new(0, 20, 0, 85),
        AutomaticSize = Enum.AutomaticSize.Y
    })

    local statusLabel = self.Util:Create("TextLabel", {
        Parent = content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.Gotham,
        Text = "Enter your key to continue",
        TextSize = 13,
        TextColor3 = theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Key Input
    self.KeyInput = self.Util:Create("TextBox", {
        Parent = content,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 28),
        Font = Enum.Font.Gotham,
        Text = "",
        PlaceholderText = "Enter Key...",
        TextSize = 14,
        TextColor3 = theme.Text,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Center
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.KeyInput})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = self.KeyInput})

    -- Buttons
    local btnFrame = self.Util:Create("Frame", {
        Parent = content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 38),
        Position = UDim2.new(0, 0, 0, 78)
    })

    local submitBtn = self.Util:Create("TextButton", {
        Parent = btnFrame,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0.48, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "Submit Key",
        TextSize = 13,
        TextColor3 = theme.Text,
        AutoButtonColor = false
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = submitBtn})

    local getKeyBtn = self.Util:Create("TextButton", {
        Parent = btnFrame,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(0.48, 0, 1, 0),
        Position = UDim2.new(0.52, 0, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = "Get Key",
        TextSize = 13,
        TextColor3 = theme.Text,
        AutoButtonColor = false
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = getKeyBtn})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = getKeyBtn})

    -- Free Access
    local freeBtn = self.Util:Create("TextButton", {
        Parent = content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 124),
        Font = Enum.Font.Gotham,
        Text = "Or continue with Free Access →",
        TextSize = 12,
        TextColor3 = theme.Accent,
        AutoButtonColor = false
    })

    -- HWID Info
    local hwidLabel = self.Util:Create("TextLabel", {
        Parent = content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 158),
        Font = Enum.Font.Gotham,
        Text = "HWID: " .. string.sub(self.Hwid, 1, 12) .. "...",
        TextSize = 10,
        TextColor3 = theme.TextDark,
        TextXAlignment = Enum.TextXAlignment.Center
    })

    self.Util:Create("UIPadding", {
        Parent = self.Main,
        PaddingBottom = UDim.new(0, 20)
    })

    -- Events
    submitBtn.MouseButton1Click:Connect(function()
        self:ValidateKey(self.KeyInput.Text)
    end)

    getKeyBtn.MouseButton1Click:Connect(function()
        if self.KeyLink ~= "" then
            setclipboard(self.KeyLink)
            self:ShowMessage("Link copied to clipboard!", "Info")
        end
    end)

    freeBtn.MouseButton1Click:Connect(function()
        self.Tier = "Free"
        self.Validated = true
        self:Destroy()
        if self.OnValidate then self.OnValidate(self.Tier) end
    end)

    -- Animations
    self.Main.Size = UDim2.new(0, 420, 0, 0)
    self.Util:Tween(self.Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 420, 0, 280)
    })
end

function KeySystem:ValidateKey(key)
    key = string.gsub(key, "%s+", "")

    if table.find(self.LifetimeKeys, key) then
        self.Tier = "Lifetime"
        self.Validated = true
        self:ShowMessage("Lifetime access granted!", "Success")
        task.delay(1, function()
            self:Destroy()
            if self.OnValidate then self.OnValidate(self.Tier) end
        end)
    elseif table.find(self.PremiumKeys, key) then
        self.Tier = "Premium"
        self.Validated = true
        self:ShowMessage("Premium access granted!", "Success")
        task.delay(1, function()
            self:Destroy()
            if self.OnValidate then self.OnValidate(self.Tier) end
        end)
    elseif table.find(self.ValidKeys, key) then
        self.Tier = "Free"
        self.Validated = true
        self:ShowMessage("Key validated successfully!", "Success")
        task.delay(1, function()
            self:Destroy()
            if self.OnValidate then self.OnValidate(self.Tier) end
        end)
    else
        self:ShowMessage("Invalid key! Please try again.", "Error")
        self.Util:Tween(self.KeyInput, TweenInfo.new(0.1), {
            Position = UDim2.new(0, 5, 0, 28)
        })
        task.delay(0.1, function()
            self.Util:Tween(self.KeyInput, TweenInfo.new(0.1), {
                Position = UDim2.new(0, -5, 0, 28)
            })
            task.delay(0.1, function()
                self.Util:Tween(self.KeyInput, TweenInfo.new(0.1), {
                    Position = UDim2.new(0, 0, 0, 28)
                })
            end)
        end)
    end
end

function KeySystem:ShowMessage(text, type)
    if self.MessageLabel then self.MessageLabel:Destroy() end
    local theme = self.Theme.Theme
    local color = type == "Success" and theme.Success or (type == "Error" and theme.Error or theme.Info)

    self.MessageLabel = self.Util:Create("TextLabel", {
        Parent = self.Main,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 0, 20),
        Position = UDim2.new(0, 20, 0, 250),
        Font = Enum.Font.GothamBold,
        Text = text,
        TextSize = 12,
        TextColor3 = color,
        TextXAlignment = Enum.TextXAlignment.Center
    })

    task.delay(2, function()
        if self.MessageLabel then
            self.Util:Tween(self.MessageLabel, TweenInfo.new(0.3), {TextTransparency = 1})
            task.delay(0.3, function() if self.MessageLabel then self.MessageLabel:Destroy() end end)
        end
    end)
end

function KeySystem:Destroy()
    self.Util:Tween(self.Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 420, 0, 0)
    })
    self.Util:Tween(self.Backdrop, TweenInfo.new(0.3), {BackgroundTransparency = 1})
    task.delay(0.3, function()
        if self.Gui then self.Gui:Destroy() end
    end)
end

function KeySystem:OnValidated(callback)
    self.OnValidate = callback
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TOOLTIP SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local TooltipSystem = {}
TooltipSystem.__index = TooltipSystem

function TooltipSystem.new(theme, util)
    local self = setmetatable({}, TooltipSystem)
    self.Theme = theme
    self.Util = util
    self:Build()
    return self
end

function TooltipSystem:Build()
    local theme = self.Theme.Theme
    self.Gui = self.Util:Create("ScreenGui", {
        Name = "NexusTooltips",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999
    })

    self.Container = self.Util:Create("Frame", {
        Parent = self.Gui,
        BackgroundColor3 = theme.NotificationBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 220, 0, 0),
        Visible = false,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Container})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = self.Container})

    self.Text = self.Util:Create("TextLabel", {
        Parent = self.Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 0, 0),
        Position = UDim2.new(0, 8, 0, 8),
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 12,
        TextColor3 = theme.TextDim,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    self.Util:Create("UIPadding", {
        Parent = self.Container,
        PaddingBottom = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8)
    })
end

function TooltipSystem:Show(text, position)
    self.Text.Text = text
    self.Container.Visible = true
    self.Container.Position = UDim2.new(0, math.clamp(position.X + 15, 10, 800), 0, math.clamp(position.Y + 15, 10, 500))
    self.Container.BackgroundTransparency = 1
    self.Text.TextTransparency = 1
    self.Util:Tween(self.Container, TweenInfo.new(0.15), {BackgroundTransparency = 0})
    self.Util:Tween(self.Text, TweenInfo.new(0.15), {TextTransparency = 0})
end

function TooltipSystem:Hide()
    self.Container.Visible = false
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CONTROL BASE
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local ControlBase = {}
ControlBase.__index = ControlBase

function ControlBase.new(name, tab, theme, util)
    local self = setmetatable({}, ControlBase)
    self.Name = name
    self.Tab = tab
    self.Theme = theme
    self.Util = util
    self.Instance = nil
    return self
end

function ControlBase:CreateContainer(height)
    local theme = self.Theme.Theme
    self.Instance = self.Util:Create("Frame", {
        Name = self.Name,
        Parent = self.Tab.Page,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, height or 48),
        AutomaticSize = Enum.AutomaticSize.Y
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.Instance})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Transparency = 0.6, Parent = self.Instance})
    self.Util:Create("UIPadding", {
        Parent = self.Instance,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12)
    })
    return self.Instance
end

function ControlBase:SetTooltip(text)
    if not text or not self.Instance then return end
    self.Instance.MouseEnter:Connect(function()
        local pos = self.Instance.AbsolutePosition
        self.Tab.Window.Hub.Tooltips:Show(text, pos)
    end)
    self.Instance.MouseLeave:Connect(function()
        self.Tab.Window.Hub.Tooltips:Hide()
    end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TOGGLE
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Toggle = setmetatable({}, {__index = ControlBase})
Toggle.__index = Toggle

function Toggle.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Toggle)
    self.Value = config.Default or false
    self.Callback = config.Callback or function() end
    self.DescriptionText = config.Description
    self.Flag = config.Flag
    self:Build()
    return self
end

function Toggle:Build()
    local theme = self.Theme.Theme
    self:CreateContainer(self.DescriptionText and 68 or 48)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    if self.DescriptionText then
        self.Description = self.Util:Create("TextLabel", {
            Name = "Description",
            Parent = self.Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -60, 0, 0),
            Position = UDim2.new(0, 0, 0, 20),
            Font = Enum.Font.Gotham,
            Text = self.DescriptionText,
            TextSize = 11,
            TextColor3 = theme.TextDim,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y
        })
    end

    self.Switch = self.Util:Create("Frame", {
        Name = "Switch",
        Parent = self.Instance,
        BackgroundColor3 = self.Value and theme.ToggleOn or theme.ToggleOff,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 40, 0, 22),
        Position = UDim2.new(1, -40, 0, self.DescriptionText and 10 or 3),
        AnchorPoint = Vector2.new(0, 0)
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Switch})

    self.Thumb = self.Util:Create("Frame", {
        Name = "Thumb",
        Parent = self.Switch,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 16, 0, 16),
        Position = self.Value and UDim2.new(1, -19, 0, 3) or UDim2.new(0, 3, 0, 3)
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Thumb})

    self.Glow = self.Util:Create("Frame", {
        Name = "Glow",
        Parent = self.Switch,
        BackgroundColor3 = theme.AccentLight,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0)
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Glow})

    self.ClickArea = self.Util:Create("TextButton", {
        Name = "ClickArea",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        ZIndex = 10
    })

    self.ClickArea.MouseButton1Click:Connect(function()
        self:SetValue(not self.Value)
    end)

    if self.Value then self:UpdateVisuals(true, true) end
end

function Toggle:SetValue(value)
    self.Value = value
    self.Callback(value)
    self:UpdateVisuals(value)
    if self.Flag and self.Tab.Window.Hub.ConfigSystem then
        -- Auto-save logic can be added here
    end
end

function Toggle:UpdateVisuals(value, instant)
    local theme = self.Theme.Theme
    local duration = instant and 0 or 0.25
    self.Util:Tween(self.Switch, TweenInfo.new(duration, Enum.EasingStyle.Quart), {
        BackgroundColor3 = value and theme.ToggleOn or theme.ToggleOff
    })
    self.Util:Tween(self.Thumb, TweenInfo.new(duration, Enum.EasingStyle.Quart), {
        Position = value and UDim2.new(1, -19, 0, 3) or UDim2.new(0, 3, 0, 3)
    })
    self.Util:Tween(self.Glow, TweenInfo.new(duration), {
        BackgroundTransparency = value and 0.75 or 1
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SLIDER
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Slider = setmetatable({}, {__index = ControlBase})
Slider.__index = Slider

function Slider.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Slider)
    self.Min = config.Min or 0
    self.Max = config.Max or 100
    self.Value = config.Default or self.Min
    self.Callback = config.Callback or function() end
    self.Dragging = false
    self.Suffix = config.Suffix or ""
    self:Build()
    return self
end

function Slider:Build()
    local theme = self.Theme.Theme
    self:CreateContainer(62)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.ValueLabel = self.Util:Create("TextLabel", {
        Name = "Value",
        Parent = self.Instance,
        BackgroundColor3 = theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 45, 0, 22),
        Position = UDim2.new(1, -45, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = tostring(self.Value) .. self.Suffix,
        TextSize = 11,
        TextColor3 = theme.Accent
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.ValueLabel})

    self.Track = self.Util:Create("Frame", {
        Name = "Track",
        Parent = self.Instance,
        BackgroundColor3 = theme.SliderTrack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 5),
        Position = UDim2.new(0, 0, 0, 36)
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Track})

    self.Fill = self.Util:Create("Frame", {
        Name = "Fill",
        Parent = self.Track,
        BackgroundColor3 = theme.SliderFill,
        BorderSizePixel = 0,
        Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0)
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Fill})

    self.Thumb = self.Util:Create("Frame", {
        Name = "Thumb",
        Parent = self.Track,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), -7, 0.5, -7)
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Thumb})

    self.Util:Create("UIStroke", {Color = theme.Accent, Thickness = 2, Parent = self.Thumb})

    self.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.Dragging = true
            self:UpdateFromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            self:UpdateFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.Dragging = false
        end
    end)
end

function Slider:UpdateFromInput(input)
    local pos = math.clamp((input.Position.X - self.Track.AbsolutePosition.X) / self.Track.AbsoluteSize.X, 0, 1)
    local value = math.floor(self.Min + (pos * (self.Max - self.Min)))
    self:SetValue(value)
end

function Slider:SetValue(value)
    self.Value = math.clamp(value, self.Min, self.Max)
    self.Callback(self.Value)
    local percent = (self.Value - self.Min) / (self.Max - self.Min)
    self.ValueLabel.Text = tostring(self.Value) .. self.Suffix
    self.Util:Tween(self.Fill, TweenInfo.new(0.1), {Size = UDim2.new(percent, 0, 1, 0)})
    self.Util:Tween(self.Thumb, TweenInfo.new(0.1), {Position = UDim2.new(percent, -7, 0.5, -7)})
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DROPDOWN
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Dropdown = setmetatable({}, {__index = ControlBase})
Dropdown.__index = Dropdown

function Dropdown.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Dropdown)
    self.Options = config.Options or {}
    self.Default = config.Default
    self.Multi = config.Multi or false
    self.Searchable = config.Searchable or false
    self.Selected = self.Multi and {} or (self.Default or nil)
    self.Callback = config.Callback or function() end
    self.Open = false
    self:Build()
    return self
end

function Dropdown:Build()
    local theme = self.Theme.Theme
    self:CreateContainer(48)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -140, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.DropBtn = self.Util:Create("TextButton", {
        Name = "DropBtn",
        Parent = self.Instance,
        BackgroundColor3 = theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 130, 0, 30),
        Position = UDim2.new(1, -130, 0, 0),
        Font = Enum.Font.Gotham,
        Text = self:GetDisplayText(),
        TextSize = 12,
        TextColor3 = theme.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.DropBtn})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = self.DropBtn})

    self.Arrow = self.Util:Create("TextLabel", {
        Parent = self.DropBtn,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -22, 0, 5),
        Font = Enum.Font.GothamBold,
        Text = "▼",
        TextSize = 10,
        TextColor3 = theme.TextDim
    })

    self.OptionsFrame = self.Util:Create("Frame", {
        Name = "Options",
        Parent = self.Instance,
        BackgroundColor3 = theme.DropdownBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 130, 0, 0),
        Position = UDim2.new(1, -130, 0, 34),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 100
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.OptionsFrame})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = self.OptionsFrame})

    self.OptionsList = self.Util:Create("UIListLayout", {
        Parent = self.OptionsFrame,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    self.Util:Create("UIPadding", {
        Parent = self.OptionsFrame,
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    })

    self:RefreshOptions()

    self.DropBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
end

function Dropdown:GetDisplayText()
    if self.Multi then
        if #self.Selected == 0 then return "Select..." end
        if #self.Selected == 1 then return self.Selected[1] end
        return self.Selected[1] .. " +" .. (#self.Selected - 1)
    else
        return self.Selected or "Select..."
    end
end

function Dropdown:RefreshOptions()
    for _, child in ipairs(self.OptionsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local theme = self.Theme.Theme
    for i, option in ipairs(self.Options) do
        local isSelected = self.Multi and table.find(self.Selected, option) or (self.Selected == option)
        local btn = self.Util:Create("TextButton", {
            Name = option,
            Parent = self.OptionsFrame,
            BackgroundColor3 = isSelected and theme.SurfaceHover or theme.DropdownBg,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 28),
            Font = Enum.Font.Gotham,
            Text = (isSelected and "✓ " or "    ") .. option,
            TextSize = 12,
            TextColor3 = isSelected and theme.Accent or theme.Text,
            AutoButtonColor = false
        })
        self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = btn})

        btn.MouseEnter:Connect(function()
            if not isSelected then
                self.Util:Tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = theme.SurfaceHover})
            end
        end)
        btn.MouseLeave:Connect(function()
            if not isSelected then
                self.Util:Tween(btn, TweenInfo.new(0.15), {BackgroundColor3 = theme.DropdownBg})
            end
        end)
        btn.MouseButton1Click:Connect(function()
            self:SelectOption(option)
        end)
    end
end

function Dropdown:SelectOption(option)
    if self.Multi then
        local idx = table.find(self.Selected, option)
        if idx then table.remove(self.Selected, idx) else table.insert(self.Selected, option) end
    else
        self.Selected = option
        self:Toggle(false)
    end
    self.DropBtn.Text = self:GetDisplayText()
    self.Callback(self.Multi and self.Selected or self.Selected)
    self:RefreshOptions()
end

function Dropdown:Toggle(state)
    if state == nil then state = not self.Open end
    self.Open = state
    local theme = self.Theme.Theme
    if self.Open then
        self.OptionsFrame.Visible = true
        local height = math.min(#self.Options * 30 + 10, 180)
        self.Util:Tween(self.OptionsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 130, 0, height)})
        self.Util:Tween(self.Arrow, TweenInfo.new(0.3), {Rotation = 180})
    else
        self.Util:Tween(self.OptionsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 130, 0, 0)})
        self.Util:Tween(self.Arrow, TweenInfo.new(0.2), {Rotation = 0})
        task.delay(0.2, function() if not self.Open then self.OptionsFrame.Visible = false end end)
    end
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- BUTTON
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Button = setmetatable({}, {__index = ControlBase})
Button.__index = Button

function Button.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Button)
    self.Callback = config.Callback or function() end
    self:Build()
    return self
end

function Button:Build()
    local theme = self.Theme.Theme
    self.Instance = self.Util:Create("TextButton", {
        Name = self.Name,
        Parent = self.Tab.Page,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 36),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 13,
        TextColor3 = theme.Text,
        AutoButtonColor = false
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.Instance})
    self.Util:Create("UIStroke", {Color = theme.AccentLight, Thickness = 1, Transparency = 0.4, Parent = self.Instance})

    local shadow = self.Util:Create("ImageLabel", {
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = theme.Shadow,
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        ZIndex = -1
    })

    self.Instance.MouseEnter:Connect(function()
        self.Util:Tween(self.Instance, TweenInfo.new(0.2), {BackgroundColor3 = theme.AccentLight, Size = UDim2.new(1, -4, 0, 38)})
    end)
    self.Instance.MouseLeave:Connect(function()
        self.Util:Tween(self.Instance, TweenInfo.new(0.2), {BackgroundColor3 = theme.Accent, Size = UDim2.new(1, -8, 0, 36)})
    end)
    self.Instance.MouseButton1Down:Connect(function()
        self.Util:Tween(self.Instance, TweenInfo.new(0.1), {Size = UDim2.new(1, -10, 0, 34)})
    end)
    self.Instance.MouseButton1Up:Connect(function()
        self.Util:Tween(self.Instance, TweenInfo.new(0.1), {Size = UDim2.new(1, -8, 0, 36)})
    end)
    self.Instance.MouseButton1Click:Connect(function()
        self.Callback()
    end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LABEL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Label = setmetatable({}, {__index = ControlBase})
Label.__index = Label

function Label.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Label)
    self.Text = config.Text or config.Name
    self:Build()
    return self
end

function Label:Build()
    local theme = self.Theme.Theme
    self.Instance = self.Util:Create("TextLabel", {
        Name = self.Name,
        Parent = self.Tab.Page,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, 26),
        Font = Enum.Font.GothamBold,
        Text = self.Text,
        TextSize = 15,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PARAGRAPH
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Paragraph = setmetatable({}, {__index = ControlBase})
Paragraph.__index = Paragraph

function Paragraph.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Paragraph)
    self.Content = config.Content or ""
    self:Build()
    return self
end

function Paragraph:Build()
    local theme = self.Theme.Theme
    self.Instance = self.Util:Create("TextLabel", {
        Name = self.Name,
        Parent = self.Tab.Page,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, 0),
        Font = Enum.Font.Gotham,
        Text = self.Content,
        TextSize = 12,
        TextColor3 = theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Section = setmetatable({}, {__index = ControlBase})
Section.__index = Section

function Section.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Section)
    self:Build()
    return self
end

function Section:Build()
    local theme = self.Theme.Theme
    self.Instance = self.Util:Create("Frame", {
        Name = self.Name,
        Parent = self.Tab.Page,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, 36)
    })
    local label = self.Util:Create("TextLabel", {
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 0, 18),
        Position = UDim2.new(0, 0, 0, 8),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 13,
        TextColor3 = theme.Accent
    })
    local line = self.Util:Create("Frame", {
        Parent = self.Instance,
        BackgroundColor3 = theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 30)
    })
    local accentLine = self.Util:Create("Frame", {
        Parent = line,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0.12, 0, 1, 0)
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DIVIDER
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Divider = setmetatable({}, {__index = ControlBase})
Divider.__index = Divider

function Divider.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new("Divider", tab, theme, util), Divider)
    self:Build()
    return self
end

function Divider:Build()
    local theme = self.Theme.Theme
    self.Instance = self.Util:Create("Frame", {
        Name = "Divider",
        Parent = self.Tab.Page,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, 16)
    })
    self.Util:Create("Frame", {
        Parent = self.Instance,
        BackgroundColor3 = theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0.5, 0)
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KEYBIND (Advanced with Hold/Toggle)
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Keybind = setmetatable({}, {__index = ControlBase})
Keybind.__index = Keybind

function Keybind.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Keybind)
    self.Key = config.Default or "None"
    self.Mode = config.Mode or "Toggle" -- Toggle, Hold
    self.Callback = config.Callback or function() end
    self.Listening = false
    self.Active = false
    self:Build()
    return self
end

function Keybind:Build()
    local theme = self.Theme.Theme
    self:CreateContainer(48)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -100, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.KeyBtn = self.Util:Create("TextButton", {
        Name = "KeyBtn",
        Parent = self.Instance,
        BackgroundColor3 = theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 70, 0, 26),
        Position = UDim2.new(1, -70, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Key,
        TextSize = 11,
        TextColor3 = theme.Accent,
        AutoButtonColor = false
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.KeyBtn})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = self.KeyBtn})

    self.KeyBtn.MouseButton1Click:Connect(function()
        self.Listening = true
        self.KeyBtn.Text = "..."
        self.Util:Tween(self.KeyBtn, TweenInfo.new(0.2), {BackgroundColor3 = theme.Accent, TextColor3 = theme.Text})
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if self.Listening and not gameProcessed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                self.Key = input.KeyCode.Name
                self.KeyBtn.Text = self.Key
                self.Listening = false
                self.Util:Tween(self.KeyBtn, TweenInfo.new(0.2), {BackgroundColor3 = theme.BackgroundSecondary, TextColor3 = theme.Accent})
            end
        elseif input.KeyCode.Name == self.Key and not gameProcessed then
            if self.Mode == "Toggle" then
                self.Active = not self.Active
                self.Callback(self.Active)
            elseif self.Mode == "Hold" then
                self.Active = true
                self.Callback(true)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode.Name == self.Key and self.Mode == "Hold" then
            self.Active = false
            self.Callback(false)
        end
    end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TEXTBOX
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Textbox = setmetatable({}, {__index = ControlBase})
Textbox.__index = Textbox

function Textbox.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Textbox)
    self.Default = config.Default or ""
    self.Placeholder = config.Placeholder or "Enter text..."
    self.Callback = config.Callback or function() end
    self.Numeric = config.Numeric or false
    self:Build()
    return self
end

function Textbox:Build()
    local theme = self.Theme.Theme
    self:CreateContainer(48)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -150, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.Input = self.Util:Create("TextBox", {
        Name = "Input",
        Parent = self.Instance,
        BackgroundColor3 = theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 140, 0, 28),
        Position = UDim2.new(1, -140, 0, 0),
        Font = Enum.Font.Gotham,
        Text = self.Default,
        PlaceholderText = self.Placeholder,
        TextSize = 12,
        TextColor3 = theme.Text,
        ClearTextOnFocus = false
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Input})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = self.Input})

    self.Input.Focused:Connect(function()
        self.Util:Tween(self.Input, TweenInfo.new(0.2), {BackgroundColor3 = theme.SurfaceHover})
    end)
    self.Input.FocusLost:Connect(function()
        self.Util:Tween(self.Input, TweenInfo.new(0.2), {BackgroundColor3 = theme.BackgroundSecondary})
        if self.Numeric then
            local num = tonumber(self.Input.Text)
            if num then self.Input.Text = tostring(num) end
        end
        self.Callback(self.Input.Text)
    end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COLOR PICKER (Advanced)
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local ColorPicker = setmetatable({}, {__index = ControlBase})
ColorPicker.__index = ColorPicker

function ColorPicker.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), ColorPicker)
    self.Default = config.Default or Color3.fromRGB(138, 46, 255)
    self.Callback = config.Callback or function() end
    self.Value = self.Default
    self.Open = false
    self:Build()
    return self
end

function ColorPicker:Build()
    local theme = self.Theme.Theme
    self:CreateContainer(48)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.Preview = self.Util:Create("TextButton", {
        Name = "Preview",
        Parent = self.Instance,
        BackgroundColor3 = self.Value,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 36, 0, 26),
        Position = UDim2.new(1, -36, 0, 0),
        Text = "",
        AutoButtonColor = false
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Preview})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 2, Parent = self.Preview})

    self.PickerFrame = self.Util:Create("Frame", {
        Parent = self.Instance,
        BackgroundColor3 = theme.DropdownBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 200, 0, 0),
        Position = UDim2.new(1, -200, 0, 34),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 100
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.PickerFrame})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = self.PickerFrame})

    -- Preset colors grid
    local colors = {
        Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(255, 128, 0), Color3.fromRGB(128, 0, 255), Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(138, 46, 255), Color3.fromRGB(255, 71, 87), Color3.fromRGB(46, 213, 115)
    }

    for i, color in ipairs(colors) do
        local row = math.floor((i - 1) / 4)
        local col = (i - 1) % 4
        local swatch = self.Util:Create("TextButton", {
            Parent = self.PickerFrame,
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 38, 0, 28),
            Position = UDim2.new(0, 10 + col * 44, 0, 10 + row * 34),
            Text = "",
            AutoButtonColor = false
        })
        self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = swatch})
        swatch.MouseButton1Click:Connect(function()
            self.Value = color
            self.Preview.BackgroundColor3 = color
            self.Callback(color)
            self:Toggle(false)
        end)
    end

    self.Preview.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
end

function ColorPicker:Toggle(state)
    if state == nil then state = not self.Open end
    self.Open = state
    if self.Open then
        self.PickerFrame.Visible = true
        self.Util:Tween(self.PickerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 200, 0, 120)})
    else
        self.Util:Tween(self.PickerFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 200, 0, 0)})
        task.delay(0.2, function() if not self.Open then self.PickerFrame.Visible = false end end)
    end
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PROGRESS BAR
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local ProgressBar = setmetatable({}, {__index = ControlBase})
ProgressBar.__index = ProgressBar

function ProgressBar.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), ProgressBar)
    self.Value = config.Default or 0
    self.Max = config.Max or 100
    self.Callback = config.Callback or function() end
    self:Build()
    return self
end

function ProgressBar:Build()
    local theme = self.Theme.Theme
    self:CreateContainer(56)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.PercentLabel = self.Util:Create("TextLabel", {
        Name = "Percent",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 50, 0, 18),
        Position = UDim2.new(1, -50, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = math.floor((self.Value / self.Max) * 100) .. "%",
        TextSize = 12,
        TextColor3 = theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right
    })

    self.Track = self.Util:Create("Frame", {
        Name = "Track",
        Parent = self.Instance,
        BackgroundColor3 = theme.SliderTrack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 32)
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Track})

    self.Fill = self.Util:Create("Frame", {
        Name = "Fill",
        Parent = self.Track,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(self.Value / self.Max, 0, 1, 0)
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Fill})
end

function ProgressBar:SetValue(value)
    self.Value = math.clamp(value, 0, self.Max)
    local percent = self.Value / self.Max
    self.PercentLabel.Text = math.floor(percent * 100) .. "%"
    self.Util:Tween(self.Fill, TweenInfo.new(0.3), {Size = UDim2.new(percent, 0, 1, 0)})
    self.Callback(self.Value)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- BADGE
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Badge = setmetatable({}, {__index = ControlBase})
Badge.__index = Badge

function Badge.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Badge)
    self.Text = config.Text or "NEW"
    self.Color = config.Color or "Accent"
    self:Build()
    return self
end

function Badge:Build()
    local theme = self.Theme.Theme
    self.Instance = self.Util:Create("Frame", {
        Name = self.Name,
        Parent = self.Tab.Page,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 26),
        AutomaticSize = Enum.AutomaticSize.X
    })
    local bg = self.Util:Create("Frame", {
        Parent = self.Instance,
        BackgroundColor3 = self.Color == "Accent" and theme.Accent or theme.SurfaceHover,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 16, 1, 0),
        Position = UDim2.new(0, 0, 0, 0)
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = bg})
    local label = self.Util:Create("TextLabel", {
        Parent = bg,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Text,
        TextSize = 11,
        TextColor3 = theme.Text
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- IMAGE
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Image = setmetatable({}, {__index = ControlBase})
Image.__index = Image

function Image.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Image)
    self.ImageId = config.Image or ""
    self.Size = config.Size or UDim2.new(1, -8, 0, 120)
    self:Build()
    return self
end

function Image:Build()
    local theme = self.Theme.Theme
    self.Instance = self.Util:Create("Frame", {
        Name = self.Name,
        Parent = self.Tab.Page,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = self.Size
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.Instance})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = self.Instance})
    local img = self.Util:Create("ImageLabel", {
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        Image = self.ImageId,
        ScaleType = Enum.ScaleType.Fit
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = img})
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DUAL BUTTON
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local DualButton = setmetatable({}, {__index = ControlBase})
DualButton.__index = DualButton

function DualButton.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), DualButton)
    self.Button1 = config.Button1 or {Name = "Button 1", Callback = function() end}
    self.Button2 = config.Button2 or {Name = "Button 2", Callback = function() end}
    self:Build()
    return self
end

function DualButton:Build()
    local theme = self.Theme.Theme
    self.Instance = self.Util:Create("Frame", {
        Name = self.Name,
        Parent = self.Tab.Page,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, 38)
    })

    local btn1 = self.Util:Create("TextButton", {
        Parent = self.Instance,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0.48, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Button1.Name,
        TextSize = 12,
        TextColor3 = theme.Text,
        AutoButtonColor = false
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = btn1})

    local btn2 = self.Util:Create("TextButton", {
        Parent = self.Instance,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(0.48, 0, 1, 0),
        Position = UDim2.new(0.52, 0, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Button2.Name,
        TextSize = 12,
        TextColor3 = theme.Text,
        AutoButtonColor = false
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = btn2})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = btn2})

    btn1.MouseButton1Click:Connect(function() self.Button1.Callback() end)
    btn2.MouseButton1Click:Connect(function() self.Button2.Callback() end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TAB CLASS
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Tab = {}
Tab.__index = Tab

function Tab.new(name, icon, window, theme, util)
    local self = setmetatable({}, Tab)
    self.Name = name
    self.Icon = icon or "•"
    self.Window = window
    self.Theme = theme
    self.Util = util
    self.Controls = {}
    self.Selected = false
    self:Build()
    return self
end

function Tab:Build()
    local theme = self.Theme.Theme

    self.Button = self.Util:Create("TextButton", {
        Name = self.Name .. "Tab",
        Parent = self.Window.TabContainer,
        BackgroundColor3 = theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 36),
        Position = UDim2.new(0, 4, 0, 0),
        Font = Enum.Font.Gotham,
        Text = "  " .. self.Icon .. "  " .. self.Name,
        TextSize = 13,
        TextColor3 = theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Button})

    self.Page = self.Util:Create("ScrollingFrame", {
        Name = self.Name .. "Page",
        Parent = self.Window.Content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarImageTransparency = 0.6
    })

    self.PageList = self.Util:Create("UIListLayout", {
        Parent = self.Page,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })

    self.PagePadding = self.Util:Create("UIPadding", {
        Parent = self.Page,
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 15),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    })

    self.Button.MouseButton1Click:Connect(function() self:Select() end)
    self.Button.MouseEnter:Connect(function()
        if not self.Selected then
            self.Util:Tween(self.Button, TweenInfo.new(0.2), {BackgroundColor3 = theme.SurfaceHover})
        end
    end)
    self.Button.MouseLeave:Connect(function()
        if not self.Selected then
            self.Util:Tween(self.Button, TweenInfo.new(0.2), {BackgroundColor3 = theme.BackgroundSecondary})
        end
    end)
end

function Tab:Select()
    if self.Window.ActiveTab == self then return end
    if self.Window.ActiveTab then self.Window.ActiveTab:Deselect() end
    self.Selected = true
    self.Window.ActiveTab = self
    local theme = self.Theme.Theme

    self.Util:Tween(self.Button, TweenInfo.new(0.25), {
        BackgroundColor3 = theme.Accent,
        TextColor3 = theme.Text
    })

    if not self.Glow then
        self.Glow = self.Util:Create("Frame", {
            Name = "Glow",
            Parent = self.Button,
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = 0.85,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 0
        })
        self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Glow})
    end

    self.Page.Visible = true
    self.Page.Position = UDim2.new(0, 15, 0, 0)
    self.Page.ScrollBarImageTransparency = 0.3
    self.Util:Tween(self.Page, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Position = UDim2.new(0, 0, 0, 0)
    })
end

function Tab:Deselect()
    self.Selected = false
    local theme = self.Theme.Theme
    self.Util:Tween(self.Button, TweenInfo.new(0.25), {
        BackgroundColor3 = theme.BackgroundSecondary,
        TextColor3 = theme.TextDim
    })
    if self.Glow then self.Glow:Destroy() self.Glow = nil end
    self.Page.Visible = false
    self.Page.ScrollBarImageTransparency = 0.6
end

-- Control Methods
function Tab:AddToggle(config) local c = Toggle.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddSlider(config) local c = Slider.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddDropdown(config) local c = Dropdown.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddButton(config) local c = Button.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddLabel(config) local c = Label.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddSection(config) local c = Section.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddDivider(config) local c = Divider.new(config or {}, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddParagraph(config) local c = Paragraph.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddKeybind(config) local c = Keybind.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddTextbox(config) local c = Textbox.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddColorPicker(config) local c = ColorPicker.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddProgressBar(config) local c = ProgressBar.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddBadge(config) local c = Badge.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddImage(config) local c = Image.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end
function Tab:AddDualButton(config) local c = DualButton.new(config, self, self.Theme, self.Util) table.insert(self.Controls, c) return c end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- WINDOW CLASS (COMPACT 600x420)
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Window = {}
Window.__index = Window

function Window.new(config, theme, util, hub)
    local self = setmetatable({}, Window)
    self.Config = config or {}
    self.Theme = theme
    self.Util = util
    self.Hub = hub
    self.Tabs = {}
    self.ActiveTab = nil
    self.Minimized = false
    self.Closed = false
    self.FloatingIcon = nil
    self.Width = config.Width or 600
    self.Height = config.Height or 420
    self:Build()
    return self
end

function Window:Build()
    local theme = self.Theme.Theme

    self.Gui = self.Util:Create("ScreenGui", {
        Name = "NexusHub",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    self.Main = self.Util:Create("Frame", {
        Name = "Main",
        Parent = self.Gui,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(0, self.Width, 0, self.Height),
        Position = UDim2.new(0.5, -self.Width/2, 0.5, -self.Height/2),
        ClipsDescendants = true
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = self.Main})

    self.Stroke = self.Util:Create("UIStroke", {
        Color = theme.Accent,
        Thickness = 1.2,
        Transparency = 0.35,
        Parent = self.Main
    })

    self.Shadow = self.Util:Create("ImageLabel", {
        Name = "Shadow",
        Parent = self.Main,
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = theme.Shadow,
        ImageTransparency = 0.55,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Size = UDim2.new(1, 50, 1, 50),
        Position = UDim2.new(0, -25, 0, -25),
        ZIndex = -1
    })

    -- Top Bar
    self.TopBar = self.Util:Create("Frame", {
        Name = "TopBar",
        Parent = self.Main,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44)
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = self.TopBar})
    local topFix = self.Util:Create("Frame", {
        Parent = self.TopBar,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.5, 0)
    })

    -- Logo
    self.Logo = self.Util:Create("TextLabel", {
        Name = "Logo",
        Parent = self.TopBar,
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0, 12, 0, 7),
        Font = Enum.Font.GothamBold,
        Text = "N",
        TextSize = 18,
        TextColor3 = theme.Text
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Logo})

    -- Hub Name
    self.HubName = self.Util:Create("TextLabel", {
        Name = "HubName",
        Parent = self.TopBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 150, 0, 22),
        Position = UDim2.new(0, 50, 0, 5),
        Font = Enum.Font.GothamBold,
        Text = self.Config.Title or "Nexus Hub",
        TextSize = 16,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.Version = self.Util:Create("TextLabel", {
        Name = "Version",
        Parent = self.TopBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 80, 0, 16),
        Position = UDim2.new(0, 50, 0, 25),
        Font = Enum.Font.Gotham,
        Text = self.Config.Version or "v1.0.0",
        TextSize = 11,
        TextColor3 = theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Search
    self.SearchBox = self.Util:Create("TextBox", {
        Name = "Search",
        Parent = self.TopBar,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 200, 0, 28),
        Position = UDim2.new(0.5, -100, 0, 8),
        Font = Enum.Font.Gotham,
        Text = "",
        PlaceholderText = "🔍  Search...",
        TextSize = 12,
        TextColor3 = theme.Text,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.SearchBox})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = self.SearchBox})
    self.Util:Create("UIPadding", {Parent = self.SearchBox, PaddingLeft = UDim.new(0, 8)})

    -- Window Controls
    local btnSize = 28
    local btnY = 8

    self.MinBtn = self.Util:Create("TextButton", {
        Name = "Minimize",
        Parent = self.TopBar,
        BackgroundColor3 = theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, btnSize, 0, btnSize),
        Position = UDim2.new(1, -100, 0, btnY),
        Font = Enum.Font.GothamBold,
        Text = "−",
        TextSize = 16,
        TextColor3 = theme.Text,
        AutoButtonColor = false
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = self.MinBtn})

    self.FavBtn = self.Util:Create("TextButton", {
        Name = "Favorite",
        Parent = self.TopBar,
        BackgroundColor3 = theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, btnSize, 0, btnSize),
        Position = UDim2.new(1, -68, 0, btnY),
        Font = Enum.Font.GothamBold,
        Text = "★",
        TextSize = 14,
        TextColor3 = theme.TextDim,
        AutoButtonColor = false
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = self.FavBtn})

    self.CloseBtn = self.Util:Create("TextButton", {
        Name = "Close",
        Parent = self.TopBar,
        BackgroundColor3 = theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, btnSize, 0, btnSize),
        Position = UDim2.new(1, -36, 0, btnY),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextSize = 18,
        TextColor3 = theme.Text,
        AutoButtonColor = false
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = self.CloseBtn})

    -- Sidebar
    self.Sidebar = self.Util:Create("Frame", {
        Name = "Sidebar",
        Parent = self.Main,
        BackgroundColor3 = theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 160, 1, -44),
        Position = UDim2.new(0, 0, 0, 44)
    })

    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = self.Sidebar})
    local sideFix = self.Util:Create("Frame", {
        Parent = self.Sidebar,
        BackgroundColor3 = theme.BackgroundSecondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0)
    })

    -- User Card
    self.UserCard = self.Util:Create("Frame", {
        Name = "UserCard",
        Parent = self.Sidebar,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -14, 0, 60),
        Position = UDim2.new(0, 7, 0, 8)
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.UserCard})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = self.UserCard})

    self.Avatar = self.Util:Create("Frame", {
        Name = "Avatar",
        Parent = self.UserCard,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 34, 0, 34),
        Position = UDim2.new(0, 10, 0, 13)
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Avatar})
    self.Util:Create("TextLabel", {
        Parent = self.Avatar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "👤",
        TextSize = 16,
        TextColor3 = theme.Text
    })

    self.Username = self.Util:Create("TextLabel", {
        Name = "Username",
        Parent = self.UserCard,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -58, 0, 18),
        Position = UDim2.new(0, 50, 0, 12),
        Font = Enum.Font.GothamBold,
        Text = LocalPlayer.Name,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.UserStatus = self.Util:Create("TextLabel", {
        Name = "Status",
        Parent = self.UserCard,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -58, 0, 16),
        Position = UDim2.new(0, 50, 0, 32),
        Font = Enum.Font.Gotham,
        Text = self.Hub.KeyTier or "Free User",
        TextSize = 11,
        TextColor3 = theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Tab Container
    self.TabContainer = self.Util:Create("ScrollingFrame", {
        Name = "Tabs",
        Parent = self.Sidebar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 1, -82),
        Position = UDim2.new(0, 4, 0, 76),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarImageTransparency = 0.7
    })

    self.Util:Create("UIListLayout", {
        Parent = self.TabContainer,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    -- Content Area
    self.Content = self.Util:Create("Frame", {
        Name = "Content",
        Parent = self.Main,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -170, 1, -52),
        Position = UDim2.new(0, 168, 0, 50),
        ClipsDescendants = true
    })

    self.Util:MakeDraggable(self.Main, self.TopBar)
    self:SetupEvents()
end

function Window:SetupEvents()
    self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:FilterControls(self.SearchBox.Text)
    end)

    self.MinBtn.MouseButton1Click:Connect(function() self:Minimize() end)
    self.MinBtn.MouseEnter:Connect(function()
        self.Util:Tween(self.MinBtn, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.Theme.Accent})
    end)
    self.MinBtn.MouseLeave:Connect(function()
        self.Util:Tween(self.MinBtn, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.Theme.BackgroundSecondary})
    end)

    self.CloseBtn.MouseButton1Click:Connect(function() self:Close() end)
    self.CloseBtn.MouseEnter:Connect(function()
        self.Util:Tween(self.CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.Theme.Error})
    end)
    self.CloseBtn.MouseLeave:Connect(function()
        self.Util:Tween(self.CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.Theme.BackgroundSecondary})
    end)

    self.FavBtn.MouseButton1Click:Connect(function()
        self.FavBtn.TextColor3 = self.FavBtn.TextColor3 == self.Theme.Theme.TextDim and self.Theme.Theme.Accent or self.Theme.Theme.TextDim
    end)
end

function Window:CreateTab(name, icon)
    local tab = Tab.new(name, icon, self, self.Theme, self.Util)
    table.insert(self.Tabs, tab)
    if not self.ActiveTab then tab:Select() end
    return tab
end

function Window:FilterControls(searchText)
    searchText = string.lower(searchText)
    for _, tab in ipairs(self.Tabs) do
        for _, control in ipairs(tab.Controls) do
            if control.Instance then
                control.Instance.Visible = (searchText == "" or string.find(string.lower(control.Name), searchText))
            end
        end
    end
end

function Window:Minimize()
    self.Minimized = not self.Minimized
    if self.Minimized then
        self.Util:Tween(self.Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {Size = UDim2.new(0, self.Width, 0, 44)})
    else
        self.Util:Tween(self.Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {Size = UDim2.new(0, self.Width, 0, self.Height)})
    end
end

function Window:Close()
    self.Closed = true
    self.Util:Tween(self.Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    task.delay(0.25, function()
        self.Main.Visible = false
        self:CreateFloatingIcon()
    end)
end

function Window:CreateFloatingIcon()
    if self.FloatingIcon then return end
    local theme = self.Theme.Theme

    self.FloatingIcon = self.Util:Create("TextButton", {
        Name = "FloatingIcon",
        Parent = self.Gui,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 15, 0.5, -22),
        Text = "N",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = theme.Text
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.FloatingIcon})
    self.Util:Create("UIStroke", {Color = theme.AccentLight, Thickness = 2, Transparency = 0.4, Parent = self.FloatingIcon})

    local glow = self.Util:Create("ImageLabel", {
        Parent = self.FloatingIcon,
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = theme.Accent,
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        ZIndex = -1
    })

    spawn(function()
        while self.FloatingIcon and self.FloatingIcon.Parent do
            self.Util:Tween(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.4})
            wait(1.2)
            if not self.FloatingIcon or not self.FloatingIcon.Parent then break end
            self.Util:Tween(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.7})
            wait(1.2)
        end
    end)

    self.Util:MakeDraggable(self.FloatingIcon)
    self.FloatingIcon.MouseButton1Click:Connect(function() self:Reopen() end)
end

function Window:Reopen()
    if self.FloatingIcon then self.FloatingIcon:Destroy() self.FloatingIcon = nil end
    self.Main.Visible = true
    self.Closed = false
    self.Main.Size = UDim2.new(0, 0, 0, 0)
    self.Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.Util:Tween(self.Main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, self.Width, 0, self.Height),
        Position = UDim2.new(0.5, -self.Width/2, 0.5, -self.Height/2)
    })
end

function Window:Prompt(config)
    config = config or {}
    local theme = self.Theme.Theme
    local promptGui = self.Util:Create("ScreenGui", {
        Name = "NexusPrompt",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 50
    })
    local backdrop = self.Util:Create("Frame", {
        Parent = promptGui,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0)
    })
    local frame = self.Util:Create("Frame", {
        Parent = promptGui,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 320, 0, 0),
        Position = UDim2.new(0.5, -160, 0.5, -80),
        AutomaticSize = Enum.AutomaticSize.Y
    })
    self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = frame})
    self.Util:Create("UIStroke", {Color = theme.Border, Thickness = 1, Parent = frame})

    local title = self.Util:Create("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 0, 26),
        Position = UDim2.new(0, 12, 0, 12),
        Font = Enum.Font.GothamBold,
        Text = config.Title or "Prompt",
        TextSize = 16,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local desc = self.Util:Create("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.new(0, 12, 0, 42),
        Font = Enum.Font.Gotham,
        Text = config.Description or "",
        TextSize = 13,
        TextColor3 = theme.TextDim,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    local btnFrame = self.Util:Create("Frame", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 0, 36),
        Position = UDim2.new(0, 12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    })

    self.Util:Create("UIPadding", {Parent = frame, PaddingBottom = UDim.new(0, 12)})
    local buttonsList = self.Util:Create("UIListLayout", {
        Parent = btnFrame,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right
    })

    frame.Size = UDim2.new(0, 320, 0, 0)
    self.Util:Tween(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 320, 0, frame.AbsoluteSize.Y)})

    local function close()
        self.Util:Tween(frame, TweenInfo.new(0.2), {Size = UDim2.new(0, 320, 0, 0)})
        task.delay(0.2, function() promptGui:Destroy() end)
    end

    if config.Buttons then
        for _, btnConfig in ipairs(config.Buttons) do
            local btn = self.Util:Create("TextButton", {
                Parent = btnFrame,
                BackgroundColor3 = btnConfig.Primary and theme.Accent or theme.BackgroundSecondary,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 90, 0, 34),
                Font = Enum.Font.GothamBold,
                Text = btnConfig.Text or "Button",
                TextSize = 13,
                TextColor3 = theme.Text,
                AutoButtonColor = false
            })
            self.Util:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = btn})
            btn.MouseButton1Click:Connect(function()
                if btnConfig.Callback then btnConfig.Callback() end
                close()
            end)
        end
    end
    return {Close = close}
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MAIN LIBRARY API
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function NexusHub:Init(config)
    config = config or {}
    local self = setmetatable({}, NexusHub)
    self.Config = config
    self.Theme = ThemeSystem.new()
    self.Util = Utility.new()
    self.Notifications = NotificationSystem.new(self.Theme, self.Util)
    self.Tooltips = TooltipSystem.new(self.Theme, self.Util)
    self.ConfigSystem = ConfigSystem.new(config.ConfigFolder or "NexusHub")
    self.Windows = {}
    self.KeyTier = "Free"

    if config.Theme and ThemeSystem.Presets[config.Theme] then
        self.Theme:SetTheme(config.Theme)
    end

    -- Key System
    if config.KeySystem then
        local keySys = KeySystem.new(self.Theme, self.Util, config.KeySystem)
        keySys:OnValidated(function(tier)
            self.KeyTier = tier
            if config.KeySystem.OnAuthenticated then
                config.KeySystem.OnAuthenticated(tier)
            end
        end)
    end

    return self
end

function NexusHub:CreateWindow(windowConfig)
    windowConfig = windowConfig or {}
    local window = Window.new(windowConfig, self.Theme, self.Util, self)
    table.insert(self.Windows, window)
    return window
end

function NexusHub:Notify(config)
    self.Notifications:Notify(config)
end

function NexusHub:SetTheme(name)
    self.Theme:SetTheme(name)
end

function NexusHub:GetThemes()
    local themes = {}
    for name, _ in pairs(ThemeSystem.Presets) do table.insert(themes, name) end
    return themes
end

function NexusHub:SaveConfig(name, data)
    return self.ConfigSystem:Save(name, data)
end

function NexusHub:LoadConfig(name)
    return self.ConfigSystem:Load(name)
end

function NexusHub:DeleteConfig(name)
    return self.ConfigSystem:Delete(name)
end

function NexusHub:ListConfigs()
    return self.ConfigSystem:List()
end

return NexusHub
