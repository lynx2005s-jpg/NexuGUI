--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                     NEXUS HUB v1.0.0                       ║
    ║            Professional Roblox GUI Library                   ║
    ║                                                              ║
    ║  Features:                                                   ║
    ║  • Modern Dark Futuristic UI                                ║
    ║  • Neon Purple Accent Theme                                 ║
    ║  • Full OOP Architecture                                    ║
    ║  • Smooth Tween Animations                                  ║
    ║  • 15+ UI Components                                        ║
    ║  • Theme System (5 Presets)                                 ║
    ║  • Config Save/Load System                                  ║
    ║  • Notification Queue System                                ║
    ║  • Mobile & PC Compatible                                   ║
    ║  • Optimized & Memory Safe                                  ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

local NexusHub = {}
NexusHub.__index = NexusHub

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SERVICES
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- UTILITY MODULE
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Utility = {}
Utility.__index = Utility

function Utility.new()
    local self = setmetatable({}, Utility)
    self.Connections = {}
    self.Tweens = {}
    return self
end

function Utility:Connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(self.Connections, conn)
    return conn
end

function Utility:DisconnectAll()
    for _, conn in ipairs(self.Connections) do
        if conn then
            pcall(function() conn:Disconnect() end)
        end
    end
    self.Connections = {}
end

function Utility:Tween(instance, tweenInfo, properties)
    if not instance or not instance.Parent then return nil end
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    table.insert(self.Tweens, tween)

    tween.Completed:Connect(function()
        for i, t in ipairs(self.Tweens) do
            if t == tween then
                table.remove(self.Tweens, i)
                break
            end
        end
    end)

    return tween
end

function Utility:Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            pcall(function()
                instance[prop] = value
            end)
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

function Utility:MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    self:Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    self:Connect(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

function Utility:Ripple(button, inputPosition)
    local theme = self.Theme or {}
    local ripple = self:Create("Frame", {
        Parent = button,
        BackgroundColor3 = theme.Accent or Color3.fromRGB(138, 46, 255),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, inputPosition.X - button.AbsolutePosition.X, 0, inputPosition.Y - button.AbsolutePosition.Y),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = button.ZIndex + 1
    })

    self:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = ripple
    })

    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5

    self:Tween(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    })

    task.delay(0.5, function()
        if ripple then ripple:Destroy() end
    end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- THEME SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local ThemeSystem = {}
ThemeSystem.__index = ThemeSystem

ThemeSystem.Presets = {
    DarkPurple = {
        Background = Color3.fromRGB(15, 16, 21),
        Surface = Color3.fromRGB(22, 23, 30),
        SurfaceHighlight = Color3.fromRGB(30, 31, 40),
        Accent = Color3.fromRGB(138, 46, 255),
        AccentGlow = Color3.fromRGB(168, 96, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(180, 180, 180),
        TextDark = Color3.fromRGB(120, 120, 120),
        Border = Color3.fromRGB(40, 40, 50),
        BorderHover = Color3.fromRGB(80, 80, 100),
        Success = Color3.fromRGB(46, 255, 139),
        Error = Color3.fromRGB(255, 46, 46),
        Warning = Color3.fromRGB(255, 196, 46),
        Info = Color3.fromRGB(46, 139, 255),
        ToggleOn = Color3.fromRGB(138, 46, 255),
        ToggleOff = Color3.fromRGB(60, 60, 70),
        SliderFill = Color3.fromRGB(138, 46, 255),
        SliderTrack = Color3.fromRGB(40, 40, 50),
        DropdownBg = Color3.fromRGB(30, 31, 40),
        NotificationBg = Color3.fromRGB(25, 26, 35),
        Glow = Color3.fromRGB(138, 46, 255),
        Shadow = Color3.fromRGB(0, 0, 0)
    },
    MidnightBlue = {
        Background = Color3.fromRGB(10, 12, 28),
        Surface = Color3.fromRGB(18, 22, 40),
        SurfaceHighlight = Color3.fromRGB(28, 32, 55),
        Accent = Color3.fromRGB(59, 130, 246),
        AccentGlow = Color3.fromRGB(96, 165, 250),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(180, 190, 220),
        TextDark = Color3.fromRGB(120, 130, 160),
        Border = Color3.fromRGB(35, 40, 70),
        BorderHover = Color3.fromRGB(70, 80, 130),
        Success = Color3.fromRGB(46, 255, 139),
        Error = Color3.fromRGB(255, 46, 46),
        Warning = Color3.fromRGB(255, 196, 46),
        Info = Color3.fromRGB(59, 130, 246),
        ToggleOn = Color3.fromRGB(59, 130, 246),
        ToggleOff = Color3.fromRGB(50, 55, 80),
        SliderFill = Color3.fromRGB(59, 130, 246),
        SliderTrack = Color3.fromRGB(35, 40, 70),
        DropdownBg = Color3.fromRGB(25, 28, 50),
        NotificationBg = Color3.fromRGB(20, 23, 40),
        Glow = Color3.fromRGB(59, 130, 246),
        Shadow = Color3.fromRGB(0, 0, 0)
    },
    Crimson = {
        Background = Color3.fromRGB(21, 10, 12),
        Surface = Color3.fromRGB(35, 18, 22),
        SurfaceHighlight = Color3.fromRGB(50, 25, 30),
        Accent = Color3.fromRGB(220, 38, 38),
        AccentGlow = Color3.fromRGB(248, 113, 113),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(220, 180, 180),
        TextDark = Color3.fromRGB(160, 120, 120),
        Border = Color3.fromRGB(70, 35, 40),
        BorderHover = Color3.fromRGB(130, 70, 80),
        Success = Color3.fromRGB(46, 255, 139),
        Error = Color3.fromRGB(255, 46, 46),
        Warning = Color3.fromRGB(255, 196, 46),
        Info = Color3.fromRGB(220, 38, 38),
        ToggleOn = Color3.fromRGB(220, 38, 38),
        ToggleOff = Color3.fromRGB(80, 50, 55),
        SliderFill = Color3.fromRGB(220, 38, 38),
        SliderTrack = Color3.fromRGB(70, 35, 40),
        DropdownBg = Color3.fromRGB(40, 20, 25),
        NotificationBg = Color3.fromRGB(30, 15, 18),
        Glow = Color3.fromRGB(220, 38, 38),
        Shadow = Color3.fromRGB(0, 0, 0)
    },
    Emerald = {
        Background = Color3.fromRGB(10, 21, 15),
        Surface = Color3.fromRGB(18, 35, 25),
        SurfaceHighlight = Color3.fromRGB(25, 50, 35),
        Accent = Color3.fromRGB(16, 185, 129),
        AccentGlow = Color3.fromRGB(52, 211, 153),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(180, 220, 200),
        TextDark = Color3.fromRGB(120, 160, 130),
        Border = Color3.fromRGB(35, 70, 50),
        BorderHover = Color3.fromRGB(70, 130, 90),
        Success = Color3.fromRGB(16, 185, 129),
        Error = Color3.fromRGB(255, 46, 46),
        Warning = Color3.fromRGB(255, 196, 46),
        Info = Color3.fromRGB(16, 185, 129),
        ToggleOn = Color3.fromRGB(16, 185, 129),
        ToggleOff = Color3.fromRGB(50, 80, 60),
        SliderFill = Color3.fromRGB(16, 185, 129),
        SliderTrack = Color3.fromRGB(35, 70, 50),
        DropdownBg = Color3.fromRGB(20, 40, 28),
        NotificationBg = Color3.fromRGB(15, 30, 20),
        Glow = Color3.fromRGB(16, 185, 129),
        Shadow = Color3.fromRGB(0, 0, 0)
    },
    Light = {
        Background = Color3.fromRGB(245, 245, 250),
        Surface = Color3.fromRGB(255, 255, 255),
        SurfaceHighlight = Color3.fromRGB(240, 240, 245),
        Accent = Color3.fromRGB(138, 46, 255),
        AccentGlow = Color3.fromRGB(168, 96, 255),
        Text = Color3.fromRGB(30, 30, 40),
        TextDim = Color3.fromRGB(100, 100, 120),
        TextDark = Color3.fromRGB(150, 150, 170),
        Border = Color3.fromRGB(220, 220, 230),
        BorderHover = Color3.fromRGB(180, 180, 200),
        Success = Color3.fromRGB(46, 255, 139),
        Error = Color3.fromRGB(255, 46, 46),
        Warning = Color3.fromRGB(255, 196, 46),
        Info = Color3.fromRGB(46, 139, 255),
        ToggleOn = Color3.fromRGB(138, 46, 255),
        ToggleOff = Color3.fromRGB(200, 200, 210),
        SliderFill = Color3.fromRGB(138, 46, 255),
        SliderTrack = Color3.fromRGB(220, 220, 230),
        DropdownBg = Color3.fromRGB(250, 250, 255),
        NotificationBg = Color3.fromRGB(255, 255, 255),
        Glow = Color3.fromRGB(138, 46, 255),
        Shadow = Color3.fromRGB(200, 200, 210)
    }
}

function ThemeSystem.new()
    local self = setmetatable({}, ThemeSystem)
    self.Current = "DarkPurple"
    self.Theme = ThemeSystem.Presets.DarkPurple
    self.Listeners = {}
    return self
end

function ThemeSystem:SetTheme(name)
    if ThemeSystem.Presets[name] then
        self.Current = name
        self.Theme = ThemeSystem.Presets[name]
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

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NOTIFICATION SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

function NotificationSystem.new(theme, util)
    local self = setmetatable({}, NotificationSystem)
    self.Theme = theme
    self.Util = util
    self.Queue = {}
    self.Active = {}
    self.MaxNotifications = 5
    self.Spacing = 10
    self.Width = 320

    self.Container = util:Create("ScreenGui", {
        Name = "NexusNotifications",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    self.Holder = util:Create("Frame", {
        Name = "Holder",
        Parent = self.Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, self.Width, 1, 0),
        Position = UDim2.new(1, -self.Width - 20, 0, 20),
        AnchorPoint = Vector2.new(0, 0)
    })

    return self
end

function NotificationSystem:Notify(config)
    config = config or {}
    local notif = {
        Title = config.Title or "Notification",
        Description = config.Description or "",
        Duration = config.Duration or 3,
        Type = config.Type or "Info",
        Icon = config.Icon or "🔔"
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

    local frame = self.Util:Create("Frame", {
        Name = "Notification",
        Parent = self.Holder,
        BackgroundColor3 = theme.NotificationBg,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ClipsDescendants = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    local corner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = frame
    })

    local stroke = self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Parent = frame
    })

    local shadow = self.Util:Create("ImageLabel", {
        Name = "Shadow",
        Parent = frame,
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = theme.Shadow,
        ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0, -15, 0, -15),
        ZIndex = -1
    })

    local iconColor = theme.Info
    if notif.Type == "Success" then iconColor = theme.Success
    elseif notif.Type == "Warning" then iconColor = theme.Warning
    elseif notif.Type == "Error" then iconColor = theme.Error end

    local icon = self.Util:Create("TextLabel", {
        Name = "Icon",
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0, 12, 0, 12),
        Font = Enum.Font.GothamBold,
        Text = notif.Icon,
        TextSize = 18,
        TextColor3 = iconColor
    })

    local title = self.Util:Create("TextLabel", {
        Name = "Title",
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 50, 0, 12),
        Font = Enum.Font.GothamBold,
        Text = notif.Title,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local desc = self.Util:Create("TextLabel", {
        Name = "Description",
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 0),
        Position = UDim2.new(0, 50, 0, 34),
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
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3)
    })

    -- Animate in
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.Position = UDim2.new(1, 20, 0, 0)

    local targetHeight = 60 + desc.TextBounds.Y
    if desc.TextBounds.Y < 20 then targetHeight = 60 end

    self.Util:Tween(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, targetHeight)
    })

    table.insert(self.Active, frame)
    self:Reposition()

    -- Progress bar animation
    self.Util:Tween(bar, TweenInfo.new(notif.Duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 3)
    })

    task.delay(notif.Duration, function()
        self:Dismiss(frame)
    end)
end

function NotificationSystem:Dismiss(frame)
    self.Util:Tween(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 20, 0, frame.Position.Y.Offset),
        Size = UDim2.new(1, 0, 0, 0)
    })

    task.delay(0.3, function()
        frame:Destroy()
        for i, f in ipairs(self.Active) do
            if f == frame then
                table.remove(self.Active, i)
                break
            end
        end
        self:Reposition()
        self:ProcessQueue()
    end)
end

function NotificationSystem:Reposition()
    local yOffset = 0
    for _, frame in ipairs(self.Active) do
        self.Util:Tween(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Position = UDim2.new(0, 0, 0, yOffset)
        })
        yOffset = yOffset + frame.AbsoluteSize.Y + self.Spacing
    end
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CONFIG SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local ConfigSystem = {}
ConfigSystem.__index = ConfigSystem

function ConfigSystem.new(folderName)
    local self = setmetatable({}, ConfigSystem)
    self.Folder = folderName or "NexusHub"
    self:EnsureFolder()
    return self
end

function ConfigSystem:EnsureFolder()
    if not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
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
        if success then
            return result
        end
    end
    return nil
end

function ConfigSystem:Delete(name)
    local path = self.Folder .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
        return true
    end
    return false
end

function ConfigSystem:List()
    self:EnsureFolder()
    local files = listfiles(self.Folder)
    local configs = {}
    for _, file in ipairs(files) do
        if file:sub(-5) == ".json" then
            local name = file:match("([^/\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    return configs
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TOOLTIP SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local TooltipSystem = {}
TooltipSystem.__index = TooltipSystem

function TooltipSystem.new(theme, util)
    local self = setmetatable({}, TooltipSystem)
    self.Theme = theme
    self.Util = util
    self.Active = nil
    self:Build()
    return self
end

function TooltipSystem:Build()
    local theme = self.Theme.Theme

    self.Gui = self.Util:Create("ScreenGui", {
        Name = "NexusTooltips",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100
    })

    self.Container = self.Util:Create("Frame", {
        Parent = self.Gui,
        BackgroundColor3 = theme.NotificationBg,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 200, 0, 0),
        Visible = false,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.Container
    })

    self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Parent = self.Container
    })

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
    self.Container.Position = UDim2.new(0, position.X + 15, 0, position.Y + 15)

    self.Util:Tween(self.Container, TweenInfo.new(0.2), {
        BackgroundTransparency = 0
    })
end

function TooltipSystem:Hide()
    self.Container.Visible = false
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LOADING SCREEN
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

function LoadingScreen.new(theme, util, config)
    local self = setmetatable({}, LoadingScreen)
    self.Theme = theme
    self.Util = util
    self.Config = config or {}
    self:Build()
    return self
end

function LoadingScreen:Build()
    local theme = self.Theme.Theme

    self.Gui = self.Util:Create("ScreenGui", {
        Name = "NexusLoading",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    self.Backdrop = self.Util:Create("Frame", {
        Parent = self.Gui,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0)
    })

    self.Container = self.Util:Create("Frame", {
        Parent = self.Backdrop,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 300, 0, 200),
        Position = UDim2.new(0.5, -150, 0.5, -100)
    })

    self.Logo = self.Util:Create("TextLabel", {
        Parent = self.Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 60),
        Font = Enum.Font.GothamBold,
        Text = self.Config.Title or "NEXUS HUB",
        TextSize = 36,
        TextColor3 = theme.Accent
    })

    self.Subtitle = self.Util:Create("TextLabel", {
        Parent = self.Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 60),
        Font = Enum.Font.Gotham,
        Text = self.Config.Subtitle or "Loading...",
        TextSize = 14,
        TextColor3 = theme.TextDim
    })

    self.BarTrack = self.Util:Create("Frame", {
        Parent = self.Container,
        BackgroundColor3 = theme.SliderTrack,
        BorderSizePixel = 0,
        Size = UDim2.new(0.8, 0, 0, 6),
        Position = UDim2.new(0.1, 0, 0, 120)
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.BarTrack
    })

    self.BarFill = self.Util:Create("Frame", {
        Parent = self.BarTrack,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0)
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.BarFill
    })

    self.Percent = self.Util:Create("TextLabel", {
        Parent = self.Container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 140),
        Font = Enum.Font.GothamBold,
        Text = "0%",
        TextSize = 16,
        TextColor3 = theme.Accent
    })
end

function LoadingScreen:SetProgress(percent)
    self.Util:Tween(self.BarFill, TweenInfo.new(0.3), {
        Size = UDim2.new(percent / 100, 0, 1, 0)
    })
    self.Percent.Text = math.floor(percent) .. "%"
end

function LoadingScreen:Destroy()
    self.Util:Tween(self.Backdrop, TweenInfo.new(0.5), {
        BackgroundTransparency = 1
    })

    for _, child in ipairs(self.Backdrop:GetChildren()) do
        self.Util:Tween(child, TweenInfo.new(0.5), {
            Position = UDim2.new(0, 0, -0.5, 0)
        })
    end

    task.delay(0.5, function()
        self.Gui:Destroy()
    end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CONTROL BASE CLASS
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
        Size = UDim2.new(1, -10, 0, height or 50),
        AutomaticSize = Enum.AutomaticSize.Y
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = self.Instance
    })

    self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Parent = self.Instance
    })

    self.Util:Create("UIPadding", {
        Parent = self.Instance,
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15)
    })

    return self.Instance
end

function ControlBase:SetTooltip(text)
    if not text then return end

    self.Instance.MouseEnter:Connect(function()
        local pos = self.Instance.AbsolutePosition
        self.Tab.Window.Hub.Tooltips:Show(text, pos)
    end)

    self.Instance.MouseLeave:Connect(function()
        self.Tab.Window.Hub.Tooltips:Hide()
    end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TOGGLE CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Toggle = setmetatable({}, {__index = ControlBase})
Toggle.__index = Toggle

function Toggle.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Toggle)
    self.Value = config.Default or false
    self.Callback = config.Callback or function() end
    self.DescriptionText = config.Description
    self:Build()
    return self
end

function Toggle:Build()
    local theme = self.Theme.Theme

    self:CreateContainer(50)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    if self.DescriptionText then
        self.Description = self.Util:Create("TextLabel", {
            Name = "Description",
            Parent = self.Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -60, 0, 0),
            Position = UDim2.new(0, 0, 0, 22),
            Font = Enum.Font.Gotham,
            Text = self.DescriptionText,
            TextSize = 12,
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
        Size = UDim2.new(0, 44, 0, 24),
        Position = UDim2.new(1, -44, 0, 13),
        AnchorPoint = Vector2.new(0, 0)
    })

    self.SwitchCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.Switch
    })

    self.Thumb = self.Util:Create("Frame", {
        Name = "Thumb",
        Parent = self.Switch,
        BackgroundColor3 = theme.Text,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 18, 0, 18),
        Position = self.Value and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3)
    })

    self.ThumbCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.Thumb
    })

    self.Glow = self.Util:Create("Frame", {
        Name = "Glow",
        Parent = self.Switch,
        BackgroundColor3 = theme.AccentGlow,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0)
    })

    self.GlowCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.Glow
    })

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

    if self.Value then
        self:UpdateVisuals(true, true)
    end
end

function Toggle:SetValue(value)
    self.Value = value
    self.Callback(value)
    self:UpdateVisuals(value)
end

function Toggle:UpdateVisuals(value, instant)
    local theme = self.Theme.Theme
    local duration = instant and 0 or 0.25

    self.Util:Tween(self.Switch, TweenInfo.new(duration, Enum.EasingStyle.Quart), {
        BackgroundColor3 = value and theme.ToggleOn or theme.ToggleOff
    })

    self.Util:Tween(self.Thumb, TweenInfo.new(duration, Enum.EasingStyle.Quart), {
        Position = value and UDim2.new(1, -21, 0, 3) or UDim2.new(0, 3, 0, 3)
    })

    self.Util:Tween(self.Glow, TweenInfo.new(duration), {
        BackgroundTransparency = value and 0.7 or 1
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SLIDER CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Slider = setmetatable({}, {__index = ControlBase})
Slider.__index = Slider

function Slider.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Slider)
    self.Min = config.Min or 0
    self.Max = config.Max or 100
    self.Value = config.Default or self.Min
    self.Callback = config.Callback or function() end
    self.Dragging = false
    self:Build()
    return self
end

function Slider:Build()
    local theme = self.Theme.Theme

    self:CreateContainer(70)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.ValueLabel = self.Util:Create("TextLabel", {
        Name = "Value",
        Parent = self.Instance,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 50, 0, 24),
        Position = UDim2.new(1, -50, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = tostring(self.Value),
        TextSize = 12,
        TextColor3 = theme.Accent
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.ValueLabel
    })

    self.Track = self.Util:Create("Frame", {
        Name = "Track",
        Parent = self.Instance,
        BackgroundColor3 = theme.SliderTrack,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 40)
    })

    self.TrackCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.Track
    })

    self.Fill = self.Util:Create("Frame", {
        Name = "Fill",
        Parent = self.Track,
        BackgroundColor3 = theme.SliderFill,
        BorderSizePixel = 0,
        Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0)
    })

    self.FillCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.Fill
    })

    self.Thumb = self.Util:Create("Frame", {
        Name = "Thumb",
        Parent = self.Track,
        BackgroundColor3 = theme.Text,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), -8, 0.5, -8)
    })

    self.ThumbCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.Thumb
    })

    self.ThumbStroke = self.Util:Create("UIStroke", {
        Color = theme.Accent,
        Thickness = 2,
        Parent = self.Thumb
    })

    self.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            self.Dragging = true
            self:UpdateFromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if self.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                              input.UserInputType == Enum.UserInputType.Touch) then
            self:UpdateFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
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

    self.ValueLabel.Text = tostring(self.Value)
    self.Util:Tween(self.Fill, TweenInfo.new(0.1), {
        Size = UDim2.new(percent, 0, 1, 0)
    })
    self.Util:Tween(self.Thumb, TweenInfo.new(0.1), {
        Position = UDim2.new(percent, -8, 0.5, -8)
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DROPDOWN CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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

    self:CreateContainer(50)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -150, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.DropBtn = self.Util:Create("TextButton", {
        Name = "DropBtn",
        Parent = self.Instance,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 140, 0, 32),
        Position = UDim2.new(1, -140, 0, 0),
        Font = Enum.Font.Gotham,
        Text = self:GetDisplayText(),
        TextSize = 12,
        TextColor3 = theme.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false
    })

    self.DropBtnCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.DropBtn
    })

    self.DropBtnStroke = self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Parent = self.DropBtn
    })

    self.Arrow = self.Util:Create("TextLabel", {
        Parent = self.DropBtn,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -22, 0, 6),
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
        Size = UDim2.new(0, 140, 0, 0),
        Position = UDim2.new(1, -140, 0, 35),
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 100
    })

    self.OptionsCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = self.OptionsFrame
    })

    self.OptionsStroke = self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Parent = self.OptionsFrame
    })

    self.OptionsList = self.Util:Create("UIListLayout", {
        Parent = self.OptionsFrame,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    self.OptionsPadding = self.Util:Create("UIPadding", {
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
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local theme = self.Theme.Theme

    for i, option in ipairs(self.Options) do
        local isSelected = self.Multi and table.find(self.Selected, option) or (self.Selected == option)

        local btn = self.Util:Create("TextButton", {
            Name = option,
            Parent = self.OptionsFrame,
            BackgroundColor3 = isSelected and theme.SurfaceHighlight or theme.DropdownBg,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            Font = Enum.Font.Gotham,
            Text = option,
            TextSize = 12,
            TextColor3 = isSelected and theme.Accent or theme.Text,
            AutoButtonColor = false
        })

        self.Util:Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = btn
        })

        btn.MouseEnter:Connect(function()
            if not (self.Multi and table.find(self.Selected, option)) and not (self.Selected == option) then
                self.Util:Tween(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = theme.SurfaceHighlight
                })
            end
        end)

        btn.MouseLeave:Connect(function()
            if not (self.Multi and table.find(self.Selected, option)) and not (self.Selected == option) then
                self.Util:Tween(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = theme.DropdownBg
                })
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
        if idx then
            table.remove(self.Selected, idx)
        else
            table.insert(self.Selected, option)
        end
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
        local height = math.min(#self.Options * 32 + 10, 200)
        self.Util:Tween(self.OptionsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, 140, 0, height)
        })
        self.Arrow.Rotation = 180
    else
        self.Util:Tween(self.OptionsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, 140, 0, 0)
        })
        self.Arrow.Rotation = 0
        task.delay(0.2, function()
            if not self.Open then
                self.OptionsFrame.Visible = false
            end
        end)
    end
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- BUTTON CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
        Size = UDim2.new(1, -10, 0, 40),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 14,
        TextColor3 = theme.Text,
        AutoButtonColor = false
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = self.Instance
    })

    self.Util:Create("UIStroke", {
        Color = theme.AccentGlow,
        Thickness = 1,
        Transparency = 0.5,
        Parent = self.Instance
    })

    local shadow = self.Util:Create("ImageLabel", {
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = theme.Shadow,
        ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        ZIndex = -1
    })

    self.Instance.MouseEnter:Connect(function()
        self.Util:Tween(self.Instance, TweenInfo.new(0.2), {
            BackgroundColor3 = theme.AccentGlow,
            Size = UDim2.new(1, -6, 0, 42)
        })
    end)

    self.Instance.MouseLeave:Connect(function()
        self.Util:Tween(self.Instance, TweenInfo.new(0.2), {
            BackgroundColor3 = theme.Accent,
            Size = UDim2.new(1, -10, 0, 40)
        })
    end)

    self.Instance.MouseButton1Down:Connect(function()
        self.Util:Tween(self.Instance, TweenInfo.new(0.1), {
            Size = UDim2.new(1, -14, 0, 38)
        })
    end)

    self.Instance.MouseButton1Up:Connect(function()
        self.Util:Tween(self.Instance, TweenInfo.new(0.1), {
            Size = UDim2.new(1, -10, 0, 40)
        })
    end)

    self.Instance.MouseButton1Click:Connect(function()
        self.Callback()
    end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LABEL CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
        Size = UDim2.new(1, -10, 0, 30),
        Font = Enum.Font.GothamBold,
        Text = self.Text,
        TextSize = 16,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SECTION CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
        Size = UDim2.new(1, -10, 0, 40)
    })

    local label = self.Util:Create("TextLabel", {
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 0, 20),
        Position = UDim2.new(0, 0, 0, 10),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 14,
        TextColor3 = theme.Accent
    })

    local line = self.Util:Create("Frame", {
        Parent = self.Instance,
        BackgroundColor3 = theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 35)
    })

    local accentLine = self.Util:Create("Frame", {
        Parent = line,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0.15, 0, 1, 0)
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DIVIDER CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
        Size = UDim2.new(1, -10, 0, 20)
    })

    local line = self.Util:Create("Frame", {
        Parent = self.Instance,
        BackgroundColor3 = theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0.5, 0)
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PARAGRAPH CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
        Size = UDim2.new(1, -10, 0, 0),
        Font = Enum.Font.Gotham,
        Text = self.Content,
        TextSize = 13,
        TextColor3 = theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KEYBIND CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Keybind = setmetatable({}, {__index = ControlBase})
Keybind.__index = Keybind

function Keybind.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Keybind)
    self.Key = config.Default or "None"
    self.Callback = config.Callback or function() end
    self.Listening = false
    self:Build()
    return self
end

function Keybind:Build()
    local theme = self.Theme.Theme

    self:CreateContainer(50)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -100, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.KeyBtn = self.Util:Create("TextButton", {
        Name = "KeyBtn",
        Parent = self.Instance,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 80, 0, 30),
        Position = UDim2.new(1, -80, 0, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Key,
        TextSize = 12,
        TextColor3 = theme.Accent,
        AutoButtonColor = false
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.KeyBtn
    })

    self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Parent = self.KeyBtn
    })

    self.KeyBtn.MouseButton1Click:Connect(function()
        self.Listening = true
        self.KeyBtn.Text = "..."
        self.Util:Tween(self.KeyBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = theme.Accent,
            TextColor3 = theme.Text
        })
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if self.Listening and not gameProcessed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                self.Key = input.KeyCode.Name
                self.KeyBtn.Text = self.Key
                self.Listening = false
                self.Util:Tween(self.KeyBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = theme.Background,
                    TextColor3 = theme.Accent
                })
                self.Callback(self.Key)
            end
        elseif input.KeyCode.Name == self.Key and not gameProcessed then
            self.Callback(self.Key)
        end
    end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TEXTBOX CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Textbox = setmetatable({}, {__index = ControlBase})
Textbox.__index = Textbox

function Textbox.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Textbox)
    self.Default = config.Default or ""
    self.Placeholder = config.Placeholder or "Enter text..."
    self.Callback = config.Callback or function() end
    self:Build()
    return self
end

function Textbox:Build()
    local theme = self.Theme.Theme

    self:CreateContainer(50)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -160, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.Input = self.Util:Create("TextBox", {
        Name = "Input",
        Parent = self.Instance,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 150, 0, 32),
        Position = UDim2.new(1, -150, 0, 0),
        Font = Enum.Font.Gotham,
        Text = self.Default,
        PlaceholderText = self.Placeholder,
        TextSize = 12,
        TextColor3 = theme.Text,
        ClearTextOnFocus = false
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.Input
    })

    self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Parent = self.Input
    })

    self.Input.Focused:Connect(function()
        self.Util:Tween(self.Input, TweenInfo.new(0.2), {
            BackgroundColor3 = theme.SurfaceHighlight
        })
    end)

    self.Input.FocusLost:Connect(function()
        self.Util:Tween(self.Input, TweenInfo.new(0.2), {
            BackgroundColor3 = theme.Background
        })
        self.Callback(self.Input.Text)
    end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COLOR PICKER CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local ColorPicker = setmetatable({}, {__index = ControlBase})
ColorPicker.__index = ColorPicker

function ColorPicker.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), ColorPicker)
    self.Default = config.Default or Color3.fromRGB(255, 255, 255)
    self.Callback = config.Callback or function() end
    self.Value = self.Default
    self:Build()
    return self
end

function ColorPicker:Build()
    local theme = self.Theme.Theme

    self:CreateContainer(50)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.Preview = self.Util:Create("TextButton", {
        Name = "Preview",
        Parent = self.Instance,
        BackgroundColor3 = self.Value,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 40, 0, 30),
        Position = UDim2.new(1, -40, 0, 0),
        Text = "",
        AutoButtonColor = false
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.Preview
    })

    self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 2,
        Parent = self.Preview
    })

    local colors = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(0, 255, 255),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(138, 46, 255),
        Color3.fromRGB(255, 128, 0),
        Color3.fromRGB(128, 0, 255)
    }

    self.Preview.MouseButton1Click:Connect(function()
        local currentIdx = 1
        for i, c in ipairs(colors) do
            if c == self.Value then
                currentIdx = i
                break
            end
        end

        self.Value = colors[(currentIdx % #colors) + 1]
        self.Preview.BackgroundColor3 = self.Value
        self.Callback(self.Value)
    end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PROGRESS BAR CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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

    self:CreateContainer(60)

    self.Label = self.Util:Create("TextLabel", {
        Name = "Label",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.PercentLabel = self.Util:Create("TextLabel", {
        Name = "Percent",
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 50, 0, 20),
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
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 0, 35)
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.Track
    })

    self.Fill = self.Util:Create("Frame", {
        Name = "Fill",
        Parent = self.Track,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(self.Value / self.Max, 0, 1, 0)
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.Fill
    })
end

function ProgressBar:SetValue(value)
    self.Value = math.clamp(value, 0, self.Max)
    local percent = self.Value / self.Max

    self.PercentLabel.Text = math.floor(percent * 100) .. "%"
    self.Util:Tween(self.Fill, TweenInfo.new(0.3), {
        Size = UDim2.new(percent, 0, 1, 0)
    })

    self.Callback(self.Value)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- BADGE CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
        Size = UDim2.new(0, 0, 0, 30),
        AutomaticSize = Enum.AutomaticSize.X
    })

    local bg = self.Util:Create("Frame", {
        Parent = self.Instance,
        BackgroundColor3 = self.Color == "Accent" and theme.Accent or theme.SurfaceHighlight,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 20, 1, 0),
        Position = UDim2.new(0, 0, 0, 0)
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = bg
    })

    local label = self.Util:Create("TextLabel", {
        Parent = bg,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Text,
        TextSize = 12,
        TextColor3 = theme.Text
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- IMAGE CONTROL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Image = setmetatable({}, {__index = ControlBase})
Image.__index = Image

function Image.new(config, tab, theme, util)
    local self = setmetatable(ControlBase.new(config.Name, tab, theme, util), Image)
    self.ImageId = config.Image or ""
    self.Size = config.Size or UDim2.new(1, -10, 0, 150)
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

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = self.Instance
    })

    self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Parent = self.Instance
    })

    local img = self.Util:Create("ImageLabel", {
        Parent = self.Instance,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        Image = self.ImageId,
        ScaleType = Enum.ScaleType.Fit
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = img
    })
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TAB CLASS
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Tab = {}
Tab.__index = Tab

function Tab.new(name, icon, window, theme, util)
    local self = setmetatable({}, Tab)
    self.Name = name
    self.Icon = icon or "📁"
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
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -10, 0, 40),
        Position = UDim2.new(0, 5, 0, 0),
        Font = Enum.Font.Gotham,
        Text = "   " .. self.Icon .. "  " .. self.Name,
        TextSize = 14,
        TextColor3 = theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false
    })

    self.ButtonCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = self.Button
    })

    self.Page = self.Util:Create("ScrollingFrame", {
        Name = self.Name .. "Page",
        Parent = self.Window.Content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarImageTransparency = 0.5
    })

    self.PageList = self.Util:Create("UIListLayout", {
        Parent = self.Page,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })

    self.PagePadding = self.Util:Create("UIPadding", {
        Parent = self.Page,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 20),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    })

    self.Button.MouseButton1Click:Connect(function()
        self:Select()
    end)

    self.Button.MouseEnter:Connect(function()
        if not self.Selected then
            self.Util:Tween(self.Button, TweenInfo.new(0.2), {
                BackgroundColor3 = theme.SurfaceHighlight
            })
        end
    end)

    self.Button.MouseLeave:Connect(function()
        if not self.Selected then
            self.Util:Tween(self.Button, TweenInfo.new(0.2), {
                BackgroundColor3 = theme.Surface
            })
        end
    end)
end

function Tab:Select()
    if self.Window.ActiveTab == self then return end

    if self.Window.ActiveTab then
        self.Window.ActiveTab:Deselect()
    end

    self.Selected = true
    self.Window.ActiveTab = self

    local theme = self.Theme.Theme

    self.Util:Tween(self.Button, TweenInfo.new(0.3), {
        BackgroundColor3 = theme.Accent,
        TextColor3 = theme.Text
    })

    if not self.Glow then
        self.Glow = self.Util:Create("Frame", {
            Name = "Glow",
            Parent = self.Button,
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = 0.8,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 0
        })
        self.Util:Create("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = self.Glow
        })
    end

    self.Page.Visible = true
    self.Page.Position = UDim2.new(0, 20, 0, 0)
    self.Util:Tween(self.Page, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
        Position = UDim2.new(0, 0, 0, 0)
    })
end

function Tab:Deselect()
    self.Selected = false
    local theme = self.Theme.Theme

    self.Util:Tween(self.Button, TweenInfo.new(0.3), {
        BackgroundColor3 = theme.Surface,
        TextColor3 = theme.TextDim
    })

    if self.Glow then
        self.Glow:Destroy()
        self.Glow = nil
    end

    self.Page.Visible = false
end

-- Tab Control Methods
function Tab:AddToggle(config)
    local toggle = Toggle.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, toggle)
    return toggle
end

function Tab:AddSlider(config)
    local slider = Slider.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, slider)
    return slider
end

function Tab:AddDropdown(config)
    local dropdown = Dropdown.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, dropdown)
    return dropdown
end

function Tab:AddButton(config)
    local button = Button.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, button)
    return button
end

function Tab:AddLabel(config)
    local label = Label.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, label)
    return label
end

function Tab:AddSection(config)
    local section = Section.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, section)
    return section
end

function Tab:AddDivider(config)
    local divider = Divider.new(config or {}, self, self.Theme, self.Util)
    table.insert(self.Controls, divider)
    return divider
end

function Tab:AddParagraph(config)
    local paragraph = Paragraph.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, paragraph)
    return paragraph
end

function Tab:AddKeybind(config)
    local keybind = Keybind.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, keybind)
    return keybind
end

function Tab:AddTextbox(config)
    local textbox = Textbox.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, textbox)
    return textbox
end

function Tab:AddColorPicker(config)
    local picker = ColorPicker.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, picker)
    return picker
end

function Tab:AddProgressBar(config)
    local bar = ProgressBar.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, bar)
    return bar
end

function Tab:AddBadge(config)
    local badge = Badge.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, badge)
    return badge
end

function Tab:AddImage(config)
    local image = Image.new(config, self, self.Theme, self.Util)
    table.insert(self.Controls, image)
    return image
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- WINDOW CLASS
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
        Size = UDim2.new(0, 800, 0, 550),
        Position = UDim2.new(0.5, -400, 0.5, -275),
        ClipsDescendants = true
    })

    self.Corner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 16),
        Parent = self.Main
    })

    self.Stroke = self.Util:Create("UIStroke", {
        Color = theme.Accent,
        Thickness = 1.5,
        Transparency = 0.3,
        Parent = self.Main
    })

    self.Shadow = self.Util:Create("ImageLabel", {
        Name = "Shadow",
        Parent = self.Main,
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = theme.Shadow,
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        Size = UDim2.new(1, 60, 1, 60),
        Position = UDim2.new(0, -30, 0, -30),
        ZIndex = -1
    })

    -- Top Bar
    self.TopBar = self.Util:Create("Frame", {
        Name = "TopBar",
        Parent = self.Main,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 50)
    })

    self.TopBarCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 16),
        Parent = self.TopBar
    })

    self.TopBarFix = self.Util:Create("Frame", {
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
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 15, 0, 5),
        Font = Enum.Font.GothamBold,
        Text = "N",
        TextSize = 24,
        TextColor3 = theme.Accent
    })

    self.LogoCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.Logo
    })

    self.LogoStroke = self.Util:Create("UIStroke", {
        Color = theme.Accent,
        Thickness = 2,
        Parent = self.Logo
    })

    -- Hub Name
    self.HubName = self.Util:Create("TextLabel", {
        Name = "HubName",
        Parent = self.TopBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 0, 25),
        Position = UDim2.new(0, 65, 0, 5),
        Font = Enum.Font.GothamBold,
        Text = self.Config.Title or "Nexus Hub",
        TextSize = 18,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Version
    self.Version = self.Util:Create("TextLabel", {
        Name = "Version",
        Parent = self.TopBar,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 100, 0, 18),
        Position = UDim2.new(0, 65, 0, 28),
        Font = Enum.Font.Gotham,
        Text = self.Config.Version or "v1.0.0",
        TextSize = 12,
        TextColor3 = theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Search Bar
    self.SearchBox = self.Util:Create("TextBox", {
        Name = "Search",
        Parent = self.TopBar,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 250, 0, 32),
        Position = UDim2.new(0.5, -125, 0, 9),
        Font = Enum.Font.Gotham,
        Text = "",
        PlaceholderText = "Search feature...",
        TextSize = 13,
        TextColor3 = theme.Text,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.SearchCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.SearchBox
    })

    self.SearchStroke = self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Parent = self.SearchBox
    })

    self.SearchIcon = self.Util:Create("TextLabel", {
        Parent = self.SearchBox,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 8, 0, 6),
        Font = Enum.Font.GothamBold,
        Text = "🔍",
        TextSize = 14,
        TextColor3 = theme.TextDim
    })

    -- Window Controls
    local btnSize = 32
    local btnY = 9

    self.MinBtn = self.Util:Create("TextButton", {
        Name = "Minimize",
        Parent = self.TopBar,
        BackgroundColor3 = theme.SurfaceHighlight,
        BorderSizePixel = 0,
        Size = UDim2.new(0, btnSize, 0, btnSize),
        Position = UDim2.new(1, -120, 0, btnY),
        Font = Enum.Font.GothamBold,
        Text = "−",
        TextSize = 18,
        TextColor3 = theme.Text,
        AutoButtonColor = false
    })

    self.MinCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.MinBtn
    })

    self.FavBtn = self.Util:Create("TextButton", {
        Name = "Favorite",
        Parent = self.TopBar,
        BackgroundColor3 = theme.SurfaceHighlight,
        BorderSizePixel = 0,
        Size = UDim2.new(0, btnSize, 0, btnSize),
        Position = UDim2.new(1, -80, 0, btnY),
        Font = Enum.Font.GothamBold,
        Text = "★",
        TextSize = 16,
        TextColor3 = theme.TextDim,
        AutoButtonColor = false
    })

    self.FavCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.FavBtn
    })

    self.CloseBtn = self.Util:Create("TextButton", {
        Name = "Close",
        Parent = self.TopBar,
        BackgroundColor3 = theme.SurfaceHighlight,
        BorderSizePixel = 0,
        Size = UDim2.new(0, btnSize, 0, btnSize),
        Position = UDim2.new(1, -40, 0, btnY),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextSize = 20,
        TextColor3 = theme.Text,
        AutoButtonColor = false
    })

    self.CloseCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.CloseBtn
    })

    -- Sidebar
    self.Sidebar = self.Util:Create("Frame", {
        Name = "Sidebar",
        Parent = self.Main,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 200, 1, -50),
        Position = UDim2.new(0, 0, 0, 50)
    })

    self.SidebarCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 16),
        Parent = self.Sidebar
    })

    self.SidebarFix = self.Util:Create("Frame", {
        Parent = self.Sidebar,
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0)
    })

    -- User Card
    self.UserCard = self.Util:Create("Frame", {
        Name = "UserCard",
        Parent = self.Sidebar,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, 70),
        Position = UDim2.new(0, 10, 0, 10)
    })

    self.UserCardCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = self.UserCard
    })

    self.UserCardStroke = self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Parent = self.UserCard
    })

    self.Avatar = self.Util:Create("Frame", {
        Name = "Avatar",
        Parent = self.UserCard,
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 12, 0, 15)
    })

    self.AvatarCorner = self.Util:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.Avatar
    })

    self.AvatarLabel = self.Util:Create("TextLabel", {
        Parent = self.Avatar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "👤",
        TextSize = 20,
        TextColor3 = theme.Text
    })

    self.Username = self.Util:Create("TextLabel", {
        Name = "Username",
        Parent = self.UserCard,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -70, 0, 20),
        Position = UDim2.new(0, 62, 0, 15),
        Font = Enum.Font.GothamBold,
        Text = LocalPlayer.Name,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    self.UserStatus = self.Util:Create("TextLabel", {
        Name = "Status",
        Parent = self.UserCard,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -70, 0, 18),
        Position = UDim2.new(0, 62, 0, 36),
        Font = Enum.Font.Gotham,
        Text = "Premium User",
        TextSize = 12,
        TextColor3 = theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Tab Container
    self.TabContainer = self.Util:Create("ScrollingFrame", {
        Name = "Tabs",
        Parent = self.Sidebar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, -100),
        Position = UDim2.new(0, 5, 0, 90),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })

    self.TabList = self.Util:Create("UIListLayout", {
        Parent = self.TabContainer,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    -- Content Area
    self.Content = self.Util:Create("Frame", {
        Name = "Content",
        Parent = self.Main,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -210, 1, -60),
        Position = UDim2.new(0, 205, 0, 55),
        ClipsDescendants = true
    })

    self.Util:MakeDraggable(self.Main, self.TopBar)

    self:SetupEvents()
end

function Window:SetupEvents()
    self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:FilterControls(self.SearchBox.Text)
    end)

    self.MinBtn.MouseButton1Click:Connect(function()
        self:Minimize()
    end)

    self.MinBtn.MouseEnter:Connect(function()
        self.Util:Tween(self.MinBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = self.Theme.Theme.Accent
        })
    end)

    self.MinBtn.MouseLeave:Connect(function()
        self.Util:Tween(self.MinBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = self.Theme.Theme.SurfaceHighlight
        })
    end)

    self.CloseBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)

    self.CloseBtn.MouseEnter:Connect(function()
        self.Util:Tween(self.CloseBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = self.Theme.Theme.Error
        })
    end)

    self.CloseBtn.MouseLeave:Connect(function()
        self.Util:Tween(self.CloseBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = self.Theme.Theme.SurfaceHighlight
        })
    end)

    self.FavBtn.MouseButton1Click:Connect(function()
        self:ToggleFavorite()
    end)
end

function Window:CreateTab(name, icon)
    local tab = Tab.new(name, icon, self, self.Theme, self.Util)
    table.insert(self.Tabs, tab)
    if not self.ActiveTab then
        tab:Select()
    end
    return tab
end

function Window:FilterControls(searchText)
    searchText = string.lower(searchText)
    for _, tab in ipairs(self.Tabs) do
        for _, control in ipairs(tab.Controls) do
            if searchText == "" or string.find(string.lower(control.Name), searchText) then
                if control.Instance then
                    control.Instance.Visible = true
                end
            else
                if control.Instance then
                    control.Instance.Visible = false
                end
            end
        end
    end
end

function Window:Minimize()
    self.Minimized = not self.Minimized
    if self.Minimized then
        self.Util:Tween(self.Main, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, 800, 0, 50)
        })
    else
        self.Util:Tween(self.Main, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, 800, 0, 550)
        })
    end
end

function Window:Close()
    self.Closed = true
    self.Util:Tween(self.Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })

    task.delay(0.3, function()
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
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 20, 0.5, -25),
        Text = "N",
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        TextColor3 = theme.Text
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.FloatingIcon
    })

    self.Util:Create("UIStroke", {
        Color = theme.AccentGlow,
        Thickness = 2,
        Transparency = 0.5,
        Parent = self.FloatingIcon
    })

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
            self.Util:Tween(glow, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.4
            })
            wait(1)
            if not self.FloatingIcon or not self.FloatingIcon.Parent then break end
            self.Util:Tween(glow, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                ImageTransparency = 0.7
            })
            wait(1)
        end
    end)

    self.Util:MakeDraggable(self.FloatingIcon)

    self.FloatingIcon.MouseButton1Click:Connect(function()
        self:Reopen()
    end)
end

function Window:Reopen()
    if self.FloatingIcon then
        self.FloatingIcon:Destroy()
        self.FloatingIcon = nil
    end

    self.Main.Visible = true
    self.Closed = false

    self.Main.Size = UDim2.new(0, 0, 0, 0)
    self.Main.Position = UDim2.new(0.5, 0, 0.5, 0)

    self.Util:Tween(self.Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 800, 0, 550),
        Position = UDim2.new(0.5, -400, 0.5, -275)
    })
end

function Window:ToggleFavorite()
    -- Implementation for favorites
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
        Size = UDim2.new(0, 350, 0, 0),
        Position = UDim2.new(0.5, -175, 0.5, -100),
        AutomaticSize = Enum.AutomaticSize.Y
    })

    self.Util:Create("UICorner", {
        CornerRadius = UDim.new(0, 16),
        Parent = frame
    })

    self.Util:Create("UIStroke", {
        Color = theme.Border,
        Thickness = 1,
        Parent = frame
    })

    local title = self.Util:Create("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 30),
        Position = UDim2.new(0, 15, 0, 15),
        Font = Enum.Font.GothamBold,
        Text = config.Title or "Prompt",
        TextSize = 18,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local desc = self.Util:Create("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 0),
        Position = UDim2.new(0, 15, 0, 50),
        Font = Enum.Font.Gotham,
        Text = config.Description or "",
        TextSize = 14,
        TextColor3 = theme.TextDim,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    local buttonsFrame = self.Util:Create("Frame", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -30, 0, 40),
        Position = UDim2.new(0, 15, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    })

    self.Util:Create("UIPadding", {
        Parent = frame,
        PaddingBottom = UDim.new(0, 15)
    })

    local buttonsList = self.Util:Create("UIListLayout", {
        Parent = buttonsFrame,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Right
    })

    frame.Size = UDim2.new(0, 350, 0, 0)
    self.Util:Tween(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 350, 0, frame.AbsoluteSize.Y)
    })

    local function close()
        self.Util:Tween(frame, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 350, 0, 0)
        })
        task.delay(0.2, function()
            promptGui:Destroy()
        end)
    end

    if config.Buttons then
        for _, btnConfig in ipairs(config.Buttons) do
            local btn = self.Util:Create("TextButton", {
                Parent = buttonsFrame,
                BackgroundColor3 = btnConfig.Primary and theme.Accent or theme.Background,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 100, 0, 36),
                Font = Enum.Font.GothamBold,
                Text = btnConfig.Text or "Button",
                TextSize = 14,
                TextColor3 = theme.Text,
                AutoButtonColor = false
            })

            self.Util:Create("UICorner", {
                CornerRadius = UDim.new(0, 8),
                Parent = btn
            })

            btn.MouseButton1Click:Connect(function()
                if btnConfig.Callback then
                    btnConfig.Callback()
                end
                close()
            end)
        end
    end

    return {
        Close = close
    }
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MAIN LIBRARY API
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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

    if config.Theme and ThemeSystem.Presets[config.Theme] then
        self.Theme:SetTheme(config.Theme)
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
    for name, _ in pairs(ThemeSystem.Presets) do
        table.insert(themes, name)
    end
    return themes
end

function NexusHub:ShowLoading(config)
    return LoadingScreen.new(self.Theme, self.Util, config)
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

-- Return library
return NexusHub
