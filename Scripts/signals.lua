local loadMap = require "Modules.loadMap"
local module = {}

function module.load()
	game.signals.playerDied:connect(function(player)
		local newPlayer = player:reset()
		game.player = newPlayer
		game.updateThreads.threads.objects:add(newPlayer, "Player")
		game.drawOrder.layers.objects:add(function ()
			newPlayer:draw()
		end, "Player")
		if game.map.name ~= nil then
			newPlayer.states.stunned = true
			loadMap.load(game.map.name)
			local t1 = twee
		else
			
		end
	end)
end

return module