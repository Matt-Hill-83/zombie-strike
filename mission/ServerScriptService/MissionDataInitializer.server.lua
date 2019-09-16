local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArmorScaling = require(ReplicatedStorage.Core.ArmorScaling)
local Data = require(ReplicatedStorage.Core.Data)
local Dungeon = require(ReplicatedStorage.Libraries.Dungeon)
local Loot = require(ReplicatedStorage.Core.Loot)
local Promise = require(ReplicatedStorage.Core.Promise)
local XP = require(ReplicatedStorage.Core.XP)

local UpdateEquipped = ReplicatedStorage.Remotes.UpdateEquipped

local function numberValue(name, value, playerData)
	local instance = Instance.new("NumberValue")
	instance.Name = name
	instance.Value = value
	instance.Parent = playerData
	return instance
end

-- TODO: initialize stuff for LootInfoButton
Players.PlayerAdded:connect(function(player)
	Promise.all({
		Data.GetPlayerDataAsync(player, "Armor"):andThen(Loot.Serialize),
		Data.GetPlayerDataAsync(player, "Helmet"):andThen(Loot.Serialize),
		Data.GetPlayerDataAsync(player, "Weapon"):andThen(Loot.Serialize),
	}):andThen(function(equipped)
		UpdateEquipped:FireClient(player, unpack(equipped))
	end)

	local playerData = Instance.new("Folder")
	playerData.Name = "PlayerData"

	local level = Data.GetPlayerData(player, "Level")
	numberValue("Level", level, playerData)

	local xp = Data.GetPlayerData(player, "XP")
	numberValue("XP", xp, playerData)

	numberValue("GoldScale", 1, playerData)
	numberValue("XPScale", 1, playerData)

	playerData.Parent = player

	local armor = Data.GetPlayerData(player, "Armor")
	local armorHealth = ArmorScaling.ArmorHealth(armor.Level, armor.Rarity)
	local armorModel = Data.GetModel(armor)

	local helmet = Data.GetPlayerData(player, "Helmet")
	local helmetHealth = ArmorScaling.HelmetHealth(helmet.Level, helmet.Rarity)
	local helmetModel = Data.GetModel(helmet)

	local function characterAdded(character)
		local health = XP.HealthForLevel(level) + armorHealth + helmetHealth
		character.Humanoid.MaxHealth = health
		character.Humanoid.Health = health

		armorModel.Shirt:Clone().Parent = character
		armorModel.Pants:Clone().Parent = character

		helmetModel.Hat:Clone().Parent = character
	end

	if player.Character then
		characterAdded(player.Character)
	end

	player.CharacterAdded:connect(characterAdded)
end)

local function clientDungeonKey(name, type)
	local instance = Instance.new(type or "NumberValue")
	instance.Name = name

	return function(value)
		instance.Value = value
		instance.Parent = ReplicatedStorage.ClientDungeonData
	end
end

clientDungeonKey("Members")(#Dungeon.GetDungeonData("Members"))
clientDungeonKey("Campaign")(Dungeon.GetDungeonData("Campaign"))
clientDungeonKey("Hardcore", "BoolValue")(Dungeon.GetDungeonData("Hardcore"))
