local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared.Configs.ObbyConfig)

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Networker = require(Packages:WaitForChild("networker"))

local CheckpointService = {}
local lastTouchTime = {}
local skipStageEvent: RemoteEvent
local vfxNetworker: any

local function getObbyFolder(): Instance?
	return Workspace:FindFirstChild(ObbyConfig.ObbyFolderName) or Workspace
end

function CheckpointService.init()
	skipStageEvent = ReplicatedStorage:FindFirstChild("SkipStageEvent") :: RemoteEvent
	if not skipStageEvent then
		skipStageEvent = Instance.new("RemoteEvent")
		skipStageEvent.Name = "SkipStageEvent"
		skipStageEvent.Parent = ReplicatedStorage
	end

	vfxNetworker = Networker.server.new("VFXNetwork")
end

function CheckpointService.start()
	skipStageEvent.OnServerEvent:Connect(function(player: Player)
		CheckpointService.skipStage(player)
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			CheckpointService.onCharacterAdded(player, character)
		end)
	end)

	local obbyFolder = getObbyFolder()
	if obbyFolder then
		obbyFolder.ChildAdded:Connect(function(child)
			CheckpointService.setupLevelFolder(child)
		end)

		for _, child in ipairs(obbyFolder:GetChildren()) do
			CheckpointService.setupLevelFolder(child)
		end
	end
end

function CheckpointService.skipStage(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local stageStat = leaderstats:FindFirstChild("Stage") :: IntValue
	if not stageStat then return end

	local LevelService = require(script.Parent.LevelService)
	local maxLevel = LevelService.getMaxLevel()
	if stageStat.Value >= maxLevel then return end

	local now = os.clock()
	if lastTouchTime[player] and (now - lastTouchTime[player]) < 0.5 then
		return
	end
	lastTouchTime[player] = now + 1.0

	stageStat.Value = math.min(stageStat.Value + 1, maxLevel)

	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local spawnPart = CheckpointService.getSpawnLocationForStage(stageStat.Value)
		if hrp and spawnPart then
			hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 3.5, 0)
			if vfxNetworker then
				vfxNetworker:fire(player, "playSpawnVFX")
			end
		end
	end
end

function CheckpointService.setupLevelFolder(levelFolder: Instance)
	local stageNum = tonumber(string.match(levelFolder.Name, "%d+"))
	if not stageNum then return end

	local function bindCheckpoint(part: BasePart)
		part.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if not player then return end

			local now = os.clock()
			if lastTouchTime[player] and (now - lastTouchTime[player]) < ObbyConfig.CheckpointCoolDown then
				return
			end

			local leaderstats = player:FindFirstChild("leaderstats")
			if not leaderstats then return end
			local stageStat = leaderstats:FindFirstChild("Stage") :: IntValue
			if not stageStat then return end

			local LevelService = require(script.Parent.LevelService)
			local maxLevel = LevelService.getMaxLevel()
			if stageStat.Value >= maxLevel then return end

			if stageNum == stageStat.Value + 1 then
				lastTouchTime[player] = now
				stageStat.Value = math.min(stageNum, maxLevel)
			end
		end)
	end

	local checkpoint = levelFolder:FindFirstChild(ObbyConfig.CheckpointName)
	if checkpoint and checkpoint:IsA("BasePart") then
		bindCheckpoint(checkpoint :: BasePart)
	end

	levelFolder.ChildAdded:Connect(function(child)
		if child.Name == ObbyConfig.CheckpointName and child:IsA("BasePart") then
			bindCheckpoint(child :: BasePart)
		end
	end)
end

function CheckpointService.getSpawnLocationForStage(stageNum: number): BasePart?
	local obbyFolder = getObbyFolder()
	if not obbyFolder then return nil end

	local levelFolder = obbyFolder:FindFirstChild(`Level{stageNum}`) or obbyFolder:FindFirstChild(tostring(stageNum))
	if levelFolder then
		local checkpoint = levelFolder:FindFirstChild(ObbyConfig.CheckpointName)
		if checkpoint and checkpoint:IsA("BasePart") then
			return checkpoint :: BasePart
		end
	end

	return nil
end

function CheckpointService.onCharacterAdded(player: Player, character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hrp or not humanoid then return end

	local leaderstats = player:WaitForChild("leaderstats", 5)
	if not leaderstats then return end
	local stageStat = leaderstats:WaitForChild("Stage", 5) :: IntValue?
	if not stageStat then return end

	local spawnPart = CheckpointService.getSpawnLocationForStage(stageStat.Value)
	if spawnPart then
		task.defer(function()
			if character.Parent and hrp.Parent then
				hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 3.5, 0)
			end
		end)
	end

	local function resetToStage()
		local now = os.clock()
		if lastTouchTime[player] and (now - lastTouchTime[player]) < 0.5 then
			return
		end
		lastTouchTime[player] = now

		local currentSpawn = CheckpointService.getSpawnLocationForStage(stageStat.Value)
		if currentSpawn and hrp.Parent then
			hrp.CFrame = currentSpawn.CFrame + Vector3.new(0, 3.5, 0)
			if vfxNetworker then
				vfxNetworker:fire(player, "playSpawnVFX")
			end
		end
	end

	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Swimming then
			resetToStage()
		end
	end)

	humanoid.Touched:Connect(function(hit)
		if hit:IsA("Terrain") and humanoid:GetState() == Enum.HumanoidStateType.Swimming then
			resetToStage()
		elseif hit.Name == "Water" or hit.Name == "WaterPart" or hit.Name == "Ocean" then
			resetToStage()
		end
	end)
end

return CheckpointService
