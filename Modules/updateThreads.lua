local thread = {}
local thread_methods = {}
thread_methods.__index = thread_methods

function thread.new()
	local self = setmetatable({
		objects = {},
		functions = {},
		enabled = true,
		nameToObject = {},
	}, thread_methods)
	return self
end

function thread_methods:update(dt)
    if not self.enabled then
        return
    end
	for i, v in pairs(self.objects) do
        v:update(dt)
    end
    for i, v in pairs(self.functions) do
        v(dt)
    end
end

function thread_methods:add(obj, name)
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
			error("trying to add something who is not a function or object in the update_threads thread")
		end
		if name ~= nil then
			self.nameToObject[name] = obj
		end
	else
		error("Trying to add a object wich is NIL.")
	end
end

function thread_methods:remove(obj_or_name)
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

local update_threads = {}
local update_threads_methods = {}
update_threads_methods.__index = update_threads_methods

function update_threads.new()
	local self = setmetatable({
		threads = {},
	}, update_threads_methods)
	return self
end

function update_threads_methods:newThread(name)
	local thread_obj = thread.new()
	if name ~= nil then
		self.threads[name] = thread_obj
	else
		table.insert(self.threads, thread_obj)
	end
	return thread_obj
end

function update_threads_methods:removeThread(key)
	if key == nil then
		return
	end
	if type(key) == "string" then
		self.threads[key] = nil
		return
	end
	for k, v in pairs(self.threads) do
		if v == key then
			if type(k) == "number" then
				table.remove(self.threads, k)
			else
				self.threads[k] = nil
			end
			return
		end
	end
end

function update_threads_methods:clear()
	self.threads = {}
end

function update_threads_methods:update(dt)
	for _, thread_obj in pairs(self.threads) do
		thread_obj:update(dt)
	end
end

return update_threads
