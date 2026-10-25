-- Owns the 4 physical plot slots in Workspace.Base.Plots. Slot state
-- (who placed what, how much it has earned) lives here rather than in
-- PlayerData because the plots are shared physical Parts, not per-player
-- data — only one player can occupy a given slot at a time.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local PlotService = {}

type Slot = {
	part: BasePart,
	prompt: ProximityPrompt,
	ownerId: number?,
	itemId: string?,
	accrued: number,
}

local slots: { Slot } = {}

local function refreshPromptText(slot: Slot)
	if slot.itemId then
		local itemConfig = Config.Items[slot.itemId]
		slot.prompt.ObjectText = itemConfig.displayName
		slot.prompt.ActionText = "Occupied"
		slot.prompt.Enabled = false
	else
		slot.prompt.ObjectText = "Empty Plot"
		slot.prompt.ActionText = "Place Item"
		slot.prompt.Enabled = true
	end
end

local function setupSlot(plotPart: BasePart): Slot
	local prompt = Instance.new("ProximityPrompt")
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.Parent = plotPart

	local slot: Slot = {
		part = plotPart,
		prompt = prompt,
		ownerId = nil,
		itemId = nil,
		accrued = 0,
	}
	refreshPromptText(slot)

	prompt.Triggered:Connect(function(player: Player)
		if slot.itemId ~= nil then
			return
		end

		local carrying = PlayerData.getCarrying(player)
		if not carrying then
			return
		end

		slot.ownerId = player.UserId
		slot.itemId = carrying
		slot.accrued = 0
		PlayerData.setCarrying(player, nil)
		refreshPromptText(slot)
	end)

	return slot
end

function PlotService.start()
	local base = Workspace:WaitForChild("Base")
	local plotsFolder = base:WaitForChild("Plots")

	for i = 1, Config.Economy.PlotCount do
		local plotPart = plotsFolder:FindFirstChild("PlotSlot" .. i)
		if plotPart and plotPart:IsA("BasePart") then
			slots[i] = setupSlot(plotPart)
		else
			warn("PlotService: missing PlotSlot" .. i)
		end
	end
end

-- Called once per economy tick with the elapsed seconds.
function PlotService.tick(dt: number)
	for _, slot in slots do
		if slot.itemId then
			local itemConfig = Config.Items[slot.itemId]
			slot.accrued += itemConfig.cashPerSecond * dt
		end
	end
end

-- Empties every slot owned by `player`, returning the total accrued cash.
function PlotService.collectForPlayer(player: Player): number
	local total = 0
	for _, slot in slots do
		if slot.ownerId == player.UserId and slot.itemId then
			total += slot.accrued
			slot.accrued = 0
			slot.itemId = nil
			slot.ownerId = nil
			refreshPromptText(slot)
		end
	end
	return math.floor(total)
end

-- Frees any slots owned by a player who is leaving, so they don't stay
-- stuck "occupied" forever with no one able to collect them.
function PlotService.releasePlayerPlots(player: Player)
	for _, slot in slots do
		if slot.ownerId == player.UserId then
			slot.itemId = nil
			slot.ownerId = nil
			slot.accrued = 0
			refreshPromptText(slot)
		end
	end
end

return PlotService
