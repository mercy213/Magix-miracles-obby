local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared.Configs.ObbyConfig)

local BadgeServer = {}
local awardedCache = {}
local teleportEvent: RemoteEvent

function BadgeServer.init()
	teleportEvent = ReplicatedStorage:FindFirstChild("TeleportToMainEvent") :: RemoteEvent
	if not teleportEvent then
		teleportEvent = Instance.new("RemoteEvent")
		teleportEvent.Name = "TeleportToMainEvent"
		teleportEvent.Parent = ReplicatedStorage
	end
end

function BadgeServer.start()
	teleportEvent.OnServerEvent:Connect(function(player: Player)
		BadgeServer.teleportToMainGame(player)
	end)

	local function checkStageBadges(player: Player, stage: number)
		if stage >= 15 then
			BadgeServer.awardBadge(player, ObbyConfig.Level15BadgeId)
		end
	end

	local function bindPlayer(player: Player)
		awardedCache[player] = {}

		local leaderstats = player:WaitForChild("leaderstats", 10)
		if not leaderstats then return end

		local stageStat = leaderstats:WaitForChild("Stage", 10) :: IntValue?
		if not stageStat then return end

		checkStageBadges(player, stageStat.Value)

		stageStat.Changed:Connect(function(newStage)
			checkStageBadges(player, newStage)
		end)
	end

	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		awardedCache[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(bindPlayer, player)
	end

	task.spawn(function()
		local obby = Workspace:WaitForChild(ObbyConfig.ObbyFolderName, 15) or Workspace

		local boundPrompts = {}
		local function bindPrompt(prompt: ProximityPrompt)
			if boundPrompts[prompt] then return end
			boundPrompts[prompt] = true

			prompt.Triggered:Connect(function(player: Player)
				BadgeServer.awardBadge(player, ObbyConfig.CompletionBadgeId)
				task.delay(2.5, function()
					if player and player.Parent then
						BadgeServer.teleportToMainGame(player)
					end
				end)
			end)
		end

		local function checkInstanceForPrompt(inst: Instance)
			if inst:IsA("ProximityPrompt") then
				bindPrompt(inst)
			end
			for _, desc in ipairs(inst:GetDescendants()) do
				if desc:IsA("ProximityPrompt") then
					bindPrompt(desc)
				end
			end
		end

		for _, desc in ipairs(obby:GetDescendants()) do
			if desc.Name == "EndPortal" or string.find(string.lower(desc.Name), "endportal") then
				checkInstanceForPrompt(desc)
			end
		end

		obby.DescendantAdded:Connect(function(desc)
			if desc:IsA("ProximityPrompt") and desc.Parent and string.find(string.lower(desc.Parent.Name), "endportal") then
				bindPrompt(desc)
			elseif desc.Name == "EndPortal" or string.find(string.lower(desc.Name), "endportal") then
				checkInstanceForPrompt(desc)
			end
		end)
	end)
end

local lastTeleportTime = {}

function BadgeServer.teleportToMainGame(player: Player)
	if not player or not player.Parent then return end

	local now = os.clock()
	if lastTeleportTime[player] and (now - lastTeleportTime[player]) < 2.0 then
		return
	end
	lastTeleportTime[player] = now

	local placeId = ObbyConfig.MainGamePlaceId
	if not placeId or placeId == 0 then return end

	print(`Attempting to teleport player {player.Name} to place {placeId}`)
	local success, err = pcall(function()
		TeleportService:TeleportAsync(placeId, { player })
	end)
	if not success then
		warn(`Teleport failed for {player.Name}:`, err)
	end
end

function BadgeServer.awardBadge(player: Player, badgeId: number)
	if not badgeId or badgeId == 0 then return end

	if not awardedCache[player] then
		awardedCache[player] = {}
	end

	if awardedCache[player][badgeId] then return end
	awardedCache[player][badgeId] = true

	print("badge collected")

	task.spawn(function()
		local success, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
		end)

		if success and not hasBadge then
			pcall(function()
				BadgeService:AwardBadge(player.UserId, badgeId)
			end)
		end
	end)
end

return BadgeServer
