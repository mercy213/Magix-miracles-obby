local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared.Configs.ObbyConfig)

local CheckpointService = {}
local lastTouchTime = {}

local function getCheckpointsFolder(): Instance?
	return Workspace:FindFirstChild("Checkpoints") or Workspace
end

function CheckpointService.init()
end

function CheckpointService.start()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			CheckpointService.onCharacterAdded(player, character)
		end)
	end)

	local checkpointsFolder = getCheckpointsFolder()
	if checkpointsFolder then
		checkpointsFolder.ChildAdded:Connect(function(child)
			CheckpointService.setupCheckpoint(child)
		end)

		for _, child in ipairs(checkpointsFolder:GetChildren()) do
			CheckpointService.setupCheckpoint(child)
		end
	end

	CollectionService:GetInstanceAddedSignal(ObbyConfig.CheckpointTag):Connect(function(instance)
		CheckpointService.setupCheckpoint(instance)
	end)
end

function CheckpointService.setupCheckpoint(instance: Instance)
	if not (instance:IsA("BasePart") or instance:IsA("Model")) then return end

	local stageNum = tonumber(string.match(instance.Name, "%d+"))
	if not stageNum then return end

	local touchPart: BasePart? = if instance:IsA("BasePart") then instance else (instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart"))
	if not touchPart then return end

	touchPart.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local now = os.clock()
		if lastTouchTime[player] and (now - lastTouchTime[player]) < ObbyConfig.CheckpointCoolDown then
			return
		end
		lastTouchTime[player] = now

		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end
		local stageStat = leaderstats:FindFirstChild("Stage") :: IntValue
		if not stageStat then return end

		if stageNum > stageStat.Value then
			stageStat.Value = stageNum
		end
	end)
end

function CheckpointService.getSpawnLocationForStage(stageNum: number): BasePart?
	local checkpointsFolder = getCheckpointsFolder()
	if not checkpointsFolder then return nil end

	for _, child in ipairs(checkpointsFolder:GetChildren()) do
		local num = tonumber(string.match(child.Name, "%d+"))
		if num == stageNum then
			if child:IsA("BasePart") then
				return child
			elseif child:IsA("Model") then
				return child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
			end
		end
	end
	return nil
end

function CheckpointService.onCharacterAdded(player: Player, character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not hrp then return end

	local leaderstats = player:WaitForChild("leaderstats", 5)
	if not leaderstats then return end
	local stageStat = leaderstats:WaitForChild("Stage", 5) :: IntValue?
	if not stageStat then return end

	local spawnPart = CheckpointService.getSpawnLocationForStage(stageStat.Value)
	if spawnPart then
		task.defer(function()
			if character:Parent() and hrp:Parent() then
				hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 3.5, 0)
			end
		end)
	end
end

return CheckpointService
