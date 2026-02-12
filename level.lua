require 'guy'

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
