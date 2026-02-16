--!strict
--[[
	Phase 2 Index UI: collection journal with biome overview, biome detail grid, and item detail view.
	Uses CollectiblesController (getConfig, getBiomeProgress, subscribeToState). Option A: UI created in code.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CollectiblesController = require(script.Parent.Parent.Controllers.CollectiblesController)
local Types = require(ReplicatedStorage.Shared.Collectibles.Types)
type BiomeProgress = Types.BiomeProgress
type ItemConfig = Types.ItemConfig

local GRID_COLUMNS = 4
local CELL_SIZE = 80
local CELL_PADDING = 8
local OVERLAY_COLOR = Color3.fromRGB(0, 0, 0)
local OVERLAY_TRANSPARENCY = 0.5
local CARD_BG = Color3.fromRGB(28, 28, 33)
local CARD_BG_UNCOLLECTED = Color3.fromRGB(18, 18, 22)
local TEXT_COLOR = Color3.fromRGB(240, 240, 245)
local TEXT_MUTED = Color3.fromRGB(140, 140, 150)

local screenGui: ScreenGui? = nil
local overlay: Frame? = nil
local mainFrame: Frame? = nil
local overviewScrollFrame: ScrollingFrame? = nil
local overviewContent: Frame? = nil
local biomeDetailContent: Frame? = nil
local itemDetailContent: Frame? = nil
local detailViewport: ViewportFrame? = nil
local detailViewModel: Model? = nil
local detailNameLabel: TextLabel? = nil
local detailBiomeLabel: TextLabel? = nil
local detailDescLabel: TextLabel? = nil
local isOpen = false
local dataReady = false
local currentScreen: "overview" | "biomeDetail" | "itemDetail" = "overview"
local selectedBiomeId: string? = nil
local selectedItemId: string? = nil
local refreshBiomeDetail: () -> ()
local refreshItemDetail: () -> ()

local function getModelTemplate(itemId: string): Model?
	local config = CollectiblesController.getConfig()
	local modelPath: string? = nil
	for _, item in config.items do
		if item.id == itemId then
			modelPath = item.modelPath
			break
		end
	end
	if not modelPath then
		return nil
	end
	local parts = string.split(modelPath, "/")
	local current: Instance = ReplicatedStorage
	for _, name in parts do
		local child = current:FindFirstChild(name)
		if not child then
			return nil
		end
		current = child
	end
	if current:IsA("Model") then
		return current :: Model
	end
	if current:IsA("BasePart") then
		local model = Instance.new("Model")
		model.Name = itemId
		local clone = (current :: BasePart):Clone()
		clone.Parent = model
		return model
	end
	return nil
end

local function setupViewportModel(viewport: ViewportFrame, itemId: string, collected: boolean)
	if detailViewModel and detailViewModel.Parent then
		detailViewModel:Destroy()
		detailViewModel = nil
	end
	local template = getModelTemplate(itemId)
	if not template then
		return
	end
	local clone = template:Clone()
	clone.Parent = viewport
	detailViewModel = clone
	local cf, size = clone:GetBoundingBox()
	clone:PivotTo(cf)
	local cam = viewport:FindFirstChildOfClass("Camera")
	if cam then
		cam.CFrame = CFrame.new(cf.Position + Vector3.new(0, 0, size.Magnitude * 0.8), cf.Position)
	end
	if not collected then
		for _, desc in clone:GetDescendants() do
			if desc:IsA("BasePart") then
				(desc :: BasePart).Color = Color3.fromRGB(40, 40, 45)
			end
		end
	end
end

local function showScreen(screen: "overview" | "biomeDetail" | "itemDetail")
	currentScreen = screen
	if not overviewScrollFrame or not biomeDetailContent or not itemDetailContent then
		return
	end
	local scroll = overviewScrollFrame :: ScrollingFrame
	local biome = biomeDetailContent :: Frame
	local item = itemDetailContent :: Frame
	scroll.Visible = (screen == "overview")
	biome.Visible = (screen == "biomeDetail")
	item.Visible = (screen == "itemDetail")
end

local function refreshOverview()
	if not overviewContent then
		return
	end
	for _, child in overviewContent:GetChildren() do
		if child:IsA("GuiButton") or child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local listLayout = overviewContent:FindFirstChildOfClass("UIListLayout")
	if not listLayout then
		return
	end
	if not dataReady then
		local loadingLabel = Instance.new("TextLabel")
		loadingLabel.Size = UDim2.new(1, 0, 0, 40)
		loadingLabel.BackgroundTransparency = 1
		loadingLabel.Text = "Loading..."
		loadingLabel.TextColor3 = TEXT_MUTED
		loadingLabel.TextSize = 14
		loadingLabel.LayoutOrder = 0
		loadingLabel.Parent = overviewContent
		local scroll = overviewScrollFrame
		local content = overviewContent
		if scroll and content then
			task.defer(function()
				if scroll and content and scroll.Parent and content.Parent then
					(scroll :: ScrollingFrame).CanvasSize = UDim2.new(0, 0, 0, math.max(0, (content :: Frame).AbsoluteSize.Y))
				end
			end)
		end
		return
	end
	local progress = CollectiblesController.getBiomeProgress()
	local config = CollectiblesController.getConfig()
	for i, p in ipairs(progress) do
		local biomeConfig = nil
		for _, b in config.biomes do
			if b.id == p.biomeId then
				biomeConfig = b
				break
			end
		end
		local displayName = biomeConfig and biomeConfig.displayName or p.biomeId
		local btn = Instance.new("TextButton")
		btn.Name = p.biomeId
		btn.Size = UDim2.new(1, -24, 0, 56)
		btn.Position = UDim2.new(0, 0, 0, 0)
		btn.BackgroundColor3 = CARD_BG
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.LayoutOrder = i
		btn.AutoButtonColor = true
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = btn
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -20, 0, 24)
		label.Position = UDim2.new(0, 10, 0, 8)
		label.BackgroundTransparency = 1
		label.Text = displayName
		label.TextColor3 = TEXT_COLOR
		label.TextSize = 16
		label.Font = Enum.Font.GothamMedium
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = btn
		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.new(1, -20, 0, 20)
		sub.Position = UDim2.new(0, 10, 0, 32)
		sub.BackgroundTransparency = 1
		sub.Text = string.format("%d / %d  (%d%%)", p.collectedCount, p.totalCount, p.totalCount > 0 and math.floor(p.collectedCount / p.totalCount * 100) or 0)
		sub.TextColor3 = TEXT_MUTED
		sub.TextSize = 14
		sub.Font = Enum.Font.Gotham
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.Parent = btn
		btn.MouseButton1Click:Connect(function()
			selectedBiomeId = p.biomeId
			refreshBiomeDetail()
			showScreen("biomeDetail")
		end)
		btn.Parent = overviewContent
	end
	local scroll = overviewScrollFrame
	local content = overviewContent
	if scroll and content then
		task.defer(function()
			if scroll and content and scroll.Parent and content.Parent then
				(scroll :: ScrollingFrame).CanvasSize = UDim2.new(0, 0, 0, math.max(0, (content :: Frame).AbsoluteSize.Y))
			end
		end)
	end
end

refreshBiomeDetail = function()
	if not biomeDetailContent or not selectedBiomeId then
		return
	end
	local config = CollectiblesController.getConfig()
	local progress = CollectiblesController.getBiomeProgress()
	local biomeProgress: BiomeProgress? = nil
	for _, p in progress do
		if p.biomeId == selectedBiomeId then
			biomeProgress = p
			break
		end
	end
	local biomeConfig = nil
	for _, b in config.biomes do
		if b.id == selectedBiomeId then
			biomeConfig = b
			break
		end
	end
	local header = biomeDetailContent:FindFirstChild("Header")
	if header and header:IsA("TextLabel") then
		(header :: TextLabel).Text = (biomeConfig and biomeConfig.displayName or selectedBiomeId) or ""
	end
	local progressLabel = biomeDetailContent:FindFirstChild("ProgressLabel")
	if progressLabel and progressLabel:IsA("TextLabel") and biomeProgress then
		(progressLabel :: TextLabel).Text = string.format("%d / %d", biomeProgress.collectedCount, biomeProgress.totalCount)
	end
	local grid = biomeDetailContent:FindFirstChild("Grid")
	if not grid or not biomeConfig then
		return
	end
	for _, child in grid:GetChildren() do
		child:Destroy()
	end
	local collectedSet: { [string]: boolean } = {}
	if biomeProgress then
		for _, id in biomeProgress.collectedItemIds do
			collectedSet[id] = true
		end
	end
	local itemsById: { [string]: ItemConfig } = {}
	for _, item in config.items do
		itemsById[item.id] = item
	end
	for i, itemId in biomeConfig.itemIds do
		local item = itemsById[itemId]
		local collected = collectedSet[itemId] == true
		local cell = Instance.new("TextButton")
		cell.Name = itemId
		cell.Size = UDim2.new(0, CELL_SIZE, 0, CELL_SIZE)
		cell.BackgroundColor3 = collected and CARD_BG or CARD_BG_UNCOLLECTED
		cell.BorderSizePixel = 0
		cell.Text = collected and (item and item.displayName or itemId) or "???"
		cell.TextColor3 = collected and TEXT_COLOR or TEXT_MUTED
		cell.TextSize = 10
		cell.TextWrapped = true
		cell.LayoutOrder = i
		cell.AutoButtonColor = true
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = cell
		cell.MouseButton1Click:Connect(function()
			selectedItemId = itemId
			refreshItemDetail()
			showScreen("itemDetail")
		end)
		cell.Parent = grid
	end
end

refreshItemDetail = function()
	if not itemDetailContent or not selectedItemId or not detailViewport or not detailNameLabel or not detailBiomeLabel or not detailDescLabel then
		return
	end
	local config = CollectiblesController.getConfig()
	local state = CollectiblesController.getState()
	local collectedSet: { [string]: boolean } = {}
	for _, id in state.collectedItemIds do
		collectedSet[id] = true
	end
	local collected = collectedSet[selectedItemId :: string] == true
	local item: ItemConfig? = nil
	for _, i in config.items do
		if i.id == selectedItemId then
			item = i
			break
		end
	end
	setupViewportModel(detailViewport :: ViewportFrame, selectedItemId :: string, collected)
	;(detailNameLabel :: TextLabel).Text = collected and (item and item.displayName or selectedItemId) or "???"
	local biomeName = item and item.biomeId or ""
	for _, b in config.biomes do
		if b.id == (item and item.biomeId or "") then
			biomeName = b.displayName
			break
		end
	end
	;(detailBiomeLabel :: TextLabel).Text = biomeName
	if collected and item and item.description and #item.description > 0 then
		(detailDescLabel :: TextLabel).Visible = true;
		(detailDescLabel :: TextLabel).Text = item.description
	else
		(detailDescLabel :: TextLabel).Visible = false;
		(detailDescLabel :: TextLabel).Text = ""
	end
end

local function closeIndex()
	if not screenGui or not overlay or not mainFrame then
		return
	end
	local ov = overlay :: Frame
	local mf = mainFrame :: Frame
	isOpen = false
	ov.Visible = false
	mf.Visible = false
end

local function openIndex()
	if not screenGui or not overlay or not mainFrame then
		return
	end
	local ov = overlay :: Frame
	local mf = mainFrame :: Frame
	isOpen = true
	ov.Visible = true
	mf.Visible = true
	showScreen("overview")
	refreshOverview()
end

local function toggleIndex()
	if isOpen then
		closeIndex()
	else
		openIndex()
	end
end

local function buildUI(player: Player)
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "CollectiblesIndex"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	screenGui = gui

	local overlayFrame = Instance.new("Frame")
	overlayFrame.Name = "Overlay"
	overlayFrame.Size = UDim2.new(1, 0, 1, 0)
	overlayFrame.Position = UDim2.new(0, 0, 0, 0)
	overlayFrame.BackgroundColor3 = OVERLAY_COLOR
	overlayFrame.BackgroundTransparency = OVERLAY_TRANSPARENCY
	overlayFrame.BorderSizePixel = 0
	overlayFrame.Visible = false
	overlayFrame.ZIndex = 1
	overlayFrame.Parent = gui
	overlay = overlayFrame
	local overlayBtn = Instance.new("TextButton")
	overlayBtn.Size = UDim2.new(1, 0, 1, 0)
	overlayBtn.BackgroundTransparency = 1
	overlayBtn.Text = ""
	overlayBtn.ZIndex = 2
	overlayBtn.Parent = overlayFrame
	overlayBtn.MouseButton1Click:Connect(closeIndex)

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(0, 400, 0, 500)
	main.Position = UDim2.new(0.5, -200, 0.5, -250)
	main.BackgroundColor3 = CARD_BG
	main.BorderSizePixel = 0
	main.Visible = false
	main.ZIndex = 3
	main.Parent = gui
	mainFrame = main
	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = main
	local mainPadding = Instance.new("UIPadding")
	mainPadding.PaddingTop = UDim.new(0, 12)
	mainPadding.PaddingBottom = UDim.new(0, 12)
	mainPadding.PaddingLeft = UDim.new(0, 12)
	mainPadding.PaddingRight = UDim.new(0, 12)
	mainPadding.Parent = main

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -80, 0, 28)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Collection Index"
	title.TextColor3 = TEXT_COLOR
	title.TextSize = 18
	title.Font = Enum.Font.GothamMedium
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 4
	title.Parent = main

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 60, 0, 28)
	closeBtn.Position = UDim2.new(1, -60, 0, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "Close"
	closeBtn.TextColor3 = TEXT_COLOR
	closeBtn.TextSize = 14
	closeBtn.ZIndex = 4
	closeBtn.Parent = main
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(closeIndex)

	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, 0, 1, -48)
	contentArea.Position = UDim2.new(0, 0, 0, 40)
	contentArea.BackgroundTransparency = 1
	contentArea.ZIndex = 4
	contentArea.Parent = main

	-- Overview screen (ScrollingFrame containing list)
	local overviewScroll = Instance.new("ScrollingFrame")
	overviewScroll.Name = "OverviewScroll"
	overviewScroll.Size = UDim2.new(1, 0, 1, 0)
	overviewScroll.BackgroundTransparency = 1
	overviewScroll.ScrollBarThickness = 6
	overviewScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	overviewScroll.Visible = true
	overviewScroll.Parent = contentArea
	overviewScrollFrame = overviewScroll
	local overview = Instance.new("Frame")
	overview.Name = "Overview"
	overview.Size = UDim2.new(1, 0, 0, 0)
	overview.AutomaticSize = Enum.AutomaticSize.Y
	overview.BackgroundTransparency = 1
	overview.Parent = overviewScroll
	overviewContent = overview
	local overviewList = Instance.new("UIListLayout")
	overviewList.Padding = UDim.new(0, 8)
	overviewList.SortOrder = Enum.SortOrder.LayoutOrder
	overviewList.Parent = overview

	-- Biome detail screen
	local biomeDetail = Instance.new("Frame")
	biomeDetail.Name = "BiomeDetail"
	biomeDetail.Size = UDim2.new(1, 0, 1, 0)
	biomeDetail.BackgroundTransparency = 1
	biomeDetail.Visible = false
	biomeDetail.Parent = contentArea
	biomeDetailContent = biomeDetail
	local biomeHeader = Instance.new("TextLabel")
	biomeHeader.Name = "Header"
	biomeHeader.Size = UDim2.new(1, 0, 0, 28)
	biomeHeader.BackgroundTransparency = 1
	biomeHeader.Text = ""
	biomeHeader.TextColor3 = TEXT_COLOR
	biomeHeader.TextSize = 16
	biomeHeader.Font = Enum.Font.GothamMedium
	biomeHeader.TextXAlignment = Enum.TextXAlignment.Left
	biomeHeader.Parent = biomeDetail
	local progressLbl = Instance.new("TextLabel")
	progressLbl.Name = "ProgressLabel"
	progressLbl.Size = UDim2.new(1, 0, 0, 20)
	progressLbl.Position = UDim2.new(0, 0, 0, 30)
	progressLbl.BackgroundTransparency = 1
	progressLbl.Text = "0 / 0"
	progressLbl.TextColor3 = TEXT_MUTED
	progressLbl.TextSize = 14
	progressLbl.TextXAlignment = Enum.TextXAlignment.Left
	progressLbl.Parent = biomeDetail
	local grid = Instance.new("Frame")
	grid.Name = "Grid"
	grid.Size = UDim2.new(1, 0, 1, -70)
	grid.Position = UDim2.new(0, 0, 0, 56)
	grid.BackgroundTransparency = 1
	grid.Parent = biomeDetail
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, CELL_SIZE, 0, CELL_SIZE)
	gridLayout.CellPadding = UDim2.new(0, CELL_PADDING, 0, CELL_PADDING)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid
	local backBiome = Instance.new("TextButton")
	backBiome.Name = "Back"
	backBiome.Size = UDim2.new(0, 60, 0, 24)
	backBiome.Position = UDim2.new(0, 0, 0, -2)
	backBiome.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	backBiome.BorderSizePixel = 0
	backBiome.Text = "Back"
	backBiome.TextColor3 = TEXT_COLOR
	backBiome.TextSize = 12
	backBiome.Parent = biomeDetail
	backBiome.MouseButton1Click:Connect(function()
		showScreen("overview")
		refreshOverview()
	end)

	-- Item detail screen
	local itemDetail = Instance.new("Frame")
	itemDetail.Name = "ItemDetail"
	itemDetail.Size = UDim2.new(1, 0, 1, 0)
	itemDetail.BackgroundTransparency = 1
	itemDetail.Visible = false
	itemDetail.Parent = contentArea
	itemDetailContent = itemDetail
	local backItem = Instance.new("TextButton")
	backItem.Name = "Back"
	backItem.Size = UDim2.new(0, 60, 0, 24)
	backItem.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	backItem.BorderSizePixel = 0
	backItem.Text = "Back"
	backItem.TextColor3 = TEXT_COLOR
	backItem.TextSize = 12
	backItem.Parent = itemDetail
	backItem.MouseButton1Click:Connect(function()
		showScreen("biomeDetail")
		refreshBiomeDetail()
	end)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "ModelView"
	vp.Size = UDim2.new(1, 0, 0, 180)
	vp.Position = UDim2.new(0, 0, 0, 32)
	vp.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
	vp.BorderSizePixel = 0
	vp.Parent = itemDetail
	detailViewport = vp
	local vpCorner = Instance.new("UICorner")
	vpCorner.CornerRadius = UDim.new(0, 8)
	vpCorner.Parent = vp
	local cam = Instance.new("Camera")
	cam.Name = "Camera"
	cam.Parent = vp
	vp.CurrentCamera = cam
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "ItemName"
	nameLbl.Size = UDim2.new(1, 0, 0, 24)
	nameLbl.Position = UDim2.new(0, 0, 0, 218)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = ""
	nameLbl.TextColor3 = TEXT_COLOR
	nameLbl.TextSize = 16
	nameLbl.Font = Enum.Font.GothamMedium
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = itemDetail
	detailNameLabel = nameLbl
	local biomeLbl = Instance.new("TextLabel")
	biomeLbl.Name = "BiomeName"
	biomeLbl.Size = UDim2.new(1, 0, 0, 18)
	biomeLbl.Position = UDim2.new(0, 0, 0, 244)
	biomeLbl.BackgroundTransparency = 1
	biomeLbl.Text = ""
	biomeLbl.TextColor3 = TEXT_MUTED
	biomeLbl.TextSize = 12
	biomeLbl.TextXAlignment = Enum.TextXAlignment.Left
	biomeLbl.Parent = itemDetail
	detailBiomeLabel = biomeLbl
	local descLbl = Instance.new("TextLabel")
	descLbl.Name = "Description"
	descLbl.Size = UDim2.new(1, 0, 0, 80)
	descLbl.Position = UDim2.new(0, 0, 0, 266)
	descLbl.BackgroundTransparency = 1
	descLbl.Text = ""
	descLbl.TextColor3 = TEXT_MUTED
	descLbl.TextSize = 12
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.TextYAlignment = Enum.TextYAlignment.Top
	descLbl.TextWrapped = true
	descLbl.Visible = false
	descLbl.Parent = itemDetail
	detailDescLabel = descLbl

	-- HUD button to open Index
	local indexBtn = Instance.new("TextButton")
	indexBtn.Name = "IndexButton"
	indexBtn.Size = UDim2.new(0, 44, 0, 44)
	indexBtn.Position = UDim2.new(1, -54, 0, 60)
	indexBtn.BackgroundColor3 = CARD_BG
	indexBtn.BorderSizePixel = 0
	indexBtn.Text = "Index"
	indexBtn.TextColor3 = TEXT_COLOR
	indexBtn.TextSize = 12
	indexBtn.ZIndex = 1
	indexBtn.Parent = gui
	local indexCorner = Instance.new("UICorner")
	indexCorner.CornerRadius = UDim.new(0, 8)
	indexCorner.Parent = indexBtn
	indexBtn.MouseButton1Click:Connect(toggleIndex)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape and isOpen then
			closeIndex()
		end
	end)

	CollectiblesController.subscribeToState(function()
		dataReady = true
		if isOpen then
			if currentScreen == "overview" then
				refreshOverview()
			elseif currentScreen == "biomeDetail" then
				refreshBiomeDetail()
			elseif currentScreen == "itemDetail" then
				refreshItemDetail()
			end
		end
	end)
end

local function init()
	local player = Players.LocalPlayer
	if not player then
		return
	end
	task.defer(function()
		buildUI(player)
	end)
end

init()

return nil
