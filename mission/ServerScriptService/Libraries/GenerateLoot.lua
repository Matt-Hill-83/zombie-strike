local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Campaigns = require(ReplicatedStorage.Core.Campaigns)
local Data = require(ReplicatedStorage.Core.Data)
local Dungeon = require(ReplicatedStorage.Libraries.Dungeon)
local GamePassDictionary = require(ReplicatedStorage.Core.GamePassDictionary)
local GamePasses = require(ReplicatedStorage.Core.GamePasses)
local GunScaling = require(ReplicatedStorage.Core.GunScaling)
local InventorySpace = require(ReplicatedStorage.Core.InventorySpace)
local Loot = require(ReplicatedStorage.Core.Loot)
local Promise = require(ReplicatedStorage.Core.Promise)

local FREE_EPIC_AFTER = 0
local WEAPON_DROP_RATE = 0.67

local RARITY_PERCENTAGES = {
	{ 0.5, 5 },
	{ 7.5, 4 },
	{ 17, 3 },
	{ 35, 2 },
	{ 40, 1 },
}

local RARITY_PERCENTAGES_LEGENDARY = {
	{ 5, 5 },
	{ 6.38, 4 },
	{ 16, 3 },
	{ 34, 2 },
	{ 39, 1 },
}

local function getModel(type, rarity)
	local loot = Dungeon.GetDungeonData("CampaignInfo").Loot
	local models = assert(loot[type], "No loot for " .. type)[Loot.Rarities[rarity].Name]
	return models[math.random(#models)]
end

local function nextDungeonLevel()
	local difficulty = Dungeon.GetDungeonData("Difficulty")
	local difficulties = Dungeon.GetDungeonData("CampaignInfo").Difficulties

	if #difficulties == difficulty then
		-- Last difficulty
		local campaign = Dungeon.GetDungeonData("Campaign")

		if #Campaigns == campaign then
			-- Last campaign!
			return nil
		else
			-- There's a next campaign
			return Campaigns[campaign + 1].Difficulties[1].MinLevel
		end
	else
		-- Not last difficulty
		return difficulties[difficulty + 1].MinLevel
	end
end

local function getLootLevel(player)
	local playerLevel = Data.GetPlayerData(player, "Level")

	local dungeonLevelMin = Dungeon.GetDungeonData("DifficultyInfo").MinLevel

	local nextDungeon = nextDungeonLevel() or dungeonLevelMin + 4

	return math.random(dungeonLevelMin, math.min(playerLevel, nextDungeon))
end

local takenAdvantageOfFreeLoot = {}

local function getLootRarity(player)
	if Data.GetPlayerData(player, "DungeonsPlayed") == FREE_EPIC_AFTER
		and not takenAdvantageOfFreeLoot[player]
	then
		takenAdvantageOfFreeLoot[player] = true
		return 4
	end

	local legendaryBonus, legendaryBonusStore = Data.GetPlayerData(player, "LegendaryBonus")
	local moreLegendaries = GamePasses.PlayerOwnsPass(player, GamePassDictionary.MoreLegendaries)

	if not legendaryBonus
		and not takenAdvantageOfFreeLoot[player]
		and moreLegendaries
	then
		takenAdvantageOfFreeLoot[player] = true
		legendaryBonusStore:Set(true)
		return 5
	end

	local rng = Random.new()

	local rarityRng = rng:NextNumber() * 100

	local cumulative = 0
	for _, percent in ipairs(moreLegendaries and RARITY_PERCENTAGES_LEGENDARY or RARITY_PERCENTAGES) do
		if rarityRng <= cumulative + percent[1] then
			return percent[2]
		else
			cumulative = cumulative + percent[1]
		end
	end

	error("unreachable code! GenerateLoot did not give a rarity percent")
end

local function generateLootItem(player)
	local rng = Random.new()
	local level = getLootLevel(player)
	local rarity = getLootRarity(player)

	local uuid = HttpService:GenerateGUID(false):gsub("-", "")

	if takenAdvantageOfFreeLoot[player] or rng:NextNumber() <= WEAPON_DROP_RATE then
		local type = GunScaling.RandomType()

		local funny = rng:NextInteger(0, 35)

		local loot = {
			Type = type,
			Rarity = rarity,
			Level = level,

			Bonus = funny,
			Upgrades = 0,
			Favorited = false,

			Model = getModel(type, rarity),
			UUID = uuid,
		}

		return loot
	else
		local type

		if rng:NextNumber() >= 0.5 then
			type = "Armor"
		else
			type = "Helmet"
		end

		local loot = {
			Level = level,
			Rarity = rarity,
			Type = type,

			Upgrades = 0,
			Favorited = false,

			Model = getModel(type, rarity),
			UUID = uuid,
		}

		return loot
	end
end

local function getLootAmount(player)
	local amount = 1

	if Dungeon.GetDungeonData("Hardcore") then
		amount = amount + 1
	end

	if GamePasses.PlayerOwnsPass(player, GamePassDictionary.MoreLoot) then
		amount = amount + 1
	end

	return Promise.all({
		Data.GetPlayerDataAsync(player, "Inventory"),
		InventorySpace(player),
	}):andThen(function(data)
		local inventory, space = unpack(data)
		local difference = space - #inventory

		if amount > difference then
			return difference
		else
			return amount
		end
	end)
end

local function generateLoot(player)
	return getLootAmount(player):andThen(function(amount)
		local lootTable = {}

		for _ = 1, amount do
			table.insert(lootTable, Promise.promisify(generateLootItem)(player))
		end

		return Promise.all(lootTable)
	end)
end

return generateLoot
