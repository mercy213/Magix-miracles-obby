local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIController = {}
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

function UIController.init()
end

function UIController.start()
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
			local skipEvent = ReplicatedStorage:FindFirstChild("SkipStageEvent") :: RemoteEvent?
			if skipEvent then
				skipEvent:FireServer()
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

	stageStat.Changed:Connect(function()
		updateText()
	end)

	task.spawn(function()
		while true do
			bindSkipButton()
			updateText()
			task.wait(0.5)
		end
	end)
end

return UIController
