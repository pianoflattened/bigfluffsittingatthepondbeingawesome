-- TO CONTINUE THIS GAME I WANT TO FIGURE OUT
-- - TEXTURING
-- - BILLBOARDED SPRITES
-- - OTHER LIGHT SOURCES OF DIFF COLORS
-- THIS WILL TAKE UP A LOT OF MY TIME LOL LMAO
-- ALSO SOUNDTRACK FOR THIS WILL BE PLAYA ONE & BLOODY BONES WANTED 4 A HOMICIDE. THANKS
raycasttest = {
	basepath = "scenes/raycasttest/",
	level = {
		{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, 
		{1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, 
		{1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, 
		{1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1}, 
		{1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1}, 
		{1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1}, 
		{1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1}, 
		{1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1}, 
		{1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, 
		{1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1}, 
		{1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, 
		{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, 
	},
	me = {
		x = 3,
		y = 3,
		z = 0,
		fov = math.pi/3,
		movespeed = 7,
		rot = 0,
		rotspeed = math.pi/2,
	},
}

function raycasttest:init()
	wall = love.image.newImageData(self.basepath.."wall.png")
	textures = {wall}
end

function raycasttest:leave()
end

function raycasttest:update(dt)
	local dx, dy = 0, 0
	if love.keyboard.isDown("up") then
		dx = math.cos(self.me.rot) * self.me.movespeed * dt
		dy = math.sin(self.me.rot) * self.me.movespeed * dt  
	end   

	if love.keyboard.isDown("down") then
		dx = -math.cos(self.me.rot) * self.me.movespeed * dt
		dy = -math.sin(self.me.rot) * self.me.movespeed * dt   
	end 

	if not love.keyboard.isDown("lshift") then
		if love.keyboard.isDown("left") then     
			self.me.rot = self.me.rot - self.me.rotspeed * dt
		end
		
		if love.keyboard.isDown("right") then     
			self.me.rot = self.me.rot + self.me.rotspeed * dt   
		end
	else
		if love.keyboard.isDown("left") then     
			dx = dx - math.cos((self.me.rot + math.pi/2) % (math.pi*2)) * self.me.movespeed * dt
			dy = dy - math.sin((self.me.rot + math.pi/2) % (math.pi*2)) * self.me.movespeed * dt
		end
		
		if love.keyboard.isDown("right") then
			dx = dx - math.cos((self.me.rot - math.pi/2) % (math.pi*2)) * self.me.movespeed * dt
			dy = dy - math.sin((self.me.rot - math.pi/2) % (math.pi*2)) * self.me.movespeed * dt  
		end
	end

	self.me.rot = self.me.rot % (math.pi*2)
	local nextx = math.floor(self.me.x + dx)
	if self.level[math.floor(self.me.y)][nextx] == 0 then
		self.me.x = self.me.x + dx
	end

	local nexty = math.floor(self.me.y + dy)
	if self.level[nexty][math.floor(self.me.x)] == 0 then
		self.me.y = self.me.y + dy
	end
end

function raycasttest:draw()
	love.graphics.clear(0.1, 0.1, 0.1)
	self:raycast()
end

function raycasttest:raycast()
	local rays = 20
	local slicewidth = width / rays
	local step = self.me.fov / rays

	for i = 0, rays do
		local angle = self.me.rot - (self.me.fov/2) + i * step
		local h = self:castray(angle)
		self:wall(i, 300/h, h, slicewidth)
	end
end

function raycasttest:castray(angle)
	local x = self.me.x
	local y = self.me.y
	local dx = math.cos(angle)
	local dy = math.sin(angle)

	local i = 0
	while self.level[math.floor(y)][math.floor(x)] == 0 do
		x = x + dx * 0.1
		y = y + dy * 0.1
		i = i + 1
		if i > 400 then break end
	end

	return 300/math.sqrt((x - self.me.x)^2 + (y - self.me.y)^2)
end

function raycasttest:wall(i, dist, h, w)
	local darkness = 1 + (dist/4)

	for j = 0, h do
		local ypos = math.floor(300 - h/2 + j)
		love.graphics.setColor(0.7/darkness, 0.7/darkness, 0.7/darkness)
		love.graphics.rectangle("fill", i * w, ypos, w, 1)
	end
end

return raycasttest
