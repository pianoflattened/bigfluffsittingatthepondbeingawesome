-- very tiny vector class
vector = {}
vector.__index = vector
function vector:new(x, y)
	local o = setmetatable({}, self)
	o.x = x or 0
	o.y = y or 0
	return o
end

function vector:normalize()
	local hyp = math.dist(0, 0, self.x, self.y)
	if hyp ~= 0 then
		self.x = self.x/hyp
		self.y = self.y/hyp
	end
end

function vector:angle()
	return math.angle(0, 0, self.x, self.y)
end
