-- inspect = require 'lib.inspect'
require 'lib.util'
require 'lib.tesound'

require 'rect'
require 'fish'
require 'guy'
require 'player'
require 'scene'

-- numbers start at 53, 69 on alarm
-- hammer starts at 71, 20
points = 0
fishes = {}
width, height = 800, 600
function love.load()
	width, height = love.graphics.getDimensions()
	love.graphics.setDefaultFilter("nearest")
	love.graphics.setLineStyle("rough")
	love.graphics.setBackgroundColor(1, 1, 1)
	canvas = love.graphics.newCanvas(width, height)

	-- accessing particular fish --> fishes.filename or fishes["filename"]
	fishes = loadfish({}) -- all fish have default values for everything unless given in this table

	-- uses functions in fishinhole.lua to start out
	gs.switch(fishinhole)
end

function love.update(dt)
	gs.update(dt)

	-- they said i had to do this idk wat it means
	TEsound.cleanup()
end

function love.draw()
	love.graphics.setCanvas(canvas)
	love.graphics.clear(1, 1, 1)
	love.graphics.setColor(1, 1, 1)

	gs.draw()

	love.graphics.setColor(1, 0, 0)
	love.graphics.printf("POINTS: $"..tostring(points), 0, 5, 525, "right", 0, 1.45, 2.142857)
	love.graphics.setColor(1, 1, 1)

	love.graphics.setCanvas()
	love.graphics.setBackgroundColor(0.5, 0.5, 0.5)
	love.graphics.draw(canvas, 0, 0, 0, scale, scale)
end
