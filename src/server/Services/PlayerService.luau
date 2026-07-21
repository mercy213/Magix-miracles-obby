local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared.Configs.ObbyConfig)

local PlayerService = {}
local stageCache = {}

function PlayerService.init()
end

function PlayerService.start()
	Players.PlayerAdded:Connect(PlayerService.onPlayerAdded)
	Players.PlayerRemoving:Connect(PlayerService.onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(PlayerService.onPlayerAdded, player)
	end
end

function PlayerService.onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local stageStat = Instance.new("IntValue")
	stageStat.Name = "Stage"
	stageStat.Value = ObbyConfig.DefaultStage
	stageStat.Parent = leaderstats

	local attemptsStat = Instance.new("IntValue")
	attemptsStat.Name = "Attempts"
	attemptsStat.Value = 0
	attemptsStat.Parent = leaderstats

	leaderstats.Parent = player

	stageCache[player] = stageStat.Value

	stageStat.Changed:Connect(function(newValue)
		stageCache[player] = newValue
	end)

	local function bindCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			humanoid.Died:Connect(function()
				attemptsStat.Value += 1
			end)
		end
	end

	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		task.spawn(bindCharacter, player.Character)
	end
end

function PlayerService.onPlayerRemoving(player: Player)
	stageCache[player] = nil
end

function PlayerService.getStage(player: Player): number
	return stageCache[player] or ObbyConfig.DefaultStage
end

function PlayerService.setStage(player: Player, stage: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local stageStat = leaderstats:FindFirstChild("Stage") :: IntValue
		if stageStat then
			stageStat.Value = stage
		end
	end
end

return PlayerService
