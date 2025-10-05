-- Premium CFrame Tracker with Animations
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

-- Professional Color Scheme
local COLORS = {
	background = Color3.fromRGB(22, 23, 27),
	backgroundLight = Color3.fromRGB(28, 29, 34),
	header = Color3.fromRGB(32, 34, 40),
	entry = Color3.fromRGB(35, 37, 44),
	entryHover = Color3.fromRGB(42, 44, 52),
	entryActive = Color3.fromRGB(48, 50, 59),
	text = Color3.fromRGB(255, 255, 255),
	textDim = Color3.fromRGB(160, 164, 175),
	textMuted = Color3.fromRGB(120, 124, 135),
	button = Color3.fromRGB(45, 47, 56),
	buttonHover = Color3.fromRGB(55, 58, 68),
	accent = Color3.fromRGB(88, 101, 242),
	accentDark = Color3.fromRGB(71, 82, 196),
	pinned = Color3.fromRGB(239, 68, 68),
	saved = Color3.fromRGB(34, 197, 94),
	warning = Color3.fromRGB(245, 158, 11),
	divider = Color3.fromRGB(40, 42, 50),
	scrollbar = Color3.fromRGB(55, 58, 68)
}

local SPEED_MULTIPLIER = 0.25
local function FastTween(time, style, dir)
	return TweenInfo.new(time * SPEED_MULTIPLIER, style, dir)
end

local TWEEN_INFO = {
	fast = FastTween(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	smooth = FastTween(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	bounce = FastTween(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	elastic = FastTween(0.45, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
	slide = FastTween(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
}

local TRACK_DISTANCE = 0.3
local MAX_TRACKED = 150

local cframes, pinned, saved = {}, {}, {}
local pinnedMarkers, entries = {}, {}
local lastPos, lastRefresh = nil, 0
local trackingEnabled = true

-- Helper Functions
local function createFrame(props)
	local f = Instance.new("Frame")
	for k,v in pairs(props) do f[k] = v end
	return f
end

local function createButton(props)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	for k,v in pairs(props) do b[k] = v end
	return b
end

local function animateProperty(obj, props, tweenInfo)
	local tween = TweenService:Create(obj, tweenInfo or TWEEN_INFO.smooth, props)
	tween:Play()
	return tween
end

local function createMarker(cf)
	local p = Instance.new("Part")
	p.Name = "PinnedMarker"
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.Neon
	p.Size = Vector3.new(0.1, 0.1, 0.1)
	p.Color = COLORS.pinned
	p.Anchored = true
	p.CanCollide = false
	p.CFrame = cf
	p.Parent = markerFolder
	
	-- Animate marker appearance
	local growTween = TweenService:Create(p, TWEEN_INFO.bounce, {
		Size = Vector3.new(0.6, 0.6, 0.6)
	})
	growTween:Play()
	
	-- Add pulsing effect
	local pulse = Instance.new("PointLight")
	pulse.Brightness = 2
	pulse.Color = COLORS.pinned
	pulse.Range = 12
	pulse.Parent = p
	
	-- Continuous pulse animation
	spawn(function()
		while p and p.Parent do
			TweenService:Create(pulse, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				Brightness = 4,
				Range = 15
			}):Play()
			wait(1)
			TweenService:Create(pulse, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				Brightness = 2,
				Range = 12
			}):Play()
			wait(1)
		end
	end)
	
	return p
end

-- Main Window
local main = createFrame({
	Size = UDim2.new(0, 560, 0, 420),
	Position = UDim2.new(0.5, -280, 1.5, 0), -- Start offscreen
	BackgroundColor3 = COLORS.background,
	BorderSizePixel = 0,
	Parent = gui
})
local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 14)

-- Animate main window entrance
wait(0.1)
animateProperty(main, {Position = UDim2.new(0.5, -280, 0.5, -210)}, TWEEN_INFO.slide)

-- Header
local header = createFrame({
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundColor3 = COLORS.header,
	BorderSizePixel = 0,
	Parent = main
})
local headerCorner = Instance.new("UICorner", header)
headerCorner.CornerRadius = UDim.new(0, 14)

local headerMask = createFrame({
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 1, -20),
	BackgroundColor3 = COLORS.header,
	BorderSizePixel = 0,
	Parent = header
})

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "CFRAME TRACKER"
title.TextColor3 = COLORS.text
title.TextTransparency = 1
title.TextSize = 15
title.Font = Enum.Font.SourceSansBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Animate title fade in
animateProperty(title, {TextTransparency = 0}, TWEEN_INFO.smooth)

local closeBtn = createButton({
	Size = UDim2.new(0, 32, 0, 32),
	Position = UDim2.new(1, -40, 0, 8),
	BackgroundColor3 = COLORS.button,
	Text = "×",
	TextColor3 = COLORS.textDim,
	TextSize = 22,
	Font = Enum.Font.SourceSans,
	Parent = header
})
local closeBtnCorner = Instance.new("UICorner", closeBtn)
closeBtnCorner.CornerRadius = UDim.new(0, 8)

closeBtn.MouseEnter:Connect(function()
	animateProperty(closeBtn, {BackgroundColor3 = COLORS.pinned, TextColor3 = COLORS.text}, TWEEN_INFO.fast)
end)
closeBtn.MouseLeave:Connect(function()
	animateProperty(closeBtn, {BackgroundColor3 = COLORS.button, TextColor3 = COLORS.textDim}, TWEEN_INFO.fast)
end)
closeBtn.MouseButton1Click:Connect(function()
	animateProperty(main, {Size = UDim2.new(0, 560, 0, 0)}, TWEEN_INFO.smooth)
	wait(0.25)
	gui.Enabled = false
	main.Size = UDim2.new(0, 560, 0, 420)
end)

-- Window dragging
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Stats Bar
local statsContainer = createFrame({
	Size = UDim2.new(1, -32, 0, 36),
	Position = UDim2.new(0, 16, 0, 56),
	BackgroundColor3 = COLORS.backgroundLight,
	BorderSizePixel = 0,
	Parent = main
})
local statsCorner = Instance.new("UICorner", statsContainer)
statsCorner.CornerRadius = UDim.new(0, 10)

local function createStat(text, color, x)
	local container = createFrame({
		Size = UDim2.new(0, 160, 1, 0),
		Position = UDim2.new(0, x, 0, 0),
		BackgroundTransparency = 1,
		Parent = statsContainer
	})
	
	local icon = Instance.new("Frame")
	icon.Size = UDim2.new(0, 8, 0, 8)
	icon.Position = UDim2.new(0, 12, 0.5, -4)
	icon.BackgroundColor3 = color
	icon.BorderSizePixel = 0
	icon.Parent = container
	Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -28, 1, 0)
	label.Position = UDim2.new(0, 28, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = COLORS.textDim
	label.TextSize = 13
	label.Font = Enum.Font.SourceSans
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	return label
end

local trackedStat = createStat("Tracked: 0", COLORS.accent, 10)
local pinnedStat = createStat("Pinned: 0", COLORS.pinned, 170)
local savedStat = createStat("Saved: 0", COLORS.saved, 330)

-- Scroll Area
local scrollContainer = createFrame({
	Size = UDim2.new(1, -32, 1, -160),
	Position = UDim2.new(0, 16, 0, 100),
	BackgroundColor3 = COLORS.backgroundLight,
	BorderSizePixel = 0,
	Parent = main
})
local scrollCorner = Instance.new("UICorner", scrollContainer)
scrollCorner.CornerRadius = UDim.new(0, 10)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -8)
scroll.Position = UDim2.new(0, 4, 0, 4)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = COLORS.scrollbar
scroll.BorderSizePixel = 0
scroll.Parent = scrollContainer

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

-- Update stats with animation
local function updateStats()
	trackedStat.Text = "Tracked: " .. #cframes
	pinnedStat.Text = "Pinned: " .. #pinned
	savedStat.Text = "Saved: " .. #saved
end

-- Entry management
local function removeEntry(cf)
	for i,v in ipairs(cframes) do if v==cf then table.remove(cframes,i) break end end
	for i,v in ipairs(pinned) do if v==cf then table.remove(pinned,i) break end end
	for i,v in ipairs(saved) do if v==cf then table.remove(saved,i) break end end
	
	if pinnedMarkers[cf] then
		local marker = pinnedMarkers[cf]
		animateProperty(marker, {Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1}, TWEEN_INFO.smooth)
		Debris:AddItem(marker, 0.3)
		pinnedMarkers[cf] = nil
	end
	
	if entries[cf] then
		local entry = entries[cf]
		animateProperty(entry, {Size = UDim2.new(0, 0, 0, 44), BackgroundTransparency = 1}, TWEEN_INFO.smooth)
		Debris:AddItem(entry, 0.3)
		entries[cf] = nil
	end
	
	updateStats()
end

local function teleportTo(cf)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		trackingEnabled = false

		-- Teleport effect
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

		-- Teleport and reset tracking state
		hrp.CFrame = cf
		lastPos = cf.Position -- reset position baseline
		task.delay(1, function()  -- wait longer to ensure no false track
			trackingEnabled = true
			lastPos = hrp.Position -- reinitialize after teleport settles
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
end

local function toggleSave(cf)
	local i = table.find(saved, cf)
	if i then table.remove(saved, i) else table.insert(saved, 1, cf) end
end

local function addEntry(cf)
	if entries[cf] then return end
	
	local pos = cf.Position
	local entry = createFrame({
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = COLORS.entry,
		BackgroundTransparency = 1,
		Parent = scroll
	})
	
	-- Set sort order
	entry.LayoutOrder = (
		table.find(pinned, cf) and -3000000 or
		table.find(saved, cf) and -2000000 or
		-os.clock()
	)
	
	local entryCorner = Instance.new("UICorner", entry)
	entryCorner.CornerRadius = UDim.new(0, 10)
	
	-- Animate entry appearance
	entry.Size = UDim2.new(0, 0, 0, 44)
	animateProperty(entry, {Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 0}, TWEEN_INFO.bounce)
	
	-- Status indicator
	local statusBar = createFrame({
		Size = UDim2.new(0, 3, 1, -12),
		Position = UDim2.new(0, 6, 0, 6),
		BackgroundColor3 = table.find(pinned, cf) and COLORS.pinned or table.find(saved, cf) and COLORS.saved or COLORS.textMuted,
		BorderSizePixel = 0,
		Parent = entry
	})
	Instance.new("UICorner", statusBar).CornerRadius = UDim.new(1, 0)
	
	-- Coordinates label
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.65, -20, 1, 0)
	label.Position = UDim2.new(0, 20, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)
	label.TextColor3 = COLORS.text
	label.TextSize = 14
	label.Font = Enum.Font.SourceSans
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = entry
	
	-- Hover effects
	entry.MouseEnter:Connect(function()
		animateProperty(entry, {BackgroundColor3 = COLORS.entryHover}, TWEEN_INFO.fast)
	end)
	entry.MouseLeave:Connect(function()
		animateProperty(entry, {BackgroundColor3 = COLORS.entry}, TWEEN_INFO.fast)
	end)
	
	label.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			animateProperty(entry, {BackgroundColor3 = COLORS.entryActive}, TweenInfo.new(0.1))
			wait(0.1)
			animateProperty(entry, {BackgroundColor3 = COLORS.entryHover}, TweenInfo.new(0.1))
			teleportTo(cf)
		end
	end)
	
	-- Action buttons
	local btnContainer = createFrame({
		Size = UDim2.new(0, 108, 1, 0),
		Position = UDim2.new(1, -116, 0, 0),
		BackgroundTransparency = 1,
		Parent = entry
	})
	
	local function actionBtn(icon, color, x, callback)
		local btn = createButton({
			Size = UDim2.new(0, 30, 0, 30),
			Position = UDim2.new(0, x, 0.5, -15),
			BackgroundColor3 = COLORS.button,
			Text = icon,
			TextColor3 = color,
			TextSize = 15,
			Font = Enum.Font.SourceSansBold,
			Parent = btnContainer
		})
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		
		btn.MouseEnter:Connect(function()
			animateProperty(btn, {BackgroundColor3 = color, TextColor3 = COLORS.text}, TWEEN_INFO.fast)
		end)
		btn.MouseLeave:Connect(function()
			animateProperty(btn, {BackgroundColor3 = COLORS.button, TextColor3 = color}, TWEEN_INFO.fast)
		end)
		btn.MouseButton1Click:Connect(function()
			-- Button press animation
			animateProperty(btn, {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(0, x + 2, 0.5, -13)}, TweenInfo.new(0.1))
			wait(0.1)
			animateProperty(btn, {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, x, 0.5, -15)}, TweenInfo.new(0.1))
			callback()
		end)
	end
	
	actionBtn("📌", COLORS.pinned, 0, function()
		togglePin(cf)
		removeEntry(cf)
		addEntry(cf)
	end)
	actionBtn("💾", COLORS.saved, 36, function()
		toggleSave(cf)
		removeEntry(cf)
		addEntry(cf)
	end)
	actionBtn("×", COLORS.textMuted, 72, function()
		removeEntry(cf)
	end)
	
	entries[cf] = entry
	scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
	updateStats()
end

-- Bottom action buttons
local actionBar = createFrame({
	Size = UDim2.new(1, -32, 0, 44),
	Position = UDim2.new(0, 16, 1, -56),
	BackgroundTransparency = 1,
	Parent = main
})

local function mainButton(text, icon, color, x, callback)
	local btn = createButton({
		Size = UDim2.new(0, 160, 0, 40),
		Position = UDim2.new(0, x, 0, 0),
		BackgroundColor3 = color,
		Text = "",
		Parent = actionBar
	})
	local btnCorner = Instance.new("UICorner", btn)
	btnCorner.CornerRadius = UDim.new(0, 10)
	
	local btnIcon = Instance.new("TextLabel")
	btnIcon.Size = UDim2.new(0, 30, 1, 0)
	btnIcon.Position = UDim2.new(0, 8, 0, 0)
	btnIcon.BackgroundTransparency = 1
	btnIcon.Text = icon
	btnIcon.TextColor3 = COLORS.text
	btnIcon.TextSize = 18
	btnIcon.Font = Enum.Font.SourceSansBold
	btnIcon.Parent = btn
	
	local btnText = Instance.new("TextLabel")
	btnText.Size = UDim2.new(1, -40, 1, 0)
	btnText.Position = UDim2.new(0, 35, 0, 0)
	btnText.BackgroundTransparency = 1
	btnText.Text = text
	btnText.TextColor3 = COLORS.text
	btnText.TextSize = 14
	btnText.Font = Enum.Font.SourceSansBold
	btnText.TextXAlignment = Enum.TextXAlignment.Left
	btnText.Parent = btn
	
	btn.MouseEnter:Connect(function()
		animateProperty(btn, {Size = UDim2.new(0, 164, 0, 44), Position = UDim2.new(0, x - 2, 0, -2)}, TWEEN_INFO.fast)
	end)
	btn.MouseLeave:Connect(function()
		animateProperty(btn, {Size = UDim2.new(0, 160, 0, 40), Position = UDim2.new(0, x, 0, 0)}, TWEEN_INFO.fast)
	end)
	btn.MouseButton1Click:Connect(function()
		animateProperty(btn, {BackgroundTransparency = 0.3}, TweenInfo.new(0.1))
		wait(0.1)
		animateProperty(btn, {BackgroundTransparency = 0}, TweenInfo.new(0.1))
		callback()
	end)
end

mainButton("Pin Current", "📌", COLORS.pinned, 0, function()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local cf = hrp.CFrame
	if not table.find(pinned, cf) then
		table.insert(pinned, 1, cf)
		pinnedMarkers[cf] = createMarker(cf)
		addEntry(cf)
	end
end)

mainButton("Save Current", "💾", COLORS.saved, 176, function()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local cf = hrp.CFrame
	if not table.find(saved, cf) then
		table.insert(saved, 1, cf)
		addEntry(cf)
	end
end)

mainButton("Clear Tracked", "🗑", COLORS.button, 352, function()
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

-- Position tracking
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
