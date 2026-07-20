local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared.Configs.ObbyConfig)

local KillBrickService = {}

local function isDeathPart(name: string): boolean
	return name == "DeathParts" or name == "DeathPart" or name == "KillBrick" or name == "Lava"
end

function KillBrickService.init()
end

function KillBrickService.start()
	CollectionService:GetInstanceAddedSignal(ObbyConfig.KillBrickTag):Connect(KillBrickService.bindKillBrick)
	for _, instance in ipairs(CollectionService:GetTagged(ObbyConfig.KillBrickTag)) do
		KillBrickService.bindKillBrick(instance)
	end

	Workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") and isDeathPart(descendant.Name) then
			KillBrickService.bindKillBrick(descendant)
		end
	end)

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("BasePart") and isDeathPart(descendant.Name) then
			KillBrickService.bindKillBrick(descendant)
		end
	end
end

function KillBrickService.bindKillBrick(instance: Instance)
	if not instance:IsA("BasePart") then return end

	local part = instance :: BasePart
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end)
end

return KillBrickService
