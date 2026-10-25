-- Per-player state: cash (via leaderstats), carried item, owned upgrades.
-- Plot ownership/earnings live in PlotService, not here, since the plot
-- Parts are shared physical objects in Workspace, not per-player data.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local PlayerData = {}

type State = {
	Carrying: string?,
	OwnedUpgrades: { [string]: boolean },
}

local state: { [number]: State } = {}

local function getState(player: Player): State?
	return state[player.UserId]
end

function PlayerData.init(player: Player)
	state[player.UserId] = {
		Carrying = nil,
		OwnedUpgrades = {},
	}

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = Config.Player.StartingCash
	cash.Parent = leaderstats
end

function PlayerData.remove(player: Player)
	state[player.UserId] = nil
end

function PlayerData.getCarrying(player: Player): string?
	local s = getState(player)
	return s and s.Carrying
end

function PlayerData.setCarrying(player: Player, itemId: string?)
	local s = getState(player)
	if not s then
		return
	end
	s.Carrying = itemId
	player:SetAttribute("CarryingItemName", itemId)
end

function PlayerData.getCash(player: Player): number
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	return (cash :: IntValue?) and cash.Value or 0
end

function PlayerData.addCash(player: Player, amount: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash") :: IntValue?
	if cash then
		cash.Value += amount
	end
end

function PlayerData.hasUpgrade(player: Player, upgradeId: string): boolean
	local s = getState(player)
	return s ~= nil and s.OwnedUpgrades[upgradeId] == true
end

function PlayerData.grantUpgrade(player: Player, upgradeId: string)
	local s = getState(player)
	if s then
		s.OwnedUpgrades[upgradeId] = true
	end
end

function PlayerData.getOwnedUpgrades(player: Player): { [string]: boolean }
	local s = getState(player)
	return s and s.OwnedUpgrades or {}
end

-- Resets WalkSpeed to base, then reapplies every owned upgrade. Call this on
-- every CharacterAdded so upgrades survive respawning.
function PlayerData.applyUpgrades(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = Config.Player.BaseWalkSpeed

	local owned = PlayerData.getOwnedUpgrades(player)
	for upgradeId in owned do
		local upgrade = Config.Upgrades[upgradeId]
		if upgrade and upgrade.statKey == "WalkSpeed" then
			humanoid.WalkSpeed += upgrade.delta
		end
	end
end

return PlayerData
