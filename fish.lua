fish = {}
fish.__index = fish
-- this passes name instead of calculating it from path b/c 
-- loadfish needs to figure out the name before making the object
function fish:new(path, name, attrs)
	local o = setmetatable({}, self)
	o.path = path
	o.name = name -- string.sub(string.sub(path, 6), 0, -5)
	o.img = love.graphics.newImage(path)
	o.len = attrs.len or o.img:getWidth()
	o.height = o.img:getHeight()
	o.scale = (attrs.len and attrs.len/o.img:getWidth()) or 100/math.min(o.img:getWidth(), o.img:getHeight())
	o.points = attrs.points or 1
	-- (1/x)*(ln(x)+1)^2) without wacky behavior near 0
	o.rarity = attrs.rarity or ((o.points + 11.54715)^(-0.772983))/(9.22967^(-1.10754))
	o.seen = false
	return o
end

function loadfish(attrs)
	local fishes = {}

	-- put the file in the folder -> it becomes a fish
	local fishfiles = love.filesystem.getDirectoryItems("fish")
	for i, v in ipairs(fishfiles) do
		local path = "fish/"..v           --         54321
		local name = string.sub(v, 0, -5) -- cuts off .png
		tmpfish = fish:new(path, name, attrs[name] or {})
		fishes[name] = tmpfish
	end
	return fishes
end
