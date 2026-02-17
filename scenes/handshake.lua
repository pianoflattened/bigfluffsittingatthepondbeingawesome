handshake = {
	basepath = "scenes/handshake/",
	timeaccum = 0
}

function handshake:init()
	friend = guy:newfromfish("friend", 345, 444)
	friend:addframe(self.basepath.."friendnohand.png")
	friend:setframe("friendnohand")
	friend.opacity = 0
	friend.reaching = false
	friend.reachtimer = timer:new(0.3)
	friend.sx = -1
	
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

	friend:setframe("friendnohand")
	friend.opacity = 0
	arm.speed = 0
	
	dooropens.show = false
end

function handshake:leave()
	resetcamera()
end

function handshake:update(dt)
	if not epiceurobeat:isPlaying() then love.audio.play(epiceurobeat) end

	local dx, dy = 0, 0

	if love.keyboard.isDown("up")    then dy = dy - arm.speed*dt end
	if love.keyboard.isDown("down")  then dy = dy + arm.speed*dt end
	if love.keyboard.isDown("left")  then dx = dx - arm.speed*dt end
	if love.keyboard.isDown("right") then dx = dx + arm.speed*dt end

	-- arm shake
	if love.math.random(2) == 1 then dx = dx + math.random(arm.speed*3/4)*(love.math.random(3)-2) end
	if love.math.random(2) == 1 then dy = dy + math.random(arm.speed*3/4)*(love.math.random(3)-2) end

	if arm.rect:at(arm.x + dx, arm.y + dy):collidesrects(friendhouse.rects) then
		if arm.rect:at(arm.x, arm.y + dy):collidesrects(friendhouse.rects) then dy = 0 end
		if arm.rect:at(arm.x + dx, arm.y):collidesrects(friendhouse.rects) then dx = 0 end
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
		if friend.opacity == 1 and not friend.reaching then
			if friend.reachtimer:countdown(dt) then 
				friend:setframe()
				friend.reaching = true
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

	if arm.x <= 388 then -- zoom in
		arm:setframe("armwarts")
		zoom = 4
		zoomx, zoomy = 300, 416
	end

	self.timeaccum = self.timeaccum + dt
end

function handshake:draw()
	friendhouse:draw()
	if dooropens.show then dooropens:draw() end
	love.graphics.setColor(1, 1, 1, friend.opacity)
	friend:draw()
	arm:draw()
	love.graphics.setColor(1, 1, 1, 1)
end
