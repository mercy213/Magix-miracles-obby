local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIController = {}
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

function UIController.init()
end

function UIController.start()
	local restartEvent = ReplicatedStorage:WaitForChild("RestartMenuEvent", 10) :: RemoteEvent?
	local isRestartMenuPrompted = false

	local function showRestartMenu()
		isRestartMenuPrompted = true
		local restartMenu = playerGui:FindFirstChild("RestartMenu", true)
		if restartMenu and restartMenu:IsA("GuiObject") then
			local current: Instance? = restartMenu
			while current and current:IsA("GuiObject") do
				(current :: GuiObject).Visible = true
				current = current.Parent
			end
		end
	end

	local function hideRestartMenu()
		isRestartMenuPrompted = false
		local restartMenu = playerGui:FindFirstChild("RestartMenu", true)
		if restartMenu and restartMenu:IsA("GuiObject") then
			(restartMenu :: GuiObject).Visible = false
		end
	end

	local boundRestartMenu = false
	local function bindRestartMenu()
		if boundRestartMenu then return end

		local restartMenu = playerGui:FindFirstChild("RestartMenu", true)
		if not restartMenu or not restartMenu:IsA("GuiObject") then return end

		boundRestartMenu = true
		if not isRestartMenuPrompted then
			(restartMenu :: GuiObject).Visible = false
		end

		local function bindGuiClick(guiObj: GuiObject, callback: () -> ())
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

		local restartBtn = restartMenu:FindFirstChild("Restart", true)
		if restartBtn and restartBtn:IsA("GuiObject") then
			bindGuiClick(restartBtn :: GuiObject, function()
				local rEvent = ReplicatedStorage:FindFirstChild("RestartMenuEvent") :: RemoteEvent?
				if rEvent then
					rEvent:FireServer("Restart")
				end
				hideRestartMenu()
			end)
		end

		local continueBtn = restartMenu:FindFirstChild("Continue", true)
		if continueBtn and continueBtn:IsA("GuiObject") then
			bindGuiClick(continueBtn :: GuiObject, function()
				local Shared = ReplicatedStorage:WaitForChild("Shared")
				local ObbyConfig = require(Shared.Configs.ObbyConfig)
				local MarketplaceService = game:GetService("MarketplaceService")

				local devProdId = ObbyConfig.ContinueDevProductId
				if devProdId and devProdId > 0 then
					MarketplaceService:PromptProductPurchase(localPlayer, devProdId)
				else
					local rEvent = ReplicatedStorage:FindFirstChild("RestartMenuEvent") :: RemoteEvent?
					if rEvent then
						rEvent:FireServer("Continue")
					end
					hideRestartMenu()
				end
			end)
		end
	end

	bindRestartMenu()

	if restartEvent then
		restartEvent.OnClientEvent:Connect(function(action: string)
			if action == "PromptMenu" then
				showRestartMenu()
			elseif action == "CloseMenu" then
				hideRestartMenu()
			end
		end)
		restartEvent:FireServer("CheckPrompt")
	end

	local leaderstats = localPlayer:WaitForChild("leaderstats", 10)
	if not leaderstats then return end

	local stageStat = leaderstats:WaitForChild("Stage", 10) :: IntValue?
	if not stageStat then return end

	local function updateText()
		local playerLevelObj = playerGui:FindFirstChild("PlayerLevel", true)
		if playerLevelObj then
			local innerTextLabel = playerLevelObj:FindFirstChildOfClass("TextLabel")
			if innerTextLabel then
				innerTextLabel.Text = tostring(stageStat.Value)
			elseif playerLevelObj:IsA("TextLabel") then
				(playerLevelObj :: TextLabel).Text = tostring(stageStat.Value)
			end
		end
	end

	local boundSkip = false
	local function bindSkipButton()
		if boundSkip then return end

		local skipObj = playerGui:FindFirstChild("SkipStage", true)
		if not skipObj or not skipObj:IsA("GuiObject") then return end

		boundSkip = true
		local obj = skipObj :: GuiObject
		obj.Active = true

		local function triggerSkip()
			local Shared = ReplicatedStorage:WaitForChild("Shared")
			local ObbyConfig = require(Shared.Configs.ObbyConfig)
			local MarketplaceService = game:GetService("MarketplaceService")

			local devProdId = ObbyConfig.SkipStageDevProductId
			if devProdId and devProdId > 0 then
				MarketplaceService:PromptProductPurchase(localPlayer, devProdId)
			else
				local skipEvent = ReplicatedStorage:FindFirstChild("SkipStageEvent") :: RemoteEvent?
				if skipEvent then
					skipEvent:FireServer()
				end
			end
		end

		if obj:IsA("GuiButton") then
			(obj :: GuiButton).MouseButton1Click:Connect(triggerSkip)
		else
			obj.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					triggerSkip()
				end
			end)
		end

		for _, child in ipairs(obj:GetDescendants()) do
			if child:IsA("GuiObject") then
				local childGui = child :: GuiObject
				childGui.Active = true
				if childGui:IsA("GuiButton") then
					(childGui :: GuiButton).MouseButton1Click:Connect(triggerSkip)
				else
					childGui.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							triggerSkip()
						end
					end)
				end
			end
		end
	end

	local boundTeleportMenu = false
	local function bindTeleportMenu()
		if boundTeleportMenu then return end

		local teleportMenu = playerGui:FindFirstChild("TeleportMenu", true)
		if not teleportMenu or not teleportMenu:IsA("GuiObject") then return end

		boundTeleportMenu = true
		(teleportMenu :: GuiObject).Visible = false

		local function bindGuiClick(guiObj: GuiObject, callback: () -> ())
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

		local lastTeleportClick = 0
		local yesBtn = teleportMenu:FindFirstChild("Yes", true)
		if yesBtn and yesBtn:IsA("GuiObject") then
			bindGuiClick(yesBtn :: GuiObject, function()
				local now = os.clock()
				if now - lastTeleportClick < 1.0 then return end
				lastTeleportClick = now

				local tpEvent = ReplicatedStorage:FindFirstChild("TeleportToMainEvent") :: RemoteEvent?
				if tpEvent then
					tpEvent:FireServer()
				end
			end)
		end

		local function closeTeleportMenu()
			teleportMenu.Visible = false
		end

		local noBtn = teleportMenu:FindFirstChild("No", true)
		if noBtn and noBtn:IsA("GuiObject") then
			bindGuiClick(noBtn :: GuiObject, closeTeleportMenu)
		end

		local closeBtn = teleportMenu:FindFirstChild("CloseMenu", true)
		if closeBtn and closeBtn:IsA("GuiObject") then
			bindGuiClick(closeBtn :: GuiObject, closeTeleportMenu)
		end
	end

	local boundPeople = false
	local function bindPeopleButton()
		if boundPeople then return end

		local peopleObj = playerGui:FindFirstChild("People", true)
		local teleportMenu = playerGui:FindFirstChild("TeleportMenu", true)
		if not peopleObj or not peopleObj:IsA("GuiObject") or not teleportMenu or not teleportMenu:IsA("GuiObject") then return end

		boundPeople = true
		local lastPeopleToggle = 0

		local function toggleTeleportMenu()
			local now = os.clock()
			if now - lastPeopleToggle < 0.35 then return end
			lastPeopleToggle = now

			teleportMenu.Visible = not teleportMenu.Visible
		end

		if peopleObj:IsA("GuiButton") then
			(peopleObj :: GuiButton).MouseButton1Click:Connect(toggleTeleportMenu)
		else
			peopleObj.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					toggleTeleportMenu()
				end
			end)
		end

		for _, child in ipairs(peopleObj:GetDescendants()) do
			if child:IsA("GuiObject") then
				local childGui = child :: GuiObject
				childGui.Active = true
				if childGui:IsA("GuiButton") then
					(childGui :: GuiButton).MouseButton1Click:Connect(toggleTeleportMenu)
				else
					childGui.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							toggleTeleportMenu()
						end
					end)
				end
			end
		end
	end

	stageStat.Changed:Connect(function()
		updateText()
	end)

	task.spawn(function()
		while true do
			bindSkipButton()
			bindTeleportMenu()
			bindPeopleButton()
			bindRestartMenu()
			updateText()
			task.wait(0.5)
		end
	end)
end

return UIController
