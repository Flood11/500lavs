-- ProximityPrompt on Workspace.Base.UpgradeStall: buys the one bare-bones
-- upgrade (WalkSpeed1). The prompt text is shared/global since cost doesn't
-- vary per player, but purchase is gated per-player via PlayerData.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local UpgradeService = {}

function UpgradeService.start()
	local base = Workspace:WaitForChild("Base")
	local upgradeStall = base:WaitForChild("UpgradeStall")

	local upgrade = Config.Upgrades.WalkSpeed1

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy"
	prompt.ObjectText = string.format("%s — $%d", upgrade.displayName, upgrade.cost)
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.Parent = upgradeStall

	prompt.Triggered:Connect(function(player: Player)
		if PlayerData.hasUpgrade(player, upgrade.id) then
			return
		end
		if PlayerData.getCash(player) < upgrade.cost then
			return
		end

		PlayerData.addCash(player, -upgrade.cost)
		PlayerData.grantUpgrade(player, upgrade.id)

		local character = player.Character
		if character then
			PlayerData.applyUpgrades(player, character)
		end
	end)
end

return UpgradeService
