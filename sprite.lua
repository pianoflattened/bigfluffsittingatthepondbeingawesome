transform = {}
transform.__index = transform
-- dx, dy -> translation
-- dr     -> rotation (radians)
-- sx, sy -> scale factor
-- ox, oy -> offset
-- maybe TODO: kx, ky -> shear factor (idk how this works & havent needed it)
function transform:new(dx, dy, r, sx, sy, ox, oy)
	local o = setmetatable({}, self)
	o.dx = dx or 0
	o.dy = dy or 0
	o.dr = dr or 0
	o.sx = sx or 1
	o.sy = sy or sx or 1
	o.ox = 0
	o.oy = 0
	-- kx
	-- ky
	return o
end

function transform:compound(other)
	self.x = self.x + other.x
	self.y = self.y + other.y
	self.r = self.r + other.r
	self.sx = self.sx * other.sx
	self.sy = self.sy * other.sy
	self.ox = self.ox + other.ox
	self.oy = self.oy + other.oy
	-- kx
	-- ky
	return self -- for chaining
end

function transform:unpack()
	return self.x, self.y, self.r, self.sx, self.sy, self.ox, self.oy -- self.kx, self.ky
end


frame = {}
frame.__index = frame
-- time      -> number (seconds)
-- test      -> function(actor, dt, ctx): bool, number?
-- costume   -> string (id which is the image's filename w/o extension)
-- transform -> transform
function frame:new(...)
	local o = setmetatable({}, self)
	local args = {...}
	for _, arg in ipairs(args) do
		if type(arg) == "number" then o.timer = timer:new(arg) end
		if type(arg) == "function" then o.test = arg end
		if type(arg) == "string" then o.costume = arg end
		if getmetatable(arg) == transform then o.transform = arg end
	end
	
	return o
end


animation = {}
animation.__index = animation
-- framedata -> args for frame constructor
-- loops     -> bool
function animation:new(framedata, loops)
	local o = setmetatable({}, self)
    o.loops = loops
    
    o.frames = {}
    for _, args in ipairs(framedata) do
        table.insert(o.frames, frame:new(table.unpack(args)))
    end
    
    return o
end

-- upto -> number (compound transforms up to this index, inclusive)
function animation:compoundtransforms(upto)
	if upto > #self.frames and not self.loops then upto = #self.frames end

	local t = transform:new()
	for i = 0, upto - 1 do
		local f = self.frames[i % #self.frames + 1]
		if f.transform then t:compound(f.transform) end
	end
	
	return t
end


actor = {}
actor.__index = actor
function actor:new(basepath, defcostume, deftransform)
	local o = setmetatable({}, self)
	o.costume = defcostume
	o.costumes = {}
	o.costumes[defcostume] = love.graphics.newImage(basepath..defcostume..".png")
	o.costumes.init = defcostume

	o.transform = deftransform
	o.transform.init = deftransform

	o.animations = {}
	o.frozen = false
	o.animation = nil
	o.frame = nil

	return o
end

function actor:draw()
	love.graphics.draw(self.costumes[self.costume], self.transform:unpack())
end

-- function actor:addanimation(name, anim)
-- 	self.animations[name] = anim
-- end

-- animname -> string
-- frameidx -> number or nil
-- MUST BE CALLED WITH UPDATE TO WORK !!
function actor:startanimation(animname, frameidx)
	self.animation = animname
	-- don't allow 0, which means animation is frozen
	self.frame = math.min(frameidx, 1) or 1
	-- return self -- for chaining
end

function actor:stopanimation()
	self.animation = nil
	self.frame = nil
	self.costume = self.costumes.init
end

-- animname -> string
-- frameidx -> number or nil
-- function actor:freeze(animname, frameidx)
-- 	self:setanimation(animname, frameidx)
-- 	self.frozen = true -- blocks update
-- end

-- dt  -> number
-- ctx -> table with anything you want
function actor:update(dt, ctx)
	if #animations == 0 or self.frozen then return end
	local currentanim = self.animations[self.animation]
	if not currentanim then return end

	local currentframeidx = (self.frame-1) % #self.frames + 1
	if self.frame ~= currentframeidx and not currentanim.loops then
		self.frame = #currentanim.frames
		return
	end
	
	local currentframe = currentanim.frames[currentframeidx]

	local passed, amt = false, 0
	if currentframe.timer then
		if currentframe.timer:countdown(dt) then
			passed, amt = true, 1
		end
	elseif currentframe.test then
		passed, amt = currentframe.test(self, dt, ctx)
	end

	if passed then
		local noloop = self.frame + amt
		self.frame = (noloop-1) % #self.frames + 1
		if self.frame ~= noloop and not currentanim.loops then
			self.frame = #self.frames
		end
		currentframe = self.frames[self.frame]
		
		if currentframe.costume then self.costume = currentframe.costume end
		if currentframe.transform then self.transform:compound(currentframe.transform) end
	end
end
