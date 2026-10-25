-- Gives every player their own personal base: clones the 10-pedestal
-- template (ServerStorage.Templates.PlayerBase — 2 rows of 5 facing
-- each other across a walkway) into a reserved slot in the world, and
-- owns all placement/earning/collection logic for that player's
-- pedestals exclusively. Only the owning player can use their own
-- pedestals; nobody else can place items on, or collect from, a base
-- that isn't theirs.

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local BaseService = {}

local PEDESTAL_COUNT = 10
local SLOT_SPACING = 32
local SLOT_ORIGIN = Vector3.new(60, 0, 0)

type PedestalSlot = {
	part: BasePart,
	prompt: ProximityPrompt,
	itemId: string?,
	accrued: number,
}

type BaseEntry = {
	instance: Instance,
	slotIndex: number,
	pedestals: { PedestalSlot },
	entrancePosition: Vector3,
}

local bases: { [number]: BaseEntry } = {} -- keyed by player.UserId
local freedSlots: { number } = {}
local nextSlotIndex = 0
local template: Instance
local baseContainer: Folder

local function allocateSlot(): number
	if #freedSlots > 0 then
		return table.remove(freedSlots) :: number
	end
	local index = nextSlotIndex
	nextSlotIndex += 1
	return index
end

local function slotToOffset(slotIndex: number): Vector3
	return SLOT_ORIGIN + Vector3.new(slotIndex * SLOT_SPACING, 0, 0)
end

-- All template geometry is axis-aligned, so moving a clone is just
-- shifting every descendant Part's Position by a flat offset.
local function offsetDescendants(root: Instance, delta: Vector3)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Position += delta
		end
	end
end

local function refreshPedestalPrompt(slot: PedestalSlot)
	if slot.itemId then
		local itemConfig = Config.Items[slot.itemId]
		slot.prompt.ObjectText = itemConfig.displayName
		slot.prompt.ActionText = "Occupied"
		slot.prompt.Enabled = false
	else
		slot.prompt.ObjectText = "Empty Pedestal"
		slot.prompt.ActionText = "Place Item"
		slot.prompt.Enabled = true
	end
end

local function setupPedestal(part: BasePart, owner: Player): PedestalSlot
	local prompt = Instance.new("ProximityPrompt")
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.Parent = part

	local slot: PedestalSlot = {
		part = part,
		prompt = prompt,
		itemId = nil,
		accrued = 0,
	}
	refreshPedestalPrompt(slot)

	prompt.Triggered:Connect(function(triggeringPlayer: Player)
		if triggeringPlayer ~= owner then
			return
		end
		if slot.itemId ~= nil then
			return
		end

		local carrying = PlayerData.getCarrying(triggeringPlayer)
		if not carrying then
			return
		end

		slot.itemId = carrying
		slot.accrued = 0
		PlayerData.setCarrying(triggeringPlayer, nil)
		refreshPedestalPrompt(slot)
	end)

	return slot
end

function BaseService.start()
	template = ServerStorage:WaitForChild("Templates"):WaitForChild("PlayerBase")

	baseContainer = Instance.new("Folder")
	baseContainer.Name = "PlayerBases"
	baseContainer.Parent = Workspace
end

function BaseService.createForPlayer(player: Player)
	local slotIndex = allocateSlot()
	local offset = slotToOffset(slotIndex)

	local clone = template:Clone()
	clone.Name = "Base_" .. player.UserId
	offsetDescendants(clone, offset)
	clone.Parent = baseContainer

	local pedestalsFolder = clone:WaitForChild("Pedestals")
	local pedestals: { PedestalSlot } = {}
	for i = 1, PEDESTAL_COUNT do
		local part = pedestalsFolder:FindFirstChild("Pedestal" .. i)
		if part and part:IsA("BasePart") then
			pedestals[i] = setupPedestal(part, player)
		else
			warn("BaseService: missing Pedestal" .. i .. " in template")
		end
	end

	bases[player.UserId] = {
		instance = clone,
		slotIndex = slotIndex,
		pedestals = pedestals,
		entrancePosition = offset + Vector3.new(0, 5, 0),
	}
end

function BaseService.removeForPlayer(player: Player)
	local entry = bases[player.UserId]
	if not entry then
		return
	end

	entry.instance:Destroy()
	table.insert(freedSlots, entry.slotIndex)
	bases[player.UserId] = nil
end

function BaseService.getEntrancePosition(player: Player): Vector3?
	local entry = bases[player.UserId]
	return entry and entry.entrancePosition
end

-- Called once per economy tick with the elapsed seconds.
function BaseService.tick(dt: number)
	for _, entry in bases do
		for _, slot in entry.pedestals do
			if slot.itemId then
				local itemConfig = Config.Items[slot.itemId]
				slot.accrued += itemConfig.cashPerSecond * dt
			end
		end
	end
end

-- Empties every occupied pedestal in `player`'s own base, returning
-- the total accrued cash.
function BaseService.collectForPlayer(player: Player): number
	local entry = bases[player.UserId]
	if not entry then
		return 0
	end

	local total = 0
	for _, slot in entry.pedestals do
		if slot.itemId then
			total += slot.accrued
			slot.accrued = 0
			slot.itemId = nil
			refreshPedestalPrompt(slot)
		end
	end
	return math.floor(total)
end

return BaseService
