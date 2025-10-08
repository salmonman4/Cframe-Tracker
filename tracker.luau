-- @6zfy on discord
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "CFrameTracker"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local workspace = game:GetService("Workspace")
local markerFolder = workspace:FindFirstChild("CFrameMarkers") or Instance.new("Folder")
markerFolder.Name = "CFrameMarkers"
markerFolder.Parent = workspace

local COLORS = {
    background = Color3.fromRGB(20, 20, 20),
    backgroundLight = Color3.fromRGB(30, 30, 30),
    header = Color3.fromRGB(25, 25, 25),
    entry = Color3.fromRGB(35, 35, 35),
    entryHover = Color3.fromRGB(50, 50, 50),
    entryActive = Color3.fromRGB(65, 65, 65),
    text = Color3.fromRGB(255, 255, 255),
    textDim = Color3.fromRGB(180, 180, 180),
    textMuted = Color3.fromRGB(120, 120, 120),
    button = Color3.fromRGB(40, 40, 40),
    buttonHover = Color3.fromRGB(60, 60, 60),
    buttonActive = Color3.fromRGB(80, 80, 80),
    accent = Color3.fromRGB(100, 100, 255),
    pinned = Color3.fromRGB(255, 60, 110),
    saved = Color3.fromRGB(0, 200, 100),
    divider = Color3.fromRGB(50, 50, 50),
    scrollbar = Color3.fromRGB(80, 80, 80)
}

local TWEEN_INFO = {
    fast = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
    smooth = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
    bounce = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    slide = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
}

local TRACK_DISTANCE = 0.2
local MAX_TRACKED = 250

local cframes, pinned, saved = {}, {}, {}
local pinnedMarkers, entries = {}, {}
local coordinateNames = {}
local lastPos, lastRefresh = nil, 0
local trackingEnabled = true

local function createFrame(props)
    local f = Instance.new("Frame")
    for k, v in pairs(props) do f[k] = v end
    return f
end

local function createButton(props)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    for k, v in pairs(props) do b[k] = v end
    return b
end

local function animateProperty(obj, props, tweenInfo)
    local tween = TweenService:Create(obj, tweenInfo or TWEEN_INFO.smooth, props)
    tween:Play()
    return tween
end

local function createMarker(cf, lastCF)
    local p = Instance.new("Part")
    p.Name = "CFrameMarker"
    p.Size = Vector3.new(0.2, 0.2, 0.2)
    p.Transparency = 1
    p.Anchored = true
    p.CanCollide = false
    p.CFrame = cf
    p.Parent = markerFolder

    local glow = Instance.new("PointLight")
    glow.Color = COLORS.pinned
    glow.Range = 6
    glow.Brightness = 1.5
    glow.Parent = p

    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 100, 0, 120)
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.StudsOffset = Vector3.new(0, 1.5, 0)
    gui.Parent = p

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 48, 0, 48)
    icon.AnchorPoint = Vector2.new(0.5, 0)
    icon.Position = UDim2.new(0.5, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://18209587530"
    icon.ImageColor3 = COLORS.pinned
    icon.Parent = gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 28)
    label.Position = UDim2.new(0, 0, 0, 58)
    label.BackgroundTransparency = 1
    label.Text = coordinateNames[cf] or string.format("X:%.1f Y:%.1f Z:%.1f", cf.X, cf.Y, cf.Z)
    label.TextColor3 = COLORS.text
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.new(0, 0, 0)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.Parent = label

    if lastCF then
        local a0 = Instance.new("Attachment", p)
        local prevMarker = markerFolder:FindFirstChild("LastCFrameMarker")
        if prevMarker then
            local a1 = Instance.new("Attachment", prevMarker)
            local beam = Instance.new("Beam")
            beam.Attachment0 = a0
            beam.Attachment1 = a1
            beam.Color = ColorSequence.new(COLORS.pinned)
            beam.Width0 = 0.05
            beam.Width1 = 0.05
            beam.LightEmission = 0.7
            beam.Transparency = NumberSequence.new(0.1)
            beam.FaceCamera = true
            beam.Parent = p
        end
    end

    for _, child in ipairs(markerFolder:GetChildren()) do
        if child.Name == "LastCFrameMarker" then
            child.Name = "OldCFrameMarker"
        end
    end
    p.Name = "LastCFrameMarker"

    return p
end

local main = createFrame({
    Size = UDim2.new(0, 540, 0, 400),
    Position = UDim2.new(0.5, -270, 1.5, 0),
    BackgroundColor3 = COLORS.background,
    BorderSizePixel = 0,
    Parent = gui
})
local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 24)

local border = Instance.new("UIStroke", main)
border.Color = COLORS.divider
border.Thickness = 1

wait(0.1)
animateProperty(main, {Position = UDim2.new(0.5, -270, 0.5, -200)}, TWEEN_INFO.slide)

local header = createFrame({
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = COLORS.header,
    BorderSizePixel = 0,
    Parent = main
})
local headerCorner = Instance.new("UICorner", header)
headerCorner.CornerRadius = UDim.new(0, 24)

local headerMask = createFrame({
    Size = UDim2.new(1, 0, 0, 24),
    Position = UDim2.new(0, 0, 1, -24),
    BackgroundColor3 = COLORS.header,
    BorderSizePixel = 0,
    Parent = header
})

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "CFRAME TRACKER"
title.TextColor3 = COLORS.text
title.TextTransparency = 1
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

animateProperty(title, {TextTransparency = 0}, TWEEN_INFO.smooth)

local closeBtn = createButton({
    Size = UDim2.new(0, 28, 0, 28),
    Position = UDim2.new(1, -36, 0, 8),
    BackgroundColor3 = COLORS.button,
    Text = "×",
    TextColor3 = COLORS.textDim,
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    Parent = header
})
local closeBtnCorner = Instance.new("UICorner", closeBtn)
closeBtnCorner.CornerRadius = UDim.new(0, 10)

closeBtn.MouseEnter:Connect(function()
    animateProperty(closeBtn, {BackgroundColor3 = COLORS.buttonHover, TextColor3 = COLORS.text}, TWEEN_INFO.fast)
end)
closeBtn.MouseLeave:Connect(function()
    animateProperty(closeBtn, {BackgroundColor3 = COLORS.button, TextColor3 = COLORS.textDim}, TWEEN_INFO.fast)
end)
closeBtn.MouseButton1Click:Connect(function()
    animateProperty(main, {Position = UDim2.new(0.5, -270, 1.5, 0)}, TWEEN_INFO.smooth)
    wait(0.3)
    gui.Enabled = false
    main.Position = UDim2.new(0.5, -270, 1.5, 0)
end)

local dragging, dragStart, startPos
local currentDragOffset = Vector2.new(0, 0)
local targetDragOffset = Vector2.new(0, 0)

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        currentDragOffset = Vector2.new(0, 0)
        targetDragOffset = Vector2.new(0, 0)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        dragging = false 
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        targetDragOffset = Vector2.new(delta.X, delta.Y)
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if dragging then
        local lerpSpeed = 20
        currentDragOffset = currentDragOffset:Lerp(targetDragOffset, math.min(dt * lerpSpeed, 1))
        main.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + currentDragOffset.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + currentDragOffset.Y
        )
    end
end)

local statsContainer = createFrame({
    Size = UDim2.new(1, -32, 0, 32),
    Position = UDim2.new(0, 16, 0, 52),
    BackgroundColor3 = COLORS.backgroundLight,
    BorderSizePixel = 0,
    Parent = main
})
local statsCorner = Instance.new("UICorner", statsContainer)
statsCorner.CornerRadius = UDim.new(0, 12)

local function createStat(text, x)
    local container = createFrame({
        Size = UDim2.new(0, 160, 1, 0),
        Position = UDim2.new(0, x, 0, 0),
        BackgroundTransparency = 1,
        Parent = statsContainer
    })
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.textDim
    label.TextSize = 11
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    return label
end

local trackedStat = createStat("TRACKED: 0", 0)
local pinnedStat = createStat("PINNED: 0", 160)
local savedStat = createStat("SAVED: 0", 320)

local scrollContainer = createFrame({
    Size = UDim2.new(1, -32, 1, -148),
    Position = UDim2.new(0, 16, 0, 92),
    BackgroundColor3 = COLORS.backgroundLight,
    BorderSizePixel = 0,
    Parent = main
})
local scrollCorner = Instance.new("UICorner", scrollContainer)
scrollCorner.CornerRadius = UDim.new(0, 12)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -4, 1, -4)
scroll.Position = UDim2.new(0, 2, 0, 2)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = COLORS.scrollbar
scroll.BorderSizePixel = 0
scroll.Parent = scrollContainer

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local function updateStats()
    trackedStat.Text = "TRACKED: " .. #cframes
    pinnedStat.Text = "PINNED: " .. #pinned
    savedStat.Text = "SAVED: " .. #saved
end

local function copyToClipboard(text)
    if setclipboard then
        setclipboard(text)
    end
end

local function removeEntry(cf)
    for i, v in ipairs(cframes) do if v == cf then table.remove(cframes, i) break end end
    for i, v in ipairs(pinned) do if v == cf then table.remove(pinned, i) break end end
    for i, v in ipairs(saved) do if v == cf then table.remove(saved, i) break end end
    
    coordinateNames[cf] = nil
    
    if pinnedMarkers[cf] then
        local marker = pinnedMarkers[cf]
        animateProperty(marker, {Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1}, TWEEN_INFO.smooth)
        Debris:AddItem(marker, 0.3)
        pinnedMarkers[cf] = nil
    end
    
    if entries[cf] then
        local entry = entries[cf]
        animateProperty(entry, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, TWEEN_INFO.smooth)
        Debris:AddItem(entry, 0.3)
        entries[cf] = nil
    end
    
    updateStats()
end

local function teleportTo(cf)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        trackingEnabled = false
        local effect = Instance.new("Part")
        effect.Shape = Enum.PartType.Ball
        effect.Material = Enum.Material.ForceField
        effect.Size = Vector3.new(2, 2, 2)
        effect.Color = COLORS.accent
        effect.Anchored = true
        effect.CanCollide = false
        effect.CFrame = hrp.CFrame
        effect.Parent = workspace
        animateProperty(effect, {Size = Vector3.new(8, 8, 8), Transparency = 1}, TWEEN_INFO.smooth)
        Debris:AddItem(effect, 0.5)
        hrp.CFrame = cf
        lastPos = cf.Position
        task.delay(1, function()
            trackingEnabled = true
            lastPos = hrp.Position
        end)
    end
end

local function togglePin(cf)
    local i = table.find(pinned, cf)
    if i then
        table.remove(pinned, i)
        if pinnedMarkers[cf] then
            local marker = pinnedMarkers[cf]
            animateProperty(marker, {Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1}, TWEEN_INFO.smooth)
            Debris:AddItem(marker, 0.3)
            pinnedMarkers[cf] = nil
        end
    else
        table.insert(pinned, 1, cf)
        pinnedMarkers[cf] = createMarker(cf)
    end
    if entries[cf] then
        removeEntry(cf)
        addEntry(cf)
    end
end

local function toggleSave(cf)
    local i = table.find(saved, cf)
    if i then
        table.remove(saved, i)
    else
        table.insert(saved, 1, cf)
    end
    if entries[cf] then
        removeEntry(cf)
        addEntry(cf)
    end
end

local function showRenameDialog(cf, label)
    local dialog = createFrame({
        Size = UDim2.new(0, 280, 0, 100),
        Position = UDim2.new(0.5, -140, 0.5, -50),
        BackgroundColor3 = COLORS.background,
        BorderSizePixel = 0,
        ZIndex = 100,
        Parent = gui
    })
    local dialogCorner = Instance.new("UICorner", dialog)
    dialogCorner.CornerRadius = UDim.new(0, 16)
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 0, 32)
    input.Position = UDim2.new(0, 10, 0, 10)
    input.BackgroundColor3 = COLORS.backgroundLight
    input.BorderSizePixel = 0
    input.Text = coordinateNames[cf] or ""
    input.PlaceholderText = "Enter name..."
    input.TextColor3 = COLORS.text
    input.PlaceholderColor3 = COLORS.textMuted
    input.TextSize = 12
    input.Font = Enum.Font.GothamMedium
    input.ClearTextOnFocus = false
    input.ZIndex = 101
    input.Parent = dialog
    local inputCorner = Instance.new("UICorner", input)
    inputCorner.CornerRadius = UDim.new(0, 8)
    
    local btnContainer = createFrame({
        Size = UDim2.new(1, -20, 0, 28),
        Position = UDim2.new(0, 10, 0, 52),
        BackgroundTransparency = 1,
        ZIndex = 101,
        Parent = dialog
    })
    
    local cancelBtn = createButton({
        Size = UDim2.new(0.48, -5, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = COLORS.button,
        Text = "CANCEL",
        TextColor3 = COLORS.textDim,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        ZIndex = 101,
        Parent = btnContainer
    })
    local cancelBtnCorner = Instance.new("UICorner", cancelBtn)
    cancelBtnCorner.CornerRadius = UDim.new(0, 8)
    
    local saveBtn = createButton({
        Size = UDim2.new(0.48, -5, 1, 0),
        Position = UDim2.new(0.52, 5, 0, 0),
        BackgroundColor3 = COLORS.button,
        Text = "SAVE",
        TextColor3 = COLORS.text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        ZIndex = 101,
        Parent = btnContainer
    })
    local saveBtnCorner = Instance.new("UICorner", saveBtn)
    saveBtnCorner.CornerRadius = UDim.new(0, 8)
    
    local function close(save)
        if save and input.Text ~= "" then
            coordinateNames[cf] = input.Text
            label.Text = input.Text
            if pinnedMarkers[cf] then
                for _, marker in ipairs(markerFolder:GetChildren()) do
                    if marker:IsA("Part") and marker.CFrame == cf then
                        local billboardGui = marker:FindFirstChildOfClass("BillboardGui")
                        if billboardGui then
                            local markerLabel = billboardGui:FindFirstChild("TextLabel")
                            if markerLabel then
                                markerLabel.Text = input.Text
                            end
                        end
                    end
                end
            end
        elseif save and input.Text == "" then
            coordinateNames[cf] = nil
            local pos = cf.Position
            label.Text = string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)
        end
        dialog:Destroy()
    end
    
    cancelBtn.MouseButton1Click:Connect(function() close(false) end)
    saveBtn.MouseButton1Click:Connect(function() close(true) end)
    
    cancelBtn.MouseEnter:Connect(function()
        animateProperty(cancelBtn, {BackgroundColor3 = COLORS.buttonHover}, TWEEN_INFO.fast)
    end)
    cancelBtn.MouseLeave:Connect(function()
        animateProperty(cancelBtn, {BackgroundColor3 = COLORS.button}, TWEEN_INFO.fast)
    end)
    
    saveBtn.MouseEnter:Connect(function()
        animateProperty(saveBtn, {BackgroundColor3 = COLORS.buttonHover}, TWEEN_INFO.fast)
    end)
    saveBtn.MouseLeave:Connect(function()
        animateProperty(saveBtn, {BackgroundColor3 = COLORS.button}, TWEEN_INFO.fast)
    end)
    
    input:CaptureFocus()
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then close(true) end
    end)
end

local function addEntry(cf)
    if entries[cf] then return end
    
    local pos = cf.Position
    local isPinned = table.find(pinned, cf)
    local isSaved = table.find(saved, cf)
    
    local entry = createFrame({
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = COLORS.entry,
        BackgroundTransparency = 1,
        Parent = scroll
    })
    local entryCorner = Instance.new("UICorner", entry)
    entryCorner.CornerRadius = UDim.new(0, 12)

    entry.LayoutOrder = isPinned and -1000000 or isSaved and -500000 or -os.clock()
    
    entry.Size = UDim2.new(1, 0, 0, 0)
    animateProperty(entry, {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 0}, TWEEN_INFO.bounce)
    
    local statusContainer = createFrame({
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = entry
    })
    
    if isPinned then
        local pinnedIcon = Instance.new("TextLabel")
        pinnedIcon.Size = UDim2.new(0, 28, 0, 28)
        pinnedIcon.Position = UDim2.new(0, 6, 0.5, -14)
        pinnedIcon.BackgroundColor3 = COLORS.pinned
        pinnedIcon.BorderSizePixel = 0
        pinnedIcon.Text = "📌"
        pinnedIcon.TextColor3 = COLORS.background
        pinnedIcon.TextSize = 14
        pinnedIcon.Font = Enum.Font.GothamBold
        pinnedIcon.Parent = statusContainer
        local pinnedCorner = Instance.new("UICorner", pinnedIcon)
        pinnedCorner.CornerRadius = UDim.new(0, 8)
    elseif isSaved then
        local savedIcon = Instance.new("TextLabel")
        savedIcon.Size = UDim2.new(0, 28, 0, 28)
        savedIcon.Position = UDim2.new(0, 6, 0.5, -14)
        savedIcon.BackgroundColor3 = COLORS.saved
        savedIcon.BorderSizePixel = 0
        savedIcon.Text = "💾"
        savedIcon.TextColor3 = COLORS.background
        savedIcon.TextSize = 14
        savedIcon.Font = Enum.Font.GothamBold
        savedIcon.Parent = statusContainer
        local savedCorner = Instance.new("UICorner", savedIcon)
        savedCorner.CornerRadius = UDim.new(0, 8)
    else
        local normalBar = createFrame({
            Size = UDim2.new(0, 2, 1, -16),
            Position = UDim2.new(0, 12, 0, 8),
            BackgroundColor3 = COLORS.textMuted,
            BorderSizePixel = 0,
            Parent = statusContainer
        })
        local normalCorner = Instance.new("UICorner", normalBar)
        normalCorner.CornerRadius = UDim.new(1, 0)
    end
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.55, -20, 1, 0)
    label.Position = UDim2.new(0, 44, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = coordinateNames[cf] or string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)
    label.TextColor3 = COLORS.text
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = entry
    
    entry.MouseEnter:Connect(function()
        animateProperty(entry, {BackgroundColor3 = COLORS.entryHover}, TWEEN_INFO.fast)
    end)
    entry.MouseLeave:Connect(function()
        animateProperty(entry, {BackgroundColor3 = COLORS.entry}, TWEEN_INFO.fast)
    end)
    
    label.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            animateProperty(entry, {BackgroundColor3 = COLORS.entryActive}, TWEEN_INFO.fast)
            wait(0.1)
            animateProperty(entry, {BackgroundColor3 = COLORS.entryHover}, TWEEN_INFO.fast)
            teleportTo(cf)
            copyToClipboard(string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z))
        end
    end)
    
    local btnContainer = createFrame({
        Size = UDim2.new(0, 134, 1, 0),
        Position = UDim2.new(1, -138, 0, 0),
        BackgroundTransparency = 1,
        Parent = entry
    })
    
    local function actionBtn(icon, x, callback)
        local btn = createButton({
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(0, x, 0.5, -14),
            BackgroundColor3 = COLORS.button,
            Text = icon,
            TextColor3 = COLORS.textDim,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            Parent = btnContainer
        })
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 8)
        
        btn.MouseEnter:Connect(function()
            animateProperty(btn, {BackgroundColor3 = COLORS.buttonHover, TextColor3 = COLORS.text}, TWEEN_INFO.fast)
        end)
        btn.MouseLeave:Connect(function()
            animateProperty(btn, {BackgroundColor3 = COLORS.button, TextColor3 = COLORS.textDim}, TWEEN_INFO.fast)
        end)
        btn.MouseButton1Click:Connect(function()
            animateProperty(btn, {BackgroundColor3 = COLORS.buttonActive}, TWEEN_INFO.fast)
            wait(0.1)
            animateProperty(btn, {BackgroundColor3 = COLORS.button}, TWEEN_INFO.fast)
            callback()
        end)
        return btn
    end
    
    actionBtn("✏️", 0, function()
        showRenameDialog(cf, label)
    end)
    
    actionBtn("📌", 34, function()
        togglePin(cf)
    end)
    
    actionBtn("💾", 68, function()
        toggleSave(cf)
    end)
    
    actionBtn("×", 102, function()
        removeEntry(cf)
    end)
    
    entries[cf] = entry
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
    updateStats()
end

local actionBar = createFrame({
    Size = UDim2.new(1, -32, 0, 40),
    Position = UDim2.new(0, 16, 1, -52),
    BackgroundTransparency = 1,
    Parent = main
})

local function mainButton(text, icon, x, callback)
    local btn = createButton({
        Size = UDim2.new(0, 156, 0, 36),
        Position = UDim2.new(0, x, 0, 0),
        BackgroundColor3 = COLORS.button,
        Text = "",
        Parent = actionBar
    })
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 12)
    
    local btnIcon = Instance.new("TextLabel")
    btnIcon.Size = UDim2.new(0, 24, 1, 0)
    btnIcon.Position = UDim2.new(0, 8, 0, 0)
    btnIcon.BackgroundTransparency = 1
    btnIcon.Text = icon
    btnIcon.TextColor3 = COLORS.text
    btnIcon.TextSize = 16
    btnIcon.Font = Enum.Font.GothamBold
    btnIcon.Parent = btn
    
    local btnText = Instance.new("TextLabel")
    btnText.Size = UDim2.new(1, -36, 1, 0)
    btnText.Position = UDim2.new(0, 32, 0, 0)
    btnText.BackgroundTransparency = 1
    btnText.Text = text
    btnText.TextColor3 = COLORS.text
    btnText.TextSize = 11
    btnText.Font = Enum.Font.GothamBold
    btnText.TextXAlignment = Enum.TextXAlignment.Left
    btnText.Parent = btn
    
    btn.MouseEnter:Connect(function()
        animateProperty(btn, {BackgroundColor3 = COLORS.buttonHover}, TWEEN_INFO.fast)
    end)
    btn.MouseLeave:Connect(function()
        animateProperty(btn, {BackgroundColor3 = COLORS.button}, TWEEN_INFO.fast)
    end)
    btn.MouseButton1Click:Connect(function()
        animateProperty(btn, {BackgroundColor3 = COLORS.buttonActive}, TWEEN_INFO.fast)
        wait(0.1)
        animateProperty(btn, {BackgroundColor3 = COLORS.button}, TWEEN_INFO.fast)
        callback()
    end)
end

mainButton("PIN CURRENT", "📌", 0, function()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local cf = hrp.CFrame
    if not table.find(pinned, cf) then
        table.insert(pinned, 1, cf)
        pinnedMarkers[cf] = createMarker(cf)
        addEntry(cf)
    end
end)

mainButton("SAVE CURRENT", "💾", 164, function()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local cf = hrp.CFrame
    if not table.find(saved, cf) then
        table.insert(saved, 1, cf)
        addEntry(cf)
    end
end)

mainButton("CLEAR TRACKED", "🗑", 328, function()
    local toRemove = {}
    for _, cf in ipairs(cframes) do
        if not table.find(saved, cf) and not table.find(pinned, cf) then
            table.insert(toRemove, cf)
        end
    end
    for _, cf in ipairs(toRemove) do
        removeEntry(cf)
    end
    updateStats()
end)

RunService.Heartbeat:Connect(function(dt)
    if not gui.Enabled or not trackingEnabled then return end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local pos = hrp.Position
    if lastPos and (pos - lastPos).Magnitude >= TRACK_DISTANCE then
        local cf = hrp.CFrame
        if not table.find(cframes, cf) then
            table.insert(cframes, 1, cf)
            if #cframes > MAX_TRACKED then
                local old = cframes[#cframes]
                table.remove(cframes, #cframes)
                if entries[old] and not table.find(pinned, old) and not table.find(saved, old) then
                    removeEntry(old)
                end
            end
            addEntry(cf)
        end
    end
    lastPos = pos
end)

updateStats()
