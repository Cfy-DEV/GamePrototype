local signal = require("Modules.signal")
local player = {}
local methods = {}
methods.__index = methods

local anim8 = require("libs.anim8")
local lg = love.graphics
local spriteSheet = lg.newImage("assets/potato_movement.png")
spriteSheet:setFilter("nearest", "nearest")
local grid = anim8.newGrid(32, 32, spriteSheet:getWidth(), spriteSheet:getHeight())
local death_spriteSheet = lg.newImage("assets/potato_death.png")
death_spriteSheet:setFilter("nearest", "nearest")
local grid2 = anim8.newGrid(32, 32, death_spriteSheet:getWidth(), death_spriteSheet:getHeight())

local function createCollider(self, x, y)
	self.collider = game.world:newBSGRectangleCollider(x or 0, y or 0, 24 * conf.MapScale, 16 * conf.MapScale, 15)
	self.collider:setType("dynamic")
	self.collider:setFixedRotation(true)
	return self.collider
end

function methods:createCollider(x, y)
	return createCollider(self, x, y)
end

function player.new(x, y)
	local self = setmetatable({}, methods)
	self = self:reset(x, y)
	return self
end

local jump_db = false

function methods:reset(x, y)
	local newSelf = setmetatable({
		lastPosition = {x = 0, y = 0},
		currentSprite = spriteSheet,
		currentAnimation = nil,
		overHealth = 25,
		maxHealth = 100,
		health = 100,
		updateCamera = true,
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
				up = anim8.newAnimation(grid("3-4", 4), 0.25),
			},
		},
		states = {
			running = false,
			walking = false,
			jumping = false,
			falling = false,
			stunned = false,
			idle = false,
			dead = false,
		},
		signals = {
			death = signal.new(),
		},
		lastDirection = "down",
	}, methods)
	newSelf:createCollider(x or 0, y or 0)
	local con = function(con)
		newSelf:createCollider(newSelf.position.x, newSelf.position.y)
	end
	game.signals.mapReset:connect(con)
	local healthBarSize = { x = 300, y = 25 }
	game.drawOrder.layers.interface:add(function()
		local screenSizeX, screenSizeY = lg.getDimensions()

		--Background :

		local pX = 10
		local pY = screenSizeY - healthBarSize.y - 10

		--Stroke
		lg.setColor(0.5, 0.84, 0.7, 1)
		lg.setLineWidth(2)
		lg.rectangle("line", pX, pY, healthBarSize.x, healthBarSize.y)
		--
		--Inside
		lg.setColor(0.1, 0.15, 0.2, 0.75)
		lg.rectangle("fill", pX, pY, healthBarSize.x, healthBarSize.y)
		--
		local Osize = healthBarSize.x - 4
		local perc = newSelf.health / newSelf.maxHealth
		perc = math.max(perc, 0)
		local Rsize = Osize * perc
		--Back
		lg.setColor(0.75, 0.15, 0.1, 1)
		lg.rectangle("fill", pX + 2, pY + 2, Osize, healthBarSize.y - 4)
		--
		--Inside
		lg.setColor(0.15, 0.75, 0.2, 1)
		lg.rectangle("fill", pX + 2, pY + 2, Rsize, healthBarSize.y - 4)
		--
	end, "HealthBar")
	self = nil
	self = newSelf
	local deathAnim = anim8.newAnimation(grid2("1-3", "1-3"), 1 / 8, false)
	newSelf.signals.death:connect(function(con2)
		newSelf.currentSprite = death_spriteSheet
		newSelf.currentAnimation = deathAnim
		deathAnim.onLoop = function()
			game.signals.playerDied:fire(newSelf)
			deathAnim:pauseAtEnd()
			if self.collider.body ~= nil then
				self.collider:destroy()
			end
		end
		newSelf.signals.death:disconnect(con2)
		game.signals.mapReset:disconnect(con)
	end)
	return self
end

function methods:update(dt)
	if self.currentAnimation ~= nil then
		self.currentAnimation:update(dt)
	end
	local spd = 0
	local xAxis = getBoolAxis(love.keyboard.isDown("d"), love.keyboard.isDown("a"))
	local shift = love.keyboard.isDown("rshift") or love.keyboard.isDown("lshift")
	local yAxis = getBoolAxis(love.keyboard.isDown("s"), love.keyboard.isDown("w"))
	if xAxis ~= 0 and yAxis ~= 0 then
		local length = math.sqrt(xAxis * xAxis + yAxis * yAxis)
		xAxis = xAxis / length
		yAxis = yAxis / length
	end
	if not (self.states.stunned or self.states.dead) and self.collider ~= nil then
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
		if self.states.running or self.states.walking then
			if self.states.running then
				spd = 250
			elseif self.states.walking then
				spd = 150
			end
		end
		self.collider:setLinearVelocity(spd * xAxis, spd * yAxis)
	end
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
	if highestPriorityState == "running" or highestPriorityState == "walking" then
		local bool1 =
			self.position.x == self.lastPosition.x
			and self.position.y == self.lastPosition.y
		if bool1 then
			highestPriorityState = "idle"
		end
	end
	local currentAnimationRepo = self.animations[highestPriorityState]
	if currentAnimationRepo and (not self.states.dead and not self.states.stunned) then
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
	local x, y
	if not self.collider.body then
		x = self.position.x
		y = self.position.y
	else
		local obj = self.collider.body
		x, y = obj:getPosition()
	end
	self.lastPosition.x = self.position.x
	self.lastPosition.y = self.position.y
	self.position.x = x
	self.position.y = y
	if self.health < 1 and (not self.states.dead and not self.states.stunned) then
		if self.collider.body ~= nil then
			self.collider:setType("kinematic")
			self.collider:setLinearVelocity(0, 0)
		end
		self.states.dead = true
		self.signals.death:fire()
	end

	local pX, pY = x + (xAxis * spd), y + (yAxis * spd)
	if self.updateCamera then
		local lerpX, lerpY = lerp(game.camera.x, pX, dt * 1.41), lerp(game.camera.y, pY, dt * 1.41)
		game.camera.x = lerpX
		game.camera.y = lerpY
	end

	game.drawOrder.layers.objects:add(function()
		lg.rectangle("fill", pX, pY, 5, 5)
	end, "HELLO")
end

function methods:spawnAnimation()
	local spawnAnim = anim8.newAnimation(grid2("3-1", "3-1"), 1 / 8, false)
	self.currentAnimation = spawnAnim
	self.currentSprite = death_spriteSheet
	self.states.stunned = true
	local ended = false
	spawnAnim.onLoop = function ()
		if ended then
			 return
		end
		ended = true
		spawnAnim:pauseAtEnd()
		self.states.stunned = false
		self.currentSprite = spriteSheet
	end
end

function methods:draw()
	local obj = self.collider.body
	local x, y = obj:getPosition()
	lg.setColor(1, 1, 1, 1)
	local o = 16 * conf.MapScale
	o = o * conf.playerSpriteScale
	x, y = x - o, y - o
	if self.currentAnimation ~= nil then
		self.currentAnimation:draw(self.currentSprite, x, y - 16, 0, conf.MapScale * conf.playerSpriteScale)
	end
	lg.print("x : " .. x .. "y : " .. y, x, y - 40)
	lg.print(message, x, y - 60)
end

return player
