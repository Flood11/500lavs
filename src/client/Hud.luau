-- Minimal bare-bones HUD: cash readout + what you're currently carrying.
-- Everything else (steal/place/collect/buy prompts, costs, rates) is
-- native ProximityPrompt UI set server-side — no custom UI for that here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local Hud = {}

local player = Players.LocalPlayer

local function createLabel(order: number, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 280, 0, 36)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	label.BackgroundTransparency = 0.25
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = ""
	label.LayoutOrder = order
	label.Parent = parent
	return label
end

function Hud.start()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RunFromHud"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 280, 0, 90)
	container.Position = UDim2.new(0, 16, 0, 16)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = container

	local cashLabel = createLabel(1, container)
	local carryingLabel = createLabel(2, container)

	local function updateCash(cash: IntValue)
		cashLabel.Text = "$ " .. cash.Value
	end

	local function bindCash()
		local leaderstats = player:FindFirstChild("leaderstats")
		local cash = leaderstats and leaderstats:FindFirstChild("Cash") :: IntValue?
		if not cash then
			return false
		end
		updateCash(cash)
		cash:GetPropertyChangedSignal("Value"):Connect(function()
			updateCash(cash)
		end)
		return true
	end

	if not bindCash() then
		cashLabel.Text = "$ 0"
		player.ChildAdded:Connect(function(child)
			if child.Name == "leaderstats" then
				bindCash()
			end
		end)
	end

	local function updateCarrying()
		local itemId = player:GetAttribute("CarryingItemName")
		local item = itemId and Config.Items[itemId]
		if item then
			carryingLabel.Text = "Carrying: " .. item.displayName
			carryingLabel.TextColor3 = Config.Rarity[item.rarity] or Color3.fromRGB(255, 255, 255)
		else
			carryingLabel.Text = "Carrying: nothing"
			carryingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	updateCarrying()
	player:GetAttributeChangedSignal("CarryingItemName"):Connect(updateCarrying)
end

return Hud
