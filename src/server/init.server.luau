local Players = game:GetService("Players")

local PlayerData = require(script.PlayerData)
local ItemService = require(script.ItemService)
local BaseService = require(script.BaseService)
local EconomyLoop = require(script.EconomyLoop)
local BankService = require(script.BankService)
local UpgradeService = require(script.UpgradeService)

ItemService.start()
BaseService.start()
EconomyLoop.start()
BankService.start()
UpgradeService.start()

local function onCharacterAdded(player: Player, character: Model)
	-- Dying (or respawning) drops whatever was being carried and
	-- reapplies any owned upgrades, since WalkSpeed resets on spawn.
	PlayerData.setCarrying(player, nil)
	PlayerData.applyUpgrades(player, character)

	-- Drop the player into their own base's walkway instead of the
	-- shared spawn every time they (re)spawn.
	local entrance = BaseService.getEntrancePosition(player)
	if entrance then
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		if humanoidRootPart then
			humanoidRootPart.CFrame = CFrame.new(entrance)
		end
	end
end

Players.PlayerAdded:Connect(function(player: Player)
	PlayerData.init(player)
	BaseService.createForPlayer(player)

	player.CharacterAdded:Connect(function(character: Model)
		onCharacterAdded(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	BaseService.removeForPlayer(player)
	PlayerData.remove(player)
end)
