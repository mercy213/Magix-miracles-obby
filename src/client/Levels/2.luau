local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Level2 = {}
local localPlayer = Players.LocalPlayer
local connections = {}
local flowerData = {}
local isBound = false

function Level2.onEnter()
	Level2.bindFlowers()
end

function Level2.bindFlowers()
	if isBound then return end
	isBound = true

	task.spawn(function()
		local obby = Workspace:WaitForChild("Obby", 15)
		if not obby then return end

		local level2Folder = obby:WaitForChild("Level2", 15)
		if not level2Folder then return end

		local function setupFlower(flower: Instance, index: number)
			if not (flower:IsA("Model") or flower:IsA("BasePart")) then return end
			if flower.Name ~= "RedFlower" then return end

			local initialPivot = if flower:IsA("Model") then flower:GetPivot() else (flower :: BasePart).CFrame

			local startPivot = initialPivot * CFrame.new(-6, 0, 0)
			local endPivot = initialPivot * CFrame.new(6, 0, 0)

			local randomSpeed = 1.2 + (math.random() * 0.4)
			local randomDirection = if math.random() > 0.5 then 1 else -1

			flowerData[flower] = {
				instance = flower,
				initialPivot = initialPivot,
				startPivot = startPivot,
				endPivot = endPivot,
				currentPivot = initialPivot,
				direction = randomDirection,
				speed = randomSpeed
			}
		end

		local count = 0
		for _, child in ipairs(level2Folder:GetChildren()) do
			if child.Name == "RedFlower" then
				count += 1
				setupFlower(child, count)
			end
		end

		level2Folder.ChildAdded:Connect(function(child)
			if child.Name == "RedFlower" then
				count += 1
				setupFlower(child, count)
			end
		end)

		local renderConn = RunService.RenderStepped:Connect(function(dt)
			Level2.updateMovement(dt)
		end)
		table.insert(connections, renderConn)
	end)
end

function Level2.isPlayerOnInstance(inst: Instance, character: Model): boolean
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return false end

	local rayOrigin = hrp.Position
	local rayDirection = Vector3.new(0, -4.5, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result and result.Instance then
		return result.Instance:IsDescendantOf(inst) or result.Instance == inst
	end

	return false
end

function Level2.updateMovement(dt: number)
	local character = localPlayer.Character
	local hrp = if character then (character:FindFirstChild("HumanoidRootPart") :: BasePart?) else nil

	for flower, data in pairs(flowerData) do
		local oldPivot = data.currentPivot
		local targetPivot = if data.direction == 1 then data.endPivot else data.startPivot

		local alpha = math.clamp(dt * data.speed, 0, 1)
		local newPivot = oldPivot:Lerp(targetPivot, alpha)

		data.currentPivot = newPivot

		if flower:IsA("Model") then
			flower:PivotTo(newPivot)
		elseif flower:IsA("BasePart") then
			(flower :: BasePart).CFrame = newPivot
		end

		local deltaPivot = newPivot * oldPivot:Inverse()

		if character and hrp and Level2.isPlayerOnInstance(flower, character) then
			hrp.CFrame = deltaPivot * hrp.CFrame
		end

		if (newPivot.Position - targetPivot.Position).Magnitude < 0.1 then
			data.direction = -data.direction
		end
	end
end

function Level2.onLeave()
end

return Level2
