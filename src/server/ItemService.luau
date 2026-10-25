-- Wires a ProximityPrompt onto each pedestal in Workspace.House.Pedestals.
-- Stealing hides the pedestal and marks the player as carrying that item;
-- it respawns after Config.Items[id].respawnTime.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local ItemService = {}

local function setupPedestal(pedestal: BasePart, itemConfig: Config.ItemConfig)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Steal"
	prompt.ObjectText = string.format(
		"%s (%s) — $%d/s",
		itemConfig.displayName,
		itemConfig.rarity,
		itemConfig.cashPerSecond
	)
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 8
	prompt.Parent = pedestal

	local available = true

	local function respawn()
		available = true
		pedestal.Transparency = 0
		pedestal.CanCollide = true
		prompt.Enabled = true
	end

	prompt.Triggered:Connect(function(player: Player)
		if not available then
			return
		end
		if PlayerData.getCarrying(player) ~= nil then
			return
		end

		available = false
		pedestal.Transparency = 1
		pedestal.CanCollide = false
		prompt.Enabled = false

		PlayerData.setCarrying(player, itemConfig.id)

		task.delay(itemConfig.respawnTime, respawn)
	end)
end

function ItemService.start()
	local house = Workspace:WaitForChild("House")
	local pedestals = house:WaitForChild("Pedestals")

	for _, pedestal in pedestals:GetChildren() do
		local itemConfig = Config.Items[pedestal.Name]
		if itemConfig and pedestal:IsA("BasePart") then
			setupPedestal(pedestal, itemConfig)
		else
			warn("ItemService: no Config.Items entry for pedestal '" .. pedestal.Name .. "'")
		end
	end
end

return ItemService
