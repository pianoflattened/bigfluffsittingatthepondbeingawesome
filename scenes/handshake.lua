handshake = {
	basepath = "scenes/handshake/",
	timeaccum = 0,
	shakelist = {},
	camwalls = {},
	doesntcounttimer = timer:new(0.3),
	failcount = 0,
	fail = false,
}

function handshake:init()
	friend = guy:new(self.basepath.."friendnohand.png", 0, 0, 229, 253)
	friend.opacity = 0
	friend.reachtimer = timer:new(0.3)

	friendhand = guy:new(self.basepath.."friendhand.png", 84, 96, 315, 453) -- 315 453
	friendhand.show = false
	friendhand.rect = rect:new(315, 453, 63, 46)
	
	friendhouse = level:new(self.basepath.."friendshouse.png", {
		rect:new(0, 0, 300, 600),
	})
	dooropens = guy:new(self.basepath.."dooropens.png")
	dooropens.show = false

	arm = guy:new(self.basepath.."arm.png", 0, 77, 600, 520)
	arm:addframe(self.basepath.."armwarts.png")
	arm.speed = 0
	arm.rect = rect:new(81, -27, 12, 59)

	airplane = guy:new(self.basepath.."airplane.png", 0, 0, 800, 20)
	airplane.speed = 800/30
	airplane.show = false
	
	epiceurobeat = love.audio.newSource(self.basepath.."epiceurobeat.mp3", "stream")
end

function handshake:leave()
	love.audio.stop(epiceurobeat)
	TEsound.stop("airplane", "splat", "heartbeat", "chatter", "breathing")
	camera:reset()

	self.timeaccum = 0
	self.shakelist = {}
	self.camwalls = {}
	self.doesntcounttimer:reset()
	self.failcount = 0

	friend.opacity = 0
	friend.reachtimer:reset()

	friendhand.show = false

	dooropens.show = false

	arm.x = 0
	arm.y = 77
	arm.speed = 0
	arm:setframe()

	airplane.x = 800
	airplane.show = false
end

function handshake:update(dt)
	if not epiceurobeat:isPlaying() then love.audio.play(epiceurobeat) end

	if not airplane.show and love.math.random(200) == 1 then 
		airplane.show = true 
		TEsound.play(self.basepath.."airplane.mp3", "static", "airplane")
	end

	if airplane.show then
		airplane.x = airplane.x - airplane.speed*dt
		if airplane.x == -airplane.width then
			airplane.show = false
		end
	end

	local dx, dy = 0, 0
	
	if love.keyboard.isDown("up")    then dy = dy - arm.speed*dt end
	if love.keyboard.isDown("down")  then dy = dy + arm.speed*dt end
	if love.keyboard.isDown("left")  then dx = dx - arm.speed*dt end
	if love.keyboard.isDown("right") then dx = dx + arm.speed*dt end

	-- arm shake
	local jx = math.random(10*dt*arm.speed)*(love.math.random(3)-2)
	local jy = math.random(10*dt*arm.speed)*(love.math.random(3)-2)

	self.fail = false
	if love.keyboard.isDown("rshift") and arm.frame == "armwarts" and 
	   arm.rect:at(arm.x + dx + jx, arm.y + dy + jy):collides(friendhand.rect) then
		friendhand.y = arm.y + dy - 17

		jx = 1/16*jx
		jy = 1/16*jy
		dx = 0
		
		-- start shaking
		if love.keyboard.isDown("down") == love.keyboard.isDown("up") then
			-- clear progress if no shaking has been inputted for 0.5 seconds
			if self.doesntcounttimer:countdown(dt) then self.fail = true end
			if #self.shakelist > 0 then
				local last = self.shakelist[#self.shakelist]
				last.duration = last.duration + dt
			end
		else -- if ONLY down or ONLY up is pressed
			dy = dy*2 -- let hand move faster up & down
			
			self.doesntcounttimer:reset()
			local shake = { duration = 0 } -- initialize object for shake stack
			if love.keyboard.isDown("down") then shake.direction = "down" end
			if love.keyboard.isDown("up") then shake.direction = "up" end
			
			if #self.shakelist == 0 then 
				table.insert(self.shakelist, shake) 
			end
			local last = self.shakelist[#self.shakelist]

			-- if current direction is opposite of last 
			-- & we were going in current direction for a good amt of time
			-- add it to the stack
			if last.direction == shake.direction then
				last.duration = last.duration + dt
				if last.duration > 0.8 then self.fail = true end
			else
				if last.duration > 0.25 then
					table.insert(self.shakelist, shake)
				else self.fail = true end
			end
		end
	end

	-- doing a fail when list is empty -> fails every dt after one fail
	if self.fail and #self.shakelist > 0 then
		self.shakelist = {}
		TEsound.play(self.basepath.."splat.mp3", "static", "splat")
		self.failcount = self.failcount + 1
	end

	dx = dx + jx
	dy = dy + jy

	local rects = friendhouse.rects
	for _, v in ipairs(self.camwalls) do
		table.insert(rects, v)
	end
	
	if arm.rect:at(arm.x + dx, arm.y + dy):collidesrects(rects) then
		if arm.rect:at(arm.x, arm.y + dy):collidesrects(rects) then dy = 0 end
		if arm.rect:at(arm.x + dx, arm.y):collidesrects(rects) then dx = 0 end
	end

	arm.x = arm.x + dx
	arm.y = arm.y + dy
	
	if self.timeaccum == 0 then
		TEsound.play(self.basepath.."knock.mp3", "static")
	end

	if self.timeaccum > 1.2 and not dooropens.show then
		dooropens.show = true
		TEsound.play(self.basepath.."dooropen.mp3", "static")
	end
	
	if self.timeaccum > 1.4 then 
		friend.opacity = math.min(1, friend.opacity + 0.025) 
		if friend.opacity == 1 and not friendhand.show then
			if friend.reachtimer:countdown(dt) then 
				friendhand.show = true
				arm.speed = 50
			end
		end
		
		if love.math.random(30) == 1 and #TEsound.findTag("heartbeat") == 0 then 
			TEsound.play(self.basepath.."heartbeat.mp3", "static", "heartbeat") end
		if love.math.random(30) == 1 and #TEsound.findTag("teethchatter") == 0 then 
			TEsound.play(self.basepath.."teethchatter.mp3", "static", "teethchatter") end
		if love.math.random(30) == 1 and #TEsound.findTag("breathing") == 0 then 
			TEsound.play(self.basepath.."breathing.mp3", "static", "breathing") end
	end

	if arm.x <= 388 and arm.y > 416 and arm.y < 566 then -- zoom in
		arm:setframe("armwarts")
		camera:zoomTo(4)
		camera:panTo(300, 416)

		-- put a bunch of invisible walls so u cant leave the area
		self.camwalls = rect:new(camera.zoomx, camera.zoomy-50, width/camera.zoom, height/camera.zoom+100):wallsaround(5)
	end

	self.timeaccum = self.timeaccum + dt

	if #self.shakelist == 6 then
		success = true
		gs.switch(fishinhole)
	end

	if self.failcount > 3 then
		success = false
		print("fail!")
		gs.switch(fishinhole)
	end
end

function handshake:draw()
	friendhouse:draw()
	if dooropens.show then dooropens:draw() end
	if airplane.show then airplane:draw() end
	
	love.graphics.setColor(1, 1, 1, friend.opacity)
	friend:draw()
	if friendhand.show then friendhand:draw(friendhand.x, friendhand.y) end
	arm:draw()
	love.graphics.setColor(1, 1, 1, 1)
end

return handshake
