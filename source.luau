-- ViperUI Library
local ViperUI = {}
ViperUI.__index = ViperUI

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local LIBRARY_VERSION = "1.0.0"
local MIN_WINDOW_SIZE = Vector2.new(400, 300)
local MAX_WINDOW_SIZE = Vector2.new(1200, 800)
local DEFAULT_WINDOW_SIZE = Vector2.new(500, 400)

local COLORS = {
    Primary = Color3.fromRGB(0, 100, 0),
    Secondary = Color3.fromRGB(0, 80, 0),
    Accent = Color3.fromRGB(0, 150, 0),
    Background = Color3.fromRGB(20, 20, 20),
    Surface = Color3.fromRGB(30, 30, 30),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(200, 200, 200),
    Error = Color3.fromRGB(255, 50, 50),
    Success = Color3.fromRGB(50, 255, 50),
    Warning = Color3.fromRGB(255, 255, 50)
}

local ANIMATION_PRESETS = {
    EaseInOut = Enum.EasingStyle.Quad,
    Bounce = Enum.EasingStyle.Bounce,
    Elastic = Enum.EasingStyle.Elastic,
    Back = Enum.EasingStyle.Back
}

local function Create(class, properties)
    local obj = Instance.new(class)
    for prop, value in pairs(properties) do
        obj[prop] = value
    end
    return obj
end

local function Tween(Object, Properties, Duration, Style, Direction)
    local tweenInfo = TweenInfo.new(Duration, Style or Enum.EasingStyle.Quad, Direction or Enum.EasingDirection.Out)
    local tween = TweenService:Create(Object, tweenInfo, Properties)
    tween:Play()
    return tween
end

local function RoundCorners(Object, CornerRadius)
    local corner = Create("UICorner", {
        CornerRadius = UDim.new(0, CornerRadius or 8),
        Parent = Object
    })
    return corner
end

local function CreateStroke(Object, Color, Thickness)
    local stroke = Create("UIStroke", {
        Parent = Object,
        Color = Color or COLORS.Accent,
        Thickness = Thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    })
    return stroke
end

local function CreateGradient(Object, Colors, Rotation)
    local gradient = Create("UIGradient", {
        Parent = Object,
        Color = ColorSequence.new(Colors),
        Rotation = Rotation or 0
    })
    return gradient
end

local function CreateShadow(Object)
    local shadow = Create("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.8,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        ZIndex = 0,
        Parent = Object
    })
    return shadow
end

function ViperUI.new(Config)
    Config = Config or {}
    
    local self = setmetatable({}, ViperUI)
    
    self.Theme = Config.Theme or "Dark Green"
    self.Transparency = Config.Transparency or 0.1
    self.AnimationSpeed = Config.AnimationSpeed or 0.3
    self.EnableBlur = Config.EnableBlur or false
    self.EnableSounds = Config.EnableSounds or false
    self.Keybinds = Config.Keybinds or {Toggle = Enum.KeyCode.RightShift}
    self.ShowLoadingScreen = Config.ShowLoadingScreen or true
    self.Logo = Config.Logo or nil
    
    self.Windows = {}
    self.Notifications = {}
    self.Elements = {}
    self.Connections = {}
    
    local loadingScreen
    if self.ShowLoadingScreen then
        loadingScreen = self:CreateLoadingScreen({
            Title = "ViperUI",
            Subtitle = "Initializing...",
            ShowProgress = true,
            Logo = self.Logo
        })
    end
    
    if loadingScreen then
        local loadingSteps = {
            {10, "Loading core modules..."},
            {30, "Setting up UI framework..."},
            {50, "Initializing components..."},
            {70, "Creating windows..."},
            {90, "Finalizing setup..."},
            {100, "Ready!"}
        }
        
        for _, step in ipairs(loadingSteps) do
            loadingScreen:SetProgress(step[1], step[2])
            task.wait(0.3)
        end
        
        task.wait(0.5)
        loadingScreen:Hide()
    end
    
    self:SetupCoreGui()
    self:SetupInputListeners()
    
    return self
end

function ViperUI:SetupCoreGui()
    self.ScreenGui = Create("ScreenGui", {
        Name = "ViperUI",
        DisplayOrder = 10,
        Parent = CoreGui
    })
    
    self.NotificationHolder = Create("Frame", {
        Name = "NotificationHolder",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -400, 0, 20),
        Size = UDim2.new(0, 380, 1, -40),
        Parent = self.ScreenGui
    })
    
    Create("UIListLayout", {
        Parent = self.NotificationHolder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })
end

function ViperUI:SetupInputListeners()
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == self.Keybinds.Toggle then
            self:ToggleUI()
        end
    end))
end

function ViperUI:ToggleUI()
    local visible = self.ScreenGui.Enabled
    self.ScreenGui.Enabled = not visible
    
    for _, window in pairs(self.Windows) do
        if not visible then
            window:Show()
        else
            window:Hide()
        end
    end
end

local Window = {}
Window.__index = Window

function Window.new(Library, Title, Config)
    Config = Config or {}
    
    local self = setmetatable({}, Window)
    
    self.Library = Library
    self.Title = Title or "ViperUI Window"
    self.Size = Config.Size or DEFAULT_WINDOW_SIZE
    self.Position = Config.Position or UDim2.new(0.5, -self.Size.X/2, 0.5, -self.Size.Y/2)
    self.MinSize = Config.MinSize or MIN_WINDOW_SIZE
    self.MaxSize = Config.MaxSize or MAX_WINDOW_SIZE
    self.Theme = Config.Theme or Library.Theme
    self.Transparency = Config.Transparency or Library.Transparency
    self.AcceptKeybinds = Config.AcceptKeybinds or true
    
    self.LogoImage = Config.Logo or nil
    self.LogoSize = Config.LogoSize or 30
    self.LogoColor = Config.LogoColor or nil
    self.LogoCornerRadius = Config.LogoCornerRadius or 6
    
    self.Tabs = {}
    self.Elements = {}
    self.Open = false
    
    self:CreateWindow()
    
    if self.LogoImage then
        self:SetLogo(self.LogoImage, self.LogoSize)
        if self.LogoColor then
            self:SetLogoColor(self.LogoColor)
        end
        self:SetLogoCornerRadius(self.LogoCornerRadius)
    end
    
    return self
end

function Window:CreateWindow()
    self.MainFrame = Create("Frame", {
        Name = "MainWindow",
        BackgroundColor3 = COLORS.Background,
        BackgroundTransparency = self.Transparency,
        BorderSizePixel = 0,
        Position = self.Position,
        Size = UDim2.new(0, self.Size.X, 0, self.Size.Y),
        Parent = self.Library.ScreenGui
    })
    
    RoundCorners(self.MainFrame, 12)
    CreateStroke(self.MainFrame, COLORS.Primary, 2)
    CreateShadow(self.MainFrame)
    
    self.TitleBar = Create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = COLORS.Primary,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = self.MainFrame
    })
    
    RoundCorners(self.TitleBar, 12)
    
    self.LogoContainer = Create("Frame", {
        Name = "LogoContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(0, 30, 0, 30),
        Parent = self.TitleBar
    })
    
    self.Logo = Create("ImageLabel", {
        Name = "Logo",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Image = "rbxassetid://0",
        ScaleType = Enum.ScaleType.Fit,
        Visible = false,
        Parent = self.LogoContainer
    })
    
    RoundCorners(self.Logo, 6)
    
    self.TitleLabel = Create("TextLabel", {
        Name = "TitleLabel",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 45, 0, 0),
        Size = UDim2.new(0.5, -45, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Title,
        TextColor3 = COLORS.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })
    
    self.CloseButton = Create("TextButton", {
        Name = "CloseButton",
        BackgroundColor3 = COLORS.Error,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -35, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "X",
        TextColor3 = COLORS.Text,
        TextSize = 14,
        Parent = self.TitleBar
    })
    
    RoundCorners(self.CloseButton, 6)
    
    self.MinimizeButton = Create("TextButton", {
        Name = "MinimizeButton",
        BackgroundColor3 = COLORS.Warning,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -65, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "_",
        TextColor3 = COLORS.Text,
        TextSize = 14,
        Parent = self.TitleBar
    })
    
    RoundCorners(self.MinimizeButton, 6)
    
    self.Sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 150, 1, -40),
        Parent = self.MainFrame
    })
    
    self.TabContainer = Create("Frame", {
        Name = "TabContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self.Sidebar
    })
    
    self.TabListLayout = Create("UIListLayout", {
        Parent = self.TabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })
    
    self.ContentContainer = Create("Frame", {
        Name = "ContentContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 160, 0, 40),
        Size = UDim2.new(1, -160, 1, -40),
        Parent = self.MainFrame
    })
    
    self:SetupInteractions()
end

function Window:SetLogo(ImageId, Size)
    if ImageId then
        self.Logo.Image = "rbxassetid://" .. tostring(ImageId)
        self.Logo.Visible = true
        
        if Size then
            self.Logo.Size = UDim2.new(0, Size, 0, Size)
            self.LogoContainer.Size = UDim2.new(0, Size, 0, Size)
            self.Logo.Position = UDim2.new(0, 0, 0, 0)
            self.TitleLabel.Position = UDim2.new(0, Size + 15, 0, 0)
            self.TitleLabel.Size = UDim2.new(0.5, -(Size + 15), 1, 0)
        end
    else
        self.Logo.Visible = false
        self.TitleLabel.Position = UDim2.new(0, 15, 0, 0)
        self.TitleLabel.Size = UDim2.new(0.5, -15, 1, 0)
    end
end

function Window:SetLogoColor(Color)
    if self.Logo then
        self.Logo.ImageColor3 = Color or COLORS.Text
    end
end

function Window:SetLogoCornerRadius(Radius)
    if self.Logo then
        RoundCorners(self.Logo, Radius or 6)
    end
end

function Window:SetLogoStroke(Color, Thickness)
    if self.Logo then
        for _, child in pairs(self.Logo:GetChildren()) do
            if child:IsA("UIStroke") then
                child:Destroy()
            end
        end
        
        if Color then
            CreateStroke(self.Logo, Color, Thickness or 1)
        end
    end
end

function Window:SetupInteractions()
    local dragging = false
    local dragInput, dragStart, startPos
    
    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    self.TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X,
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    self.CloseButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end)
    
    self.MinimizeButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
end

function Window:Toggle()
    self.Open = not self.Open
    if self.Open then
        self:Show()
    else
        self:Hide()
    end
end

function Window:Show()
    self.MainFrame.Visible = true
    Tween(self.MainFrame, {Size = UDim2.new(0, self.Size.X, 0, self.Size.Y)}, 0.3, ANIMATION_PRESETS.EaseInOut)
end

function Window:Hide()
    Tween(self.MainFrame, {Size = UDim2.new(0, self.Size.X, 0, 40)}, 0.3, ANIMATION_PRESETS.EaseInOut)
    task.wait(0.3)
    self.MainFrame.Visible = false
end

function Window:Destroy()
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    self.MainFrame:Destroy()
end

local Tab = {}
Tab.__index = Tab

function Tab.new(Window, Title, Icon)
    local self = setmetatable({}, Tab)
    
    self.Window = Window
    self.Title = Title or "New Tab"
    self.Icon = Icon or ""
    self.Sections = {}
    self.Active = false
    
    self:CreateTab()
    
    return self
end

function Tab:CreateTab()
    self.TabButton = Create("TextButton", {
        Name = "TabButton",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -10, 0, 40),
        Font = Enum.Font.Gotham,
        Text = self.Title,
        TextColor3 = COLORS.SubText,
        TextSize = 14,
        Parent = self.Window.TabContainer
    })
    
    RoundCorners(self.TabButton, 8)
    
    self.TabContent = Create("ScrollingFrame", {
        Name = "TabContent",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.Primary,
        Visible = false,
        Parent = self.Window.ContentContainer
    })
    
    self.ContentLayout = Create("UIListLayout", {
        Parent = self.TabContent,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })
    
    self.ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.TabContent.CanvasSize = UDim2.new(0, 0, 0, self.ContentLayout.AbsoluteContentSize.Y + 10)
    end)
    
    self:SetupInteractions()
end

function Tab:SetupInteractions()
    self.TabButton.MouseButton1Click:Connect(function()
        self:Activate()
    end)
end

function Tab:Activate()
    for _, tab in pairs(self.Window.Tabs) do
        if tab ~= self then
            tab:Deactivate()
        end
    end
    
    self.Active = true
    Tween(self.TabButton, {BackgroundColor3 = COLORS.Primary, TextColor3 = COLORS.Text}, 0.2)
    
    if self.Window.CurrentTab then
        Tween(self.Window.CurrentTab.TabContent, {Position = UDim2.new(1, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        self.Window.CurrentTab.TabContent.Visible = false
    end
    
    self.TabContent.Visible = true
    self.TabContent.Position = UDim2.new(-1, 0, 0, 0)
    Tween(self.TabContent, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
    
    self.Window.CurrentTab = self
end

function Tab:Deactivate()
    self.Active = false
    Tween(self.TabButton, {BackgroundColor3 = COLORS.Surface, TextColor3 = COLORS.SubText}, 0.2)
end

local Section = {}
Section.__index = Section

function Section.new(Tab, Title, Side)
    local self = setmetatable({}, Section)
    
    self.Tab = Tab
    self.Title = Title or "Section"
    self.Side = Side or "Left"
    self.Elements = {}
    
    self:CreateSection()
    
    return self
end

function Section:CreateSection()
    self.SectionFrame = Create("Frame", {
        Name = "Section",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, 0),
        Parent = self.Tab.TabContent
    })
    
    RoundCorners(self.SectionFrame, 8)
    CreateStroke(self.SectionFrame, COLORS.Primary, 1)
    
    self.TitleLabel = Create("TextLabel", {
        Name = "TitleLabel",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -30, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = self.Title:upper(),
        TextColor3 = COLORS.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.SectionFrame
    })
    
    self.ContentContainer = Create("Frame", {
        Name = "ContentContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 35),
        Size = UDim2.new(1, 0, 1, -35),
        Parent = self.SectionFrame
    })
    
    self.ContentLayout = Create("UIListLayout", {
        Parent = self.ContentContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })
    
    self.ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.SectionFrame.Size = UDim2.new(1, -20, 0, self.ContentLayout.AbsoluteContentSize.Y + 45)
    end)
end

function Section:AddButton(Config)
    Config = Config or {}
    
    local Button = {}
    
    Button.Name = Config.Name or "Button"
    Button.Callback = Config.Callback or function() end
    
    Button.Main = Create("TextButton", {
        Name = "Button",
        BackgroundColor3 = COLORS.Primary,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, 35),
        Font = Enum.Font.Gotham,
        Text = "",
        AutoButtonColor = false,
        Parent = self.ContentContainer
    })
    
    RoundCorners(Button.Main, 6)
    CreateStroke(Button.Main, COLORS.Accent, 1)
    
    Button.Label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = Button.Name,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        Parent = Button.Main
    })
    
    Button.Main.MouseEnter:Connect(function()
        Tween(Button.Main, {BackgroundTransparency = 0.6}, 0.2)
    end)
    
    Button.Main.MouseLeave:Connect(function()
        Tween(Button.Main, {BackgroundTransparency = 0.8}, 0.2)
    end)
    
    Button.Main.MouseButton1Click:Connect(function()
        Tween(Button.Main, {BackgroundColor3 = COLORS.Accent}, 0.1)
        task.wait(0.1)
        Tween(Button.Main, {BackgroundColor3 = COLORS.Primary}, 0.1)
        Button.Callback()
    end)
    
    table.insert(self.Elements, Button)
    return Button
end

function Section:AddToggle(Config)
    Config = Config or {}
    
    local Toggle = {}
    Toggle.Value = Config.Default or false
    Toggle.Name = Config.Name or "Toggle"
    Toggle.Callback = Config.Callback or function() end
    
    Toggle.Main = Create("Frame", {
        Name = "Toggle",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Parent = self.ContentContainer
    })
    
    Toggle.Label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.7, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = Toggle.Name,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Toggle.Main
    })
    
    Toggle.Background = Create("Frame", {
        Name = "Background",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.8,
        Position = UDim2.new(1, -50, 0.5, -10),
        Size = UDim2.new(0, 50, 0, 20),
        Parent = Toggle.Main
    })
    
    RoundCorners(Toggle.Background, 10)
    CreateStroke(Toggle.Background, COLORS.Primary, 1)
    
    Toggle.Button = Create("Frame", {
        Name = "Button",
        BackgroundColor3 = COLORS.Primary,
        Position = UDim2.new(0, 2, 0, 2),
        Size = UDim2.new(0, 16, 0, 16),
        Parent = Toggle.Background
    })
    
    RoundCorners(Toggle.Button, 8)
    
    local function UpdateToggle()
        if Toggle.Value then
            Tween(Toggle.Button, {Position = UDim2.new(1, -18, 0, 2), BackgroundColor3 = COLORS.Accent}, 0.2)
            Tween(Toggle.Background, {BackgroundColor3 = COLORS.Success}, 0.2)
        else
            Tween(Toggle.Button, {Position = UDim2.new(0, 2, 0, 2), BackgroundColor3 = COLORS.Primary}, 0.2)
            Tween(Toggle.Background, {BackgroundColor3 = COLORS.Surface}, 0.2)
        end
    end
    
    Toggle.Background.MouseButton1Click:Connect(function()
        Toggle.Value = not Toggle.Value
        UpdateToggle()
        Toggle.Callback(Toggle.Value)
    end)
    
    UpdateToggle()
    
    table.insert(self.Elements, Toggle)
    return Toggle
end

function Section:AddSlider(Config)
    Config = Config or {}
    
    local Slider = {}
    Slider.Value = Config.Default or Config.Min or 0
    Slider.Min = Config.Min or 0
    Slider.Max = Config.Max or 100
    Slider.Name = Config.Name or "Slider"
    Slider.Callback = Config.Callback or function() end
    Slider.Precision = Config.Precision or 1
    
    Slider.Main = Create("Frame", {
        Name = "Slider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 50),
        Parent = self.ContentContainer
    })
    
    Slider.Label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.Gotham,
        Text = Slider.Name,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Slider.Main
    })
    
    Slider.ValueLabel = Create("TextLabel", {
        Name = "ValueLabel",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.Gotham,
        Text = tostring(Slider.Value),
        TextColor3 = COLORS.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Slider.Main
    })
    
    Slider.Track = Create("Frame", {
        Name = "Track",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.8,
        Position = UDim2.new(0, 0, 0, 25),
        Size = UDim2.new(1, 0, 0, 10),
        Parent = Slider.Main
    })
    
    RoundCorners(Slider.Track, 5)
    CreateStroke(Slider.Track, COLORS.Primary, 1)
    
    Slider.Fill = Create("Frame", {
        Name = "Fill",
        BackgroundColor3 = COLORS.Accent,
        Size = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0),
        Parent = Slider.Track
    })
    
    RoundCorners(Slider.Fill, 5)
    
    Slider.Button = Create("TextButton", {
        Name = "Button",
        BackgroundColor3 = COLORS.Text,
        Position = UDim2.new((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), -8, 0, -3),
        Size = UDim2.new(0, 16, 0, 16),
        Text = "",
        AutoButtonColor = false,
        Parent = Slider.Track
    })
    
    RoundCorners(Slider.Button, 8)
    CreateStroke(Slider.Button, COLORS.Primary, 1)
    
    local dragging = false
    
    local function UpdateSlider(value)
        value = math.clamp(value, Slider.Min, Slider.Max)
        value = math.floor(value / Slider.Precision) * Slider.Precision
        
        Slider.Value = value
        Slider.ValueLabel.Text = tostring(value)
        
        local ratio = (value - Slider.Min) / (Slider.Max - Slider.Min)
        Tween(Slider.Fill, {Size = UDim2.new(ratio, 0, 1, 0)}, 0.2)
        Tween(Slider.Button, {Position = UDim2.new(ratio, -8, 0, -3)}, 0.2)
        
        Slider.Callback(value)
    end
    
    Slider.Button.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    Slider.Track.MouseButton1Down:Connect(function(x, y)
        dragging = true
        local relativeX = x - Slider.Track.AbsolutePosition.X
        local ratio = math.clamp(relativeX / Slider.Track.AbsoluteSize.X, 0, 1)
        UpdateSlider(Slider.Min + ratio * (Slider.Max - Slider.Min))
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = input.Position.X - Slider.Track.AbsolutePosition.X
            local ratio = math.clamp(relativeX / Slider.Track.AbsoluteSize.X, 0, 1)
            UpdateSlider(Slider.Min + ratio * (Slider.Max - Slider.Min))
        end
    end)
    
    table.insert(self.Elements, Slider)
    return Slider
end

function Section:AddDropdown(Config)
    Config = Config or {}
    
    local Dropdown = {}
    Dropdown.Options = Config.Options or {}
    Dropdown.Value = Config.Default or Dropdown.Options[1]
    Dropdown.Name = Config.Name or "Dropdown"
    Dropdown.Callback = Config.Callback or function() end
    Dropdown.Open = false
    
    Dropdown.Main = Create("Frame", {
        Name = "Dropdown",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Parent = self.ContentContainer
    })
    
    Dropdown.Label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.7, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = Dropdown.Name,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Dropdown.Main
    })
    
    Dropdown.Button = Create("TextButton", {
        Name = "Button",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.8,
        Position = UDim2.new(1, -100, 0, 0),
        Size = UDim2.new(0, 100, 1, 0),
        Font = Enum.Font.Gotham,
        Text = Dropdown.Value or "Select...",
        TextColor3 = COLORS.Text,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = Dropdown.Main
    })
    
    RoundCorners(Dropdown.Button, 6)
    CreateStroke(Dropdown.Button, COLORS.Primary, 1)
    
    Dropdown.List = Create("ScrollingFrame", {
        Name = "List",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 5),
        Size = UDim2.new(1, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.Primary,
        Visible = false,
        Parent = Dropdown.Main
    })
    
    RoundCorners(Dropdown.List, 6)
    CreateStroke(Dropdown.List, COLORS.Primary, 1)
    
    Dropdown.ListLayout = Create("UIListLayout", {
        Parent = Dropdown.List,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    Dropdown.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Dropdown.List.CanvasSize = UDim2.new(0, 0, 0, Dropdown.ListLayout.AbsoluteContentSize.Y)
    end)
    
    local function CreateOptions()
        for _, option in pairs(Dropdown.Options) do
            local optionButton = Create("TextButton", {
                Name = option,
                BackgroundColor3 = COLORS.Surface,
                BackgroundTransparency = 0.9,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -10, 0, 25),
                Font = Enum.Font.Gotham,
                Text = option,
                TextColor3 = COLORS.Text,
                TextSize = 12,
                AutoButtonColor = false,
                Parent = Dropdown.List
            })
            
            RoundCorners(optionButton, 4)
            
            optionButton.MouseEnter:Connect(function()
                Tween(optionButton, {BackgroundTransparency = 0.7}, 0.2)
            end)
            
            optionButton.MouseLeave:Connect(function()
                Tween(optionButton, {BackgroundTransparency = 0.9}, 0.2)
            end)
            
            optionButton.MouseButton1Click:Connect(function()
                Dropdown.Value = option
                Dropdown.Button.Text = option
                Dropdown.Callback(option)
                Dropdown:Toggle()
            end)
        end
    end
    
    CreateOptions()
    
    function Dropdown:Toggle()
        self.Open = not self.Open
        
        if self.Open then
            self.List.Visible = true
            Tween(self.List, {Size = UDim2.new(1, 0, 0, math.min(#self.Options * 30, 150))}, 0.3)
        else
            Tween(self.List, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
            task.wait(0.3)
            self.List.Visible = false
        end
    end
    
    Dropdown.Button.MouseButton1Click:Connect(function()
        Dropdown:Toggle()
    end)
    
    local connection
    connection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and Dropdown.Open then
            local absolutePosition = Dropdown.List.AbsolutePosition
            local absoluteSize = Dropdown.List.AbsoluteSize
            
            if not (input.Position.X >= absolutePosition.X and input.Position.X <= absolutePosition.X + absoluteSize.X and
                   input.Position.Y >= absolutePosition.Y and input.Position.Y <= absolutePosition.Y + absoluteSize.Y) then
                Dropdown:Toggle()
            end
        end
    end)
    
    table.insert(self.Elements, Dropdown)
    return Dropdown
end

function Section:AddTextbox(Config)
    Config = Config or {}
    
    local Textbox = {}
    Textbox.Placeholder = Config.Placeholder or "Enter text..."
    Textbox.Name = Config.Name or "Textbox"
    Textbox.Callback = Config.Callback or function() end
    Textbox.ClearOnFocus = Config.ClearOnFocus or false
    
    Textbox.Main = Create("Frame", {
        Name = "Textbox",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 50),
        Parent = self.ContentContainer
    })
    
    Textbox.Label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.Gotham,
        Text = Textbox.Name,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Textbox.Main
    })
    
    Textbox.Input = Create("TextBox", {
        Name = "Input",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.8,
        Position = UDim2.new(0, 0, 0, 25),
        Size = UDim2.new(1, 0, 0, 25),
        Font = Enum.Font.Gotham,
        Text = "",
        PlaceholderText = Textbox.Placeholder,
        TextColor3 = COLORS.Text,
        PlaceholderColor3 = COLORS.SubText,
        TextSize = 14,
        ClearTextOnFocus = Textbox.ClearOnFocus,
        Parent = Textbox.Main
    })
    
    RoundCorners(Textbox.Input, 6)
    CreateStroke(Textbox.Input, COLORS.Primary, 1)
    
    Textbox.Input.Focused:Connect(function()
        Tween(Textbox.Input, {BackgroundTransparency = 0.6}, 0.2)
    end)
    
    Textbox.Input.FocusLost:Connect(function()
        Tween(Textbox.Input, {BackgroundTransparency = 0.8}, 0.2)
        Textbox.Callback(Textbox.Input.Text)
    end)
    
    table.insert(self.Elements, Textbox)
    return Textbox
end

function Section:AddKeybind(Config)
    Config = Config or {}
    
    local Keybind = {}
    Keybind.Value = Config.Default or Enum.KeyCode.Unknown
    Keybind.Name = Config.Name or "Keybind"
    Keybind.Callback = Config.Callback or function() end
    Keybind.Listening = false
    
    Keybind.Main = Create("Frame", {
        Name = "Keybind",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Parent = self.ContentContainer
    })
    
    Keybind.Label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.7, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = Keybind.Name,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Keybind.Main
    })
    
    Keybind.Button = Create("TextButton", {
        Name = "Button",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.8,
        Position = UDim2.new(1, -100, 0, 0),
        Size = UDim2.new(0, 100, 1, 0),
        Font = Enum.Font.Gotham,
        Text = Keybind.Value.Name,
        TextColor3 = COLORS.Text,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = Keybind.Main
    })
    
    RoundCorners(Keybind.Button, 6)
    CreateStroke(Keybind.Button, COLORS.Primary, 1)
    
    Keybind.Button.MouseButton1Click:Connect(function()
        Keybind.Listening = true
        Keybind.Button.Text = "..."
        Tween(Keybind.Button, {BackgroundColor3 = COLORS.Accent}, 0.2)
    end)
    
    local connection
    connection = UserInputService.InputBegan:Connect(function(input)
        if Keybind.Listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Keybind.Value = input.KeyCode
                Keybind.Button.Text = input.KeyCode.Name
                Keybind.Listening = false
                Tween(Keybind.Button, {BackgroundColor3 = COLORS.Surface}, 0.2)
                Keybind.Callback(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                Keybind.Value = Enum.KeyCode.Unknown
                Keybind.Button.Text = "Unknown"
                Keybind.Listening = false
                Tween(Keybind.Button, {BackgroundColor3 = COLORS.Surface}, 0.2)
            end
        end
    end)
    
    table.insert(self.Elements, Keybind)
    return Keybind
end

function Section:AddLabel(Config)
    Config = Config or {}
    
    local Label = {}
    Label.Text = Config.Text or "Label"
    Label.Color = Config.Color or COLORS.Text
    
    Label.Main = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 25),
        Font = Enum.Font.Gotham,
        Text = Label.Text,
        TextColor3 = Label.Color,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.ContentContainer
    })
    
    table.insert(self.Elements, Label)
    return Label
end

function Section:AddMultiDropdown(Config)
    Config = Config or {}
    
    local MultiDropdown = {}
    MultiDropdown.Options = Config.Options or {}
    MultiDropdown.Values = Config.Default or {}
    MultiDropdown.Name = Config.Name or "Multi Dropdown"
    MultiDropdown.Callback = Config.Callback or function() end
    MultiDropdown.Open = false
    MultiDropdown.MaxDisplay = Config.MaxDisplay or 3
    
    MultiDropdown.Main = Create("Frame", {
        Name = "MultiDropdown",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Parent = self.ContentContainer
    })
    
    MultiDropdown.Label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.7, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = MultiDropdown.Name,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = MultiDropdown.Main
    })
    
    MultiDropdown.Button = Create("TextButton", {
        Name = "Button",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.8,
        Position = UDim2.new(1, -100, 0, 0),
        Size = UDim2.new(0, 100, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "",
        TextColor3 = COLORS.Text,
        TextSize = 10,
        TextWrapped = true,
        AutoButtonColor = false,
        Parent = MultiDropdown.Main
    })
    
    RoundCorners(MultiDropdown.Button, 6)
    CreateStroke(MultiDropdown.Button, COLORS.Primary, 1)
    
    MultiDropdown.List = Create("ScrollingFrame", {
        Name = "List",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 5),
        Size = UDim2.new(1, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.Primary,
        Visible = false,
        Parent = MultiDropdown.Main
    })
    
    RoundCorners(MultiDropdown.List, 6)
    CreateStroke(MultiDropdown.List, COLORS.Primary, 1)
    
    MultiDropdown.ListLayout = Create("UIListLayout", {
        Parent = MultiDropdown.List,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    MultiDropdown.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        MultiDropdown.List.CanvasSize = UDim2.new(0, 0, 0, MultiDropdown.ListLayout.AbsoluteContentSize.Y)
    end)
    
    MultiDropdown.SearchBox = Create("TextBox", {
        Name = "SearchBox",
        BackgroundColor3 = COLORS.Background,
        BackgroundTransparency = 0.7,
        Position = UDim2.new(0, 5, 0, 5),
        Size = UDim2.new(1, -10, 0, 25),
        Font = Enum.Font.Gotham,
        Text = "",
        PlaceholderText = "Search...",
        TextColor3 = COLORS.Text,
        PlaceholderColor3 = COLORS.SubText,
        TextSize = 12,
        Parent = MultiDropdown.List
    })
    
    RoundCorners(MultiDropdown.SearchBox, 4)
    
    MultiDropdown.OptionsContainer = Create("Frame", {
        Name = "OptionsContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 35),
        Size = UDim2.new(1, 0, 1, -35),
        Parent = MultiDropdown.List
    })
    
    MultiDropdown.OptionsLayout = Create("UIListLayout", {
        Parent = MultiDropdown.OptionsContainer,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    function MultiDropdown:UpdateDisplayText()
        local selectedCount = 0
        local displayText = ""
        
        for option, selected in pairs(self.Values) do
            if selected then
                selectedCount = selectedCount + 1
                if selectedCount <= self.MaxDisplay then
                    if displayText ~= "" then
                        displayText = displayText .. ", "
                    end
                    displayText = displayText .. option
                end
            end
        end
        
        if selectedCount == 0 then
            displayText = "Select..."
        elseif selectedCount > self.MaxDisplay then
            displayText = displayText .. " +" .. (selectedCount - self.MaxDisplay) .. " more"
        end
        
        self.Button.Text = displayText
    end
    
    function MultiDropdown:CreateOptions()
        for _, child in pairs(self.OptionsContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local searchText = string.lower(self.SearchBox.Text)
        
        for _, option in pairs(self.Options) do
            if string.lower(option):find(searchText) or searchText == "" then
                local optionButton = Create("TextButton", {
                    Name = option,
                    BackgroundColor3 = self.Values[option] and COLORS.Primary or COLORS.Surface,
                    BackgroundTransparency = self.Values[option] and 0.6 or 0.9,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -10, 0, 25),
                    Font = Enum.Font.Gotham,
                    Text = option,
                    TextColor3 = COLORS.Text,
                    TextSize = 12,
                    AutoButtonColor = false,
                    Parent = self.OptionsContainer
                })
                
                RoundCorners(optionButton, 4)
                
                if self.Values[option] then
                    Create("TextLabel", {
                        Name = "Checkmark",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -20, 0, 0),
                        Size = UDim2.new(0, 20, 1, 0),
                        Font = Enum.Font.GothamBold,
                        Text = "✓",
                        TextColor3 = COLORS.Success,
                        TextSize = 12,
                        Parent = optionButton
                    })
                end
                
                optionButton.MouseEnter:Connect(function()
                    Tween(optionButton, {BackgroundTransparency = 0.7}, 0.2)
                end)
                
                optionButton.MouseLeave:Connect(function()
                    if not self.Values[option] then
                        Tween(optionButton, {BackgroundTransparency = 0.9}, 0.2)
                    else
                        Tween(optionButton, {BackgroundTransparency = 0.6}, 0.2)
                    end
                end)
                
                optionButton.MouseButton1Click:Connect(function()
                    self.Values[option] = not self.Values[option]
                    self:UpdateOptions()
                    self.Callback(self.Values)
                end)
            end
        end
    end
    
    function MultiDropdown:UpdateOptions()
        self:CreateOptions()
        self:UpdateDisplayText()
    end
    
    MultiDropdown.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        MultiDropdown:CreateOptions()
    end)
    
    local ClearButton = Create("TextButton", {
        Name = "ClearButton",
        BackgroundColor3 = COLORS.Error,
        BackgroundTransparency = 0.8,
        Position = UDim2.new(0, 5, 1, -30),
        Size = UDim2.new(1, -10, 0, 25),
        Font = Enum.Font.Gotham,
        Text = "Clear All",
        TextColor3 = COLORS.Text,
        TextSize = 12,
        Parent = MultiDropdown.List
    })
    
    RoundCorners(ClearButton, 4)
    
    ClearButton.MouseButton1Click:Connect(function()
        MultiDropdown.Values = {}
        MultiDropdown:UpdateOptions()
        MultiDropdown.Callback(MultiDropdown.Values)
    end)
    
    function MultiDropdown:Toggle()
        self.Open = not self.Open
        
        if self.Open then
            self.List.Visible = true
            Tween(self.List, {Size = UDim2.new(1, 0, 0, math.min(#self.Options * 30 + 70, 250))}, 0.3)
            self.SearchBox:CaptureFocus()
        else
            Tween(self.List, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
            task.wait(0.3)
            self.List.Visible = false
        end
    end
    
    MultiDropdown.Button.MouseButton1Click:Connect(function()
        MultiDropdown:Toggle()
    end)
    
    MultiDropdown:UpdateOptions()
    
    local connection
    connection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and MultiDropdown.Open then
            local absolutePosition = MultiDropdown.List.AbsolutePosition
            local absoluteSize = MultiDropdown.List.AbsoluteSize
            
            if not (input.Position.X >= absolutePosition.X and input.Position.X <= absolutePosition.X + absoluteSize.X and
                   input.Position.Y >= absolutePosition.Y and input.Position.Y <= absolutePosition.Y + absoluteSize.Y) then
                MultiDropdown:Toggle()
            end
        end
    end)
    
    table.insert(self.Elements, MultiDropdown)
    return MultiDropdown
end

function Section:AddProgressBar(Config)
    Config = Config or {}
    
    local ProgressBar = {}
    ProgressBar.Value = Config.Value or 0
    ProgressBar.Min = Config.Min or 0
    ProgressBar.Max = Config.Max or 100
    ProgressBar.Name = Config.Name or "Progress Bar"
    ProgressBar.ShowText = Config.ShowText or true
    ProgressBar.Animated = Config.Animated or true
    ProgressBar.Color = Config.Color or COLORS.Accent
    ProgressBar.Callback = Config.Callback or function() end
    
    ProgressBar.Main = Create("Frame", {
        Name = "ProgressBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 40),
        Parent = self.ContentContainer
    })
    
    ProgressBar.Label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.Gotham,
        Text = ProgressBar.Name,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ProgressBar.Main
    })
    
    ProgressBar.Track = Create("Frame", {
        Name = "Track",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.8,
        Position = UDim2.new(0, 0, 0, 25),
        Size = UDim2.new(1, 0, 0, 15),
        Parent = ProgressBar.Main
    })
    
    RoundCorners(ProgressBar.Track, 8)
    CreateStroke(ProgressBar.Track, COLORS.Primary, 1)
    
    ProgressBar.Fill = Create("Frame", {
        Name = "Fill",
        BackgroundColor3 = ProgressBar.Color,
        Size = UDim2.new((ProgressBar.Value - ProgressBar.Min) / (ProgressBar.Max - ProgressBar.Min), 0, 1, 0),
        Parent = ProgressBar.Track
    })
    
    RoundCorners(ProgressBar.Fill, 8)
    
    ProgressBar.Text = Create("TextLabel", {
        Name = "Text",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 25),
        Size = UDim2.new(1, 0, 0, 15),
        Font = Enum.Font.GothamBold,
        Text = string.format("%d / %d (%.1f%%)", ProgressBar.Value, ProgressBar.Max, (ProgressBar.Value / ProgressBar.Max) * 100),
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Visible = ProgressBar.ShowText,
        Parent = ProgressBar.Main
    })
    
    local gradient = CreateGradient(ProgressBar.Fill, {
        ProgressBar.Color,
        Color3.new(
            math.clamp(ProgressBar.Color.R * 1.3, 0, 1),
            math.clamp(ProgressBar.Color.G * 1.3, 0, 1),
            math.clamp(ProgressBar.Color.B * 1.3, 0, 1)
        )
    }, 90)
    
    function ProgressBar:SetValue(Value)
        self.Value = math.clamp(Value, self.Min, self.Max)
        
        local targetSize = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0)
        
        if self.Animated then
            Tween(self.Fill, {Size = targetSize}, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        else
            self.Fill.Size = targetSize
        end
        
        if self.ShowText then
            self.Text.Text = string.format("%d / %d (%.1f%%)", self.Value, self.Max, (self.Value / self.Max) * 100)
        end
        
        self.Callback(self.Value)
    end
    
    function ProgressBar:SetColor(Color)
        self.Color = Color
        self.Fill.BackgroundColor3 = Color
        
        gradient.Color = ColorSequence.new({
            Color,
            Color3.new(
                math.clamp(Color.R * 1.3, 0, 1),
                math.clamp(Color.G * 1.3, 0, 1),
                math.clamp(Color.B * 1.3, 0, 1)
            )
        })
    end
    
    function ProgressBar:SetTextVisible(Visible)
        self.ShowText = Visible
        self.Text.Visible = Visible
    end
    
    ProgressBar:SetValue(ProgressBar.Value)
    
    table.insert(self.Elements, ProgressBar)
    return ProgressBar
end

function Section:AddLoadingSpinner(Config)
    Config = Config or {}
    
    local LoadingSpinner = {}
    LoadingSpinner.Size = Config.Size or 30
    LoadingSpinner.Speed = Config.Speed or 1
    LoadingSpinner.Color = Config.Color or COLORS.Accent
    LoadingSpinner.Name = Config.Name or "Loading..."
    LoadingSpinner.Running = Config.Running or true
    
    LoadingSpinner.Main = Create("Frame", {
        Name = "LoadingSpinner",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 40),
        Parent = self.ContentContainer
    })
    
    LoadingSpinner.Label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.Gotham,
        Text = LoadingSpinner.Name,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = LoadingSpinner.Main
    })
    
    LoadingSpinner.SpinnerFrame = Create("Frame", {
        Name = "SpinnerFrame",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 25),
        Size = UDim2.new(1, 0, 0, LoadingSpinner.Size),
        Parent = LoadingSpinner.Main
    })
    
    local circleCount = 8
    local circles = {}
    
    for i = 1, circleCount do
        local circle = Create("Frame", {
            Name = "Circle" .. i,
            BackgroundColor3 = LoadingSpinner.Color,
            Size = UDim2.new(0, LoadingSpinner.Size / 3, 0, LoadingSpinner.Size / 3),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Parent = LoadingSpinner.SpinnerFrame
        })
        
        RoundCorners(circle, LoadingSpinner.Size / 6)
        
        local angle = (i - 1) * (2 * math.pi / circleCount)
        local radius = LoadingSpinner.Size / 2
        circle.Position = UDim2.new(
            0.5, math.cos(angle) * radius,
            0.5, math.sin(angle) * radius
        )
        
        circles[i] = circle
    end
    
    LoadingSpinner.AnimationConnection = nil
    
    function LoadingSpinner:Start()
        if self.AnimationConnection then
            self.AnimationConnection:Disconnect()
        end
        
        self.Running = true
        local startTime = tick()
        
        self.AnimationConnection = RunService.Heartbeat:Connect(function()
            if not self.Running then return end
            
            local time = (tick() - startTime) * self.Speed
            
            for i, circle in pairs(circles) do
                local angle = (i - 1) * (2 * math.pi / circleCount) + time * 2 * math.pi
                local radius = self.Size / 2
                
                circle.Position = UDim2.new(
                    0.5, math.cos(angle) * radius,
                    0.5, math.sin(angle) * radius
                )
                
                local alpha = (math.sin(angle + time * 8) + 1) / 2
                circle.BackgroundTransparency = 1 - alpha * 0.8
            end
        end)
    end
    
    function LoadingSpinner:Stop()
        self.Running = false
        if self.AnimationConnection then
            self.AnimationConnection:Disconnect()
            self.AnimationConnection = nil
        end
        
        for i, circle in pairs(circles) do
            local angle = (i - 1) * (2 * math.pi / circleCount)
            local radius = self.Size / 2
            circle.Position = UDim2.new(
                0.5, math.cos(angle) * radius,
                0.5, math.sin(angle) * radius
            )
            circle.BackgroundTransparency = 0.2
        end
    end
    
    function LoadingSpinner:SetVisible(Visible)
        self.Main.Visible = Visible
        if Visible and self.Running then
            self:Start()
        else
            self:Stop()
        end
    end
    
    function LoadingSpinner:SetColor(Color)
        self.Color = Color
        for _, circle in pairs(circles) do
            circle.BackgroundColor3 = Color
        end
    end
    
    if LoadingSpinner.Running then
        LoadingSpinner:Start()
    end
    
    table.insert(self.Elements, LoadingSpinner)
    return LoadingSpinner
end

function Window:CreateLoadingOverlay(Config)
    Config = Config or {}
    
    local LoadingOverlay = {}
    LoadingOverlay.Text = Config.Text or "Loading..."
    LoadingOverlay.Color = Config.Color or COLORS.Accent
    LoadingOverlay.Visible = false
    
    LoadingOverlay.Main = Create("Frame", {
        Name = "LoadingOverlay",
        BackgroundColor3 = COLORS.Background,
        BackgroundTransparency = 0.3,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        ZIndex = 100,
        Parent = self.MainFrame
    })
    
    LoadingOverlay.Container = Create("Frame", {
        Name = "Container",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(0, 200, 0, 120),
        Position = UDim2.new(0.5, -100, 0.5, -60),
        Parent = LoadingOverlay.Main
    })
    
    RoundCorners(LoadingOverlay.Container, 12)
    CreateStroke(LoadingOverlay.Container, COLORS.Primary, 2)
    
    LoadingOverlay.Spinner = Create("Frame", {
        Name = "Spinner",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0.5, -20, 0.3, -20),
        Parent = LoadingOverlay.Container
    })
    
    local spinnerCircle = Create("Frame", {
        Name = "SpinnerCircle",
        BackgroundColor3 = LoadingOverlay.Color,
        Size = UDim2.new(0, 8, 0, 8),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Parent = LoadingOverlay.Spinner
    })
    
    RoundCorners(spinnerCircle, 4)
    
    LoadingOverlay.TextLabel = Create("TextLabel", {
        Name = "TextLabel",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0.7, 0),
        Size = UDim2.new(1, 0, 0, 30),
        Font = Enum.Font.Gotham,
        Text = LoadingOverlay.Text,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        Parent = LoadingOverlay.Container
    })
    
    LoadingOverlay.AnimationConnection = nil
    LoadingOverlay.Rotation = 0
    
    function LoadingOverlay:Show(Text)
        if Text then
            self.Text = Text
            self.TextLabel.Text = Text
        end
        
        self.Visible = true
        self.Main.Visible = true
        self.Main.BackgroundTransparency = 0.8
        self.Container.Size = UDim2.new(0, 0, 0, 0)
        
        Tween(self.Main, {BackgroundTransparency = 0.3}, 0.3)
        Tween(self.Container, {Size = UDim2.new(0, 200, 0, 120)}, 0.5, Enum.EasingStyle.Back)
        
        self:StartAnimation()
    end
    
    function LoadingOverlay:Hide()
        self.Visible = false
        self:StopAnimation()
        
        Tween(self.Main, {BackgroundTransparency = 0.8}, 0.3)
        Tween(self.Container, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        
        task.wait(0.3)
        self.Main.Visible = false
    end
    
    function LoadingOverlay:StartAnimation()
        if self.AnimationConnection then
            self.AnimationConnection:Disconnect()
        end
        
        local startTime = tick()
        
        self.AnimationConnection = RunService.Heartbeat:Connect(function()
            if not self.Visible then return end
            
            local time = tick() - startTime
            self.Rotation = time * 360
            
            local radius = 15
            local angle = math.rad(self.Rotation)
            spinnerCircle.Position = UDim2.new(
                0.5, math.cos(angle) * radius,
                0.5, math.sin(angle) * radius
            )
            
            local scale = 0.8 + 0.2 * math.sin(time * 8)
            spinnerCircle.Size = UDim2.new(0, 8 * scale, 0, 8 * scale)
        end)
    end
    
    function LoadingOverlay:StopAnimation()
        if self.AnimationConnection then
            self.AnimationConnection:Disconnect()
            self.AnimationConnection = nil
        end
    end
    
    function LoadingOverlay:SetText(Text)
        self.Text = Text
        self.TextLabel.Text = Text
    end
    
    table.insert(self.Elements, LoadingOverlay)
    return LoadingOverlay
end

function ViperUI:CreateLoadingScreen(Config)
    Config = Config or {}
    
    local LoadingScreen = {}
    LoadingScreen.Title = Config.Title or "ViperUI"
    LoadingScreen.Subtitle = Config.Subtitle or "Loading..."
    LoadingScreen.ShowProgress = Config.ShowProgress or true
    LoadingScreen.Logo = Config.Logo or nil
    
    LoadingScreen.Main = Create("ScreenGui", {
        Name = "ViperUILoading",
        DisplayOrder = 999,
        Parent = CoreGui
    })
    
    LoadingScreen.Background = Create("Frame", {
        Name = "Background",
        BackgroundColor3 = COLORS.Background,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = LoadingScreen.Main
    })
    
    LoadingScreen.Container = Create("Frame", {
        Name = "Container",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(0, 400, 0, 200),
        Position = UDim2.new(0.5, -200, 0.5, -100),
        Parent = LoadingScreen.Background
    })
    
    RoundCorners(LoadingScreen.Container, 12)
    CreateStroke(LoadingScreen.Container, COLORS.Primary, 2)
    CreateShadow(LoadingScreen.Container)
    
    if LoadingScreen.Logo then
        LoadingScreen.LogoImage = Create("ImageLabel", {
            Name = "Logo",
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, -25, 0.1, -25),
            Size = UDim2.new(0, 50, 0, 50),
            Image = "rbxassetid://" .. tostring(LoadingScreen.Logo),
            ScaleType = Enum.ScaleType.Fit,
            Parent = LoadingScreen.Container
        })
        
        RoundCorners(LoadingScreen.LogoImage, 8)
        
        LoadingScreen.TitleLabel = Create("TextLabel", {
            Name = "Title",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0.35, 0),
            Size = UDim2.new(1, 0, 0, 40),
            Font = Enum.Font.GothamBold,
            Text = LoadingScreen.Title,
            TextColor3 = COLORS.Text,
            TextSize = 24,
            Parent = LoadingScreen.Container
        })
    else
        LoadingScreen.TitleLabel = Create("TextLabel", {
            Name = "Title",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0.1, 0),
            Size = UDim2.new(1, 0, 0, 40),
            Font = Enum.Font.GothamBold,
            Text = LoadingScreen.Title,
            TextColor3 = COLORS.Text,
            TextSize = 24,
            Parent = LoadingScreen.Container
        })
    end
    
    LoadingScreen.SubtitleLabel = Create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0.3, 0),
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.Gotham,
        Text = LoadingScreen.Subtitle,
        TextColor3 = COLORS.SubText,
        TextSize = 14,
        Parent = LoadingScreen.Container
    })
    
    if LoadingScreen.ShowProgress then
        LoadingScreen.ProgressTrack = Create("Frame", {
            Name = "ProgressTrack",
            BackgroundColor3 = COLORS.Surface,
            BackgroundTransparency = 0.8,
            Position = UDim2.new(0.1, 0, 0.6, 0),
            Size = UDim2.new(0.8, 0, 0, 20),
            Parent = LoadingScreen.Container
        })
        
        RoundCorners(LoadingScreen.ProgressTrack, 10)
        CreateStroke(LoadingScreen.ProgressTrack, COLORS.Primary, 1)
        
        LoadingScreen.ProgressFill = Create("Frame", {
            Name = "ProgressFill",
            BackgroundColor3 = COLORS.Accent,
            Size = UDim2.new(0, 0, 1, 0),
            Parent = LoadingScreen.ProgressTrack
        })
        
        RoundCorners(LoadingScreen.ProgressFill, 10)
        CreateGradient(LoadingScreen.ProgressFill, {
            COLORS.Accent,
            Color3.new(
                math.clamp(COLORS.Accent.R * 1.3, 0, 1),
                math.clamp(COLORS.Accent.G * 1.3, 0, 1),
                math.clamp(COLORS.Accent.B * 1.3, 0, 1)
            )
        }, 90)
        
        LoadingScreen.ProgressText = Create("TextLabel", {
            Name = "ProgressText",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0.8, 0),
            Size = UDim2.new(1, 0, 0, 20),
            Font = Enum.Font.Gotham,
            Text = "0%",
            TextColor3 = COLORS.Text,
            TextSize = 12,
            Parent = LoadingScreen.Container
        })
    end
    
    LoadingScreen.Spinner = Create("Frame", {
        Name = "Spinner",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0.5, -20, 0.8, -20),
        Parent = LoadingScreen.Container
    })
    
    local spinnerCircles = {}
    local circleCount = 8
    
    for i = 1, circleCount do
        local circle = Create("Frame", {
            Name = "Circle" .. i,
            BackgroundColor3 = COLORS.Accent,
            BackgroundTransparency = 0.5,
            Size = UDim2.new(0, 6, 0, 6),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Parent = LoadingScreen.Spinner
        })
        
        RoundCorners(circle, 3)
        spinnerCircles[i] = circle
    end
    
    LoadingScreen.AnimationConnection = RunService.Heartbeat:Connect(function()
        local time = tick()
        
        for i, circle in pairs(spinnerCircles) do
            local angle = (i - 1) * (2 * math.pi / circleCount) + time * 2 * math.pi
            local radius = 15
            
            circle.Position = UDim2.new(
                0.5, math.cos(angle) * radius,
                0.5, math.sin(angle) * radius
            )
            
            local alpha = (math.sin(angle + time * 8) + 1) / 2
            circle.BackgroundTransparency = 1 - alpha * 0.5
        end
    end)
    
    function LoadingScreen:SetProgress(Progress, Text)
        Progress = math.clamp(Progress, 0, 100)
        
        if self.ShowProgress then
            self.ProgressFill.Size = UDim2.new(Progress / 100, 0, 1, 0)
            self.ProgressText.Text = Text or string.format("%d%%", Progress)
        end
        
        if Text and self.SubtitleLabel then
            self.SubtitleLabel.Text = Text
        end
    end
    
    function LoadingScreen:Destroy()
        if self.AnimationConnection then
            self.AnimationConnection:Disconnect()
        end
        self.Main:Destroy()
    end
    
    function LoadingScreen:Hide()
        Tween(self.Container, {Size = UDim2.new(0, 0, 0, 0)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        Tween(self.Background, {BackgroundTransparency = 1}, 0.5)
        
        task.wait(0.5)
        self:Destroy()
    end
    
    return LoadingScreen
end

function ViperUI:Notify(Config)
    Config = Config or {}
    
    local Notification = {}
    Notification.Title = Config.Title or "Notification"
    Notification.Message = Config.Message or ""
    Notification.Duration = Config.Duration or 5
    Notification.Type = Config.Type or "Info"
    
    local TypeColors = {
        Info = COLORS.Primary,
        Success = COLORS.Success,
        Warning = COLORS.Warning,
        Error = COLORS.Error
    }
    
    Notification.Main = Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, 0, 0, 80),
        Parent = self.NotificationHolder
    })
    
    RoundCorners(Notification.Main, 8)
    CreateStroke(Notification.Main, TypeColors[Notification.Type], 2)
    CreateShadow(Notification.Main)
    
    Create("Frame", {
        Name = "AccentBar",
        BackgroundColor3 = TypeColors[Notification.Type],
        BorderSizePixel = 0,
        Size = UDim2.new(0, 5, 1, 0),
        Parent = Notification.Main
    })
    
    Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -30, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = Notification.Title,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Notification.Main
    })
    
    Create("TextLabel", {
        Name = "Message",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 30),
        Size = UDim2.new(1, -30, 0, 40),
        Font = Enum.Font.Gotham,
        Text = Notification.Message,
        TextColor3 = COLORS.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = Notification.Main
    })
    
    local CloseButton = Create("TextButton", {
        Name = "CloseButton",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -25, 0, 5),
        Size = UDim2.new(0, 20, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = COLORS.SubText,
        TextSize = 16,
        Parent = Notification.Main
    })
    
    task.spawn(function()
        task.wait(Notification.Duration)
        Notification:Remove()
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        Notification:Remove()
    end)
    
    function Notification:Remove()
        Tween(self.Main, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        self.Main:Destroy()
    end
    
    Notification.Main.Size = UDim2.new(1, 0, 0, 0)
    Tween(Notification.Main, {Size = UDim2.new(1, 0, 0, 80)}, 0.3)
    
    table.insert(self.Notifications, Notification)
    return Notification
end

function ViperUI:CreateWatermark(Config)
    Config = Config or {}
    
    local Watermark = {}
    Watermark.Text = Config.Text or "ViperUI " .. LIBRARY_VERSION
    Watermark.Enabled = true
    
    Watermark.Main = Create("Frame", {
        Name = "Watermark",
        BackgroundColor3 = COLORS.Background,
        BackgroundTransparency = 0.2,
        Position = UDim2.new(0, 20, 0, 20),
        Size = UDim2.new(0, 200, 0, 40),
        Parent = self.ScreenGui
    })
    
    RoundCorners(Watermark.Main, 8)
    CreateStroke(Watermark.Main, COLORS.Primary, 1)
    CreateShadow(Watermark.Main)
    
    Watermark.Label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = Watermark.Text,
        TextColor3 = COLORS.Text,
        TextSize = 12,
        Parent = Watermark.Main
    })
    
    local FPSLabel = Create("TextLabel", {
        Name = "FPSLabel",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, 5),
        Size = UDim2.new(1, 0, 0, 15),
        Font = Enum.Font.Gotham,
        Text = "FPS: 0",
        TextColor3 = COLORS.SubText,
        TextSize = 10,
        Parent = Watermark.Main
    })
    
    local lastTime = tick()
    local frameCount = 0
    
    RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        
        if currentTime - lastTime >= 1 then
            local fps = math.floor(frameCount / (currentTime - lastTime))
            FPSLabel.Text = "FPS: " .. fps
            frameCount = 0
            lastTime = currentTime
        end
    end)
    
    function Watermark:Toggle()
        self.Enabled = not self.Enabled
        self.Main.Visible = self.Enabled
    end
    
    function Watermark:SetText(Text)
        self.Text = Text
        self.Label.Text = Text
    end
    
    table.insert(self.Elements, Watermark)
    return Watermark
end

function ViperUI:SaveConfig(Name)
    local config = {
        Windows = {}
    }
    
    for _, window in pairs(self.Windows) do
        local windowConfig = {
            Position = window.MainFrame.Position,
            Size = window.Size,
            Tabs = {}
        }
        
        for _, tab in pairs(window.Tabs) do
            local tabConfig = {
                Sections = {}
            }
            
            for _, section in pairs(tab.Sections) do
                local sectionConfig = {
                    Elements = {}
                }
                
                for _, element in pairs(section.Elements) do
                    if element.Value ~= nil then
                        sectionConfig.Elements[element.Name] = element.Value
                    end
                end
                
                table.insert(tabConfig.Sections, sectionConfig)
            end
            
            table.insert(windowConfig.Tabs, tabConfig)
        end
        
        config.Windows[window.Title] = windowConfig
    end
    
    return config
end

function ViperUI:LoadConfig(Config)
end

function ViperUI:CreateWindow(Title, Config)
    local window = Window.new(self, Title, Config)
    table.insert(self.Windows, window)
    return window
end

function Window:AddTab(Title, Icon)
    local tab = Tab.new(self, Title, Icon)
    table.insert(self.Tabs, tab)
    
    if #self.Tabs == 1 then
        tab:Activate()
    end
    
    return tab
end

function Tab:AddSection(Title, Side)
    local section = Section.new(self, Title, Side)
    table.insert(self.Sections, section)
    return section
end

function Section:AddColorPicker(Config)
    Config = Config or {}
    
    local ColorPicker = {}
    ColorPicker.Value = Config.Default or Color3.new(1, 1, 1)
    ColorPicker.Name = Config.Name or "Color Picker"
    ColorPicker.Callback = Config.Callback or function() end
    ColorPicker.Open = false
    
    ColorPicker.Main = Create("Frame", {
        Name = "ColorPicker",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 30),
        Parent = self.ContentContainer
    })
    
    ColorPicker.Label = Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.7, 0, 1, 0),
        Font = Enum.Font.Gotham,
        Text = ColorPicker.Name,
        TextColor3 = COLORS.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ColorPicker.Main
    })
    
    ColorPicker.Preview = Create("TextButton", {
        Name = "Preview",
        BackgroundColor3 = ColorPicker.Value,
        Position = UDim2.new(1, -60, 0.5, -10),
        Size = UDim2.new(0, 60, 0, 20),
        Text = "",
        AutoButtonColor = false,
        Parent = ColorPicker.Main
    })
    
    RoundCorners(ColorPicker.Preview, 4)
    CreateStroke(ColorPicker.Preview, COLORS.Primary, 1)
    
    ColorPicker.Dialog = Create("Frame", {
        Name = "Dialog",
        BackgroundColor3 = COLORS.Surface,
        BackgroundTransparency = 0.1,
        Position = UDim2.new(0, 0, 1, 5),
        Size = UDim2.new(1, 0, 0, 150),
        Visible = false,
        Parent = ColorPicker.Main
    })
    
    RoundCorners(ColorPicker.Dialog, 8)
    CreateStroke(ColorPicker.Dialog, COLORS.Primary, 1)
    
    ColorPicker.Spectrum = Create("ImageButton", {
        Name = "Spectrum",
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.new(0, 130, 0, 130),
        Image = "rbxassetid://4155801252",
        AutoButtonColor = false,
        Parent = ColorPicker.Dialog
    })
    
    ColorPicker.Brightness = Create("Frame", {
        Name = "Brightness",
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.new(0, 150, 0, 10),
        Size = UDim2.new(0, 20, 0, 130),
        Parent = ColorPicker.Dialog
    })
    
    CreateGradient(ColorPicker.Brightness, {
        Color3.new(1, 1, 1),
        Color3.new(0, 0, 0)
    }, 0)
    
    ColorPicker.BrightnessSelector = Create("Frame", {
        Name = "BrightnessSelector",
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.new(0, 145, 0, 10),
        Size = UDim2.new(0, 30, 0, 10),
        Parent = ColorPicker.Dialog
    })
    
    RoundCorners(ColorPicker.BrightnessSelector, 2)
    CreateStroke(ColorPicker.BrightnessSelector, Color3.new(0, 0, 0), 2)
    
    ColorPicker.Current = Create("Frame", {
        Name = "Current",
        BackgroundColor3 = ColorPicker.Value,
        Position = UDim2.new(0, 180, 0, 10),
        Size = UDim2.new(0, 50, 0, 50),
        Parent = ColorPicker.Dialog
    })
    
    local function CreateRGBInput(Name, Position)
        local container = Create("Frame", {
            Name = Name,
            BackgroundTransparency = 1,
            Position = Position,
            Size = UDim2.new(0, 50, 0, 20),
            Parent = ColorPicker.Dialog
        })
        
        Create("TextLabel", {
            Name = "Label",
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 15, 1, 0),
            Font = Enum.Font.Gotham,
            Text = Name:upper(),
            TextColor3 = COLORS.Text,
            TextSize = 10,
            Parent = container
        })
        
        local input = Create("TextBox", {
            Name = "Input",
            BackgroundColor3 = COLORS.Surface,
            BackgroundTransparency = 0.8,
            Position = UDim2.new(0, 20, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            Font = Enum.Font.Gotham,
            Text = "255",
            TextColor3 = COLORS.Text,
            TextSize = 10,
            Parent = container
        })
        
        RoundCorners(input, 4)
        return input
    end
    
    ColorPicker.RInput = CreateRGBInput("R", UDim2.new(0, 180, 0, 70))
    ColorPicker.GInput = CreateRGBInput("G", UDim2.new(0, 180, 0, 95))
    ColorPicker.BInput = CreateRGBInput("B", UDim2.new(0, 180, 0, 120))
    
    local CloseButton = Create("TextButton", {
        Name = "CloseButton",
        BackgroundColor3 = COLORS.Primary,
        Position = UDim2.new(0, 180, 0, 115),
        Size = UDim2.new(0, 50, 0, 25),
        Font = Enum.Font.Gotham,
        Text = "Apply",
        TextColor3 = COLORS.Text,
        TextSize = 12,
        Parent = ColorPicker.Dialog
    })
    
    RoundCorners(CloseButton, 4)
    
    local function UpdateColor(hue, sat, val)
        local color = Color3.fromHSV(hue, sat, val)
        ColorPicker.Value = color
        ColorPicker.Preview.BackgroundColor3 = color
        ColorPicker.Current.BackgroundColor3 = color
        
        ColorPicker.RInput.Text = tostring(math.floor(color.R * 255))
        ColorPicker.GInput.Text = tostring(math.floor(color.G * 255))
        ColorPicker.BInput.Text = tostring(math.floor(color.B * 255))
        
        ColorPicker.Callback(color)
    end
    
    ColorPicker.Spectrum.MouseButton1Down:Connect(function(x, y)
        local relativeX = (x - ColorPicker.Spectrum.AbsolutePosition.X) / ColorPicker.Spectrum.AbsoluteSize.X
        local relativeY = (y - ColorPicker.Spectrum.AbsolutePosition.Y) / ColorPicker.Spectrum.AbsoluteSize.Y
        
        local hue = math.clamp(relativeX, 0, 1)
        local sat = 1 - math.clamp(relativeY, 0, 1)
        
        UpdateColor(hue, sat, 1)
    end)
    
    ColorPicker.Brightness.MouseButton1Down:Connect(function(x, y)
        local relativeY = (y - ColorPicker.Brightness.AbsolutePosition.Y) / ColorPicker.Brightness.AbsoluteSize.Y
        local brightness = 1 - math.clamp(relativeY, 0, 1)
        
        UpdateColor(0, 1, brightness)
    end)
    
    function ColorPicker:Toggle()
        self.Open = not self.Open
        
        if self.Open then
            self.Dialog.Visible = true
            Tween(self.Dialog, {Size = UDim2.new(1, 0, 0, 150)}, 0.3)
        else
            Tween(self.Dialog, {Size = UDim2.new(1, 0, 0, 0)}, 0.3)
            task.wait(0.3)
            self.Dialog.Visible = false
        end
    end
    
    ColorPicker.Preview.MouseButton1Click:Connect(function()
        ColorPicker:Toggle()
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        ColorPicker:Toggle()
    end)
    
    table.insert(self.Elements, ColorPicker)
    return ColorPicker
end

return ViperUI
