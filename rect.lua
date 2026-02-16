-- USEFUL RECTS
-- 	rect:new(-5, -5, width+10, 5) -- top
-- 	rect:new(-5, -5, 5, height+10) -- left
-- 	rect:new(width, -5, 5, height+10) -- right
-- 	rect:new(-5, height, width+10, 5) -- bottom

rect = {}
rect.__index = rect
function rect:new(ox, oy, dx, dy)
	local o = setmetatable({}, self)
	o.ox = ox
	o.oy = oy
	o.dx = dx
	o.dy = dy
	o.x = 0
	o.y = 0
	return o
end

function rect:area()
	return self.dx * self.dy
end

function rect:randpoint()
	return love.math.random(self.x + self.ox, self.x + self.ox + self.dx), love.math.random(self.y + self.oy, self.y + self.oy + self.dy)
end

function rect:at(x, y)
	local c = copy(self)
	c.x, c.y = x, y
	return c
end

function rect:haspoint(x, y)
	return x > self.x + self.ox and x < self.x + self.ox + self.dx and y > self.y + self.oy and y < self.y + self.oy + self.dy
end

function rect:collides(other)
	return self.x + self.ox + self.dx > other.x + other.ox and self.x + self.ox < other.x + other.ox + other.dx and self.y + self.oy + self.dy > other.y + other.oy and self.y + self.oy < other.y + other.oy + other.dy
end

function rect:collidesrects(others)
	for _, other in ipairs(others) do
		if self:collides(other) then return true end
	end
	return false
end

function pointinrects(x, y, others)
	for _, other in ipairs(others) do
		if other:haspoint(x, y) then return true end
	end
	return false
end

function rect:draw(kind)
	love.graphics.rectangle(kind, self.x+self.ox, self.y+self.oy, self.dx, self.dy, 0, 0)
end
