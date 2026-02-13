width, height = 800, 600
require 'util'
require 'level'
require 'timer'
require 'rect'
require 'fish'

require 'tesound'

function love.load()
	love.graphics.setDefaultFilter("nearest")
	love.graphics.setLineStyle("rough")

	fisher = guy:new("img/fisher.png", 75, 159, 610, 397)
	fisher.hasrod = true
	fisher.casting = false
	fisher.castTimer = timer:new(0.2)
	fisher.ctrldown = false
	fisher.rect = rect:new(-52, 103, 107, 32)
	fisher.fishin = false
	fisher.speed = 200
	
	rod = guy:new("img/rod.png", 132, 98)
	line = guy:new("img/line.png", 172, 97)
	line:stretchy(0)
	line.hstretch = 0
	line.threshold = 50
	line.speed = 400

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

	fishes = {
		alan = fish:new("fish/alan.png"),
		geofish = fish:new("fish/geofish.png"),
		eel = fish:new("fish/eel.png"),
		shellwyck = fish:new("fish/shellwyck.png"),
		pish = fish:new("fish/pish.png"),
		gish = fish:new("fish/gish.png"),
		oish = fish:new("fish/oish.png"),
		fish2 = fish:new("fish/fish2.png"),
		dish = fish:new("fish/dish.png"),
		friend = fish:new("fish/friend.png"),
		vish = fish:new("fish/vish.png"),
		ruth = fish:new("fish/ruth.png"),
		unamused = fish:new("fish/unamused.png"),
		suitfish = fish:new("fish/suitfish.png"),
		alan = fish:new("fish/alan.png"),
		max = fish:new("fish/max.png"),
		max1 = fish:new("fish/max1.png"),
		max2 = fish:new("fish/max2.png"),
		max3 = fish:new("fish/max3.png"),
		max4 = fish:new("fish/max4.png"),
		max5 = fish:new("fish/max5.png"),
		mondrary = fish:new("fish/mondrary.png"),
		max6 = fish:new("fish/max6.png"),
		ben = fish:new("fish/ben.png"),
		max7 = fish:new("fish/max7.png"),
		prechoo = fish:new("fish/prechoo.png"),
		words = fish:new("fish/words.png"),
		hive = fish:new("fish/hive.png"),
		alan1 = fish:new("fish/alan1.png"),
		clownfishinthecomputer = fish:new("fish/clownfishinthecomputer.png"),
		emily = fish:new("fish/emily.png"),
		ugy = fish:new("fish/ugy.png"),
		drunkfish1 = fish:new("fish/drunkfish1.png"),
		drunkfish2 = fish:new("fish/drunkfish2.png"),
		drunkfish13 = fish:new("fish/drunkfish13.png"),
		beautifulfishency = fish:new("fish/beautifulfishency.png"),
	}
	
	caughtfish = fishes[1]
	caughtfish.x = 0
	caughtfish.y = 0
	caughtfish.state = "hidden"
	caughtfish.timer = timer:new(0)
	caughtfish.t = 0
	caughtfish.curve = love.math.newBezierCurve(0, 0, 20, 20, 40, 0)

	love.graphics.setBackgroundColor(1, 1, 1)
	scene = 0
	scale = 1
	width, height = love.graphics.getDimensions()
	canvas = love.graphics.newCanvas(width*2*(1/scale), height*2*(1/scale))
	song = love.audio.newSource("aud/crawdadhole.wav", "stream")
	points = 0
	starting = true
	firstsplash = timer:new(2)
end

function love.update(dt)
	if scene == 0 then
		if not song:isPlaying() then
			love.audio.play(song)
		end

		local dx = 0
		local dy = 0
		if love.keyboard.isDown("up")    then dy = dy - fisher.speed*dt end
		if love.keyboard.isDown("down")  then dy = dy + fisher.speed*dt end
		if love.keyboard.isDown("left")  then dx = dx - fisher.speed*dt end
		if love.keyboard.isDown("right") then dx = dx + fisher.speed*dt end
		
		if love.keyboard.isDown("lshift") and line.height > 0 then line:stretchy(math.floor(line.height - line.speed*dt)) end
		if love.keyboard.isDown("x") and line.hstretch > -line.threshold then 
			line:stretchx(math.floor(line.width - line.speed*dt))
			line.hstretch = math.floor(line.hstretch - line.speed*dt)
			if line.hstretch <= -line.threshold then line.hstretch = -line.threshold end
		end
		if love.keyboard.isDown("z") and line.hstretch < line.threshold then 
			line:stretchx(math.floor(line.width + line.speed*dt))
			line.hstretch = math.floor(line.hstretch + line.speed*dt)
			if line.hstretch >= line.threshold then line.hstretch = line.threshold end
		end

		if fisher.rect:at(fisher.x + dx, fisher.y + dy):collidesrects(lake.rects) then
			if fisher.rect:at(fisher.x, fisher.y + dy):collidesrects(lake.rects) then dy = 0 end
			if fisher.rect:at(fisher.x + dx, fisher.y):collidesrects(lake.rects) then dx = 0 end
		end

		fisher.x = fisher.x + dx
		fisher.y = fisher.y + dy

		if love.keyboard.isDown("lctrl") then -- cast line
			fisher.castTimer:reset()
			fisher.ctrlDown = true
			rod.r = 0.57*math.pi
			rod.oy = rod.ooy + 50
			rod.ox = rod.oox + 10
		elseif fisher.ctrlDown then
			fisher.casting = true
			fisher.ctrlDown = false
		end

		if fisher.casting and fisher.castTimer:countdown(dt) then
			rod.r = 0
			line.r = 0
			
			fisher.casting = false
			fisher.castTimer:reset()
			rod.oy = rod.ooy
			rod.ox = rod.oox
			line.oy = line.ooy
			line:stretchy(line.height + line.img:getHeight())
		end
		
		if fisher.hasrod then
			rod.x, rod.y = fisher.x, fisher.y
			line.x, line.y = fisher.x, fisher.y
		end

		ripple.x = line.x - line.oox - line.hstretch
		ripple.y = line.y - line.ooy + (line.height)
		ripple.inwater = pointinrects(ripple.x, ripple.y, lake.rects) and line.height >= 12

		if starting and firstsplash:countdown(dt) then
			table.insert(splash.spots, tryspawnfish(lake.rects, true))
			starting = false
		elseif fisher.speed > 0 then
			local maybespawn = tryspawnfish(lake.rects)
			if maybespawn then table.insert(splash.spots, maybespawn) end
		end

		local forremoval = {}
		for idx, spot in ipairs(splash.spots) do
			if spot.timer:countdown(dt) then
				table.insert(forremoval, idx)
			end

			if spot.snagged and spot.timer.clock > 0.5 then spot.timer.clock = 0.5 end
		end

		for _, spot in ipairs(splash.spots) do
			if ripple:rect():haspoint(spot.x, spot.y) and not spot.snagged then
				table.insert(forremoval, idx)
				spot.snagged = true
				caughtfish.img = dictrandom(fishes)
				caughtfish.x = spot.x
				caughtfish.y = spot.y
				caughtfish.timer = timer:new(5)
				caughtfish.state = "emerges"
				caughtfish.t = 0
			end
		end

		-- sort greatest to least so indices dont get fd up
		table.sort(forremoval, function(a, b) return a > b end)
		for _, idx in ipairs(forremoval) do
			table.remove(splash.spots, idx)
		end

		if not caughtfish.timer:countdown(dt) then
			local curvetime = 1.5
			if caughtfish.state == "emerges" then
				caughtfish.curve = fishcurve(caughtfish.x, caughtfish.y, fisher.x, fisher.y-fisher.height/3)
				-- lock controls
				fisher.speed = 0
				caughtfish.state = "catching"
			elseif caughtfish.state == "catching" then
				caughtfish.t = caughtfish.t + math.sqrt(dt)/3
				if caughtfish.t > curvetime then caughtfish.t = curvetime end
				caughtfish.x, caughtfish.y = caughtfish.curve:evaluate(caughtfish.t/curvetime)
			end

			if caughtfish.state == "hidden" then 
				fisher.speed = 200 
			elseif caughtfish.t >= curvetime then
				points = points + (caughtfish.points or 1)
				caughtfish.state = "hidden" 
			end
		else caughtfish.state = "hidden" end
	end
	TEsound.cleanup()
end

function love.draw()
	love.graphics.setCanvas(canvas)
	love.graphics.clear(1, 1, 1)

	if scene == 0 then
		love.graphics.setColor(1, 1, 1)
		lake:draw(0, 0)

		if not fisher.casting and not fisher.ctrlDown and ripple.inwater then
			ripple:draw()
			-- ripple:rect():draw("line")
		end

		for _, spot in ipairs(splash.spots) do
			splash:draw(spot.x, spot.y)
		end
		
		line:draw()
		fisher:draw()
		rod:draw()
		if caughtfish.state ~= "hidden" then
			local scale = 100/math.min(caughtfish.img.width, caughtfish.img.height)
			caughtfish:draw(caughtfish.x, caughtfish.y, scale)
			-- love.graphics.setColor(0, 0, 1)
			-- love.graphics.line(caughtfish.curve:render())
			-- love.graphics.setColor(1, 1, 1)
		end
	end

	love.graphics.setColor(1, 0, 0)
	love.graphics.printf("POINTS: $"..tostring(points), 0, 5, 525, "right", 0, 1.45, 2.142857)
	love.graphics.setColor(1, 1, 1)

	love.graphics.setCanvas()
	love.graphics.setBackgroundColor(0.5, 0.5, 0.5)
	love.graphics.draw(canvas, 0, 0, 0, scale, scale)
end
