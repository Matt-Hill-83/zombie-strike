local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = ReplicatedStorage.Items

local function quick(type, instanceType, patch)
	return function(name, codename)
		if codename == nil then
			codename = name:gsub(" ", "")
		end

		local data = {
			Name = name,
			Type = type,
		}

		local item = Items[instanceType .. "_" .. codename]
		patch(data, item)
		return data
	end
end

local face = quick("Face", "Face", function(data, item)
	data.Instance = item.Face
end)

local particle = quick("Particle", "Particle", function(data, item)
	data.Instance = item.Contents
	data.Image = item.Image
end)

local lowTier = quick("LowTier", "Bundle", function(data, item)
	data.Instance = item
end)

local highTier = quick("HighTier", "Bundle", function(data, item)
	data.Instance = item
end)

-- DON'T REORDER THIS LIST!
-- ALWAYS PUT NEW COSMETICS AT THE END!
-- DATA IS SAVED AS INDEXES!
return {
	face("Chill"),
	lowTier("Doge"),
	highTier("Ud'zal", "Udzal"),
	particle("Fire"),
	lowTier("Oof"),
	particle("Balls"),
	face("Err"),
	face("Shiny Teeth"),
	face("Super Super Happy Face", "DevFace"),
	face("Friendly Smile"),
	face(":3", "Cat"),
	face("Prankster"),
	face("Bandage"),
	face("Skeptic"),
	face("Blizzard Beast Mode"),
	face("Golden Shiny Teeth"),
	face("Goofball"),
	face("Freckled Cheeks"),
	face("Zorgo"),
	face("Monarch Butterfly Smile", "Butterfly"),
	face("Yum"),
	highTier("Light Dominus: the God", "God1"),
	highTier("Thanoid"),
	lowTier("Valkyrian"),
	lowTier("Skeleton"),
}