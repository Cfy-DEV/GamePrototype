local player = {}
local methods = {}
methods.__index = methods

local anim8 = require("libs.anim8")
local lg = love.graphics
local spriteSheet = lg.newImage("assets/potato_movement.png")
spriteSheet:setFilter("nearest", "nearest")
local grid = anim8.newGrid(32, 32, spriteSheet:getWidth(), spriteSheet:getHeight())

local function createCollider(self, x, y)
	self.collider = currentWorld:newBSGRectangleCollider(x or 0, y or 0, 24 * conf.MapScale, 32 * conf.MapScale, 15)
	self.collider:setType("dynamic")
	self.collider:setFixedRotation(true)
	return self.collider
end

function methods:createCollider(x, y)
	return createCollider(self, x, y)
end

function player.new(x, y)
	local self = setmetatable({
		currentAnimation = nil,
		position = {
			x = 0,
			y = 0,
		},
		speed = {
			x = 0,
			y = 0,
		},
		priority = {
			idle = 3,
			walking = 2,
			running = 1,
		},
		animations = {
			idle = {
				left = anim8.newAnimation(grid("1-2", 1), 0.25),
				right = anim8.newAnimation(grid("1-2", 2), 0.25),
				down = anim8.newAnimation(grid("1-2", 3), 0.25),
				up = anim8.newAnimation(grid("1-2", 4), 0.25),
			},
			walking = {
				left = anim8.newAnimation(grid("3-4", 1), 0.25),
				right = anim8.newAnimation(grid("3-4", 2), 0.25),
				down = anim8.newAnimation(grid("3-4", 3), 0.25),
				up = anim8.newAnimation(grid("3-4", 4), 0.25),
			},
			running = {
				left = anim8.newAnimation(grid("3-4", 1), 0.25),
				right = anim8.newAnimation(grid("3-4", 2), 0.25),
				down = anim8.newAnimation(grid("3-4", 3), 0.25),
				up = anim8.newAnimation(grid("3-4", 4), 0.25)
			},
		},
		states = {
			running = false,
			walking = false,
			jumping = false,
			falling = false,
			stunned = false,
			idle = false,
		},
		lastDirection = "down",
	}, methods)
	self:createCollider(x or 0, y or 0)
	return self
end

local jump_db = false

function methods:update(dt)
	if self.stunned then
		return
	end
	local xAxis = getBoolAxis(love.keyboard.isDown("d"), love.keyboard.isDown("a"))
	local shift = love.keyboard.isDown("rshift") or love.keyboard.isDown("lshift")
	local yAxis = getBoolAxis(love.keyboard.isDown("s"), love.keyboard.isDown("w"))
	if yAxis ~= 0 or xAxis ~= 0 then
		if not shift then
			self.states.running = false
			self.states.walking = true
		else
			self.states.running = true
			self.states.walking = false
		end
		self.states.idle = false
	else
		self.states.running = false
		self.states.walking = false
		self.states.idle = true
	end
	local spd = 0
	if self.states.running or self.states.walking then
		if self.states.running then
			spd = 250
		elseif self.states.walking then
			spd = 150
		end
	end
	self.collider:setLinearVelocity(spd * xAxis, spd * yAxis)
	local highestPriorityState = nil
	local x = 0
	for i, v in pairs(self.states) do
		if not (v == true) then
			goto continue
		end
		local find = self.priority[i]
		if not find then
			goto continue
		end
		if find >= x then
			x = find
			highestPriorityState = i
		end
		::continue::
	end
	local currentAnimationRepo = self.animations[highestPriorityState]
	if currentAnimationRepo then
		if yAxis ~= 0 or xAxis ~= 0 then
			if yAxis > 0 then
				self.lastDirection = "down"
			elseif yAxis < 0 then
				self.lastDirection = "up"
			elseif xAxis > 0 then
				self.lastDirection = "right"
			elseif xAxis < 0 then
				self.lastDirection = "left"
			end
		end
		if self.lastDirection == "down" then
			self.currentAnimation = currentAnimationRepo["down"]
		elseif self.lastDirection == "up" then
			self.currentAnimation = currentAnimationRepo["up"]
		elseif self.lastDirection == "right" then
			self.currentAnimation = currentAnimationRepo["right"]
		elseif self.lastDirection == "left" then
			self.currentAnimation = currentAnimationRepo["left"]
		end
	end
	::continue::
	if self.currentAnimation ~= nil then
		self.currentAnimation:update(dt)
	end
	local obj = self.collider.body
	local x, y = obj:getPosition()
	currentCamera.x = x
	currentCamera.y = y
end

function methods:draw()
	local obj = self.collider.body
	local x, y = obj:getPosition()
	lg.setColor(1, 1, 1, 1)
	local o = 16 * conf.MapScale
	o = o * conf.playerSpriteScale
	x, y = x - o, y - o
	if self.currentAnimation ~= nil then
		self.currentAnimation:draw(spriteSheet, x, y, 0, conf.MapScale * conf.playerSpriteScale)
	end
end



return player
