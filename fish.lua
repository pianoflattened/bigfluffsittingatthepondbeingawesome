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

function tryspawnfish(rects, freq, force)
	local fishchance = math.ceil(1500/((freq/120)+5))
	if love.math.random(1, fishchance) == 1 or force then
		local weights = {}
		for _, r in ipairs(rects) do table.insert(weights, r:area()) end
		local whichrect = weightedrandom(rects, weights)

		local spawnx, spawny = whichrect:randpoint()
		local timer = timer:new(3.6) -- length of splash audio

		TEsound.play("aud/splash.mp3", "static", {}, 1)
		return {
			x = spawnx, 
			y = spawny,
			timer = timer,
		}
	end
	return false
end

-- https://math.stackexchange.com/questions/3557767/how-to-construct-a-catenary-of-a-specified-length-through-two-specified-points
function catenary(x1, y1, x2, y2)
	local L = 2*math.sqrt(width^2 + height^2) -- this is reading the size globals in main SORRY 
	local dx, dy = x2-x1, y2-y1
	local ax, ay = (x1+x2)/2, (y1+y2)/2
	local r = math.sqrt(L^2 - dy^2)/dx
	
	-- initial approximation for solution of Ar - sinh(A) = 0
	local A0 = 0.25*(1+3*math.log(2*r)) + math.sqrt(2*math.log(2*r/math.exp(1)))
	-- two iterations of newton's method
	local f, fp = function(x) return x*r - math.sinh(x) end, function(x) return r - math.cosh(x) end
	local A1 = A0 - f(A0)/fp(A0)
	local A = A1 - f(A1)/fp(A1)
	
	local a, c = dx/2*A, ay - L/(2*math.tanh(A))
	local b = ax - a*math.atanh(dy/L)
	return function(x) return a*math.cosh((x-b)/a)+c end
end

function fishcurve(x1, y1, x3, y3)
	local x2 = (x1+x3)/2
	local y2 = 2*catenary(x1, y1, x3, y3)(x2)
	return love.math.newBezierCurve(x1, y1, x2, y2, x3, y3)
end
