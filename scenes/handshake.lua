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

	arm = level:new(self.basepath.."arm.png", 0, 77, 793, 520)
	arm:addframe(self.basepath.."armwarts.png")
	arm.speed = 0
	
	epiceurobeat = love.audio.newSource(self.basepath.."epiceurobeat.mp3", "stream")
end

function handshake:enter()
	self.timeaccum = 0

	friend:setframe("friendnohand")
	friend.opacity = 0
	arm.speed = 0
	
	dooropens.show = false
end

function handshake:update(dt)
	if not epiceurobeat:isPlaying() then love.audio.play(epiceurobeat) end

	local dx, dy = domovement(arm, {
		rect:new(-100, -100, width, 100),
		rect:new(-100, -100, 100, height),
		rect:new(width, 0, 100, height),
		rect:new(0, height, width, 100),
		table.unpack(friendhouse.rects)
	}, dt)
	
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
				arm.speed = 100
			end
		end
		
		if love.math.random(50) == 1 and #TEsound.findTag("heartbeat") == 0 then 
			TEsound.play(self.basepath.."heartbeat.mp3", "static", "heartbeat") end
		if love.math.random(40) == 1 and #TEsound.findTag("headshakes") == 0 then 
			TEsound.play(self.basepath.."headshakes.mp3", "static", "headshakes") end
		if love.math.random(50) == 1 and #TEsound.findTag("breathing") == 0 then 
			TEsound.play(self.basepath.."breathing.mp3", "static", "breathing") end
	end

	self.timeaccum = self.timeaccum + dt
end

function handshake:draw()
	friendhouse:draw()
	if dooropens.show then dooropens:draw() end
	love.graphics.setColor(1, 1, 1, friend.opacity)
	friend:draw()
	love.graphics.setColor(1, 1, 1, 1)
end
