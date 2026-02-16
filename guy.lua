guy = {}
guy.__index = guy
function guy:new(path, ox, oy, x, y)
	local o = setmetatable({}, self)
	o.img = love.graphics.newImage(path)
	o.path = path
	
	-- sometimes i have to mess w the offsets when i scale guys
	-- to do it properly i store the original offsets and divide them to get a desired size
	-- hence "oox" "ooy"
	o.ox, o.oox = ox or 0, ox or 0
	o.oy, o.ooy = oy or 0, oy or 0
	o.width = o.img:getWidth()
	o.height = o.img:getHeight()

	o.r = 0
	o.sx, o.sy = 1, 1
	o.x, o.y = x or 0, y or 0
	return o
end

function guy:newfromfish(fish, x, y, ox, oy)
	local o = setmetatable({}, self)
	local f = fishes[fish]
	o.img = f.img
	o.path = f.path
	o.width = f.len
	o.height = f.img:getHeight()
	o.ox, o.oy = o.width/2, o.height/2
	o.oox, o.ooy = o.ox, o.oy
	o.r = 0
	o.sx, o.sy = 1, 1
	o.x, o.y = x or 0, y or 0
	return o
end

function guy:draw(x, y)
	x = x or self.x or width/2
	y = y or self.y or height/2
	self.x = x
	self.y = y
	love.graphics.draw(self.img, x, y, self.r, self.sx, self.sy, self.ox, self.oy)
end

function guy:stretchx(newwidth, limit)
	if limit and newwidth > limit then newwidth = limit end

	self.sx = newwidth / self.img:getWidth()
	self.ox = ((self.oox-39) / self.sx) + 39
	self.width = newwidth
end

function guy:stretchy(newheight, limit)
	if limit and newheight > limit then newheight = limit end
	if newheight <= 0 then newheight = 0.01 end

	self.sy = newheight / self.img:getHeight()
	self.oy = self.ooy / self.sy
	self.height = newheight
end

function guy:rect()
	return rect:new(self.x - self.ox, self.y - self.oy, self.width, self.height)
end

-- animation functions
function guy:addframe(path) -- this should only be used in loading scripts
	if not self.frames then self.frames = { default = self.img }  end
	self.frames[stripfilename(path)] = love.graphics.newImage(path)
end

function guy:setframe(name)
	if not name then name = "default" end
	self.img = self.frames[name]
end

function guy:frame()
	if not self.frames then return "default" end
	for k, v in pairs(self.frames) do
		if self.img == v then return k end
	end
	return "default"
end

effect = {}
effect.__index = effect
function effect:new(path, ox, oy)
	local o = setmetatable({}, self)
	o.img = love.graphics.newImage(path)
	o.path = path
	o.width = o.img:getWidth()
	o.height = o.img:getHeight()
	o.ox = ox or o.width/2 or 0
	o.oy = oy or o.height/2 or 0
	o.oox = o.ox
	o.ooy = o.oy
	-- o.r = 0
	-- o.sx = 1
	-- o.sy = 1
	return o
end

function effect:draw(x, y, scale)
	scale = scale or 1
	love.graphics.draw(self.img, x, y, 0, scale, scale, self.ox, self.oy)
end


level = {}
level.__index = level
setmetatable(level, {__index = guy})

function level:new(path, rects)
	local o = setmetatable(guy:new(path, 0, 0, 0, 0), self)
	o.rects = rects
	return o
end

function drawrects(rs)
	for _, r in ipairs(rs) do r:draw("line") end
end


-- USEFUL RECTS
-- 	rect:new(-5, -5, width+10, 5) -- top
-- 	rect:new(-5, -5, 5, height+10) -- left
-- 	rect:new(width, -5, 5, height+10) -- right
-- 	rect:new(-5, height, width+10, 5) -- bottom

function domovement(player, rects, dt)
	local dx, dy = 0, 0

	if love.keyboard.isDown("up")    then dy = dy - player.speed*dt end
	if love.keyboard.isDown("down")  then dy = dy + player.speed*dt end
	if love.keyboard.isDown("left")  then dx = dx - player.speed*dt end
	if love.keyboard.isDown("right") then dx = dx + player.speed*dt end

	if player.rect:at(player.x + dx, player.y + dy):collidesrects(rects) then
		if player.rect:at(player.x, player.y + dy):collidesrects(rects) then dy = 0 end
		if player.rect:at(player.x + dx, player.y):collidesrects(rects) then dx = 0 end
	end
	
	return dx, dy
end
