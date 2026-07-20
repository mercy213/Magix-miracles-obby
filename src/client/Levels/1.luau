local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Level1 = {}
local localPlayer = Players.LocalPlayer
local activeTweens = {}
local originalCFrames = {}
local bounceDebounce = {}
local isBound = false

function Level1.onEnter()
	Level1.bindPlates()
end

function Level1.bindPlates()
	if isBound then return end
	isBound = true

	task.spawn(function()
		local obby = Workspace:WaitForChild("Obby", 15)
		if not obby then return end

		local level1Folder = obby:WaitForChild("Level1", 15)
		if not level1Folder then return end

		local plates = level1Folder:WaitForChild("Plates", 15)
		if not plates then return end

		local function bindPart(part: Instance)
			if not part:IsA("BasePart") then return end
			local basePart = part :: BasePart
			if originalCFrames[basePart] then return end

			originalCFrames[basePart] = basePart.CFrame

			basePart.Touched:Connect(function(hit)
				local char = localPlayer.Character
				if char and hit:IsDescendantOf(char) then
					Level1.bouncePart(basePart)
				end
			end)
		end

		for _, descendant in ipairs(plates:GetDescendants()) do
			bindPart(descendant)
		end

		plates.DescendantAdded:Connect(function(descendant)
			bindPart(descendant)
		end)
	end)
end

function Level1.bouncePart(part: BasePart)
	local originalCF = originalCFrames[part]
	if not originalCF then return end

	local now = os.clock()
	if bounceDebounce[part] and (now - bounceDebounce[part]) < 0.3 then
		return
	end
	bounceDebounce[part] = now

	if activeTweens[part] then
		activeTweens[part]:Cancel()
	end

	local dipCF = originalCF * CFrame.new(0, -0.35, 0) * CFrame.Angles(math.rad(math.random(-3, 3)), 0, math.rad(math.random(-3, 3)))

	local dipTween = TweenService:Create(part, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = dipCF
	})

	local bounceTween = TweenService:Create(part, TweenInfo.new(0.45, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		CFrame = originalCF
	})

	activeTweens[part] = dipTween
	dipTween:Play()

	dipTween.Completed:Connect(function()
		activeTweens[part] = bounceTween
		bounceTween:Play()
	end)
end

function Level1.onLeave()
end

return Level1
