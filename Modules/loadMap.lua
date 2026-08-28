local module = {}

local sti = require("libs.sti")
local wf = require("libs.windfield")
local lg = love.graphics
local i = 0

function module.load(mapFile)
	if i ~= 0 then
		currentWorld:destroy()
	end
	lg.push()
	local map = sti(mapFile)
	currentMap = map
	if map.layers["Objects"] then
		local objX, objY = getMapLayerObjectRealPosition(map.layers["Objects"], "PlayerSpawn")
		if objX or objY then
			currentPlayer.collider:setPosition(objX, objY)
		end
	end
	if map.layers["Collisions"] then
		for _, info in pairs(map.layers["Collisions"].objects) do
			if not (info.width == 0 or info.height == 0) then
				local wall = currentWorld:newRectangleCollider(
					info.x * conf.MapScale,
					info.y * conf.MapScale,
					info.width * conf.MapScale,
					info.height * conf.MapScale
				)
				wall:setType("static")
			end
		end
	end
	lg.pop()
	return function()
		lg.setColor(1, 1, 1, 1)
		if currentMap ~= nil then
			if currentMap.layers["Background"] then
				currentMap:drawLayer(currentMap.layers["Background"])
			end
			if currentMap.layers["Path"] then
				currentMap:drawLayer(currentMap.layers["Path"])
			end
			if currentMap.layers["Map"] then
				currentMap:drawLayer(currentMap.layers["Map"])
			end
			if currentMap.layers["Deco"] then
				currentMap:drawLayer(currentMap.layers["Deco"])
			end
			if currentMap.layers["Deco2"] then
				currentMap:drawLayer(currentMap.layers["Deco2"])
			end
		end
	end, function(dt)
		map:update(dt)
	end
end

return module
