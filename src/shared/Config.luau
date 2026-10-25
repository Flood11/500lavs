-- Single source of truth for tunable numbers. Keep this the only place
-- items/upgrades/economy values live so the loop is easy to retune later.

export type ItemConfig = {
	id: string,
	displayName: string,
	rarity: string,
	cashPerSecond: number,
	respawnTime: number,
}

export type UpgradeConfig = {
	id: string,
	displayName: string,
	cost: number,
	statKey: string,
	delta: number,
}

local Config = {}

Config.Player = {
	StartingCash = 0,
	BaseWalkSpeed = 16,
}

Config.Economy = {
	TickInterval = 1,
	PlotCount = 4,
}

Config.Rarity = {
	Common = Color3.fromRGB(255, 255, 255),
	Uncommon = Color3.fromRGB(0, 255, 80),
	Rare = Color3.fromRGB(0, 220, 255),
}

Config.Items = {
	Watch = {
		id = "Watch",
		displayName = "Gold Watch",
		rarity = "Common",
		cashPerSecond = 1,
		respawnTime = 15,
	},
	Vase = {
		id = "Vase",
		displayName = "Ming Vase",
		rarity = "Uncommon",
		cashPerSecond = 3,
		respawnTime = 20,
	},
	Painting = {
		id = "Painting",
		displayName = "Oil Painting",
		rarity = "Rare",
		cashPerSecond = 6,
		respawnTime = 30,
	},
} :: { [string]: ItemConfig }

Config.Upgrades = {
	WalkSpeed1 = {
		id = "WalkSpeed1",
		displayName = "Faster Shoes",
		cost = 100,
		statKey = "WalkSpeed",
		delta = 8,
	},
} :: { [string]: UpgradeConfig }

return Config
