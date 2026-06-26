--[[
    NexusUI - Modern Roblox GUI Library
    Inspired by Rayfield | Single-file, modular, aesthetic
--]]

local NexusUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- THEMES
local Themes = {
    Dark = {
        Background = Color3.fromRGB(25, 25, 30),
        Secondary = Color3.fromRGB(35, 35, 42),
        Tertiary = Color3.fromRGB(45, 45, 55),
        Accent = Color3.fromRGB(88, 101, 242),
        AccentLight = Color3.fromRGB(114, 137, 218),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(180, 180, 190),
        Border = Color3.fromRGB(50, 50, 60),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60),
        Shadow = Color3.fromRGB(0, 0, 0)
    },
    Light = {
        Background = Color3.fromRGB(245, 245, 250),
        Secondary = Color3.fromRGB(235, 235, 240),
        Tertiary = Color3.fromRGB(225, 225, 230),
        Accent = Color3.fromRGB(88, 101, 242),
        AccentLight = Color3.fromRGB(114, 137, 218),
        Text = Color3.fromRGB(30, 30, 35),
        TextDark = Color3.fromRGB(100, 100, 110),
        Border = Color3.fromRGB(200, 200, 210),
        Success = Color3.fromRGB(39, 174, 96),
        Warning = Color3.fromRGB(211, 168, 15),
        Error = Color3.fromRGB(192, 57, 43),
        Shadow = Color3.fromRGB(150, 150, 160)
    },
    Midnight = {
        Background = Color3.fromRGB(15, 15, 25),
        Secondary = Color3.fromRGB(25, 25, 40),
        Tertiary = Color3.fromRGB(35, 35, 55),
        Accent = Color3.fromRGB(155, 89, 182),
        AccentLight = Color3.fromRGB(175, 122, 197),
        Text = Color3.fromRGB(236, 240, 241),
        TextDark = Color3.fromRGB(160, 160, 175),
        Border = Color3.fromRGB(40, 40, 60),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60),
        Shadow = Color3.fromRGB(0, 0, 0)
    },
    Ocean = {
        Background = Color3.fromRGB(20, 30, 40),
        Secondary = Color3.fromRGB(30, 45, 60),
        Tertiary = Color3.fromRGB(40, 60, 80),
        Accent = Color3.fromRGB(52, 152, 219),
        AccentLight = Color3.fromRGB(93, 173, 226),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(180, 190, 200),
        Border = Color3.fromRGB(50, 70, 90),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60),
        Shadow = Color3.fromRGB(0, 0, 0)
    },
    Crimson = {
        Background = Color3.fromRGB(30, 15, 20),
        Secondary = Color3.fromRGB(45, 20, 25),
        Tertiary = Color3.fromRGB(60, 25, 30),
        Accent = Color3.fromRGB(231, 76, 60),
        AccentLight = Color3.fromRGB(236, 112, 99),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(200, 180, 180),
        Border = Color3.fromRGB(80, 40, 45),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(192, 57, 43),
        Shadow = Color3.fromRGB(0, 0, 0)
    }
}

-- UTILITY FUNCTIONS
local Utility = {}

function Utility:Tween(Object, Properties, Duration, EasingStyle, EasingDirection, Callback)
    EasingStyle = EasingStyle or Enum.EasingStyle.Quint
    EasingDirection = EasingDirection or Enum.EasingDirection.Out
    Duration = Duration or 0.3
    local Tween = TweenService:Create(Object, TweenInfo.new(Duration, EasingStyle, EasingDirection), Properties)
    Tween:Play()
    if Callback then
        Tween.Completed:Connect(Callback)
    end
    return Tween
end

function Utility:Create(ClassName, Properties)
    local Object = Instance.new(ClassName)
    for Property, Value in pairs(Properties or {}) do
        if Property ~= "Parent" then
            Object[Property] = Value
        end
    end
    if Properties and Properties.Parent then
        Object.Parent = Properties.Parent
    end
    return Object
end

function Utility:MakeDraggable(Object, DragArea)
    local Dragging = false
    local DragStart = nil
    local StartPos = nil
    DragArea = DragArea or Object
    DragArea.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = Input.Position
            StartPos = Object.Position
            Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(Input)
        if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
            local Delta = Input.Position - DragStart
            Object.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
        end
    end)
end

function Utility:RippleEffect(Button, MousePos, Theme)
    local Ripple = Utility:Create("Frame", {
        Name = "Ripple",
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, MousePos.X - Button.AbsolutePosition.X, 0, MousePos.Y - Button.AbsolutePosition.Y),
        Parent = Button,
        ZIndex = Button.ZIndex + 1
    })
    local Corner = Utility:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Ripple})
    local MaxSize = math.max(Button.AbsoluteSize.X, Button.AbsoluteSize.Y) * 2.5
    Utility:Tween(Ripple, {
        Size = UDim2.new(0, MaxSize, 0, MaxSize),
        Position = UDim2.new(0, MousePos.X - Button.AbsolutePosition.X - MaxSize/2, 0, MousePos.Y - Button.AbsolutePosition.Y - MaxSize/2),
        BackgroundTransparency = 1
    }, 0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, function()
        Ripple:Destroy()
    end)
end

-- NOTIFICATION SYSTEM
local NotificationSystem = {}
NotificationSystem.ActiveNotifications = {}
NotificationSystem.MaxNotifications = 5

function NotificationSystem:Init(Parent, Theme)
    self.Container = Utility:Create("Frame", {
        Name = "NotificationContainer",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -20),
        Position = UDim2.new(1, -340, 0, 10),
        Parent = Parent
    })
    self.Theme = Theme
    self.Layout = Utility:Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Parent = self.Container
    })
end

function NotificationSystem:Notify(Options)
    Options = Options or {}
    local Title = Options.Title or "Notification"
    local Content = Options.Content or ""
    local Duration = Options.Duration or 3
    local Type = Options.Type or "Info"
    local Color = self.Theme.Accent
    if Type == "Success" then Color = self.Theme.Success
    elseif Type == "Warning" then Color = self.Theme.Warning
    elseif Type == "Error" then Color = self.Theme.Error end
    while #self.ActiveNotifications >= self.MaxNotifications do
        local Old = table.remove(self.ActiveNotifications, 1)
        if Old and Old.Object then
            Utility:Tween(Old.Object, {Position = UDim2.new(1, 20, 0, Old.Object.Position.Y.Offset)}, 0.3, nil, nil, function()
                Old.Object:Destroy()
            end)
        end
    end
    local Notification = Utility:Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(1, 20, 0, 0),
        ClipsDescendants = true,
        Parent = self.Container
    })
    local Corner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Notification})
    local Stroke = Utility:Create("UIStroke", {Color = Color, Thickness = 1.5, Transparency = 0.5, Parent = Notification})
    local Shadow = Utility:Create("ImageLabel", {
        Name = "Shadow", BackgroundTransparency = 1, Image = "rbxassetid://5554236805",
        ImageColor3 = self.Theme.Shadow, ImageTransparency = 0.6, ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277), Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0, -15, 0, -15), ZIndex = 0, Parent = Notification
    })
    local AccentBar = Utility:Create("Frame", {Name = "AccentBar", BackgroundColor3 = Color, BorderSizePixel = 0, Size = UDim2.new(0, 4, 1, 0), Parent = Notification})
    local ContentFrame = Utility:Create("Frame", {Name = "Content", BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 12, 0, 10), Parent = Notification})
    local TitleLabel = Utility:Create("TextLabel", {Name = "Title", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.GothamBold, Text = Title, TextColor3 = self.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = ContentFrame})
    local ContentLabel = Utility:Create("TextLabel", {Name = "Content", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 22), Font = Enum.Font.Gotham, Text = Content, TextColor3 = self.Theme.TextDark, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = ContentFrame})
    local TextHeight = ContentLabel.TextBounds.Y
    local TotalHeight = math.max(70, 32 + TextHeight + 20)
    Notification.Size = UDim2.new(1, 0, 0, TotalHeight)
    local ProgressBar = Utility:Create("Frame", {Name = "ProgressBar", BackgroundColor3 = Color, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), Parent = Notification})
    Utility:Tween(Notification, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    table.insert(self.ActiveNotifications, {Object = Notification})
    Utility:Tween(ProgressBar, {Size = UDim2.new(0, 0, 0, 2)}, Duration, Enum.EasingStyle.Linear)
    task.delay(Duration, function()
        if Notification and Notification.Parent then
            Utility:Tween(Notification, {Position = UDim2.new(1, 20, 0, Notification.Position.Y.Offset)}, 0.3, nil, nil, function()
                if Notification then Notification:Destroy() end
            end)
        end
    end)
    Notification.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Utility:Tween(Notification, {Position = UDim2.new(1, 20, 0, Notification.Position.Y.Offset)}, 0.2, nil, nil, function()
                if Notification then Notification:Destroy() end
            end)
        end
    end)
end

-- KEY SYSTEM
local KeySystem = {}
function KeySystem:Verify(Key, CorrectKey)
    return Key == CorrectKey
end

function KeySystem:CreateWindow(Parent, Theme, Options, Callback)
    local Window = Utility:Create("Frame", {
        Name = "KeySystem", BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
        Size = UDim2.new(0, 400, 0, 280), Position = UDim2.new(0.5, -200, 0.5, -140), Parent = Parent
    })
    local Corner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Window})
    local Stroke = Utility:Create("UIStroke", {Color = Theme.Border, Thickness = 1, Parent = Window})
    local Shadow = Utility:Create("ImageLabel", {
        Name = "Shadow", BackgroundTransparency = 1, Image = "rbxassetid://5554236805",
        ImageColor3 = Theme.Shadow, ImageTransparency = 0.7, ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277), Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0, -20, 0, -20), ZIndex = 0, Parent = Window
    })
    local Header = Utility:Create("Frame", {Name = "Header", BackgroundColor3 = Theme.Secondary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 60), Parent = Window})
    local HeaderCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Header})
    local HeaderFix = Utility:Create("Frame", {BackgroundColor3 = Theme.Secondary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), Parent = Header})
    local Title = Utility:Create("TextLabel", {Name = "Title", BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 15, 0, 8), Font = Enum.Font.GothamBold, Text = Options.Name or "Key System", TextColor3 = Theme.Text, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Parent = Header})
    local Subtitle = Utility:Create("TextLabel", {Name = "Subtitle", BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0, 15, 0, 33), Font = Enum.Font.Gotham, Text = "Enter your key to continue", TextColor3 = Theme.TextDark, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = Header})
    local InputFrame = Utility:Create("Frame", {Name = "InputFrame", BackgroundColor3 = Theme.Tertiary, BorderSizePixel = 0, Size = UDim2.new(1, -40, 0, 45), Position = UDim2.new(0, 20, 0, 80), Parent = Window})
    local InputCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = InputFrame})
    local InputBox = Utility:Create("TextBox", {Name = "InputBox", BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), Font = Enum.Font.Gotham, Text = "", PlaceholderText = "Enter key here...", TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextDark, TextSize = 14, ClearTextOnFocus = false, Parent = InputFrame})
    local StatusLabel = Utility:Create("TextLabel", {Name = "Status", BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 20), Position = UDim2.new(0, 20, 0, 135), Font = Enum.Font.Gotham, Text = "", TextColor3 = Theme.Error, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = Window})
    local SubmitButton = Utility:Create("TextButton", {Name = "SubmitButton", BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0, 20, 0, 170), Font = Enum.Font.GothamBold, Text = "Submit Key", TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 14, AutoButtonColor = false, Parent = Window})
    local SubmitCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = SubmitButton})
    local GetKeyButton = Utility:Create("TextButton", {Name = "GetKeyButton", BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 30), Position = UDim2.new(0, 20, 0, 220), Font = Enum.Font.Gotham, Text = "Get Key", TextColor3 = Theme.Accent, TextSize = 12, Parent = Window})
    SubmitButton.MouseEnter:Connect(function() Utility:Tween(SubmitButton, {BackgroundColor3 = Theme.AccentLight}, 0.2) end)
    SubmitButton.MouseLeave:Connect(function() Utility:Tween(SubmitButton, {BackgroundColor3 = Theme.Accent}, 0.2) end)
    local function Submit()
        local Key = InputBox.Text
        if Key == "" then
            StatusLabel.Text = "Please enter a key"
            Utility:Tween(InputFrame, {BackgroundColor3 = Color3.fromRGB(60, 30, 30)}, 0.2)
            task.delay(0.5, function() Utility:Tween(InputFrame, {BackgroundColor3 = Theme.Tertiary}, 0.3) end)
            return
        end
        if self:Verify(Key, Options.Key) then
            StatusLabel.Text = ""
            Utility:Tween(Window, {Size = UDim2.new(0, 400, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In, function()
                Window:Destroy()
                Callback(true)
            end)
        else
            StatusLabel.Text = "Invalid key! Please try again."
            Utility:Tween(InputFrame, {BackgroundColor3 = Color3.fromRGB(60, 30, 30)}, 0.2)
            task.delay(0.5, function() Utility:Tween(InputFrame, {BackgroundColor3 = Theme.Tertiary}, 0.3) end)
        end
    end
    SubmitButton.MouseButton1Click:Connect(Submit)
    InputBox.FocusLost:Connect(function(EnterPressed) if EnterPressed then Submit() end end)
    GetKeyButton.MouseButton1Click:Connect(function()
        if Options.KeyLink then
            StatusLabel.Text = "Key link copied to clipboard!"
            StatusLabel.TextColor3 = Theme.Success
        end
    end)
    Utility:MakeDraggable(Window, Header)
    Window.Size = UDim2.new(0, 400, 0, 0)
    Utility:Tween(Window, {Size = UDim2.new(0, 400, 0, 280)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end


-- MAIN WINDOW
function NexusUI:CreateWindow(Options)
    Options = Options or {}
    local WindowName = Options.Name or "NexusUI"
    local ThemeName = Options.Theme or "Dark"
    local Theme = Themes[ThemeName] or Themes.Dark
    local UseKeySystem = Options.KeySystem or false
    local Key = Options.Key or ""

    local ScreenGui = Utility:Create("ScreenGui", {
        Name = WindowName .. "_NexusUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game.CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    })

    local Main = Utility:Create("Frame", {
        Name = "Main", BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
        Size = UDim2.new(0, 700, 0, 450), Position = UDim2.new(0.5, -350, 0.5, -225),
        ClipsDescendants = true, Parent = ScreenGui
    })
    local MainCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Main})
    local MainStroke = Utility:Create("UIStroke", {Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = Main})
    local MainShadow = Utility:Create("ImageLabel", {
        Name = "Shadow", BackgroundTransparency = 1, Image = "rbxassetid://5554236805",
        ImageColor3 = Theme.Shadow, ImageTransparency = 0.7, ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277), Size = UDim2.new(1, 50, 1, 50),
        Position = UDim2.new(0, -25, 0, -25), ZIndex = 0, Parent = Main
    })

    -- Sidebar
    local Sidebar = Utility:Create("Frame", {Name = "Sidebar", BackgroundColor3 = Theme.Secondary, BorderSizePixel = 0, Size = UDim2.new(0, 180, 1, 0), Parent = Main})
    local SidebarCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Sidebar})
    local SidebarFix = Utility:Create("Frame", {BackgroundColor3 = Theme.Secondary, BorderSizePixel = 0, Size = UDim2.new(0, 12, 1, 0), Position = UDim2.new(1, -12, 0, 0), Parent = Sidebar})
    local LogoArea = Utility:Create("Frame", {Name = "LogoArea", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 70), Parent = Sidebar})
    local LogoText = Utility:Create("TextLabel", {Name = "LogoText", BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 15, 0, 15), Font = Enum.Font.GothamBold, Text = WindowName, TextColor3 = Theme.Text, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Parent = LogoArea})
    local VersionText = Utility:Create("TextLabel", {Name = "Version", BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 16), Position = UDim2.new(0, 15, 0, 42), Font = Enum.Font.Gotham, Text = "v2.0.0", TextColor3 = Theme.Accent, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = LogoArea})
    local Divider = Utility:Create("Frame", {Name = "Divider", BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Size = UDim2.new(1, -30, 0, 1), Position = UDim2.new(0, 15, 0, 68), Parent = Sidebar})
    local TabContainer = Utility:Create("ScrollingFrame", {Name = "TabContainer", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -140), Position = UDim2.new(0, 0, 0, 75), ScrollBarThickness = 0, ScrollBarImageTransparency = 1, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = Sidebar})
    local TabLayout = Utility:Create("UIListLayout", {Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = TabContainer})
    local BottomInfo = Utility:Create("Frame", {Name = "BottomInfo", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 55), Position = UDim2.new(0, 0, 1, -60), Parent = Sidebar})
    local BottomDivider = Utility:Create("Frame", {BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Size = UDim2.new(1, -30, 0, 1), Position = UDim2.new(0, 15, 0, 0), Parent = BottomInfo})
    local ProfilePic = Utility:Create("ImageLabel", {Name = "ProfilePic", BackgroundColor3 = Theme.Tertiary, BorderSizePixel = 0, Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(0, 15, 0, 12), Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48), Parent = BottomInfo})
    local ProfileCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ProfilePic})
    local UsernameLabel = Utility:Create("TextLabel", {Name = "Username", BackgroundTransparency = 1, Size = UDim2.new(1, -60, 0, 18), Position = UDim2.new(0, 55, 0, 12), Font = Enum.Font.GothamBold, Text = LocalPlayer.DisplayName or LocalPlayer.Name, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = BottomInfo})
    local UserIdLabel = Utility:Create("TextLabel", {Name = "UserId", BackgroundTransparency = 1, Size = UDim2.new(1, -60, 0, 14), Position = UDim2.new(0, 55, 0, 30), Font = Enum.Font.Gotham, Text = "@" .. LocalPlayer.Name, TextColor3 = Theme.TextDark, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = BottomInfo})

    -- Content Area
    local ContentArea = Utility:Create("Frame", {Name = "ContentArea", BackgroundTransparency = 1, Size = UDim2.new(1, -180, 1, 0), Position = UDim2.new(0, 180, 0, 0), Parent = Main})
    local TopBar = Utility:Create("Frame", {Name = "TopBar", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), Parent = ContentArea})
    local TabTitle = Utility:Create("TextLabel", {Name = "TabTitle", BackgroundTransparency = 1, Size = UDim2.new(1, -120, 0, 30), Position = UDim2.new(0, 20, 0, 12), Font = Enum.Font.GothamBold, Text = "Home", TextColor3 = Theme.Text, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar})
    local MinimizeButton = Utility:Create("TextButton", {Name = "Minimize", BackgroundTransparency = 1, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -70, 0, 10), Font = Enum.Font.GothamBold, Text = "−", TextColor3 = Theme.TextDark, TextSize = 20, Parent = TopBar})
    local CloseButton = Utility:Create("TextButton", {Name = "Close", BackgroundTransparency = 1, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -40, 0, 10), Font = Enum.Font.GothamBold, Text = "×", TextColor3 = Theme.TextDark, TextSize = 20, Parent = TopBar})
    local ContentScroll = Utility:Create("ScrollingFrame", {Name = "ContentScroll", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -50), Position = UDim2.new(0, 0, 0, 50), ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Border, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = ContentArea})
    local ContentLayout = Utility:Create("UIListLayout", {Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = ContentScroll})
    local ContentPadding = Utility:Create("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 20), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), Parent = ContentScroll})

    -- Window Logic
    local Window = {}
    Window.Tabs = {}
    Window.CurrentTab = nil
    Window.Theme = Theme
    Window.ScreenGui = ScreenGui
    Window.Main = Main
    Window.IsMinimized = false

    NotificationSystem:Init(ScreenGui, Theme)
    Window.Notify = function(Options) NotificationSystem:Notify(Options) end

    Utility:MakeDraggable(Main, TopBar)

    MinimizeButton.MouseButton1Click:Connect(function()
        Window.IsMinimized = not Window.IsMinimized
        if Window.IsMinimized then
            Utility:Tween(Main, {Size = UDim2.new(0, 700, 0, 50)}, 0.4, Enum.EasingStyle.Quart)
            ContentArea.Visible = false; Sidebar.Visible = false
        else
            ContentArea.Visible = true; Sidebar.Visible = true
            Utility:Tween(Main, {Size = UDim2.new(0, 700, 0, 450)}, 0.4, Enum.EasingStyle.Quart)
        end
    end)

    CloseButton.MouseButton1Click:Connect(function()
        Utility:Tween(Main, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In, function()
            ScreenGui:Destroy()
        end)
    end)

    MinimizeButton.MouseEnter:Connect(function() Utility:Tween(MinimizeButton, {TextColor3 = Theme.Text}, 0.2) end)
    MinimizeButton.MouseLeave:Connect(function() Utility:Tween(MinimizeButton, {TextColor3 = Theme.TextDark}, 0.2) end)
    CloseButton.MouseEnter:Connect(function() Utility:Tween(CloseButton, {TextColor3 = Theme.Error}, 0.2) end)
    CloseButton.MouseLeave:Connect(function() Utility:Tween(CloseButton, {TextColor3 = Theme.TextDark}, 0.2) end)

    function Window:SwitchTab(Tab)
        if Window.CurrentTab == Tab then return end
        if Window.CurrentTab then
            Utility:Tween(Window.CurrentTab.Button, {BackgroundColor3 = Theme.Secondary}, 0.2)
            Utility:Tween(Window.CurrentTab.Button.Text, {TextColor3 = Theme.TextDark}, 0.2)
            Utility:Tween(Window.CurrentTab.Button.Icon, {ImageColor3 = Theme.TextDark}, 0.2)
            Window.CurrentTab.Page.Visible = false
        end
        Window.CurrentTab = Tab
        Utility:Tween(Tab.Button, {BackgroundColor3 = Theme.Accent}, 0.2)
        Utility:Tween(Tab.Button.Text, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
        Utility:Tween(Tab.Button.Icon, {ImageColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
        Tab.Page.Visible = true
        TabTitle.Text = Tab.Name
        Tab.Page.Position = UDim2.new(0, 20, 0, 0)
        Utility:Tween(Tab.Page, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Quart)
    end

    function Window:CreateTab(TabOptions)
        TabOptions = TabOptions or {}
        local TabName = TabOptions.Name or "Tab"
        local TabIcon = TabOptions.Icon or ""

        local TabButton = Utility:Create("TextButton", {Name = TabName .. "Tab", BackgroundColor3 = Theme.Secondary, BorderSizePixel = 0, Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0, 0), Font = Enum.Font.Gotham, Text = "", AutoButtonColor = false, Parent = TabContainer})
        local TabButtonCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = TabButton})
        local TabIconImage = Utility:Create("ImageLabel", {Name = "Icon", BackgroundTransparency = 1, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 12, 0.5, -10), Image = TabIcon, ImageColor3 = Theme.TextDark, Parent = TabButton})
        local TabButtonText = Utility:Create("TextLabel", {Name = "Text", BackgroundTransparency = 1, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 42, 0, 0), Font = Enum.Font.Gotham, Text = TabName, TextColor3 = Theme.TextDark, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = TabButton})
        local TabPage = Utility:Create("Frame", {Name = TabName .. "Page", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, Parent = ContentScroll})
        local PageLayout = Utility:Create("UIListLayout", {Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = TabPage})
        local PagePadding = Utility:Create("UIPadding", {PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 20), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), Parent = TabPage})

        local Tab = {}
        Tab.Name = TabName; Tab.Button = TabButton; Tab.Page = TabPage; Tab.Elements = {}

        TabButton.MouseButton1Click:Connect(function() Window:SwitchTab(Tab) end)
        TabButton.MouseEnter:Connect(function() if Window.CurrentTab ~= Tab then Utility:Tween(TabButton, {BackgroundColor3 = Theme.Tertiary}, 0.2) end end)
        TabButton.MouseLeave:Connect(function() if Window.CurrentTab ~= Tab then Utility:Tween(TabButton, {BackgroundColor3 = Theme.Secondary}, 0.2) end end)

        -- Section
        function Tab:CreateSection(SectionOptions)
            SectionOptions = SectionOptions or {}
            local SectionName = SectionOptions.Name or "Section"
            local Section = Utility:Create("Frame", {Name = SectionName .. "Section", BackgroundColor3 = Theme.Secondary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = TabPage})
            local SectionCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = Section})
            local SectionPadding = Utility:Create("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), Parent = Section})
            local SectionTitle = Utility:Create("TextLabel", {Name = "Title", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.GothamBold, Text = SectionName, TextColor3 = Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = Section})
            local SectionDivider = Utility:Create("Frame", {Name = "Divider", BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 28), Parent = Section})
            local ElementContainer = Utility:Create("Frame", {Name = "Elements", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 35), AutomaticSize = Enum.AutomaticSize.Y, Parent = Section})
            local ElementLayout = Utility:Create("UIListLayout", {Padding = UDim.new(0, 8), Parent = ElementContainer})

            local SectionObj = {}
            SectionObj.Container = ElementContainer
            function SectionObj:CreateButton(ButtonOptions) return Tab:CreateButton(ButtonOptions, ElementContainer) end
            function SectionObj:CreateToggle(ToggleOptions) return Tab:CreateToggle(ToggleOptions, ElementContainer) end
            function SectionObj:CreateSlider(SliderOptions) return Tab:CreateSlider(SliderOptions, ElementContainer) end
            function SectionObj:CreateDropdown(DropdownOptions) return Tab:CreateDropdown(DropdownOptions, ElementContainer) end
            function SectionObj:CreateInput(InputOptions) return Tab:CreateInput(InputOptions, ElementContainer) end
            function SectionObj:CreateKeybind(KeybindOptions) return Tab:CreateKeybind(KeybindOptions, ElementContainer) end
            function SectionObj:CreateLabel(LabelOptions) return Tab:CreateLabel(LabelOptions, ElementContainer) end
            function SectionObj:CreateParagraph(ParagraphOptions) return Tab:CreateParagraph(ParagraphOptions, ElementContainer) end
            function SectionObj:CreateColorPicker(ColorPickerOptions) return Tab:CreateColorPicker(ColorPickerOptions, ElementContainer) end
            return SectionObj
        end

        -- Button
        function Tab:CreateButton(ButtonOptions, ParentFrame)
            ParentFrame = ParentFrame or TabPage
            ButtonOptions = ButtonOptions or {}
            local ButtonName = ButtonOptions.Name or "Button"
            local Callback = ButtonOptions.Callback or function() end
            local Button = Utility:Create("TextButton", {Name = ButtonName .. "Button", BackgroundColor3 = Theme.Tertiary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38), Font = Enum.Font.Gotham, Text = "", AutoButtonColor = false, Parent = ParentFrame})
            local ButtonCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Button})
            local ButtonText = Utility:Create("TextLabel", {Name = "Text", BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), Font = Enum.Font.Gotham, Text = ButtonName, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Button})
            local ArrowIcon = Utility:Create("ImageLabel", {Name = "Arrow", BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -26, 0.5, -8), Image = "rbxassetid://7072706748", ImageColor3 = Theme.TextDark, Parent = Button})
            Button.MouseEnter:Connect(function() Utility:Tween(Button, {BackgroundColor3 = Theme.Accent}, 0.2); Utility:Tween(ButtonText, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2); Utility:Tween(ArrowIcon, {ImageColor3 = Color3.fromRGB(255, 255, 255)}, 0.2) end)
            Button.MouseLeave:Connect(function() Utility:Tween(Button, {BackgroundColor3 = Theme.Tertiary}, 0.2); Utility:Tween(ButtonText, {TextColor3 = Theme.Text}, 0.2); Utility:Tween(ArrowIcon, {ImageColor3 = Theme.TextDark}, 0.2) end)
            Button.MouseButton1Click:Connect(function() Utility:RippleEffect(Button, Vector2.new(Mouse.X, Mouse.Y), Theme); Callback() end)
            return Button
        end

        -- Toggle
        function Tab:CreateToggle(ToggleOptions, ParentFrame)
            ParentFrame = ParentFrame or TabPage
            ToggleOptions = ToggleOptions or {}
            local ToggleName = ToggleOptions.Name or "Toggle"
            local Default = ToggleOptions.Default or false
            local Callback = ToggleOptions.Callback or function() end
            local ToggleFrame = Utility:Create("Frame", {Name = ToggleName .. "Toggle", BackgroundColor3 = Theme.Tertiary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38), Parent = ParentFrame})
            local ToggleCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = ToggleFrame})
            local ToggleText = Utility:Create("TextLabel", {Name = "Text", BackgroundTransparency = 1, Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 10, 0, 0), Font = Enum.Font.Gotham, Text = ToggleName, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = ToggleFrame})
            local ToggleBackground = Utility:Create("Frame", {Name = "Background", BackgroundColor3 = Default and Theme.Accent or Theme.Border, BorderSizePixel = 0, Size = UDim2.new(0, 44, 0, 22), Position = UDim2.new(1, -54, 0.5, -11), Parent = ToggleFrame})
            local ToggleBgCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ToggleBackground})
            local ToggleCircle = Utility:Create("Frame", {Name = "Circle", BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Size = UDim2.new(0, 18, 0, 18), Position = Default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9), Parent = ToggleBackground})
            local ToggleCircleCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ToggleCircle})
            local State = Default
            local function UpdateToggle()
                State = not State
                Utility:Tween(ToggleBackground, {BackgroundColor3 = State and Theme.Accent or Theme.Border}, 0.3)
                Utility:Tween(ToggleCircle, {Position = State and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}, 0.3, Enum.EasingStyle.Quart)
                Callback(State)
            end
            ToggleFrame.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then UpdateToggle() end end)
            local ToggleObj = {}
            function ToggleObj:Set(Value) if Value ~= State then UpdateToggle() end end
            function ToggleObj:Get() return State end
            return ToggleObj
        end

        -- Slider
        function Tab:CreateSlider(SliderOptions, ParentFrame)
            ParentFrame = ParentFrame or TabPage
            SliderOptions = SliderOptions or {}
            local SliderName = SliderOptions.Name or "Slider"
            local Min = SliderOptions.Min or 0
            local Max = SliderOptions.Max or 100
            local Default = SliderOptions.Default or Min
            local Increment = SliderOptions.Increment or 1
            local Suffix = SliderOptions.Suffix or ""
            local Callback = SliderOptions.Callback or function() end
            local SliderFrame = Utility:Create("Frame", {Name = SliderName .. "Slider", BackgroundColor3 = Theme.Tertiary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 55), Parent = ParentFrame})
            local SliderCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = SliderFrame})
            local SliderText = Utility:Create("TextLabel", {Name = "Text", BackgroundTransparency = 1, Size = UDim2.new(1, -70, 0, 20), Position = UDim2.new(0, 10, 0, 6), Font = Enum.Font.Gotham, Text = SliderName, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = SliderFrame})
            local ValueText = Utility:Create("TextLabel", {Name = "Value", BackgroundTransparency = 1, Size = UDim2.new(0, 60, 0, 20), Position = UDim2.new(1, -70, 0, 6), Font = Enum.Font.GothamBold, Text = tostring(Default) .. Suffix, TextColor3 = Theme.Accent, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = SliderFrame})
            local SliderBarBg = Utility:Create("Frame", {Name = "BarBg", BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 35), Parent = SliderFrame})
            local SliderBarBgCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SliderBarBg})
            local SliderBarFill = Utility:Create("Frame", {Name = "BarFill", BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0), Parent = SliderBarBg})
            local SliderBarFillCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SliderBarFill})
            local SliderKnob = Utility:Create("Frame", {Name = "Knob", BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new((Default - Min) / (Max - Min), -7, 0.5, -7), Parent = SliderBarBg})
            local SliderKnobCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SliderKnob})
            local Dragging = false
            local CurrentValue = Default
            local function UpdateSlider(Input)
                local Pos = math.clamp((Input.Position.X - SliderBarBg.AbsolutePosition.X) / SliderBarBg.AbsoluteSize.X, 0, 1)
                local Value = math.floor((Min + (Max - Min) * Pos) / Increment + 0.5) * Increment
                Value = math.clamp(Value, Min, Max)
                if Value ~= CurrentValue then
                    CurrentValue = Value
                    local Scale = (Value - Min) / (Max - Min)
                    Utility:Tween(SliderBarFill, {Size = UDim2.new(Scale, 0, 1, 0)}, 0.1)
                    Utility:Tween(SliderKnob, {Position = UDim2.new(Scale, -7, 0.5, -7)}, 0.1)
                    ValueText.Text = tostring(Value) .. Suffix
                    Callback(Value)
                end
            end
            SliderBarBg.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = true; UpdateSlider(Input) end end)
            UserInputService.InputChanged:Connect(function(Input) if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then UpdateSlider(Input) end end)
            UserInputService.InputEnded:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end end)
            local SliderObj = {}
            function SliderObj:Set(Value)
                Value = math.clamp(math.floor(Value / Increment + 0.5) * Increment, Min, Max)
                CurrentValue = Value
                local Scale = (Value - Min) / (Max - Min)
                Utility:Tween(SliderBarFill, {Size = UDim2.new(Scale, 0, 1, 0)}, 0.2)
                Utility:Tween(SliderKnob, {Position = UDim2.new(Scale, -7, 0.5, -7)}, 0.2)
                ValueText.Text = tostring(Value) .. Suffix
                Callback(Value)
            end
            function SliderObj:Get() return CurrentValue end
            return SliderObj
        end

        -- Dropdown
        function Tab:CreateDropdown(DropdownOptions, ParentFrame)
            ParentFrame = ParentFrame or TabPage
            DropdownOptions = DropdownOptions or {}
            local DropdownName = DropdownOptions.Name or "Dropdown"
            local OptionsList = DropdownOptions.Options or {}
            local Default = DropdownOptions.Default or (OptionsList[1] or "")
            local Callback = DropdownOptions.Callback or function() end
            local DropdownFrame = Utility:Create("Frame", {Name = DropdownName .. "Dropdown", BackgroundColor3 = Theme.Tertiary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38), ClipsDescendants = true, Parent = ParentFrame})
            local DropdownCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = DropdownFrame})
            local DropdownText = Utility:Create("TextLabel", {Name = "Text", BackgroundTransparency = 1, Size = UDim2.new(1, -50, 0, 38), Position = UDim2.new(0, 10, 0, 0), Font = Enum.Font.Gotham, Text = DropdownName, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = DropdownFrame})
            local SelectedText = Utility:Create("TextLabel", {Name = "Selected", BackgroundTransparency = 1, Size = UDim2.new(0, 120, 0, 38), Position = UDim2.new(1, -140, 0, 0), Font = Enum.Font.Gotham, Text = Default, TextColor3 = Theme.Accent, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = DropdownFrame})
            local ArrowIcon = Utility:Create("ImageLabel", {Name = "Arrow", BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -26, 0.5, -8), Image = "rbxassetid://7072706748", ImageColor3 = Theme.TextDark, Rotation = 0, Parent = DropdownFrame})
            local OptionsFrame = Utility:Create("Frame", {Name = "Options", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 38), Parent = DropdownFrame})
            local OptionsLayout = Utility:Create("UIListLayout", {Padding = UDim.new(0, 2), Parent = OptionsFrame})
            local OptionsPadding = Utility:Create("UIPadding", {PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = OptionsFrame})
            local IsOpen = false
            local CurrentSelection = Default
            local OptionButtons = {}
            for _, Option in ipairs(OptionsList) do
                local OptionButton = Utility:Create("TextButton", {Name = Option, BackgroundColor3 = Theme.Secondary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 32), Font = Enum.Font.Gotham, Text = Option, TextColor3 = Option == Default and Theme.Accent or Theme.TextDark, TextSize = 12, AutoButtonColor = false, Parent = OptionsFrame})
                local OptionCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = OptionButton})
                OptionButton.MouseEnter:Connect(function() if Option ~= CurrentSelection then Utility:Tween(OptionButton, {BackgroundColor3 = Theme.Tertiary}, 0.2) end end)
                OptionButton.MouseLeave:Connect(function() if Option ~= CurrentSelection then Utility:Tween(OptionButton, {BackgroundColor3 = Theme.Secondary}, 0.2) end end)
                OptionButton.MouseButton1Click:Connect(function()
                    CurrentSelection = Option; SelectedText.Text = Option
                    for _, Btn in ipairs(OptionButtons) do Utility:Tween(Btn, {BackgroundColor3 = Theme.Secondary, TextColor3 = Theme.TextDark}, 0.2) end
                    Utility:Tween(OptionButton, {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
                    Callback(Option); IsOpen = false
                    Utility:Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 38)}, 0.3)
                    Utility:Tween(ArrowIcon, {Rotation = 0}, 0.3)
                end)
                table.insert(OptionButtons, OptionButton)
            end
            for _, Btn in ipairs(OptionButtons) do if Btn.Name == Default then Utility:Tween(Btn, {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0) end end
            DropdownFrame.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    IsOpen = not IsOpen
                    local OptionsHeight = #OptionsList * 34 + 10
                    Utility:Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, IsOpen and 38 + OptionsHeight or 38)}, 0.3, Enum.EasingStyle.Quart)
                    Utility:Tween(ArrowIcon, {Rotation = IsOpen and 180 or 0}, 0.3)
                end
            end)
            local DropdownObj = {}
            function DropdownObj:Set(Value)
                for _, Btn in ipairs(OptionButtons) do
                    if Btn.Name == Value then
                        CurrentSelection = Value; SelectedText.Text = Value
                        for _, B in ipairs(OptionButtons) do Utility:Tween(B, {BackgroundColor3 = Theme.Secondary, TextColor3 = Theme.TextDark}, 0.2) end
                        Utility:Tween(Btn, {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
                        Callback(Value); break
                    end
                end
            end
            function DropdownObj:Get() return CurrentSelection end
            function DropdownObj:Refresh(NewOptions, KeepSelected)
                for _, Btn in ipairs(OptionButtons) do Btn:Destroy() end
                OptionButtons = {}
                for _, Option in ipairs(NewOptions) do
                    local OptionButton = Utility:Create("TextButton", {Name = Option, BackgroundColor3 = Theme.Secondary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 32), Font = Enum.Font.Gotham, Text = Option, TextColor3 = Theme.TextDark, TextSize = 12, AutoButtonColor = false, Parent = OptionsFrame})
                    local OptionCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = OptionButton})
                    OptionButton.MouseEnter:Connect(function() if Option ~= CurrentSelection then Utility:Tween(OptionButton, {BackgroundColor3 = Theme.Tertiary}, 0.2) end end)
                    OptionButton.MouseLeave:Connect(function() if Option ~= CurrentSelection then Utility:Tween(OptionButton, {BackgroundColor3 = Theme.Secondary}, 0.2) end end)
                    OptionButton.MouseButton1Click:Connect(function()
                        CurrentSelection = Option; SelectedText.Text = Option
                        for _, Btn in ipairs(OptionButtons) do Utility:Tween(Btn, {BackgroundColor3 = Theme.Secondary, TextColor3 = Theme.TextDark}, 0.2) end
                        Utility:Tween(OptionButton, {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
                        Callback(Option); IsOpen = false
                        Utility:Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 38)}, 0.3)
                        Utility:Tween(ArrowIcon, {Rotation = 0}, 0.3)
                    end)
                    table.insert(OptionButtons, OptionButton)
                end
                if not KeepSelected then CurrentSelection = NewOptions[1] or ""; SelectedText.Text = CurrentSelection end
            end
            return DropdownObj
        end

        -- Input
        function Tab:CreateInput(InputOptions, ParentFrame)
            ParentFrame = ParentFrame or TabPage
            InputOptions = InputOptions or {}
            local InputName = InputOptions.Name or "Input"
            local Placeholder = InputOptions.Placeholder or "Enter text..."
            local Default = InputOptions.Default or ""
            local Numeric = InputOptions.Numeric or false
            local Finished = InputOptions.Finished or false
            local Callback = InputOptions.Callback or function() end
            local InputFrame = Utility:Create("Frame", {Name = InputName .. "Input", BackgroundColor3 = Theme.Tertiary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 70), Parent = ParentFrame})
            local InputCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = InputFrame})
            local InputLabel = Utility:Create("TextLabel", {Name = "Label", BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 6), Font = Enum.Font.Gotham, Text = InputName, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = InputFrame})
            local InputBoxFrame = Utility:Create("Frame", {Name = "BoxFrame", BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Size = UDim2.new(1, -20, 0, 32), Position = UDim2.new(0, 10, 0, 30), Parent = InputFrame})
            local BoxFrameCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = InputBoxFrame})
            local InputBox = Utility:Create("TextBox", {Name = "InputBox", BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), Font = Enum.Font.Gotham, Text = Default, PlaceholderText = Placeholder, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextDark, TextSize = 12, ClearTextOnFocus = false, Parent = InputBoxFrame})
            if Numeric then InputBox:GetPropertyChangedSignal("Text"):Connect(function() InputBox.Text = InputBox.Text:gsub("[^%d.-]", "") end) end
            if Finished then InputBox.FocusLost:Connect(function(EnterPressed) Callback(InputBox.Text) end)
            else InputBox:GetPropertyChangedSignal("Text"):Connect(function() Callback(InputBox.Text) end) end
            local InputObj = {}
            function InputObj:Set(Text) InputBox.Text = tostring(Text); Callback(InputBox.Text) end
            function InputObj:Get() return InputBox.Text end
            return InputObj
        end

        -- Keybind
        function Tab:CreateKeybind(KeybindOptions, ParentFrame)
            ParentFrame = ParentFrame or TabPage
            KeybindOptions = KeybindOptions or {}
            local KeybindName = KeybindOptions.Name or "Keybind"
            local Default = KeybindOptions.Default or "None"
            local Callback = KeybindOptions.Callback or function() end
            local KeybindFrame = Utility:Create("Frame", {Name = KeybindName .. "Keybind", BackgroundColor3 = Theme.Tertiary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38), Parent = ParentFrame})
            local KeybindCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = KeybindFrame})
            local KeybindText = Utility:Create("TextLabel", {Name = "Text", BackgroundTransparency = 1, Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 10, 0, 0), Font = Enum.Font.Gotham, Text = KeybindName, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = KeybindFrame})
            local KeybindButton = Utility:Create("TextButton", {Name = "KeybindButton", BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Size = UDim2.new(0, 80, 0, 26), Position = UDim2.new(1, -90, 0.5, -13), Font = Enum.Font.GothamBold, Text = Default == "None" and "None" or Default.Name, TextColor3 = Theme.Accent, TextSize = 11, AutoButtonColor = false, Parent = KeybindFrame})
            local KeybindButtonCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = KeybindButton})
            local CurrentKey = Default == "None" and nil or Default
            local WaitingForInput = false
            KeybindButton.MouseButton1Click:Connect(function()
                if WaitingForInput then return end
                WaitingForInput = true; KeybindButton.Text = "..."
                local Connection
                Connection = UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        CurrentKey = Input.KeyCode; KeybindButton.Text = Input.KeyCode.Name; WaitingForInput = false; Connection:Disconnect()
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        CurrentKey = Enum.UserInputType.MouseButton1; KeybindButton.Text = "MB1"; WaitingForInput = false; Connection:Disconnect()
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        CurrentKey = Enum.UserInputType.MouseButton2; KeybindButton.Text = "MB2"; WaitingForInput = false; Connection:Disconnect()
                    end
                end)
                task.delay(5, function()
                    if WaitingForInput then WaitingForInput = false; KeybindButton.Text = CurrentKey and (CurrentKey.Name or "MB1") or "None"; if Connection then Connection:Disconnect() end end
                end)
            end)
            UserInputService.InputBegan:Connect(function(Input)
                if not WaitingForInput and CurrentKey and Input.KeyCode == CurrentKey then Callback(CurrentKey) end
            end)
            local KeybindObj = {}
            function KeybindObj:Set(Key) CurrentKey = Key; KeybindButton.Text = Key and (Key.Name or "MB1") or "None" end
            function KeybindObj:Get() return CurrentKey end
            return KeybindObj
        end

        -- Label
        function Tab:CreateLabel(LabelOptions, ParentFrame)
            ParentFrame = ParentFrame or TabPage
            LabelOptions = LabelOptions or {}
            local LabelText = LabelOptions.Text or "Label"
            local Color = LabelOptions.Color or Theme.Text
            local Label = Utility:Create("TextLabel", {Name = "Label", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.Gotham, Text = LabelText, TextColor3 = Color, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = ParentFrame})
            local LabelObj = {}
            function LabelObj:Set(Text) Label.Text = tostring(Text) end
            function LabelObj:Get() return Label.Text end
            return LabelObj
        end

        -- Paragraph
        function Tab:CreateParagraph(ParagraphOptions, ParentFrame)
            ParentFrame = ParentFrame or TabPage
            ParagraphOptions = ParagraphOptions or {}
            local Title = ParagraphOptions.Title or "Paragraph"
            local Content = ParagraphOptions.Content or ""
            local ParagraphFrame = Utility:Create("Frame", {Name = "Paragraph", BackgroundColor3 = Theme.Tertiary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = ParentFrame})
            local ParagraphCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = ParagraphFrame})
            local ParagraphPadding = Utility:Create("UIPadding", {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = ParagraphFrame})
            local TitleLabel = Utility:Create("TextLabel", {Name = "Title", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.GothamBold, Text = Title, TextColor3 = Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = ParagraphFrame})
            local ContentLabel = Utility:Create("TextLabel", {Name = "Content", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 24), Font = Enum.Font.Gotham, Text = Content, TextColor3 = Theme.TextDark, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Parent = ParagraphFrame})
            local ParagraphObj = {}
            function ParagraphObj:SetTitle(NewTitle) TitleLabel.Text = tostring(NewTitle) end
            function ParagraphObj:SetContent(NewContent) ContentLabel.Text = tostring(NewContent) end
            return ParagraphObj
        end

        -- Color Picker
        function Tab:CreateColorPicker(ColorPickerOptions, ParentFrame)
            ParentFrame = ParentFrame or TabPage
            ColorPickerOptions = ColorPickerOptions or {}
            local PickerName = ColorPickerOptions.Name or "Color Picker"
            local Default = ColorPickerOptions.Default or Color3.fromRGB(255, 255, 255)
            local Callback = ColorPickerOptions.Callback or function() end
            local ColorPickerFrame = Utility:Create("Frame", {Name = PickerName .. "ColorPicker", BackgroundColor3 = Theme.Tertiary, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38), ClipsDescendants = true, Parent = ParentFrame})
            local ColorPickerCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = ColorPickerFrame})
            local ColorPickerText = Utility:Create("TextLabel", {Name = "Text", BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0), Font = Enum.Font.Gotham, Text = PickerName, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = ColorPickerFrame})
            local ColorPreview = Utility:Create("Frame", {Name = "Preview", BackgroundColor3 = Default, BorderSizePixel = 0, Size = UDim2.new(0, 30, 0, 22), Position = UDim2.new(1, -45, 0.5, -11), Parent = ColorPickerFrame})
            local PreviewCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = ColorPreview})
            local PickerArea = Utility:Create("Frame", {Name = "PickerArea", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 180), Position = UDim2.new(0, 0, 0, 38), Parent = ColorPickerFrame})
            local RSlider = Utility:Create("Frame", {Name = "RSlider", BackgroundColor3 = Color3.fromRGB(50, 0, 0), BorderSizePixel = 0, Size = UDim2.new(1, -20, 0, 8), Position = UDim2.new(0, 10, 0, 15), Parent = PickerArea})
            local RCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = RSlider})
            local RFill = Utility:Create("Frame", {Name = "Fill", BackgroundColor3 = Color3.fromRGB(255, 0, 0), BorderSizePixel = 0, Size = UDim2.new(Default.R, 0, 1, 0), Parent = RSlider})
            local RFillCorner = Utility:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = RFill})
            local RLabel = Utility:Create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(0, 30, 0, 20), Position = UDim2.new(0, 0, 0, -5), Font = Enum.Font.GothamBold, Text = "R", TextColor3 = Color3.fromRGB(255, 100, 100), TextSize = 10, Parent = RSlider})
            local GSlider = RSlider:Clone(); GSlider.Name = "GSlider"; GSlider.BackgroundColor3 = Color3.fromRGB(0, 50, 0); GSlider.Position = UDim2.new(0, 10, 0, 50); GSlider.Parent = PickerArea; GSlider.Fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0); GSlider.Fill.Size = UDim2.new(Default.G, 0, 1, 0); GSlider.TextLabel.Text = "G"; GSlider.TextLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            local BSlider = RSlider:Clone(); BSlider.Name = "BSlider"; BSlider.BackgroundColor3 = Color3.fromRGB(0, 0, 50); BSlider.Position = UDim2.new(0, 10, 0, 85); BSlider.Parent = PickerArea; BSlider.Fill.BackgroundColor3 = Color3.fromRGB(0, 0, 255); BSlider.Fill.Size = UDim2.new(Default.B, 0, 1, 0); BSlider.TextLabel.Text = "B"; BSlider.TextLabel.TextColor3 = Color3.fromRGB(100, 100, 255)
            local HexLabel = Utility:Create("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 120), Font = Enum.Font.Gotham, Text = string.format("#%02X%02X%02X", Default.R * 255, Default.G * 255, Default.B * 255), TextColor3 = Theme.TextDark, TextSize = 12, Parent = PickerArea})
            local IsOpen = false
            local CurrentColor = Default
            local function UpdateColor()
                CurrentColor = Color3.fromRGB(math.floor(RSlider.Fill.Size.X.Scale * 255), math.floor(GSlider.Fill.Size.X.Scale * 255), math.floor(BSlider.Fill.Size.X.Scale * 255))
                ColorPreview.BackgroundColor3 = CurrentColor
                HexLabel.Text = string.format("#%02X%02X%02X", CurrentColor.R * 255, CurrentColor.G * 255, CurrentColor.B * 255)
                Callback(CurrentColor)
            end
            local function SetupSlider(Slider)
                local Dragging = false
                Slider.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = true; local Pos = math.clamp((Input.Position.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1); Utility:Tween(Slider.Fill, {Size = UDim2.new(Pos, 0, 1, 0)}, 0.1); UpdateColor() end end)
                UserInputService.InputChanged:Connect(function(Input) if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then local Pos = math.clamp((Input.Position.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1); Utility:Tween(Slider.Fill, {Size = UDim2.new(Pos, 0, 1, 0)}, 0.05); UpdateColor() end end)
                UserInputService.InputEnded:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end end)
            end
            SetupSlider(RSlider); SetupSlider(GSlider); SetupSlider(BSlider)
            ColorPickerFrame.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then IsOpen = not IsOpen; Utility:Tween(ColorPickerFrame, {Size = UDim2.new(1, 0, 0, IsOpen and 220 or 38)}, 0.3) end end)
            local ColorPickerObj = {}
            function ColorPickerObj:Set(Color) RSlider.Fill.Size = UDim2.new(Color.R, 0, 1, 0); GSlider.Fill.Size = UDim2.new(Color.G, 0, 1, 0); BSlider.Fill.Size = UDim2.new(Color.B, 0, 1, 0); CurrentColor = Color; ColorPreview.BackgroundColor3 = Color; HexLabel.Text = string.format("#%02X%02X%02X", Color.R * 255, Color.G * 255, Color.B * 255); Callback(Color) end
            function ColorPickerObj:Get() return CurrentColor end
            return ColorPickerObj
        end

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then Window:SwitchTab(Tab) end
        return Tab
    end

    -- Key System Handling
    if UseKeySystem then
        Main.Visible = false
        KeySystem:CreateWindow(ScreenGui, Theme, {Name = WindowName, Key = Key}, function(Success)
            if Success then
                Main.Visible = true
                Utility:Tween(Main, {Size = UDim2.new(0, 700, 0, 0)}, 0)
                Utility:Tween(Main, {Size = UDim2.new(0, 700, 0, 450)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                Window:Notify({Title = "Success!", Content = "Key validated successfully. Welcome to " .. WindowName .. "!", Duration = 4, Type = "Success"})
            end
        end)
    else
        Main.Size = UDim2.new(0, 700, 0, 0)
        Utility:Tween(Main, {Size = UDim2.new(0, 700, 0, 450)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end

    task.delay(0.6, function()
        Window:Notify({Title = WindowName, Content = "GUI loaded successfully! Press the button in the top right to close.", Duration = 5, Type = "Info"})
    end)

    return Window
end

-- EXAMPLE USAGE
--[[
local Window = NexusUI:CreateWindow({
    Name = "Nexus Hub",
    Theme = "Dark",
    KeySystem = false,
    Key = "NEXUS-2024"
})

local MainTab = Window:CreateTab({Name = "Main", Icon = "rbxassetid://4483345998"})
local PlayerSection = MainTab:CreateSection({Name = "Player"})

PlayerSection:CreateButton({Name = "Fly", Callback = function() print("Fly enabled!") end})
PlayerSection:CreateToggle({Name = "Noclip", Default = false, Callback = function(Value) print("Noclip:", Value) end})
PlayerSection:CreateSlider({Name = "WalkSpeed", Min = 16, Max = 200, Default = 16, Suffix = " studs/s", Callback = function(Value) print("Speed:", Value) end})
PlayerSection:CreateDropdown({Name = "Teleport", Options = {"Spawn", "Shop", "Bank", "House"}, Default = "Spawn", Callback = function(Value) print("Teleport to:", Value) end})
PlayerSection:CreateInput({Name = "Username", Placeholder = "Enter username...", Callback = function(Text) print("Username:", Text) end})
PlayerSection:CreateKeybind({Name = "Fly Key", Default = Enum.KeyCode.F, Callback = function() print("Fly toggled!") end})
PlayerSection:CreateColorPicker({Name = "ESP Color", Default = Color3.fromRGB(255, 0, 0), Callback = function(Color) print("Color:", Color) end})
MainTab:CreateParagraph({Title = "Information", Content = "Welcome to Nexus Hub! This is a modern GUI library for Roblox with smooth animations and a clean design."})
Window:Notify({Title = "Welcome", Content = "Nexus Hub loaded successfully!", Duration = 5, Type = "Success"})
--]]

return NexusUI
