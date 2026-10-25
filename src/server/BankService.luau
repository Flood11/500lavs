-- ProximityPrompt on Workspace.Base.BankStall: collects a player's accrued
-- pedestal earnings (from their own personal base) into their spendable Cash.

local Workspace = game:GetService("Workspace")
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)

local BankService = {}

function BankService.start()
	local base = Workspace:WaitForChild("Base")
	local bankStall = base:WaitForChild("BankStall")

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect Earnings"
	prompt.ObjectText = "Bank"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.Parent = bankStall

	prompt.Triggered:Connect(function(player: Player)
		local collected = BaseService.collectForPlayer(player)
		if collected > 0 then
			PlayerData.addCash(player, collected)
		end
	end)
end

return BankService
