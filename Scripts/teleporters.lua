local loadMap = require("Modules.loadMap")
local tween = require("libs.tween")

local function a()
	if not (#game.teleporters > 0) then
		return
	end

	for _, collider in pairs(game.teleporters) do
		if collider:enter("Player") then
			game.player.states.stunned = true
			local alphaTween
			local cameraTween
			game.updateThreads.threads.interface:add(function (dt)
				if alphaTween ~= nil then
					alphaTween:update(dt)
				end
				if cameraTween ~= nil then
					cameraTween:update(dt)
				end
			end, "MapFadeAwayFromRoomChanging")
			coroutine.wrap(function ()
				alphaTween = tween.new(1, game, {mapAlpha = 0}, tween.easing.inCirc)
				cameraTween = tween.new(1, game.player, {cameraAlpha = 100}, tween.easing.inCirc)
				task.wait(1)
				loadMap.load(collider.name)
				game.player.states.stunned = false
				alphaTween = tween.new(1, game, {mapAlpha = 1}, tween.easing.inCirc)
				cameraTween = tween.new(1, game.player, {cameraAlpha = 2}, tween.easing.inCirc)
				task.wait(1)
			end)()
		end
	end
end

local m = {}

function m.load()
	game.updateThreads.threads.objects:add(a, "Teleporters")
end

return m
