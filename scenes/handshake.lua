handshake = {
	basepath = "scenes/handshake/",
	timeaccum = 0,
	shakelist = {},
	camwalls = {},
	doesntcounttimer = timer:new(0.3)
}

function handshake:init()
	friend = guy:new(self.basepath.."friendnohand.png", 0, 0, 229, 253)
	friend.opacity = 0
	friend.reachtimer = timer:new(0.3)
	-- friend.sx = -1

	friendhand = guy:new(self.basepath.."friendhand.png", 0, 0, 231, 357)
	friendhand.show = false
	friendhand.rect = rect:new(315, 453, 63, 46)
	friendhand.dy = 0
	-- friendhand.sx = -1
	
	friendhouse = level:new(self.basepath.."friendshouse.png", {
		rect:new(0, 0, 300, 600),
	})
	dooropens = guy:new(self.basepath.."dooropens.png")
	dooropens.show = false

	arm = guy:new(self.basepath.."arm.png", 0, 77, 600, 520)
	arm:addframe(self.basepath.."armwarts.png")
	arm.speed = 0
	arm.rect = rect:new(81, -27, 12, 59)
	
	epiceurobeat = love.audio.newSource(self.basepath.."epiceurobeat.mp3", "stream")
end

function handshake:enter()
	self.timeaccum = 0
	self.shakelist = {}
	self.camwalls = {}
	self.doesntcounttimer:reset()
	
	friend.opacity = 0
	friend.reachtimer:reset()

	friendhand.show = false

	dooropens.show = false
	arm.speed = 0
	arm:setframe()
end

function handshake:leave()
	camera:reset()
end

function handshake:update(dt)
	if not epiceurobeat:isPlaying() then love.audio.play(epiceurobeat) end

	local dx, dy = 0, 0
	
	if love.keyboard.isDown("up")    then dy = dy - arm.speed*dt end
	if love.keyboard.isDown("down")  then dy = dy + arm.speed*dt end
	if love.keyboard.isDown("left")  then dx = dx - arm.speed*dt end
	if love.keyboard.isDown("right") then dx = dx + arm.speed*dt end

	-- arm shake
	local jx = math.random(arm.speed*2/3)*(love.math.random(3)-2)
	local jy = math.random(arm.speed*2/3)*(love.math.random(3)-2)

	if love.keyboard.isDown("rshift") and arm.frame == "armwarts" and 
	   arm.rect:at(arm.x + dx + jx, arm.y + dy + jy):collides(friendhand.rect) then
		jx = 1/16*jx
		jy = 1/16*jy
		dx = 0

		local fail = false
		-- start shaking
		if love.keyboard.isDown("down") == love.keyboard.isDown("up") then
			-- clear progress if no shaking has been inputted for 0.5 seconds
			if self.doesntcounttimer:countdown(dt) then fail = true end
		else -- if ONLY down or ONLY up is pressed
			dy = dy*3 -- let hand move faster up & down
			friendhand.dy = dy -- friend's hand follows
			
			self.doesntcounttimer:reset()
			local shake = { duration = 0 } -- initialize object for shake stack
			if love.keyboard.isDown("down") then shake.direction = "down" end
			if love.keyboard.isDown("up") then shake.direction = "up" end
			
			if #self.shakelist == 0 then table.insert(self.shakelist, shake) end
			local last = self.shakelist[#self.shakelist]

			-- if current direction is opposite of last 
			-- & we were going in current direction for a good amt of time
			-- add it to the stack
			if last.direction ~= shake.direction then
				if last.duration > 0.5 then
					table.insert(self.shakelist, shake)
				else fail = true end
			else
				last.duration = last.duration + dt
				if last.duration > 2 then fail = true end
			end
		end
	end

	if fail then
		self.shakelist = {}
		friendhand.dy = 0
		if #TEsound.findTag("splat") == 0 then 
			TEsound.play(self.basepath.."splat.mp3", "static", "splat") 
		end
	end

	if #self.shakelist == 6 then
		gs.switch(fishinhole)
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
				arm.speed = 10
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
		self.camwalls = rect:new(camera.zoomx, camera.zoomy-50, width/camera.zoom, height/camera.zoom+100):wallsaround(5)
	end

	self.timeaccum = self.timeaccum + dt
end

function handshake:draw()
	friendhouse:draw()
	if dooropens.show then dooropens:draw() end
	love.graphics.setColor(1, 1, 1, friend.opacity)
	friend:draw()
	if friendhand.show then 
		friendhand:draw(friendhand.x, friendhand.y + friendhand.dy)
		friendhand.rect:draw("line")
	end
	arm:draw()
	arm.rect:at(arm.x, arm.y):draw("line")
	love.graphics.setColor(1, 1, 1, 1)
end
