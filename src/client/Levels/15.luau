local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Level15 = {}
local localPlayer = Players.LocalPlayer
local connections = {}
local mushroomData = {}
local isBound = false

function Level15.onEnter()
	Level15.bindMushrooms()
end

function Level15.bindMushrooms()
	if isBound then return end
	isBound = true

	task.spawn(function()
		local obby = Workspace:WaitForChild("Obby", 15)
		if not obby then return end

		local level15Folder = obby:WaitForChild("Level15", 15)
		if not level15Folder then return end

		local function setupMushroom(inst: Instance, index: number)
			if not (inst:IsA("Model") or inst:IsA("BasePart")) then return end
			if mushroomData[inst] then return end

			local initialPivot = if inst:IsA("Model") then inst:GetPivot() else (inst :: BasePart).CFrame
			local pos = initialPivot.Position
			local phase = (pos.X * 0.4 + pos.Z * 0.4 + index) % (math.pi * 2)

			local partsList = {}
			if inst:IsA("BasePart") then
				table.insert(partsList, { part = inst :: BasePart, baseTrans = (inst :: BasePart).Transparency })
			elseif inst:IsA("Model") then
				for _, desc in ipairs(inst:GetDescendants()) do
					if desc:IsA("BasePart") then
						table.insert(partsList, { part = desc, baseTrans = desc.Transparency })
					end
				end
			end

			mushroomData[inst] = {
				instance = inst,
				initialPivot = initialPivot,
				currentPivot = initialPivot,
				phase = phase,
				parts = partsList,
				moveRadiusX = 1.6,
				moveRadiusZ = 1.6,
				moveRadiusY = 0.35,
				moveSpeed = 1.1,
				fadeSpeed = 1.4,
				maxFadeAlpha = 0.75,
			}
		end

		local function isMushroomName(name: string): boolean
			local lower = string.lower(name)
			return string.find(lower, "mushroom") ~= nil
		end

		for _, descendant in ipairs(level15Folder:GetDescendants()) do
			if isMushroomName(descendant.Name) then
				setupMushroom(descendant, #mushroomData + 1)
			end
		end

		local conn = level15Folder.DescendantAdded:Connect(function(descendant)
			if isMushroomName(descendant.Name) then
				setupMushroom(descendant, #mushroomData + 1)
			end
		end)
		table.insert(connections, conn)

		local renderConn = RunService.RenderStepped:Connect(function(dt)
			Level15.updateMushrooms(dt)
		end)
		table.insert(connections, renderConn)
	end)
end

function Level15.isPlayerOnInstance(inst: Instance, character: Model): boolean
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

function Level15.updateMushrooms(dt: number)
	local now = os.clock()
	local character = localPlayer.Character
	local hrp = if character then (character:FindFirstChild("HumanoidRootPart") :: BasePart?) else nil

	for inst, data in pairs(mushroomData) do
		if not inst.Parent then
			mushroomData[inst] = nil
			continue
		end

		local dx = math.sin(now * data.moveSpeed + data.phase) * data.moveRadiusX
		local dz = math.cos(now * (data.moveSpeed * 0.85) + data.phase) * data.moveRadiusZ
		local dy = math.sin(now * (data.moveSpeed * 1.3) + data.phase) * data.moveRadiusY

		local oldPivot = data.currentPivot
		local newPivot = data.initialPivot * CFrame.new(dx, dy, dz)
		data.currentPivot = newPivot

		if inst:IsA("Model") then
			inst:PivotTo(newPivot)
		elseif inst:IsA("BasePart") then
			(inst :: BasePart).CFrame = newPivot
		end

		if character and hrp and Level15.isPlayerOnInstance(inst, character) then
			local deltaPivot = newPivot * oldPivot:Inverse()
			hrp.CFrame = deltaPivot * hrp.CFrame
		end

		local fadeAlpha = (math.sin(now * data.fadeSpeed + data.phase) + 1) * 0.5
		local currentAddTrans = fadeAlpha * data.maxFadeAlpha

		for _, item in ipairs(data.parts) do
			if item.part and item.part.Parent then
				item.part.Transparency = math.clamp(item.baseTrans + (1 - item.baseTrans) * currentAddTrans, 0, 1)
			end
		end
	end
end

function Level15.onLeave()
end

return Level15
