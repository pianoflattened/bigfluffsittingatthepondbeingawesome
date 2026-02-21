fishinhole = {
	basepath = "scenes/fishinhole/"
}

function fishinhole:init()
	fisher = guy:new(self.basepath.."bigfluff.png", 99, 165, 610, 397)
	fisherstates = enum:new("none", "ctrldown", "casting")
	fisher.state = fisherstates.none
	fisher.castTimer = timer:new(0.2)
	fisher.rect = rect:new(-42, 93, 87, 32)
	fisher.speed = 200
	fisher.grunting = false
	
	rod = guy:new(self.basepath.."rod.png", 193, 210) -- 132, 30
	line = guy:new(self.basepath.."line.png", 233, 208) -- 172, 97
	line.oheight = line.img:getHeight()
	line.owidth = line.img:getWidth()
	line:stretchy(0) -- rod starts out reeled in
	line.hstretch = 0
	line.threshold = 50
	line.speed = 400
	line.reeling = false

	lake = level:new(self.basepath.."level.png", {
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

	ripple = guy:new(self.basepath.."ripple.png", 32, 9)
	ripple.inwater = false

	splash = effect:new(self.basepath.."splash.png", 35, 40)
	splash.spots = {}
	
	-- bunch of default values that should never see the light of day
	caughtfish = fishes.alan
	caughtfish.x = 0
	caughtfish.y = 0
	caughtfish.show = false
	caughtfish.timer = timer:new(0)
	caughtfish.t = 0
	caughtfish.curve = love.math.newBezierCurve(0, 0, 20, 20, 40, 0)

	starting = true
	firstsplash = timer:new(2)
	fishspawnfreqtimer = 0

	crawdadhole = love.audio.newSource(self.basepath.."bigfluff.wav", "stream")
end

function fishinhole:leave() 
	love.audio.stop(crawdadhole)
end

function fishinhole:update(dt)
	fishspawnfreqtimer = fishspawnfreqtimer + dt
	if not crawdadhole:isPlaying() then love.audio.play(crawdadhole) end

	-- checks arrow keys & collision
	local dx, dy = domovement(fisher, {
		rect:new(-5, -5, width+210, 5), -- top
		rect:new(-5, -5, 5, height+10), -- left
		rect:new(width+200, -5, 5, height+10), -- right
		rect:new(width, height, width+210, 5), -- bottom
		table.unpack(lake.rects)
	}, dt, function (x, dt, s) return x + dt*s end)
	
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
		table.insert(splash.spots, self:tryspawnfish(lake.rects, fishspawnfreqtimer, true))
		starting = false
	
	-- if not at the beginning only try to spawn when a fish is not being caught
	-- we test by seeing if controls r locked
	elseif fisher.speed > 0 then
		local maybespawn = self:tryspawnfish(lake.rects, fishspawnfreqtimer)
		if maybespawn then table.insert(splash.spots, maybespawn) end
	end

	-- if above manages to spawn a fish in a certain spot,
	-- the x/y goes into a table along with a timer
	local forremoval = {}
	for idx, spot in ipairs(splash.spots) do
		-- each timer is counted down while untouched by the player & if at 0,
		if not spot.snagged and spot.timer:countdown(dt) then
			table.insert(forremoval, idx) -- then the index is queued for removal
		end
	end

	-- here we check to see if the ripple collides with any of the splash points
	-- used to be a bug where finding multiple spots would freeze the rod
	-- this picks the closest one
	local collidedspot = nil
	local collideddist = math.huge
	local collidedidx = nil
	for idx, spot in ipairs(splash.spots) do
		local collides = ripple:rect():haspoint(spot.x, spot.y)
		local distance = distance(ripple:rect():center(), {spot.x, spot.y})
		if collides and distance < collideddist then 
			collidedspot = spot
			collideddist = distance
			collidedidx = idx
		end
	end

	if collidedspot ~= nil and line.reeling then
		if not collidedspot.snagged then 
			collidedspot.snagged = true -- can probably remove this but like it doesnt matter idk it works
			if not collidedspot.pulltimer then collidedspot.pulltimer = timer:new(1) end
			line.speed = 0
		end

		if not fisher.grunting then 
			local grunter = trandom({"alan", "macy", "jack", "june"})
			TEsound.play(self.basepath..grunter.."grunt.mp3", "static", 1)
			fisher.grunting = true
		end

		if collidedspot.pulltimer:countdown(dt) then
			table.insert(forremoval, collidedidx)
			local fishesinorder = keys(fishes)
			local fishweights = {}
			for _, k in ipairs(fishesinorder) do table.insert(fishweights, fishes[k].rarity) end
			local fishname = weightedrandom(fishesinorder, fishweights)
			caughtfish = fishes[fishname]

			if scenes[fishname] then gs.switch(scenes[fishname]) end
			points = points + caughtfish.points

			-- put fish at beginning of curve
			caughtfish.x, caughtfish.y = collidedspot.x, collidedspot.y
			caughtfish.ox, caughtfish.oy = collidedspot.x, collidedspot.y
			-- amount of time spent following the catch curve
			caughtfish.timer = timer:new(1.5)

			-- makes sure the fish is drawn
			caughtfish.show = true
			-- stop playing the sound & let the line move
			line.speed = 400
			fisher.grunting = false
		end
	elseif collidedspot then
		if collidedspot.pulltimer then collidedspot.pulltimer:reset() end
		collidedspot.snagged = false
		line.speed = 400
		fisher.grunting = false
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

		-- follow the curve
		caughtfish.curve = fishcurve(caughtfish.ox, caughtfish.oy, fisher.x, fisher.y-fisher.height/3)
		caughtfish.x, caughtfish.y = caughtfish.curve:evaluate(1-caughtfish.timer:progress())
	end
end

function fishinhole:draw()
	love.graphics.setColor(1, 1, 1)
			
	lake:draw(0, 0)
	if fisher.state == fisherstates.none and ripple.inwater then 
		ripple:draw()
	end
	
	for _, spot in ipairs(splash.spots) do splash:draw(spot.x, spot.y) end

	-- makes line jitter only visual so doesnt mess w physics
	if fisher.grunting then
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

function fishinhole:tryspawnfish(rects, freq, force)
	local fishchance = math.ceil(1500/((freq/120)+5))
	if love.math.random(1, fishchance) == 1 or force then
		local weights = {}
		for _, r in ipairs(rects) do table.insert(weights, r:area()) end
		local whichrect = weightedrandom(rects, weights)

		local spawnx, spawny = whichrect:randpoint()
		local timer = timer:new(3.6) -- length of splash audio

		TEsound.play(self.basepath.."splash.mp3", "static", {}, 0.8)
		return {
			x = spawnx, 
			y = spawny,
			timer = timer,
		}
	end
	return false
end

function fishcurve(x1, y1, x3, y3)
	local x2 = (x1+x3)/2
	local y2 = 2*catenary(x1, y1, x3, y3)(x2)
	return love.math.newBezierCurve(x1, y1, x2, y2, x3, y3)
end
