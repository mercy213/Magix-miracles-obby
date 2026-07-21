local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Level16 = {}
local localPlayer = Players.LocalPlayer
local connections = {}
local partData = {}
local isBound = false

function Level16.onEnter()
	Level16.bindParts()
end

function Level16.bindParts()
	if isBound then return end
	isBound = true

	task.spawn(function()
		local obby = Workspace:WaitForChild("Obby", 15)
		if not obby then return end

		local level16Folder = obby:WaitForChild("Level16", 15)
		if not level16Folder then return end

		local function setupPart(inst: Instance, index: number)
			if not (inst:IsA("Model") or inst:IsA("BasePart")) then return end
			if partData[inst] then return end

			local initialPivot = if inst:IsA("Model") then inst:GetPivot() else (inst :: BasePart).CFrame
			local pos = initialPivot.Position
			local phase = (pos.X * 0.3 + pos.Z * 0.3 + index) % (math.pi * 2)

			partData[inst] = {
				instance = inst,
				initialPivot = initialPivot,
				phase = phase,
				floatSpeed = 2.2,
				floatAmplitude = 0.6,
				spinSpeed = 1.8,
			}
		end

		local function bindFolder(targetFolder: Instance)
			local count = 0
			for _, child in ipairs(targetFolder:GetChildren()) do
				count += 1
				setupPart(child, count)
			end

			local childConn = targetFolder.ChildAdded:Connect(function(child)
				count += 1
				setupPart(child, count)
			end)
			table.insert(connections, childConn)
		end

		local foundFolder = false
		for _, child in ipairs(level16Folder:GetChildren()) do
			if child:IsA("Folder") and string.lower(child.Name) == "folder" then
				foundFolder = true
				bindFolder(child)
			end
		end

		if not foundFolder then
			local folder = level16Folder:WaitForChild("Folder", 10)
			if folder then
				bindFolder(folder)
			end
		end

		local renderConn = RunService.RenderStepped:Connect(function(dt)
			Level16.updateParts(dt)
		end)
		table.insert(connections, renderConn)
	end)
end

function Level16.updateParts(dt: number)
	local now = os.clock()

	for inst, data in pairs(partData) do
		if not inst.Parent then
			partData[inst] = nil
			continue
		end

		local floatOffset = math.sin(now * data.floatSpeed + data.phase) * data.floatAmplitude
		local spinAngle = (now * data.spinSpeed + data.phase) % (math.pi * 2)
		local subtleTilt = math.sin(now * 1.4 + data.phase) * math.rad(3)

		local animCFrame = data.initialPivot
			* CFrame.new(0, floatOffset, 0)
			* CFrame.Angles(subtleTilt, spinAngle, 0)

		if inst:IsA("Model") then
			inst:PivotTo(animCFrame)
		elseif inst:IsA("BasePart") then
			(inst :: BasePart).CFrame = animCFrame
		end
	end
end

function Level16.onLeave()
end

return Level16
