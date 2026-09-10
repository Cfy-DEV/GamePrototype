local module = {}

local timerModule = require("libs.hump.timer")
local timer = timerModule()

local lg = love.graphics
local dialogueActive = false

function module.load()
	game.signals.dialogue:connect(function(_, dialogueFile)
		if dialogueActive then
			return
		end
		dialogueActive = true
		local font = lg.newFont(dialogueFile.font, 16)
		local text = ""
		local index = 1
		local started = love.timer.getTime()
		local dialogueInfo = dialogueFile.dialogue
		local skipped = false
		local function goto_next_dialogue()
			skipped = false
			index = index + 1
			started = love.timer.getTime()
			if index > #dialogueInfo then
				dialogueActive = false
				game.updateThreads.threads.interface:remove("dialogue")
				game.drawOrder.layers.interface:remove("dialogue")
			end
		end
		game.updateThreads.threads.interface:add(function(dt)
			local diff = love.timer.getTime() - started
			local currentInfo = table.clone(dialogueInfo[index])
			if not currentInfo then
				return
			end
			local skip = love.keyboard.isDown("g")
			if skip then
				skipped = true
			end
			if skipped then
				currentInfo.textSpeed = .01
			end
			local currenttext = currentInfo.text
			local timeToFinish = currentInfo.textSpeed * #currenttext
			local perc = math.min(diff / timeToFinish, 1)
			local letters = math.floor(#currenttext * perc)
			if letters == #currenttext then
				text = currenttext
				local gotoNext = love.keyboard.isDown("f")
				if gotoNext and not currentInfo.autoSkip then
					goto_next_dialogue()
				else
					if diff >= timeToFinish + currentInfo.endDelay then
						goto_next_dialogue()
					end
				end
			else
				local finaltext = string.sub(currenttext, 1, letters)
				text = finaltext
			end
		end, "dialogue")
		local backgroundSize = {
			x = 500,
			y = 75,
		}
		game.drawOrder.layers.interface:add(function()
			lg.setFont(font)
			local sX, sY = lg.getDimensions()
			local posX, posY = sX / 2 - backgroundSize.x / 2, sY - backgroundSize.y - 10
			lg.setColor(1, 1, 1, 1)
			lg.setLineWidth(3)
			lg.rectangle("line", posX, posY, backgroundSize.x, backgroundSize.y)
			lg.setColor(0, 0, 0, 1)
			lg.rectangle("fill", posX, posY, backgroundSize.x, backgroundSize.y)
			local tX, tY = posX + 10, posY + 10
			lg.setColor(1, 1, 1, 1)
			lg.printf(text, tX, tY, backgroundSize.x - 20)
		end, "dialogue")
	end)
end

return module
