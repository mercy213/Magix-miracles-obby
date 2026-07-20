local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared.Configs.ObbyConfig)

local KillBrickController = {}
local localPlayer = Players.LocalPlayer

function KillBrickController.init()
end

function KillBrickController.start()
	local function bindLocalKill(part: BasePart)
		part.Touched:Connect(function(hit)
			if hit.Parent == localPlayer.Character then
				local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					humanoid.Health = 0
				end
			end
		end)
	end

	CollectionService:GetInstanceAddedSignal(ObbyConfig.KillBrickTag):Connect(function(instance)
		if instance:IsA("BasePart") then bindLocalKill(instance) end
	end)

	for _, instance in ipairs(CollectionService:GetTagged(ObbyConfig.KillBrickTag)) do
		if instance:IsA("BasePart") then bindLocalKill(instance) end
	end
end

return KillBrickController
