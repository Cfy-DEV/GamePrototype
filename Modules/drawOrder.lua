local layer = {}
local layer_methods = {}
layer_methods.__index = layer_methods

function layer.new()
	local self = setmetatable({
		objects = {},
		functions = {},
		visible = true,
		alpha = 1,
		color = {1, 1, 1},
		relativeToCamera = true,
		drawOrder = "random",
		nameToObject = {},
	}, layer_methods)
	return self
end

local function sort_layer(objects, order)
	if order == "x" then
		table.sort(objects, function(a, b)
			return a.x < b.x
		end)
	elseif order == "y" then
		table.sort(objects, function(a, b)
			return a.y < b.y
		end)
	end
end

function layer_methods:update(dt)
	if self.drawOrder ~= "random" then
		sort_layer(self.objects, self.drawOrder)
	end
end

local lg = love.graphics

function layer_methods:draw()
	if not self.visible then
		return
	end
	local order = self.drawOrder
	local objects = self.objects
	local functions = self.functions
	if self.relativeToCamera then
		game.camera:attach()
	end
	lg.push()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)
	if order == "random" then
		for _, obj in pairs(objects) do
			obj:draw()
		end
		for _, func in pairs(functions) do
			func()
		end
	elseif order == "x" then
		for _, obj in pairs(objects) do
			obj:draw()
		end
		for _, func in pairs(functions) do
			func()
		end
	elseif order == "y" then
		for _, obj in ipairs(objects) do
			obj:draw()
		end
		for _, func in ipairs(functions) do
			func()
		end
	end
	if self.relativeToCamera then
		game.camera:detach()
	end
	lg.pop()
end

function layer_methods:add(obj, name)
	local previous_object = self.nameToObject[name]
	if previous_object then
		self:remove(name)
	end
	if obj ~= nil then
		if type(obj) == "function" then
			table.insert(self.functions, obj)
		elseif type(obj) == "table" then
			table.insert(self.objects, obj)
		else
			error("trying to add something who is not a function or object in the draworder layer")
		end
		if name ~= nil then
			self.nameToObject[name] = obj
		end
	else
		error("Trying to add a object wich is NIL.")
	end
end

function layer_methods:remove(obj_or_name)
	if obj_or_name == nil then
		return
	end

	if type(obj_or_name) == "string" then
		local obj = self.nameToObject[obj_or_name]
		if obj == nil then
			return
		end
		self.nameToObject[obj_or_name] = nil
		for i, v in ipairs(self.objects) do
			if v == obj then
				table.remove(self.objects, i)
				return
			end
		end
		for i, v in ipairs(self.functions) do
			if v == obj then
				table.remove(self.functions, i)
				return
			end
		end
		return
	end

	for i, v in ipairs(self.objects) do
		if v == obj_or_name then
			table.remove(self.objects, i)
			for name, obj in pairs(self.nameToObject) do
				if obj == v then
					self.nameToObject[name] = nil
					break
				end
			end
			return
		end
	end

	for i, v in ipairs(self.functions) do
		if v == obj_or_name then
			table.remove(self.functions, i)
			for name, obj in pairs(self.nameToObject) do
				if obj == v then
					self.nameToObject[name] = nil
					break
				end
			end
			return
		end
	end
end

local drawOrder = {}
local drawOrder_methods = {}
drawOrder_methods.__index = drawOrder_methods

function drawOrder.new()
	local self = setmetatable({
		layers = {},
		order = {},
	}, drawOrder_methods)
	return self
end

function drawOrder_methods:newLayer(name, level)
	local layer_obj = layer.new()
	if name ~= nil then
		self.layers[name] = layer_obj
	else
		table.insert(self.layers, layer_obj)
	end
	if level ~= nil then
		self.order[level] = name
	else
		table.insert(self.order, name)
	end
	return layer_obj
end

function drawOrder_methods:removeLayer(key)
	if key == nil then
		return
	end
	if type(key) == "string" then
		self.layers[key] = nil
		return
	end
	if type(key) == "number" then
		local layer_name = self.order[key]
		local layer_obj = self.layers[layer_name]
		if layer_obj then
			self.layers[layer_name] = nil
		end
		return
	end
	for k, v in pairs(self.layers) do
		if v == key then
			if type(k) == "number" then
				table.remove(self.layers, k)
			else
				self.layers[k] = nil
			end
			return
		end
	end
end

function drawOrder_methods:clear()
	self.layers = {}
	self.order = {}
end

function drawOrder_methods:update(dt)
	for _, layer_obj in pairs(self.layers) do
		layer_obj:update(dt)
	end
end

function drawOrder_methods:draw()
	for _, layer_name in ipairs(self.order) do
		local layer_obj = self.layers[layer_name]
		if layer_obj then
			layer_obj:draw()
		end
	end
end

return drawOrder
