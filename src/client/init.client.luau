local ControllersFolder = script:WaitForChild("Controllers")
local controllers = {}

for _, child in ipairs(ControllersFolder:GetChildren()) do
	if child:IsA("ModuleScript") then
		local success, controller = pcall(require, child)
		if success then
			controllers[child.Name] = controller
		else
			warn(`Failed to require controller {child.Name}:`, controller)
		end
	end
end

for name, controller in pairs(controllers) do
	if typeof(controller) == "table" and typeof(controller.init) == "function" then
		local success, err = pcall(controller.init)
		if not success then
			warn(`Error initializing controller {name}:`, err)
		end
	end
end

for name, controller in pairs(controllers) do
	if typeof(controller) == "table" and typeof(controller.start) == "function" then
		task.spawn(function()
			local success, err = pcall(controller.start)
			if not success then
				warn(`Error running controller {name}:`, err)
			end
		end)
	end
end
