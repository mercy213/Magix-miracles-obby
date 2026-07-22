local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared.Configs.ObbyConfig)

local PlayerService = {}
local stageCache = {}
local pendingRestartMenu = {}

local stageDataStore = DataStoreService:GetDataStore("ObbyStageDataStore_v1")
local restartMenuEvent: RemoteEvent

function PlayerService.init()
	restartMenuEvent = ReplicatedStorage:FindFirstChild("RestartMenuEvent") :: RemoteEvent
	if not restartMenuEvent then
		restartMenuEvent = Instance.new("RemoteEvent")
		restartMenuEvent.Name = "RestartMenuEvent"
		restartMenuEvent.Parent = ReplicatedStorage
	end

	restartMenuEvent.OnServerEvent:Connect(function(player: Player, action: string)
		if action == "Restart" then
			PlayerService.confirmRestart(player)
		elseif action == "Continue" then
			local devProdId = ObbyConfig.ContinueDevProductId
			if not devProdId or devProdId == 0 then
				PlayerService.confirmContinue(player)
			end
		elseif action == "CheckPrompt" then
			if pendingRestartMenu[player] then
				restartMenuEvent:FireClient(player, "PromptMenu", pendingRestartMenu[player])
			end
		end
	end)
end

function PlayerService.start()
	Players.PlayerAdded:Connect(PlayerService.onPlayerAdded)
	Players.PlayerRemoving:Connect(PlayerService.onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(PlayerService.onPlayerAdded, player)
	end

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerService.savePlayerData(player)
		end
	end)
end

function PlayerService.onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local defaultStage = ObbyConfig.DefaultStage or 0

	local stageStat = Instance.new("IntValue")
	stageStat.Name = "Stage"
	stageStat.Value = defaultStage
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

	local LevelService = require(script.Parent.LevelService)
	local maxLevel = LevelService.getMaxLevel()
	local key = "PlayerStage_" .. player.UserId

	local success, savedStage = pcall(function()
		return stageDataStore:GetAsync(key)
	end)

	if success and type(savedStage) == "number" then
		if savedStage >= maxLevel then
			stageStat.Value = defaultStage
			pcall(function()
				stageDataStore:RemoveAsync(key)
			end)
		elseif savedStage > defaultStage then
			stageStat.Value = savedStage
			pendingRestartMenu[player] = savedStage
		else
			stageStat.Value = defaultStage
		end
	else
		stageStat.Value = defaultStage
	end

	local function bindCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			humanoid.Died:Connect(function()
				attemptsStat.Value += 1
			end)
		end

		if pendingRestartMenu[player] then
			if humanoid then
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
				humanoid.JumpHeight = 0
			end
			task.spawn(function()
				task.wait(0.3)
				if pendingRestartMenu[player] and player.Parent then
					restartMenuEvent:FireClient(player, "PromptMenu", pendingRestartMenu[player])
				end
			end)
		end
	end

	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		task.spawn(bindCharacter, player.Character)
	end
end

function PlayerService.unlockPlayerMovement(player: Player)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.JumpHeight = 7.2
		end
	end
end

function PlayerService.confirmRestart(player: Player)
	pendingRestartMenu[player] = nil
	local defaultStage = ObbyConfig.DefaultStage or 0
	PlayerService.setStage(player, defaultStage)
	local key = "PlayerStage_" .. player.UserId
	pcall(function()
		stageDataStore:RemoveAsync(key)
	end)
	local CheckpointService = require(script.Parent.CheckpointService)
	local spawnPart = CheckpointService.getSpawnLocationForStage(defaultStage)
	if spawnPart and player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 3.5, 0)
		end
	end
	PlayerService.unlockPlayerMovement(player)
	restartMenuEvent:FireClient(player, "CloseMenu")
end

function PlayerService.confirmContinue(player: Player)
	pendingRestartMenu[player] = nil
	local leaderstats = player:FindFirstChild("leaderstats")
	local stageStat = if leaderstats then leaderstats:FindFirstChild("Stage") :: IntValue? else nil
	local currentStage = if stageStat then stageStat.Value else (ObbyConfig.DefaultStage or 0)
	local CheckpointService = require(script.Parent.CheckpointService)
	local spawnPart = CheckpointService.getSpawnLocationForStage(currentStage)
	if spawnPart and player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 3.5, 0)
		end
	end
	PlayerService.unlockPlayerMovement(player)
	restartMenuEvent:FireClient(player, "CloseMenu")
end

function PlayerService.savePlayerData(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	local stageStat = leaderstats:FindFirstChild("Stage") :: IntValue?
	if not stageStat then return end

	local LevelService = require(script.Parent.LevelService)
	local maxLevel = LevelService.getMaxLevel()
	local currentStage = stageStat.Value
	local key = "PlayerStage_" .. player.UserId
	local defaultStage = ObbyConfig.DefaultStage or 0

	if currentStage >= maxLevel or currentStage <= defaultStage then
		pcall(function()
			stageDataStore:RemoveAsync(key)
		end)
	else
		pcall(function()
			stageDataStore:SetAsync(key, currentStage)
		end)
	end
end

function PlayerService.onPlayerRemoving(player: Player)
	PlayerService.savePlayerData(player)
	stageCache[player] = nil
	pendingRestartMenu[player] = nil
end

function PlayerService.getStage(player: Player): number
	return stageCache[player] or (ObbyConfig.DefaultStage or 0)
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
