local player = require("Modules.player")
local loadMap = require("Modules.loadMap")
local drawOrder = require("Modules.drawOrder")
local signal = require("Modules.signal")
local updateThreads = require("Modules.updateThreads")
if os.getenv("LOVE2D_TOOLS") then
	pcall(require, "_love2d_tools_bridge")
end

local camera = require("libs.hump.camera")
local wf = require("libs.windfield")

game = {}
game.world = wf.newWorld()
game.camera = camera.new(0, 0)
game.drawOrder = drawOrder.new()
game.updateThreads = updateThreads.new()
game.map = {
	map = nil,
	name = nil,
	draw = nil,
	update = nil,
}
game.signals = {
	mapReset = signal.new(),
	playerDied = signal.new(),
}

local lg = love.graphics
conf = {}
conf.GameSpeed = 1
conf.MapScale = 1.75
conf.playerSpriteScale = 1.5

local function generateUUID()
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	math.randomseed(os.time())

	return string.gsub(template, "[xy]", function(c)
		local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format("%x", v)
	end)
end

function lerp(a, b, c)
	return a + (b - a) * c
end
	
function getBoolAxis(positive, negative)
	local a = positive and 1 or 0
	local b = negative and 1 or 0
	return a - b
end

function findObjectInMapLayer(layer, objectName)
	for _, object in pairs(layer.objects) do
		if object.name == objectName then
			return object
		end
	end
	return nil
end

function getMapLayerObjectRealPosition(layer, objectName)
	if not layer or not layer.objects then
		return nil, nil
	end

	for _, obj in ipairs(layer.objects) do
		if obj.name == objectName then
			local raw_world_x = obj.x + (layer.offsetx or 0)
			local raw_world_y = obj.y + (layer.offsety or 0)
			local screen_x = raw_world_x * conf.MapScale
			local screen_y = raw_world_y * conf.MapScale
			return screen_x, screen_y
		end
	end
	return nil, nil
end

function love.load()
	lg.setDefaultFilter("nearest", "nearest")
	game.updateThreads:newThread("objects")
	game.updateThreads:newThread("maps")
	game.updateThreads:newThread("world")
	game.drawOrder:newLayer("background", 1)
	game.drawOrder:newLayer("map", 2)
	game.drawOrder:newLayer("objects", 3)
	game.drawOrder:newLayer("interface", 4)
	game.drawOrder:newLayer("debug", 5)
	game.drawOrder.layers.objects:add(function ()
		if game.world ~= nil then
			--game.world:draw(1)
		end
	end, "windfield")
	game.drawOrder.layers.interface.relativeToCamera = false
	game.updateThreads.threads.world:add(function(dt)
		if game.world ~= nil and game.world.box2d_world ~= nil then
			game.world:update(dt)
		end
	end, "windfield")
	game.drawOrder.layers.debug:add(function()
		for i, v in pairs(squares) do
			lg.rectangle("fill", v.x, v.y, 50, 50)
		end
	end, "squares")
	squares = {}
	local plr = player.new(0, 0)
	game.player = plr
	game.updateThreads.threads.objects:add(plr, "Player")
	game.drawOrder.layers.objects:add(plr, "Player")
	--ngl, vscode's AI did this one function.
	local function requireScripts()
		if love and love.filesystem then
			local files = love.filesystem.getDirectoryItems("Scripts")
			table.sort(files)
			for _, file in ipairs(files) do
				if file:sub(-4) == ".lua" then
					local moduleName = file:sub(1, -5)
					local ok, err = pcall(require, "Scripts." .. moduleName)
					if not ok then
						print(("Failed to require Scripts/%s: %s"):format(file, err))
					elseif err.load then
						err.load()
					end
				end
			end
		end
	end

	requireScripts()
	--It didnt anything down here tho!, dw
end

local db = false
local mapToggle = false
local maps = {
	[1] = "TESTTTTbutlua",
	[2] = "Startermap",
	[3] = "test2",
	[4] = "freeslopmaplol"
}

local bruhuhuh = 1

function love.update(dt)
	if love.keyboard.isDown("e") then
		game.player.health = game.player.health - (150 * dt)
	end
	if love.keyboard.isDown("r") then
		if not db then
			db = true
			mapToggle = not mapToggle
			loadMap.load(maps[bruhuhuh])
			if bruhuhuh == #maps then
				bruhuhuh = 1
			else
				bruhuhuh = bruhuhuh + 1
			end
		end
	else
		db = false
	end
	game.updateThreads:update(dt * conf.GameSpeed)
end

message = "Map not loaded!"

function love.draw()
	game.drawOrder:draw()
end
