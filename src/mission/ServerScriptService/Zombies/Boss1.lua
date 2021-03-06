local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Dungeon = require(ReplicatedStorage.Libraries.Dungeon)
local Equip = require(ServerScriptService.Shared.Ruddev.Equip)
local FastSpawn = require(ReplicatedStorage.Core.FastSpawn)
local TakeDamage = require(ServerScriptService.Shared.TakeDamage)
local Zombie = require(script.Parent.Zombie)

local Assets = ReplicatedStorage.Assets.Campaign.Campaign1.Boss
local Remotes = ReplicatedStorage.Remotes.CityBoss

local Boulder = Assets.Boulder

local HitByBoulder = Remotes.HitByBoulder
local HitBySlam = Remotes.HitBySlam
local ThrowBoulder = Remotes.ThrowBoulder

local BOSS_DEATH_DELAY = 4.5

local CityBoss = {}
CityBoss.__index = CityBoss

CityBoss.BoulderDamage = {
	{ 50, 2 },
	{ 110, 4 },
	{ 190, 4 },
	{ 600, 5 },
	{ 1100, 8 },
}

CityBoss.SlamCount = { 2, 3, 4, 5, 6 }

CityBoss.SlamDamage = {
	{ 15, 1.5 },
	{ 90, 3 },
	{ 190, 4 },
	{ 600, 5 },
	{ 1100, 8 },
}

CityBoss.SlamInterval = { 1.5, 1.3, 1.1, 1.1, 1.1 }
CityBoss.SummonCount = { 3, 4, 7, 8, 9 }

CityBoss.Name = "Giga Zombie"
CityBoss.Model = "Boss"

function CityBoss.new()
	return setmetatable({
		zombiesSummoned = {},
	}, CityBoss)
end

function CityBoss.GetDeathSound()
	return SoundService.ZombieSounds["1"].Boss.Death
end

function CityBoss:AfterDeath()
	for _, zombie in pairs(self.zombiesSummoned) do
		FastSpawn(function()
			zombie:Die()
		end)
	end

	self.instance.Humanoid:LoadAnimation(
		ReplicatedStorage.Assets.Campaign.Campaign1.Boss.DeathAnimation
	):Play()

	wait(BOSS_DEATH_DELAY)

	self:Destroy()
end

function CityBoss:AfterSpawn()
	local instance = self.instance
	instance.PrimaryPart.Anchored = true

	self.boulderTossAnimation = instance.Humanoid:LoadAnimation(Assets.BoulderTossAnimation)
	self.boulderTossAnimation.KeyframeReached:connect(function()
		self:RockTossThrow()
	end)

	self.summonZombieAnimation = instance.Humanoid:LoadAnimation(Assets.SummonZombieAnimation)
	self.summonZombieAnimation.KeyframeReached:connect(function()
		self:SummonZombies()
	end)

	HitByBoulder.OnServerEvent:connect(function(player)
		local character = player.Character
		if character then
			local damage = self:GetDamageAgainstConstant(
				player,
				unpack(CityBoss.BoulderDamage[Dungeon.GetDungeonData("Difficulty")])
			)

			TakeDamage(player, damage)
		end
	end)

	HitBySlam.OnServerEvent:connect(function(player)
		local character = player.Character
		if character then
			local damage = self:GetDamageAgainstConstant(
				player,
				unpack(CityBoss.SlamDamage[Dungeon.GetDungeonData("Difficulty")])
			)

			TakeDamage(player, damage)
		end
	end)
end

function CityBoss.InitializeAI() end

function CityBoss:InitializeBossAI(room)
	self.bossRoom = room

	local currentSequence = math.random(1, #CityBoss.AttackSequence)

	wait(1.5)

	while self.alive do
		CityBoss.AttackSequence[currentSequence](self)
		currentSequence = (currentSequence % #CityBoss.AttackSequence) + 1
		wait(4)
	end
end

function CityBoss:RockTossBegin()
	local rockPickup = SoundService.ZombieSounds["1"].Boss.RockPickup:Clone()
	rockPickup.PlayOnRemove = true
	rockPickup.Parent = Workspace
	rockPickup:Destroy()

	local boulderModel = Instance.new("Model")

	local boulder = Boulder:Clone()
	boulder.Transparency = 1
	boulder.Parent = boulderModel

	boulderModel.PrimaryPart = boulder
	boulderModel.Parent = self.instance

	Equip(boulderModel, self.instance.UpperTorso)
	self.boulder = boulderModel

	TweenService:Create(
		boulder,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transparency = 0 }
	):Play()

	self.boulderTossAnimation:Play()
end

function CityBoss:RockTossThrow()
	local alivePositions = {}
	local deadPositions = {}

	for _, player in pairs(Players:GetPlayers()) do
		local root = player.Character and player.Character.PrimaryPart
		if root then
			if player.Character.Humanoid.Health > 0 then
				table.insert(alivePositions, root.Position)
			else
				table.insert(deadPositions, root.Position)
			end
		end
	end

	local position

	if #alivePositions > 0 then
		position = alivePositions[math.random(#alivePositions)]
	elseif #deadPositions > 0 then
		position = deadPositions[math.random(#deadPositions)]
	else
		warn("no dead or alive positions")
		self.boulder:Destroy()
		return
	end

	ThrowBoulder:FireAllClients(self.boulder, position)
	Debris:AddItem(self.boulder)
end

function CityBoss.Slam()
	local difficulty = Dungeon.GetDungeonData("Difficulty")
	HitBySlam:FireAllClients()
	wait(CityBoss.SlamInterval[difficulty] * CityBoss.SlamCount[difficulty])
end

function CityBoss:SummonZombiesBegin()
	self.summonZombieAnimation:Play()
end

function CityBoss:SummonZombies()
	local amountToSummon = CityBoss.SummonCount[Dungeon.GetDungeonData("Difficulty")]

	local zombieSummon = self.bossRoom.ZombieSummon
	local basePosition = zombieSummon.Position
	local sizeX, sizeZ = zombieSummon.Size.X, zombieSummon.Size.Z

	for _ = 1, amountToSummon - #self.zombiesSummoned do
		delay(math.random(30, 100) / 60, function()
			if not self.alive then return end

			local x = math.random(-sizeX / 2, sizeX / 2)
			local z = math.random(-sizeZ / 2, sizeZ / 2)

			local position = basePosition + Vector3.new(x, 0, z)

			local zombie = Zombie.new("Common", Dungeon.RNGZombieLevel())

			table.insert(self.zombiesSummoned, zombie)

			zombie.Died:connect(function()
				for index, otherZombie in pairs(self.zombiesSummoned) do
					if otherZombie == zombie then
						table.remove(self.zombiesSummoned, index)
					end
				end
			end)

			zombie.GetXP = function() return 0 end
			zombie:Spawn(position)
			zombie:Aggro()
		end)
	end
end

CityBoss.AttackSequence = {
	CityBoss.RockTossBegin,
	CityBoss.Slam,
	CityBoss.RockTossBegin,
	CityBoss.SummonZombiesBegin,
}

return CityBoss
