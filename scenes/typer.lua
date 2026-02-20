typer = {
	basepath = "scenes/typer/",
	cloudanim = {
		timer = timer:new(0.1),
		frame = 1,
		rot = 0,
		rot2 = 0,
		center = {
			x = 400,
			y = 375,
		},
	},
	talkanim = {
		talking = true,
		timer = timer:new(0.28),
	},
	points = {}
}

function typer:init()
	self.bgs = {}
	local allfiles = love.filesystem.getDirectoryItems(self.basepath)
	for _, file in ipairs(allfiles) do
		local _, _, ext = string.find(file, "%.([A-Za-z0-9]+)")
		if ext == "JPG" then
			local l = level:new(self.basepath..file, {})
			l.sx, l.sy = 1.25, 1.25
			table.insert(self.bgs, l)
		end
	end

	host = guy:new(self.basepath.."hostclosed.png", 179, 263, 400, 300)
	host:addframe(self.basepath.."hostopen.png")
	host.sx, host.sy = 0.5, 0.5

	cloud = guy:new(self.basepath.."CLO-F1.png", 50, 21, 139, 380)
	for i = 2, 5 do cloud:addframe(self.basepath.."CLO-F"..tostring(i)..".png") end
	cloud.sx, cloud.sy = 2, 2
	print(inspect(cloud.frames))
end

function typer:enter()
	self.bg = trandom(self.bgs)
	TEsound.playLooping(self.basepath.."palj.mp3", "stream", "typermusic")
	TEsound.playLooping(self.basepath.."eb.mp3", "stream", "typermusic", 0.8)
end

function typer:leave()
	TEsound.stop("typermusic")
end

function typer:update(dt)
	-- first orbit
	cloud.x = self.cloudanim.center.x + 300*math.cos(self.cloudanim.rot)
	cloud.y = self.cloudanim.center.y + 100*math.sin(self.cloudanim.rot)

	-- second orbit
	cloud.x = (cloud.x - self.cloudanim.center.x) * math.cos(self.cloudanim.rot2) + (cloud.y - self.cloudanim.center.y) * math.sin(self.cloudanim.rot2) + self.cloudanim.center.x
	cloud.y = (cloud.y - self.cloudanim.center.y) * math.cos(self.cloudanim.rot2) - (cloud.x - self.cloudanim.center.x) * math.sin(self.cloudanim.rot2) + self.cloudanim.center.y
	
	host.x = cloud.x
	host.y = cloud.y - 49

	table.insert(self.points, cloud.x)
	table.insert(self.points, cloud.y)

	self.cloudanim.rot = (self.cloudanim.rot + 11*dt/25) % (2 * math.pi)
	self.cloudanim.rot2 = (self.cloudanim.rot2 + 43*dt/25) % (2 * math.pi)

	if self.cloudanim.timer:countdown(dt) then
		self.cloudanim.frame = (self.cloudanim.frame % 4) + 1
		cloud:setframe("CLO-F"..tostring(self.cloudanim.frame))
		self.cloudanim.timer:reset()
	end

	if self.talkanim.timer:countdown(dt) and self.talkanim.talking then
		if host.frame == "hostclosed" then host:setframe("hostopen")
		elseif host.frame == "hostopen" then host:setframe("hostclosed") 
		else host:setframe("hostopen") end
		self.talkanim.timer:reset()
	end
end

function typer:draw()
	if self.bg then self.bg:draw() end
	love.graphics.setColor(love.math.random(2)-1, love.math.random(2)-1, love.math.random(2)-1)
	love.graphics.points(table.unpack(self.points))
	love.graphics.setColor(0.9, 0.9, 1)
	cloud:draw()
	love.graphics.setColor(1, 1, 1)
	host:draw()
end
