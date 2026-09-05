local module = {}

local sti = require("libs.sti")
local wf = require("libs.windfield")
local lg = love.graphics
local i = 0
local maps = {}

local function getLayerByName(map, layerName)
	if type(map) ~= "table" or type(map.layers) ~= "table" then
		return nil
	end

	for _, layer in ipairs(map.layers) do
		if layer and layer.name == layerName then
			return layer
		end
	end

	return nil
end

local function load(map)
	if game.world and game.world.box2d_world then
		game.world:destroy()
	end
	game.world = wf.newWorld()
	game.signals.mapReset:fire()

	local objectsLayer = getLayerByName(map, "Objects")
	if objectsLayer and objectsLayer.objects then
		local objX, objY = getMapLayerObjectRealPosition(objectsLayer, "PlayerSpawn")
		if objX ~= nil and objY ~= nil then
			game.camera.x = objX
			game.camera.y = objY
			if game.player ~= nil and game.player.collider ~= nil and game.player.collider.body ~= nil then
				game.player.collider:setPosition(objX, objY)
			end
		end
	end
	local collisionsLayer = getLayerByName(map, "Collisions")
	if collisionsLayer and collisionsLayer.objects then
		for _, info in pairs(collisionsLayer.objects) do
			if not (info.width == 0 or info.height == 0) then
				local wall = game.world:newRectangleCollider(
					info.x * conf.MapScale,
					info.y * conf.MapScale,
					info.width * conf.MapScale,
					info.height * conf.MapScale
				)
				wall:setType("static")
			end
		end
	end
end

function module.load(mapName)
	local find = maps[mapName]
	if find then
		message = "found!"
		game.map.name = mapName
		game.map.draw = find.draw
		game.map.update = find.update
		game.map.map = find.map
		game.drawOrder.layers.map:add(find.draw, "Map")
		load(find.map)
		return find.map, find.draw, find.update
	else
		message = "not found!"
	end
	local mapFile = require("Maps." .. mapName)
	if not mapFile then
		return
	end
	local map = sti(mapFile)
	game.map.map = map
	load(map)
	i = 1
	local draw = function()
		lg.setColor(1, 1, 1, 1)
		if map ~= nil then
			local backgroundLayer = getLayerByName(map, "Background")
			local pathLayer = getLayerByName(map, "Path")
			local mapLayer = getLayerByName(map, "Map")
			local decoLayer = getLayerByName(map, "Deco")
			local deco2Layer = getLayerByName(map, "Deco2")

			if backgroundLayer then
				map:drawLayer(backgroundLayer)
			end
			if pathLayer then
				map:drawLayer(pathLayer)
			end
			if mapLayer then
				map:drawLayer(mapLayer)
			end
			if decoLayer then
				map:drawLayer(decoLayer)
			end
			if deco2Layer then
				map:drawLayer(deco2Layer)
			end
		end
	end
	local update = function(dt)
		if map and map.update then
			map:update(dt)
		end
	end
	maps[mapName] = {
		map = map,
		draw = draw,
		update = update,
	}
	game.map.name = mapName
	game.map.draw = draw
	game.map.update = update
	game.map.map = map
	game.drawOrder.layers.map:add(draw, "Map")
	return map, draw, update
end

return module
