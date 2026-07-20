local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared.Configs.ObbyConfig)

local LevelService = {}
local maxLevel = 1
local obbyFolder: Folder?

function LevelService.init()
end

function LevelService.start()
	obbyFolder = Workspace:WaitForChild(ObbyConfig.ObbyFolderName, 10) :: Folder?
	LevelService.recalculateMaxLevel()

	if obbyFolder then
		obbyFolder.ChildAdded:Connect(function()
			LevelService.recalculateMaxLevel()
		end)
		obbyFolder.ChildRemoved:Connect(function()
			LevelService.recalculateMaxLevel()
		end)
	end
end

function LevelService.recalculateMaxLevel()
	local highest = 1
	if obbyFolder then
		for _, child in ipairs(obbyFolder:GetChildren()) do
			local num = tonumber(string.match(child.Name, "%d+"))
			if num and num > highest then
				highest = num
			end
		end
	end
	maxLevel = highest
end

function LevelService.getMaxLevel(): number
	return maxLevel
end

function LevelService.getLevelFolder(levelNum: number): Instance?
	if not obbyFolder then return nil end
	return obbyFolder:FindFirstChild(`Level{levelNum}`) or obbyFolder:FindFirstChild(tostring(levelNum))
end

return LevelService
