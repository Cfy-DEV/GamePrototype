local loadMap = require "Modules.loadMap"
local tween   = require "libs.tween"
local timer = require "libs.hump.timer"
local updateThreads = require "Modules.updateThreads"
local module = {}

function module.load()
	game.signals.playerDied:connect(function(_, player)
		local oldX = game.camera.x
		local oldY = game.camera.y
		local newPlayer = player:reset()
		game.player = newPlayer
		game.updateThreads.threads.objects:add(newPlayer, "Player")
		game.drawOrder.layers.objects:add(function ()
			newPlayer:draw()
		end, "Player")
		if game.map.name ~= nil then
			newPlayer.updateCamera = false
			loadMap.load(game.map.name)
			local newX = game.camera.x
			local newY = game.camera.y
			game.camera.x = oldX
			game.camera.y = oldY
			local t1 = tween.new(.75, game.camera, {x = newX, y = newY}, tween.easing.outQuad)
			game.updateThreads.threads.objects:add(function (dt)
				t1:update(dt)
				if t1.clock >= t1.duration then
					game.updateThreads.threads.objects:remove("RespawningCameraTween")
					game.player.updateCamera = true
				end
			end, "RespawningCameraTween")
			newPlayer:spawnAnimation()
		end
	end)
end

return module