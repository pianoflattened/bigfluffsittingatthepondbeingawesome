fish = {}
fish.__index = fish
-- this passes name instead of calculating it from path b/c 
-- loadfish needs to figure out the name before making the object
function fish:new(path, name, len, points, rarity, scene)
	local o = setmetatable({}, self)
	o.path = path
	o.name = name -- string.sub(string.sub(path, 6), 0, -5)
	o.img = love.graphics.newImage(path)
	o.len = len or o.img:getWidth()
	o.scale = (len and len/o.img:getWidth()) or 100/math.min(o.img:getWidth(), o.img:getHeight())
	o.points = points or 1
	-- (1/x)*(ln(x)+1)^2) without wacky behavior near 0
	o.rarity = rarity or ((o.points + 11.54715)^(-0.772983))/(9.22967^(-1.10754))
	o.scene = scene or function() return false end
	return o
end

function fish:draw(x, y, scale)
	love.graphics.draw(self.img, x, y, 0, scale, scale, self.img:getWidth()/2, self.img:getHeight()/2)
end

function loadfish(attrs)
	local fishes = {}
	local fishfiles = love.filesystem.getDirectoryItems("fish")
	for i, v in ipairs(fishfiles) do
		local path = "fish/"..v           --         54321
		local name = string.sub(v, 0, -5) -- cuts off .png
		tmpfish = fish:new(path, name, unpack(attrs[name] or {}))
		fishes[name] = tmpfish
	end
	return fishes
end
