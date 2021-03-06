local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CoreData = require(ReplicatedStorage.Core.CoreData)
local DataStore2 = require(ServerScriptService.Vendor.DataStore2)
local MockPlayer = require(ReplicatedStorage.Core.MockData.MockPlayer)
local Promise = require(ReplicatedStorage.Core.Promise)

local Migrations = ServerScriptService.Shared.Migrations

local FORCE_MOCK_DATA = false

DataStore2.Combine("DATA", "Inventory", "Version")

local Data = {}

local baseMockPlayer = MockPlayer()

local migrated = {}

local function migrateData(player)
	local versionStore = DataStore2("Version", player)

	-- Versions didn't save until now
	local version = versionStore:Get()

	if version == nil and DataStore2("Inventory", player):Get() ~= nil then
		print("💾" .. player.Name .. " data before version were added")
		version = 1
	elseif version == nil then
		version = baseMockPlayer.Version
	end

	if version < baseMockPlayer.Version then
		print("💾" .. player.Name .. " data out of date, using version " .. version)

		for migrate = version, baseMockPlayer.Version - 1 do
			require(Migrations[migrate])(player)
		end

		print("💾" .. player.Name .. " migration finished")
	end

	versionStore:Set(baseMockPlayer.Version)
end

function Data.GetPlayerData(player, key)
	if CoreData.Equippable[key] then
		local inventory = Data.GetPlayerData(player, "Inventory")
		local equipped = Data.GetPlayerData(player, "Equipped" .. key)

		return inventory[equipped]
	elseif baseMockPlayer[key] ~= nil then
		DataStore2.Combine("DATA", key)

		if migrated[player] then
			migrated[player]:await()
		end

		-- Check migrations
		if key ~= "Version" and not migrated[player] then
			-- TODO: Cancel if the player leaves
			migrated[player] = Promise.promisify(migrateData)(player)
			migrated[player]:awaitValue()
		end

		local dataStore = DataStore2(key, player)

		-- BeforeInitialGet doesn't work well with combined stores
		-- if key == "Inventory" then
			-- dataStore:BeforeInitialGet(Loot.DeserializeTable)
			-- dataStore:BeforeSave(Loot.SerializeTable)
		-- end

		local mockPlayer = MockPlayer()
		local default = mockPlayer[key]
		if default == mockPlayer.None then
			default = nil
		end

		if RunService:IsStudio() and FORCE_MOCK_DATA then
			return default, dataStore
		end

		return dataStore:Get(default), dataStore
	else
		error("unknown data key " .. key)
	end
end

Data.GetPlayerDataAsync = Promise.promisify(Data.GetPlayerData)

Players.PlayerRemoving:connect(function(player)
	migrated[player] = nil
end)

return Data
