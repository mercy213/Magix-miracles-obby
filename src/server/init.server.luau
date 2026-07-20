local ServicesFolder = script:WaitForChild("Services")
local services = {}

for _, child in ipairs(ServicesFolder:GetChildren()) do
	if child:IsA("ModuleScript") then
		local success, service = pcall(require, child)
		if success then
			services[child.Name] = service
		else
			warn(`Failed to require service {child.Name}:`, service)
		end
	end
end

for name, service in pairs(services) do
	if typeof(service) == "table" and typeof(service.init) == "function" then
		local success, err = pcall(service.init)
		if not success then
			warn(`Error initializing service {name}:`, err)
		end
	end
end

for name, service in pairs(services) do
	if typeof(service) == "table" and typeof(service.start) == "function" then
		task.spawn(function()
			local success, err = pcall(service.start)
			if not success then
				warn(`Error running service {name}:`, err)
			end
		end)
	end
end
