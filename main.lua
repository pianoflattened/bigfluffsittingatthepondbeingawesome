require 'util'
require 'enum'
require 'guy'
require 'timer'
require 'rect'
require 'fish'
require 'player'
require 'tesound'

function love.load()
	width, height = love.graphics.getDimensions()
	love.graphics.setDefaultFilter("nearest")
	love.graphics.setLineStyle("rough")

	fisher = guy:new("img/fisher.png", 75, 159, 610, 397)
	fisherstates = enum:new("none", "ctrldown", "casting")
	fisher.state = fisherstates.none
	fisher.castTimer = timer:new(0.2)
	fisher.rect = rect:new(-52, 103, 107, 32)
	fisher.speed = 200
	fisher.grunting = false
	
	rod = guy:new("img/rod.png", 132, 98)
	line = guy:new("img/line.png", 172, 97)
	line.oheight = line.img:getHeight()
	line.owidth = line.img:getWidth()
	line:stretchy(0) -- rod starts out reeled in
	line.hstretch = 0
	line.threshold = 50
	line.speed = 400
	line.reeling = false
	line.jittering = false

	lake = level:new("img/level.png", {
		rect:new(114, 273, 121, 86),
		rect:new(180, 291, 208, 195),
		rect:new(132, 354, 54, 97),
		rect:new(362, 344, 290, 111),
		rect:new(383, 300, 41, 186),
		rect:new(424, 455, 90, 22),
		rect:new(145, 451, 35, 29),
		rect:new(298, 279, 82, 12),
		rect:new(538, 327, 107, 17),
		rect:new(514, 455, 105, 17),
		rect:new(651, 351, 28, 101),
		rect:new(135, 450, 14, 20),
	})

	ripple = guy:new("img/ripple.png", 32, 9)
	ripple.inwater = false

	splash = effect:new("img/splash.png", 35, 40)
	splash.spots = {}

	-- accessing particular fish --> fishes.filename or fishes["filename"]
	fishes = loadfish({}) -- all fish have default values for everything unless given in this table
	
	-- bunch of default values that should never see the light of day
	caughtfish = fishes.alan
	caughtfish.x = 0
	caughtfish.y = 0
	caughtfish.show = false
	caughtfish.timer = timer:new(0)
	caughtfish.t = 0
	caughtfish.curve = love.math.newBezierCurve(0, 0, 20, 20, 40, 0)

	scene = 0
	points = 0
	starting = true
	firstsplash = timer:new(2)
	fishspawnfreqtimer = 0

	love.graphics.setBackgroundColor(1, 1, 1)
	canvas = love.graphics.newCanvas(width, height)

	crawdadhole = love.audio.newSource("aud/crawdadhole.wav", "stream")
end

function love.update(dt)
	if scene == 0 then
		fishspawnfreqtimer = fishspawnfreqtimer + dt
		if not crawdadhole:isPlaying() then love.audio.play(crawdadhole) end

		-- checks arrow keys & collision
		local dx, dy = domovement(fisher, lake, dt)
		fisher.x = fisher.x + dx
		fisher.y = fisher.y + dy

		-- reel in line
		if love.keyboard.isDown("lshift") and line.height > 0 then 
			line:stretchy(math.floor(line.height - line.speed*dt))
			line.reeling = true
		else line.reeling = false
		end

		-- move line a little to the right
		if love.keyboard.isDown("x") and line.hstretch > -line.threshold then 
			line:stretchx(math.floor(line.width - line.speed*dt)) -- actually stretches

			-- bookkeeping so that it can't stretch past threshold
			line.hstretch = math.floor(line.hstretch - line.speed*dt)
			if line.hstretch <= -line.threshold then 
				line.hstretch = -line.threshold
				line:stretchx(math.floor(line.owidth - line.threshold))
			end
		end

		-- move line a little to the left
		if love.keyboard.isDown("z") and line.hstretch < line.threshold then 
			line:stretchx(math.floor(line.width + line.speed*dt)) -- actually stretches

			-- bookkeeping
			line.hstretch = math.floor(line.hstretch + line.speed*dt)
			if line.hstretch >= line.threshold then 
				line.hstretch = line.threshold
				line:stretchx(math.floor(line.owidth + line.threshold))
			end
		end

		-- cast line
		if love.keyboard.isDown("lctrl") then
			fisher.castTimer:reset()
			fisher.state = fisherstates.ctrldown

			-- animation stuff
			rod.r = 0.57*math.pi
			rod.oy = rod.ooy + 50
			rod.ox = rod.oox + 10
			
			line.r = 0.57*math.pi
			line.ox = line.oox + 50
			line.oy = line.ooy + 10
		
		-- cast timer only starts counting down AFTER ctrl is released
		elseif fisher.state == fisherstates.ctrldown then fisher.state = fisherstates.casting end
		if fisher.state == fisherstates.casting and fisher.castTimer:countdown(dt) then
			-- reset animation stuff
			rod.r = 0
			line.r = 0
			rod.oy = rod.ooy
			rod.ox = rod.oox
			line.ox = line.oox
			line.oy = line.ooy

			-- extend the line, limit to 5 casts
			line:stretchy(line.height + line.oheight, line.oheight*5)
			
			fisher.state = fisherstates.none
			fisher.castTimer:reset()
		end

		-- i set the offsets for the line and rod so that this works
		rod.x, rod.y = fisher.x, fisher.y
		line.x, line.y = fisher.x, fisher.y
		ripple.x = line.x - line.oox - line.hstretch
		ripple.y = line.y - line.ooy + (line.height)
		ripple.inwater = pointinrects(ripple.x, ripple.y, lake.rects) and line.height >= 12

		-- i try to get the spawns going really quick
		-- firstsplash guarantees a fish spawns within the first 2 seconds
		if starting and firstsplash:countdown(dt) then
			table.insert(splash.spots, tryspawnfish(lake.rects, fishspawnfreqtimer, true))
			starting = false
		
		-- if not at the beginning only try to spawn when a fish is not being caught
		-- we test by seeing if controls r locked
		elseif fisher.speed > 0 then
			local maybespawn = tryspawnfish(lake.rects, fishspawnfreqtimer)
			if maybespawn then table.insert(splash.spots, maybespawn) end
		end

		-- if above manages to spawn a fish in a certain spot,
		-- the x/y goes into a table along with a timer
		local forremoval = {}
		for idx, spot in ipairs(splash.spots) do
			-- each timer is counted down & if at 0, then
			if not spot.snagged and spot.timer:countdown(dt) then
				table.insert(forremoval, idx) -- the index is queued for removal
			end

			-- -- once a fish is snagged the timer should not cause the spot to disappear
			-- if spot.snagged and spot.timer.clock > 0.5 then spot.timer.clock = 0.5 end
		end

		-- here we check to see if the ripple collides with any of the splash points
		for idx, spot in ipairs(splash.spots) do
			local collides = ripple:rect():haspoint(spot.x, spot.y)
			if collides then
				if not spot.snagged then
					spot.snagged = true
					if not spot.pulltimer then spot.pulltimer = timer:new(1) end
					line.speed = 0
				end

				if line.reeling then
					if not fisher.grunting then
						local grunter = trandom({"alan", "macy", "jack", "june"})
						TEsound.play("aud/"..grunter.."grunt.mp3", "static", 1)
						fisher.grunting = true
						line.jittering = true
					end
					
					if spot.pulltimer:countdown(dt) then
						table.insert(forremoval, idx)
						caughtfish = dictrandom(fishes)
						line.speed = 400
						
						-- animation stuff
						caughtfish.x, caughtfish.y = spot.x, spot.y
						caughtfish.ox, caughtfish.oy = spot.x, spot.y
						-- amount of time spent following the catch curve
						caughtfish.timer = timer:new(1.5)
	
						-- makes sure the fish is drawn
						caughtfish.show = true
						fisher.grunting = false
						line.jittering = false
					end
				end
			end

			if caughtfish.show then line.speed = 400 end
		end

		-- sort greatest to least so indices dont get fd up
		table.sort(forremoval, function(a, b) return a > b end)
		for _, idx in ipairs(forremoval) do
			-- remove everything that needs to go
			table.remove(splash.spots, idx)
		end

		-- i need to make it so that reeling in the fish (shift) catches it
		-- and u can fail to catch by not reeling. and it pulls a little
		if caughtfish.show then			
			if caughtfish.timer:countdown(math.sqrt(dt)/4) then
				caughtfish.timer:reset()
				points = points + caughtfish.points
				fisher.speed = 200 
				caughtfish.show = false
			end

			caughtfish.curve = fishcurve(caughtfish.ox, caughtfish.oy, fisher.x, fisher.y-fisher.height/3)
			caughtfish.x, caughtfish.y = caughtfish.curve:evaluate(1-caughtfish.timer:progress())
		end
	end
	
	TEsound.cleanup()
end

function love.draw()
	love.graphics.setCanvas(canvas)
	love.graphics.clear(1, 1, 1)

	if scene == 0 then
		love.graphics.setColor(1, 1, 1)

		
		lake:draw(0, 0)
		if fisher.state == fisherstates.none and ripple.inwater then 
			ripple:draw() 
		end
		
		for _, spot in ipairs(splash.spots) do splash:draw(spot.x, spot.y) end

		if line.jittering then
			local jitteramt = 20
			line:draw(line.x + (jitteramt*(love.math.random()-0.5)),
					  line.y + (jitteramt*(love.math.random()-0.5))) 
		else
			line:draw()
		end
		
		fisher:draw()
		rod:draw()
		if caughtfish.show then
			caughtfish:draw(caughtfish.x, caughtfish.y, caughtfish.scale) 
		end
	end

	love.graphics.setColor(1, 0, 0)
	love.graphics.printf("POINTS: $"..tostring(points), 0, 5, 525, "right", 0, 1.45, 2.142857)
	love.graphics.setColor(1, 1, 1)

	love.graphics.setCanvas()
	love.graphics.setBackgroundColor(0.5, 0.5, 0.5)
	love.graphics.draw(canvas, 0, 0, 0, scale, scale)
end
