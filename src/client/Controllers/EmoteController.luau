local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared.Configs.ObbyConfig)

local EmoteController = {}
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local currentEmoteTrack: AnimationTrack? = nil
local isMenuOpen = false
local originalMenuPos: UDim2? = nil
local offScreenMenuPos: UDim2? = nil
local targetEmoteMenu: GuiObject? = nil

local boundTaunt = false
local boundClose = false
local boundItems = false

function EmoteController.init()
end

function EmoteController.start()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
		if player == localPlayer and wasPurchased and gamepassId == ObbyConfig.PremiumDanceGamepassId then
			print("Premium Dance Gamepass purchase completed!")
		end
	end)

	localPlayer.CharacterAdded:Connect(function(character)
		EmoteController.onCharacterAdded(character)
	end)

	if localPlayer.Character then
		task.spawn(function()
			EmoteController.onCharacterAdded(localPlayer.Character)
		end)
	end

	task.spawn(function()
		while true do
			EmoteController.bindUI()
			task.wait(0.5)
		end
	end)
end

function EmoteController.onCharacterAdded(character: Model)
	if currentEmoteTrack then
		currentEmoteTrack:Stop()
		currentEmoteTrack = nil
	end

	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid then
		humanoid.Running:Connect(function(speed)
			if speed > 0.5 and currentEmoteTrack then
				currentEmoteTrack:Stop()
				currentEmoteTrack = nil
			end
		end)
		humanoid.StateChanged:Connect(function(_, newState)
			if (newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall) and currentEmoteTrack then
				currentEmoteTrack:Stop()
				currentEmoteTrack = nil
			end
		end)
	end

	EmoteController.updateViewports(character)
end

function EmoteController.bindUI()
	local emoteMenu = playerGui:FindFirstChild("EmoteMenu", true) :: GuiObject?
	if not emoteMenu then return end

	if not targetEmoteMenu then
		targetEmoteMenu = emoteMenu
		emoteMenu.Visible = false
	end

	if not boundTaunt then
		local tauntBtn = playerGui:FindFirstChild("Taunt", true)
		if tauntBtn and tauntBtn:IsA("GuiObject") then
			boundTaunt = true
			EmoteController.bindGuiClick(tauntBtn :: GuiObject, function()
				EmoteController.toggleEmoteMenu()
			end)
		end
	end

	if not boundClose then
		local closeBtn = emoteMenu:FindFirstChild("Close", true)
		if closeBtn and closeBtn:IsA("GuiObject") then
			boundClose = true
			EmoteController.bindGuiClick(closeBtn :: GuiObject, function()
				EmoteController.closeEmoteMenu()
			end)
		end
	end

	if not boundItems then
		local itemsContainer = emoteMenu:FindFirstChildOfClass("Frame") or emoteMenu
		local foundAny = false
		for _, child in ipairs(itemsContainer:GetChildren()) do
			if string.sub(child.Name, 1, 4) == "Item" and child:IsA("GuiObject") then
				foundAny = true
				EmoteController.bindItemButton(child :: GuiObject)
			end
		end
		if foundAny then
			boundItems = true
		end
	end
end

local lastToggleTime = 0

function EmoteController.toggleEmoteMenu()
	local now = os.clock()
	if now - lastToggleTime < 0.35 then return end
	lastToggleTime = now

	if targetEmoteMenu then
		targetEmoteMenu.Visible = not targetEmoteMenu.Visible
	end
end

function EmoteController.openEmoteMenu()
	if targetEmoteMenu then
		targetEmoteMenu.Visible = true
	end
end

function EmoteController.closeEmoteMenu()
	if targetEmoteMenu then
		targetEmoteMenu.Visible = false
	end
end

function EmoteController.bindItemButton(itemObj: GuiObject)
	EmoteController.bindGuiClick(itemObj, function()
		EmoteController.playEmoteFromItem(itemObj)
	end)
end

function EmoteController.bindGuiClick(guiObj: GuiObject, callback: () -> ())
	guiObj.Active = true
	if guiObj:IsA("GuiButton") then
		(guiObj :: GuiButton).MouseButton1Click:Connect(callback)
	else
		guiObj.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				callback()
			end
		end)
	end

	for _, child in ipairs(guiObj:GetDescendants()) do
		if child:IsA("GuiObject") then
			local childGui = child :: GuiObject
			childGui.Active = true
			if childGui:IsA("GuiButton") then
				(childGui :: GuiButton).MouseButton1Click:Connect(callback)
			else
				childGui.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						callback()
					end
				end)
			end
		end
	end
end

function EmoteController.playEmoteFromItem(itemObj: GuiObject)
	local character = localPlayer.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not humanoid or not animator then return end

	local isGamepassRequired = itemObj:GetAttribute("Gamepass")
	if isGamepassRequired == true then
		local gamepassId = ObbyConfig.PremiumDanceGamepassId
		if gamepassId and gamepassId > 0 then
			local success, ownsPass = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(localPlayer.UserId, gamepassId)
			end)
			if not success or not ownsPass then
				MarketplaceService:PromptGamePassPurchase(localPlayer, gamepassId)
				return
			end
		end
	end

	local animObj = itemObj:FindFirstChildOfClass("Animation") or itemObj:FindFirstChild("Animation")
	if not animObj or not animObj:IsA("Animation") then return end

	if currentEmoteTrack then
		currentEmoteTrack:Stop()
		currentEmoteTrack = nil
	end

	local track = animator:LoadAnimation(animObj :: Animation)
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = true
	track:Play()

	currentEmoteTrack = track
end

function EmoteController.updateViewports(character: Model)
	local emoteMenu = playerGui:FindFirstChild("EmoteMenu", true)
	if not emoteMenu then return end

	local itemsContainer = emoteMenu:FindFirstChildOfClass("Frame") or emoteMenu
	for _, child in ipairs(itemsContainer:GetChildren()) do
		if string.sub(child.Name, 1, 4) == "Item" and child:IsA("GuiObject") then
			EmoteController.setupViewportForItem(child :: GuiObject, character)
		end
	end
end

function EmoteController.setupViewportForItem(itemObj: GuiObject, character: Model)
	local viewport = itemObj:FindFirstChildOfClass("ViewportFrame") or itemObj:FindFirstChild("ViewportFrame", true) :: ViewportFrame?
	if not viewport or not viewport:IsA("ViewportFrame") then return end

	local animObj = itemObj:FindFirstChildOfClass("Animation") or itemObj:FindFirstChild("Animation")
	if not animObj or not animObj:IsA("Animation") then return end

	viewport:ClearAllChildren()

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	character.Archivable = true
	local charClone = character:Clone()
	character.Archivable = false

	if not charClone then return end

	for _, descendant in ipairs(charClone:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("Sound") then
			descendant:Destroy()
		end
	end

	charClone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi, math.rad(-90)))
	charClone.Parent = worldModel

	local hrp = charClone:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = charClone:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid))

	if hrp and humanoid and animator then
		hrp.Anchored = true
		hrp.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi, math.rad(-90))

		viewport.Ambient = Color3.fromRGB(220, 220, 220)
		viewport.LightColor = Color3.fromRGB(255, 255, 255)
		viewport.LightDirection = Vector3.new(0, -1, 1)

		local camera = Instance.new("Camera")
		camera.FieldOfView = 45
		camera.CFrame = CFrame.new(Vector3.new(0, 0.2, 6.5), Vector3.new(0, 0, 0))
		camera.Parent = viewport
		viewport.CurrentCamera = camera

		local track = animator:LoadAnimation(animObj :: Animation)
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = true
		track:Play()
	end
end

return EmoteController
