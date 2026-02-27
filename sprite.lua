transform = {}
transform.__index = transform
-- dx, dy -> translation
-- dr     -> rotation (radians)
-- sx, sy -> scale factor
-- ox, oy -> offset
-- maybe TODO: kx, ky -> shear factor (idk how this works & havent needed it)
function transform:new(dx, dy, dr, sx, sy, ox, oy)
	local o = setmetatable({}, self)
	o.dx = dx or 0
	o.dy = dy or 0
	o.dr = dr or 0
	o.sx = sx or 1
	o.sy = sy or sx or 1
	o.ox = ox or 0
	o.oy = oy or 0
	-- kx
	-- ky
	return o
end

function transform:compound(other)
	self.dx = self.dx + other.dx
	self.dy = self.dy + other.dy
	self.dr = self.dr + other.dr
	self.sx = self.sx * other.sx
	self.sy = self.sy * other.sy
	self.ox = self.ox + other.ox
	self.oy = self.oy + other.oy
	-- kx
	-- ky
	return self -- for chaining
end

function transform:unpack()
	return self.dx, self.dy, self.dr, self.sx, self.sy, self.ox, self.oy -- self.kx, self.ky
end


frame = {}
frame.__index = frame
-- time      -> number (seconds)
-- test      -> function(actor, dt, ctx): bool, number?
-- costume   -> string (id which is the image's filename w/o extension)
-- transform -> function(actor, dt, ctx): transform OR transform
function frame:new(time, test, costume, transform)
	local o = setmetatable({}, self)
	o.timer = time and timer:new(time)
	o.test = test
	o.costume = costume
	o.transform = transform
	return o
end


action = {}
action.__index = action
-- framedata -> keyed table of args for frame constructor
-- loops     -> bool
function action:new(framedata, loops)
	local o = setmetatable({}, self)
    o.loops = loops
    
    o.frames = {}
    for i = 1, #framedata do
    	local args = framedata[i]
    	o.frames[i] = frame:new(args.time, args.test, args.costume, args.transform)
    end
    
    return o
end


actor = {}
actor.__index = actor
-- basepath      -> string
-- defcostume    -> string
-- defstransform -> transform OR table with params
function actor:new(basepath, defcostume, deftransform)
	local o = setmetatable({}, self)	
	o.costume = defcostume
	o.defcostume = defcostume
	o.costumes = {}

	-- idk
	if string.find(defcostume, "%.") then o.costumes[defcostume] = love.graphics.newImage(basepath..defcostume)
	else o.costumes[defcostume] = love.graphics.newImage(basepath..defcostume..".png") end

	o.img = o.costumes[defcostume]
	o.x = 0
	o.y = 0
	o.height = o.img:getHeight()
	o.width = o.img:getWidth()

	local t
	if getmetatable(deftransform) ~= transform and type(deftransform) == "table" then
		t = transform:new(deftransform.dx, deftransform.dy, deftransform.dr, 
						  deftransform.sx, deftransform.sy, deftransform.ox, deftransform.oy)
	else t = deftransform or transform:new() end
	o.transform = copy(t)
	o.transform.init = t

	-- for individual definition
	o.actions = {}
	
	-- list of state names
	o.state = {}
	-- table of state names -> frame numbers
	o.frame = {}

	return o
end

function actor:rect()
	return rect:new(self.x - self.transform.ox, self.y - self.transform.oy, self.width, self.height)
end

function actor:addcostume(basepath, name)
	if not self.costumes[name] then 
		self.costumes[name] = love.graphics.newImage(basepath..name..".png") 
	end
end

function actor:addcostumes(basepath, ...)
	for _, arg in ipairs(table.pack(...)) do self:addcostume(basepath, arg) end
end

function actor:draw()
	local dx, dy, dr, sx, sy, ox, oy = self.transform:unpack()
	love.graphics.draw(self.costumes[self.costume], self.x+dx, self.y+dy, dr, sx, sy, ox, oy)
end

-- MUST BE CALLED WITH UPDATE TO WORK !!
function actor:start(animname, dt)
	-- return without doing anything if we already have animname in state
	for _, v in ipairs(self.state) do
		if v == animname then return end
	end
	if not dt then dt = 0 end
	-- push ainmname to state, set its frame to 1
	self.state[#self.state+1] = animname
	self.frame[animname] = 1
	self:doframe(self.actions[animname].frames[1], dt)
end

function actor:stop(animname)
	-- self:resettimers({animname})
	for i = 1, #self.state do
		if self.state[i] == animname then
			table.remove(self.state, i)
			return
		end
	end
end

function actor:doframe(cframe, dt)
	if cframe.costume then self.costume = cframe.costume end
	if cframe.transform then
		if type(cframe.transform) == "function" then
			local t = cframe.transform(self, dt, cframe.timer)
			if t then self.transform = t end
		elseif getmetatable(cframe.transform) == transform then
			self.transform:compound(cframe.transform)
		end
	end
end

function actor:resettimers(states)
	if not states then states = self.state end
	for _, state in ipairs(states) do
		for _, frame in ipairs(self.actions[state].frames) do
			if frame.timer then frame.timer:reset() end
		end
	end
end

-- dt -> number
function actor:docurrentframe(dt)
	if not next(self.actions) then return end
	for _, state in ipairs(self.state) do
		local currentanim = self.actions[state]
		if not currentanim or not currentanim.frames then goto continue end
		local currentframe = currentanim.frames[self.frame[state]]
		if currentframe then self:doframe(currentframe, dt) end
		::continue::
	end
end

-- dt -> number
-- returns: a bunch of crap for debugging
function actor:update(dt)
	local o = {}
	for i = 1, #self.state do o[#o+1] = table.pack(self:updateonestate(self.state[i], dt)) end
	return table.unpack(o)
end

-- state -> string
-- dt    -> number
-- returns: bool (if anything was updated this frame) & relevant info
function actor:updateonestate(state, dt) -- or self.frozen
	local fr = self.frame[state]

	if not next(self.actions) then 
		return false, self.actions, fr, 0
	end
	local currentanim = self.actions[state]
	if not currentanim then 
		return false, self.actions, fr, 0
	end	
	
	local currentframe = currentanim.frames[fr]

	-- check if should move on
	local passed, amt = true, 1
	if currentframe.timer then
		passed = currentframe.timer:countdown(dt)
		if passed then currentframe.timer:reset() end
		if not passed then amt = 0 end
	elseif currentframe.test then
		passed, amt = currentframe.test(copy(self), dt)
		if passed and not amt then amt = 1 end
	end

	-- move on
	if passed then
		if currentframe.timer then currentframe.timer:reset() end
		self.frame[state] = self.frame[state] + amt
		
		if self.frame[state] > #currentanim.frames and not currentanim.loops then
			self:stop(state)
			-- self.frame[state] = nil
			return true, nil, nil, 0
		end

		-- if loop is set to true then this will bring us back to 1 after #currentanim.frames
		-- self:resettimers({state})
		self.frame[state] = (self.frame[state] - 1) % #currentanim.frames + 1
		currentframe = currentanim.frames[self.frame[state]]
	end

	-- update
	self:doframe(currentframe, dt)
	return passed, state, self.frame[state]
end

function actor:is(s)
	for i = 1, #self.state do
		if self.state[i] == s then return true end
	end
	return false
end


effect = {}
effect.__index = effect
-- an effect is a machine that makes actors w/ the same action data & different positions/transforms
function effect:new(basepath, defcostume, deftransform)
	local o = setmetatable({}, self)
	o.spots = {}

	o.costume = defcostume
	o.defcostume = defcostume
	o.costumes = {}
	o.costumes[defcostume] = love.graphics.newImage(basepath..defcostume..".png")

	o.basepath = basepath
	o.img = o.costumes[defcostume]
	o.height = o.img:getHeight()
	o.width = o.img:getWidth()

	o.actions = {}

	if getmetatable(deftransform) ~= transform and type(deftransform) == "table" then
		o.transform = transform:new()
		for key, val in pairs(deftransform) do o.transform[key] = val end
	else o.transform = deftransform end

	return o
end

function effect:addcostume(name)
	if not self.costumes[name] then 
		self.costumes[name] = love.graphics.newImage(self.basepath..name..".png") 
	end
end

function effect:addcostumes(...)
	for _, arg in ipairs(table.pack(...)) do self:addcostume(arg) end
end

function effect:spawn(x, y, tform)
	local a = actor:new(self.basepath, self.defcostume, self.transform)
	a.costumes = copy(self.costumes)
	a.actions = copy(self.actions)
	
	if getmetatable(tform) ~= transform and type(tform) == "table" then
		local t = transform:new(tform.dx, tform.dy, tform.dr, tform.sx, tform.sy, tform.ox, tform.oy)
		-- for key, val in pairs(tform) do t[key] = val end
		tform = t
	elseif not tform then tform = transform:new() end
	a.transform:compound(tform)
	a.x, a.y = x, y
	a.destroy = false
	self.spots[#self.spots+1] = a
	return a
end

-- function effect:clean()
-- 	-- go backwards so that indices dont get messed up mid-loop
-- 	for i = #self.spots, 1, -1 do
-- 		if self.spots[i].destroy then
-- 			table.remove(self.spots, i)
-- 		end
-- 	end
-- end

effect.destroy = function(fct) fct.destroy = true end

-- function effect:updateall(dt)
-- 	for _, spot in ipairs(self.spots) do spot:update(dt) end
-- end
-- 
-- function effect:drawall()
-- 	for _, spot in ipairs(self.spots) do spot:draw() end
-- end


level = {}
level.__index = level
-- actor with collision rects & empty transform
setmetatable(level, {__index = actor})

function level:new(basepath, name, rects)
	local o = setmetatable(actor:new(basepath, name, transform:new()), self)
	o.rects = rects
	return o
end

function drawrects(rs)
	for _, r in ipairs(rs) do r:draw("line") end
end

