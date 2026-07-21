local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Networker = require(Packages:WaitForChild("networker"))

local VFXController = {}
local localPlayer = Players.LocalPlayer
local networkerClient

function VFXController.init()
	networkerClient = Networker.client.new("VFXNetwork", VFXController)
end

function VFXController.start()
	localPlayer.CharacterAdded:Connect(function(char)
		task.defer(function()
			VFXController.playSpawnVFX()
		end)
	end)

	if localPlayer.Character then
		task.defer(function()
			VFXController.playSpawnVFX()
		end)
	end
end

function VFXController.playSpawnVFX(key: string?, ...: any)
	local character = localPlayer.Character
	if not character then return end

	local fxFolder = ReplicatedStorage:FindFirstChild("FX")
	if not fxFolder then return end

	local spawnEffectModule = fxFolder:FindFirstChild("SpawnEffect")
	if not spawnEffectModule or not spawnEffectModule:IsA("ModuleScript") then return end

	local success, spawnEffect = pcall(require, spawnEffectModule)
	if success then
		if typeof(spawnEffect) == "table" and typeof(spawnEffect.play) == "function" then
			spawnEffect.play(character)
		elseif typeof(spawnEffect) == "function" then
			spawnEffect(character)
		end
	end
end

return VFXController
