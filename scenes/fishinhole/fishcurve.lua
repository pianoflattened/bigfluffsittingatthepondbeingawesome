local function atanh(x)
	if x <= -1 or x >= 1 then return 0/0 end
	return 0.5*math.log((1+x)/(1-x))
end

-- https://math.stackexchange.com/questions/3557767/how-to-construct-a-catenary-of-a-specified-length-through-two-specified-points
local function catenary(x1, y1, x2, y2)
	local L = 2*math.sqrt(width^2 + height^2) -- this is reading the size globals from main SORRY 
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
	local b = ax - a*atanh(dy/L)
	return function(x) return a*math.cosh((x-b)/a)+c end
end

function fishcurve(x1, y1, x3, y3)
	local x2 = (x1+x3)/2
	local y2 = 2*catenary(x1, y1, x3, y3)(x2)
	return love.math.newBezierCurve(x1, y1, x2, y2, x3, y3)
end

return fishcurve
