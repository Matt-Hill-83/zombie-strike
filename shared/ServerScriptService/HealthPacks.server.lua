local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")

local Data = require(ReplicatedStorage.Core.Data)
local Equip = require(ServerScriptService.Shared.Ruddev.Equip)

local Effect = ReplicatedStorage.RuddevRemotes.Effect
local HealthPackAnimation = ReplicatedStorage.Assets.Animations.HealthPackAnimation

local COOLDOWN = 10
local HEAL_AMOUNT = 0.3

local healthPackCooldowns = {}

ReplicatedStorage.Remotes.HealthPack.OnServerEvent:connect(function(player)
	local character = player.Character
	if not character or character.Humanoid.Health <= 0 then return end

	if tick() - (healthPackCooldowns[player] or 0) > COOLDOWN then
		healthPackCooldowns[player] = tick()

		local healthPack = ReplicatedStorage.Items[
			"HealthPack" .. Data.GetPlayerData(
				player,
				"EquippedHealthPack"
			)
		]:Clone()

		healthPack.Parent = character
		Equip(healthPack, character.LeftHand)

		local humanoid = character.Humanoid
		local animation = humanoid:LoadAnimation(HealthPackAnimation)

		local healthPrime = SoundService.SFX.HealthPrime:Clone()
		local healthUse = SoundService.SFX.HealthUse:Clone()

		healthPrime.Parent = character.PrimaryPart
		healthPrime:Play()
		Debris:AddItem(healthPrime)

		healthUse.Parent = character.PrimaryPart
		Debris:AddItem(healthUse)

		animation.KeyframeReached:connect(function(name)
			if name == "Heal" then
				healthUse:Play()
				healthPack:Destroy()

				if humanoid.Health > 0 then
					humanoid.Health = humanoid.Health + humanoid.MaxHealth * HEAL_AMOUNT
					ReplicatedStorage.Remotes.HealthPack:FireClient(player)
				end

				Effect:FireAllClients("Shatter", character)
			end
		end)

		animation:Play()
	end
end)
