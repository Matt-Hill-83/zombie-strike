local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Vendor.t)

local Easy = {
	Name = "Easy",
	Color = Color3.fromRGB(76, 209, 55),
}

local Medium = {
	Name = "Medium",
	Color = Color3.fromRGB(251, 197, 49),
}

local Hard = {
	Name = "Hard",
	Color = Color3.fromRGB(232, 65, 24),
}

local VeryHard = {
	Name = "Very Hard",
	Color = Color3.fromRGB(30, 55, 153),
}

local Extreme = {
	Name = "Extreme",
	Color = Color3.fromRGB(109, 35, 35),
}

local function range(start, finish)
	local range = {}

	for number = start, finish do
		table.insert(range, number)
	end

	return range
end

local function classicGuns(loot)
	local models = {
		Common = { 1 },
		Uncommon = { 2 },
		Rare = { 3 },
		Epic = { 4 },
		Legendary = { 5 },
	}

	local total = {
		Pistol = models,
		Rifle = models,
		SMG = models,
		Shotgun = models,
		Sniper = models,
	}

	for key, value in pairs(loot) do
		total[key] = value
	end

	return total
end

local lootRewardType = t.strictInterface({
	Common = t.array(t.number),
	Uncommon = t.array(t.number),
	Rare = t.array(t.number),
	Epic = t.array(t.number),
	Legendary = t.array(t.number),
})

local campaignsType = t.array(t.strictInterface({
	Name = t.string,
	Image = t.string,
	ZombieTypes = t.map(t.string, t.numberMin(1)),

	Difficulties = t.array(t.strictInterface({
		MinLevel = t.numberMin(1),
		Style = t.strictInterface({
			Name = t.string,
			Color = t.Color3,
		}),

		Gold = t.numberMin(1),
		Rooms = t.numberMin(1),
		XP = t.numberMin(1),
		ZombieSpawnRate = t.numberConstrained(0, 1),

		BossStats = t.strictInterface({
			Health = t.numberMin(1),
		}),
	})),

	Loot = t.strictInterface({
		Armor = lootRewardType,
		Helmet = lootRewardType,

		Pistol = lootRewardType,
		Rifle = lootRewardType,
		SMG = lootRewardType,
		Shotgun = lootRewardType,
		Sniper = lootRewardType,
	}),
}))

local Campaigns = {
	{
		Name = "Campaign A",
		Image = "rbxassetid://2278464",
		ZombieTypes = {
			Common = 3,
			Fast = 1,
			Strong = 1,
			Turret = 1,
		},

		Difficulties = {
			{
				MinLevel = 1,
				Style = Easy,

				Gold = 50,
				Rooms = 8,
				XP = 600,
				ZombieSpawnRate = 0.4,

				BossStats = {
					Health = 2250,
				},
			},

			{
				MinLevel = 6,
				Style = Medium,

				Gold = 120,
				Rooms = 10,
				XP = 1300,
				ZombieSpawnRate = 0.65,

				BossStats = {
					Health = 4200,
				},
			},

			{
				MinLevel = 12,
				Style = Hard,

				Gold = 370,
				Rooms = 12,
				XP = 3000,
				ZombieSpawnRate = 0.75,

				BossStats = {
					Health = 8400,
				},
			},

			{
				MinLevel = 18,
				Style = VeryHard,

				Gold = 800,
				Rooms = 14,
				XP = 4800,
				ZombieSpawnRate = 0.9,

				BossStats = {
					Health = 30000,
				},
			},

			{
				MinLevel = 24,
				Style = Extreme,

				Gold = 1900,
				Rooms = 16,
				XP = 10000,
				ZombieSpawnRate = 1,

				BossStats = {
					Health = 75000,
				},
			},
		},

		Loot = classicGuns({
			Armor = {
				Common = range(1, 7),
				Uncommon = range(8, 13),
				Rare = { 14 },
				Epic = { 15 },
				Legendary = { 16 },
			},

			Helmet = {
				Common = { 1 },
				Uncommon = { 2 },
				Rare = { 3 },
				Epic = { 4 },
				Legendary = { 5 },
			},
		}),
	},
}

assert(campaignsType(Campaigns))

return Campaigns
