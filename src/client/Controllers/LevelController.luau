local Players = game:GetService("Players")

local LevelController = {}
local localPlayer = Players.LocalPlayer

local loadedLevels = {}
local currentActiveLevel: number?
local currentModule: any?

function LevelController.init()
	local levelsFolder = script.Parent.Parent:FindFirstChild("Levels")
	if levelsFolder then
		for _, child in ipairs(levelsFolder:GetChildren()) do
			if child:IsA("ModuleScript") then
				local levelNum = tonumber(child.Name)
				if levelNum then
					local success, module = pcall(require, child)
					if success then
						loadedLevels[levelNum] = module
					end
				end
			end
		end
	end
end

function LevelController.start()
	local leaderstats = localPlayer:WaitForChild("leaderstats", 10)
	if leaderstats then
		local stageStat = leaderstats:WaitForChild("Stage", 10) :: IntValue?
		if stageStat then
			LevelController.switchLevel(stageStat.Value)
			stageStat.Changed:Connect(function(newValue)
				LevelController.switchLevel(newValue)
			end)
		end
	end
end

function LevelController.switchLevel(newLevel: number)
	if currentActiveLevel == newLevel then return end

	if currentModule and typeof(currentModule) == "table" and typeof(currentModule.onLeave) == "function" then
		pcall(currentModule.onLeave)
	end

	currentActiveLevel = newLevel
	currentModule = loadedLevels[newLevel]

	if currentModule and typeof(currentModule) == "table" and typeof(currentModule.onEnter) == "function" then
		pcall(currentModule.onEnter)
	end
end

return LevelController
