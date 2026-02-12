local inspect = require 'inspect'

fish = {}
fish.__index = fish
function fish:new(path, points, scene)
	local o = setmetatable({}, self)
	o.path = path                                            -- 123456   54321
	o.name = string.sub(string.sub(path, 6), 0, -5) -- cuts off fish/ and .png
	o.img = love.graphics.newImage(path)
	o.points = points or 1
	-- 1/x(ln x + 1)^2 without wacky behavior near 0
	o.rarity = ((points + 11.54715)^(-0.772983))/(9.22967^(-1.10754))
	o.scene = scene or function() return false end
	return o
end

function fish:draw(x, y, scale)
	love.graphics.draw(self.img, x, y, 0, scale, scale, self.img:getWidth()/2, self.img:getHeight()/2)
end

function tryspawnfish(rects, force)
	if love.math.random(1, 100) == 1 or force then
		local weights = {}
		for _, r in ipairs(rects) do table.insert(weights, r:area()) end
		local whichrect = weightedrandom(rects, weights)
		
		-- local sum = reduce(weights, function(a, b) return a+b end, 0)
		-- local whichrect = love.math.random(0, sum)
		-- local s = 0
		-- for i, w in ipairs(weights) do
		-- 	s = s + w
		-- 	if s >= whichrect then
		-- 		s = i
		-- 		break
		-- 	end
		-- end

		local spawnx, spawny = whichrect:randpoint()
		local timer = timer:new(3.6) -- length of splash audio

		TEsound.play("aud/splash.mp3", "static", {}, 1/2)
		return {
			x = spawnx, 
			y = spawny,
			timer = timer,
			snagged = false
		}
	end
	return false
end

function randomfish(fishes)
	local k = keys(fishes)
	local c = k[love.math.random(#k)]
	
end

function catenary(x1, y1, x2, y2)
	-- https://math.stackexchange.com/questions/3557767/how-to-construct-a-catenary-of-a-specified-length-through-two-specified-points
	local L = width*2
	local dx = x2-x1
	local ax = (x1+x2)/2
	local dy = y2-y1
	local ay = (y1+y2)/2
	local r = math.sqrt(L^2 - dy^2)/dx
	-- initial approximation for solution of Ar - sinh(A) = 0
	local A0 = 0.25*(1+3*math.log(2*r)) + math.sqrt(2*math.log(2*r/math.exp(1)))
	-- two iterations of newton's method
	local f = function(x) return x*r - math.sinh(x) end
	local fp = function(x) return r - math.cosh(x) end
	local A1 = A0 - f(A0)/fp(A0)
	local A = A1 - f(A1)/fp(A1)
	local a = dx/2*A
	local b = ax - a*math.atanh(dy/L)
	local c = ay - L/(2*math.tanh(A))
	return function(x) return a*math.cosh((x-b)/a)+c end
end

function fishcurve(x1, y1, x3, y3)
	local x2 = (x1+x3)/2
	local y2 = 2*catenary(x1, y1, x3, y3)(x2)
	return love.math.newBezierCurve(x1, y1, x2, y2, x3, y3)
end
