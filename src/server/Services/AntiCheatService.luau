local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared.Configs.ObbyConfig)

local AntiCheatService = {}
local airTimeTracker = {}
local speedViolationTracker = {}

function AntiCheatService.init()
end

function AntiCheatService.start()
	Players.PlayerRemoving:Connect(function(player)
		airTimeTracker[player] = nil
		speedViolationTracker[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(1.5)
			for _, player in ipairs(Players:GetPlayers()) do
				AntiCheatService.checkPlayer(player)
			end
		end
	end)
end

function AntiCheatService.checkPlayer(player: Player)
	local character = player.Character
	if not character then
		airTimeTracker[player] = 0
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then
		airTimeTracker[player] = 0
		return
	end

	local voidThreshold = ObbyConfig.VoidYThreshold or -150
	if hrp.Position.Y < voidThreshold then
		player:Kick("Anti-Cheat: Out of bounds fall")
		return
	end

	local maxSpeed = ObbyConfig.MaxWalkSpeed or 32
	local horizontalVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude

	if horizontalVelocity > (maxSpeed + 25) then
		speedViolationTracker[player] = (speedViolationTracker[player] or 0) + 1
		if speedViolationTracker[player] >= 3 then
			player:Kick("Anti-Cheat: Speed exploit detected")
			return
		end
	else
		speedViolationTracker[player] = math.max(0, (speedViolationTracker[player] or 0) - 1)
	end

	local state = humanoid:GetState()
	local isAirState = (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Flying)

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { character }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local rayResult = Workspace:Raycast(hrp.Position, Vector3.new(0, -14, 0), rayParams)

	if isAirState and not rayResult and horizontalVelocity > 5 then
		airTimeTracker[player] = (airTimeTracker[player] or 0) + 1.5
		if airTimeTracker[player] >= 5.0 then
			player:Kick("Anti-Cheat: Fly exploit detected")
			return
		end
	else
		airTimeTracker[player] = 0
	end
end

return AntiCheatService
