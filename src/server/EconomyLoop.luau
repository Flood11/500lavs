-- Single server-wide tick that accrues cash into every occupied plot slot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local PlotService = require(script.Parent.PlotService)

local EconomyLoop = {}

function EconomyLoop.start()
	task.spawn(function()
		while true do
			task.wait(Config.Economy.TickInterval)
			PlotService.tick(Config.Economy.TickInterval)
		end
	end)
end

return EconomyLoop
