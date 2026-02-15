guy = {}
guy.__index = guy
function guy:new(path, ox, oy, x, y)
	local o = setmetatable({}, self)
	o.img = love.graphics.newImage(path)
	o.path = path
	o.ox = ox or 0
	o.oox = ox or 0
	o.oy = oy
	o.ooy = oy
	o.width = o.img:getWidth()
	o.height = o.img:getHeight()

	o.r = 0
	o.sx = 1
	o.sy = 1
	o.x = x or 0
	o.y = y or 0
	return o
end

-- function guy:loadfrom(res)
-- 	self.img = res[self.path]
-- end

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
