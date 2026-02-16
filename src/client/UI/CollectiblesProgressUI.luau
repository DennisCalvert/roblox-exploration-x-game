--!strict
--[[
	Minimal V1 UI: shows collection progress per biome.
	Backend support (getBiomeProgress, subscribeToState) is in CollectiblesController.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollectiblesController = require(script.Parent.Parent.Controllers.CollectiblesController)

local function createUI()
	local player = Players.LocalPlayer
	if not player then
		return
	end
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CollectiblesProgress"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "ProgressFrame"
	frame.Size = UDim2.new(0, 220, 0, 280)
	frame.Position = UDim2.new(1, -230, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 28)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "Collection progress"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 16
	title.Font = Enum.Font.GothamMedium
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 40)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = frame

	local contentFolder = Instance.new("Folder")
	contentFolder.Name = "Content"
	contentFolder.Parent = frame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = contentFolder

	local function updateProgress()
		for _, child in contentFolder:GetChildren() do
			child:Destroy()
		end
		local progress = CollectiblesController.getBiomeProgress()
		local config = CollectiblesController.getConfig()
		local displayNames: { [string]: string } = {}
		for _, b in config.biomes do
			displayNames[b.id] = b.displayName
		end
		for i, p in ipairs(progress) do
			local row = Instance.new("TextLabel")
			row.Name = p.biomeId
			row.LayoutOrder = i
			row.Size = UDim2.new(1, -10, 0, 22)
			row.BackgroundTransparency = 1
			row.Text = string.format("%s: %d / %d", displayNames[p.biomeId] or p.biomeId, p.collectedCount, p.totalCount)
			row.TextColor3 = Color3.fromRGB(200, 200, 210)
			row.TextSize = 14
			row.Font = Enum.Font.Gotham
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.Parent = contentFolder
		end
	end

	CollectiblesController.subscribeToState(function()
		updateProgress()
	end)
	updateProgress()
end

-- Run when client is ready
task.defer(createUI)

return nil
