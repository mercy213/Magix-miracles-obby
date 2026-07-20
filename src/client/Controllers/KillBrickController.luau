local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared.Configs.ObbyConfig)

local KillBrickController = {}
local localPlayer = Players.LocalPlayer

local function isDeathPart(name: string): boolean
	return name == "DeathParts" or name == "DeathPart" or name == "KillBrick" or name == "Lava"
end

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

	Workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") and isDeathPart(descendant.Name) then
			bindLocalKill(descendant)
		end
	end)

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("BasePart") and isDeathPart(descendant.Name) then
			bindLocalKill(descendant)
		end
	end
end

return KillBrickController
