local player = require("Modules.player")
local loadMap = require("Modules.loadMap")
if os.getenv("LOVE2D_TOOLS") then
	pcall(require, "_love2d_tools_bridge")
end

local camera = require("libs.hump.camera")
local wf = require("libs.windfield")
currentWorld = wf.newWorld()
currentCamera = camera.new(0, 0)
currentMap = nil

local lg = love.graphics
conf = {}
conf.GameSpeed = 1
conf.MapScale = 1.75
conf.playerSpriteScale = 1.5

thingsToUpdate = {}
thingsToDraw = {}

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
	for _, obj in ipairs(layer.objects) do
		if not (obj.name ~= objectName) then
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
	local plr = player.new(0, 0)
	currentPlayer = plr
	thingsToDraw[2] = plr
	table.insert(thingsToUpdate, currentWorld)
	table.insert(thingsToUpdate, plr)
	local mapDraw, mapUpdate = loadMap.load(require("Maps.test2"))
	thingsToDraw[1] = mapDraw
	table.insert(thingsToUpdate, mapUpdate)
end

function love.update(dt)
	for i, v in ipairs(thingsToUpdate) do
		if type(v) == "function" then
			v(dt * conf.GameSpeed)
		elseif type(v) == "table" then
			v:update(dt * conf.GameSpeed)
		end
	end
end

function love.draw()
	currentCamera:attach()
	lg.push()
	for i, v in ipairs(thingsToDraw) do
		print(i)
		lg.setColor(1, 1, 1, 1)
		if type(v) == "function" then
			v()
		elseif type(v) == "table" then
			v:draw()
		end
	end
	lg.pop()
	currentCamera:detach()
end
