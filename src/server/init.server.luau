local Players = game:GetService("Players")

local PlayerData = require(script.PlayerData)
local ItemService = require(script.ItemService)
local PlotService = require(script.PlotService)
local EconomyLoop = require(script.EconomyLoop)
local BankService = require(script.BankService)
local UpgradeService = require(script.UpgradeService)

ItemService.start()
PlotService.start()
EconomyLoop.start()
BankService.start()
UpgradeService.start()

Players.PlayerAdded:Connect(function(player: Player)
	PlayerData.init(player)

	player.CharacterAdded:Connect(function(character: Model)
		-- Dying (or respawning) drops whatever was being carried and
		-- reapplies any owned upgrades, since WalkSpeed resets on spawn.
		PlayerData.setCarrying(player, nil)
		PlayerData.applyUpgrades(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	PlotService.releasePlayerPlots(player)
	PlayerData.remove(player)
end)
