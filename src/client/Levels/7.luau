local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Level7 = {}
local localPlayer = Players.LocalPlayer
local connections = {}
local daisyData = {}
local isBound = false

function Level7.onEnter()
	Level7.bindDaisies()
end

function Level7.bindDaisies()
	if isBound then return end
	isBound = true

	task.spawn(function()
		local obby = Workspace:WaitForChild("Obby", 15)
		if not obby then return end

		local level7Folder = obby:WaitForChild("Level7", 15)
		if not level7Folder then return end

		local function setupDaisy(daisy: Instance, index: number)
			if not (daisy:IsA("Model") or daisy:IsA("BasePart")) then return end
			if daisyData[daisy] then return end

			local initialPivot = if daisy:IsA("Model") then daisy:GetPivot() else (daisy :: BasePart).CFrame
			local pos = initialPivot.Position
			local phase = (pos.X * 0.3 + pos.Z * 0.3 + index) % (math.pi * 2)

			daisyData[daisy] = {
				instance = daisy,
				initialPivot = initialPivot,
				phase = phase,
				floatSpeed = 2.2,
				floatAmplitude = 0.6,
				spinSpeed = 1.8,
			}
		end

		local function scanFolder(container: Instance)
			local count = 0
			for _, child in ipairs(container:GetChildren()) do
				if child.Name == "Daisy" then
					count += 1
					setupDaisy(child, count)
				elseif child:IsA("Folder") or child:IsA("Model") then
					for _, subChild in ipairs(child:GetChildren()) do
						if subChild.Name == "Daisy" then
							count += 1
							setupDaisy(subChild, count)
						end
					end
				end
			end
		end

		scanFolder(level7Folder)

		for _, descendant in ipairs(level7Folder:GetDescendants()) do
			if descendant.Name == "Daisy" then
				setupDaisy(descendant, #daisyData + 1)
			end
		end

		local conn = level7Folder.DescendantAdded:Connect(function(descendant)
			if descendant.Name == "Daisy" then
				setupDaisy(descendant, #daisyData + 1)
			end
		end)
		table.insert(connections, conn)

		local renderConn = RunService.RenderStepped:Connect(function(dt)
			Level7.updateDaisies(dt)
		end)
		table.insert(connections, renderConn)
	end)
end

function Level7.updateDaisies(dt: number)
	local now = os.clock()

	for daisy, data in pairs(daisyData) do
		if not daisy.Parent then
			daisyData[daisy] = nil
			continue
		end

		local floatOffset = math.sin(now * data.floatSpeed + data.phase) * data.floatAmplitude
		local spinAngle = (now * data.spinSpeed + data.phase) % (math.pi * 2)
		local subtleTilt = math.sin(now * 1.4 + data.phase) * math.rad(3)

		local animCFrame = data.initialPivot
			* CFrame.new(0, floatOffset, 0)
			* CFrame.Angles(subtleTilt, spinAngle, 0)

		if daisy:IsA("Model") then
			daisy:PivotTo(animCFrame)
		elseif daisy:IsA("BasePart") then
			(daisy :: BasePart).CFrame = animCFrame
		end
	end
end

function Level7.onLeave()
end

return Level7
