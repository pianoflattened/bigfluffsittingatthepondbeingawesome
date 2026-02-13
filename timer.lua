timer = { duration = 0 }
timer.__index = timer
function timer:new(duration)
	local o = setmetatable({}, self)
	o.duration = duration
	o.clock = duration
	return o
end

function timer:reset()
	self.clock = self.duration
end

function timer:countdown(dt)
	self.clock = self.clock - dt
	return self.clock <= 0
end

function timer:progress()
	return math.max(math.min(1, self.clock/self.duration), 0)
end
