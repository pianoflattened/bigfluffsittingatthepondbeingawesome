transform = {}
transform.__index = transform
function transform:new(x, y, r, sx, sy, ox, oy)
    local o = setmetatable({}, self)
    o.x = x or 0
    o.y = y or 0
    o.r = r or 0
    o.sx = sx or 1
    o.sy = sy or sx or 1
    o.ox = ox or 0
    o.oy = oy or 0

    return o
end

function transform:unpack()
    return self.x, self.y, self.r, self.sx, self.sy, self.ox, self.oy
end

function transform:compound(other)
    c.x = self.x + other.x
    c.y = self.y + other.y
    c.r = self.r + other.r
    c.sx = self.sx * other.sx
    c.sy = self.sy * other.sy
    c.ox = self.ox + other.ox
    c.oy = self.oy + other.oy
end

nulltransform = transform:new()
nulltransform.init = nil


actor = {}
actor.__index = actor
-- is created with no animation data, just a default costume & transform
function actor:new(imgpath, inittransform)
    local o = setmetatable({}, self)
    o.defaultcostume = stripfilename(imgpath)
    o.costume = stripfilename(imgpath)
    o.costumes = {}
    o.costumes[o.costume] = love.graphics.newImage(imgpath)

    o.transform = copy(inittransform) or copy(nulltransform)
    o.transform.init = inittransform
    
    o.animations = {}
    o.animation = 0
    o.frame = 0

    o.x = 0
    o.y = 0
    o.r = 0
    o.sx = 1
    o.sy = 1
    o.ox = 0
    o.oy = 0
    return o
end

function actor:draw()
    love.graphics.draw(self.costumes[self.costume], self.transform:unpack())
end

function actor:addanimation(name, framedata)
    self.animations[name] = {}
    local tmp = {}
    for _, f in ipairs(framedata) do
        if type(f) == "number" or type(r) == "function" and #tmp > 0 then
            table.insert(self.animations[name], frame:new(table.unpack(tmp)))
            tmp = {}
        end
        table.insert(tmp, f)
    end    
end

function actor:freeze(costume, transform)
    self.animation = 0
    self.frame = 0
    self.costume = costume or self.defaultcostume
    self.transform = transform or self.transform.init
    return
end
    
function actor:update(dt, ctx)
    if #animations == 0 then return end
    local currentanim = self.animations[self.animation]
    if not currentanim then return end
    local currentframe = currentanim.frames[self.currentframe]
    if not currentframe then return end
    
    local passed, amt = false, 0
    
    if currentframe.test then
        passed, amt = currentframe:test(dt, ctx)
        if not amt then amt = 1 end
    elseif currentframe.timer then
        if currentframe.timer:countdown(dt) then
            currentframe.timer:reset()
            passed, amt = true, 1
        end
    else passed, amt = true, 1 end
    
    if passed then
        if self.currentframe > #currentanim and not currentanim.loops then
            local freezeon = {self.defaultcostume, self.transform.init or nulltransform}
            if currentanim.freezeon > 0 then
            	for _, f in ipairs(currentanim.frames) do
					freezeon[2]:compound(f.transform)
            	end
                local freezeframe = currentanim.frames[currentanim.freezeon]
                freezeon = {freezeframe.costume, freezeframe.transform}
            end
            self:freeze(table.unpack(freezeon))
        end
    
        if currentanim.loops then
            self.currentframe = self.currentframe % #currentanim + 1
        end
    end
end


animation = {}
animation.__index = animation
-- framedata -> [][]frame:new args
-- loops     -> bool
-- freezeon  -> framedata index
-- (see docs for 'frame')
function animation:new(framedata, loops, freezeon)
    local o = setmetatable(o, self)
    o.loops = loops
    o.freezeon = freezeon or 0
    
    o.frames = {}
    for _, args in ipairs(framedata) do
        table.insert(o.frames, frame:new(table.unpack(args)))
    end
    
    return o
end

frame = {}
frame.__index = frame
-- time      -> number (seconds)
-- test      -> function(self, dt, ctx): bool, number?
-- costume   -> string (id which is the image's filename w/o extension)
-- transform -> love.math.transform object (for rotation, scaling, etc)
function frame:new(...)
    local o = setmetatable({}, self)
    
    local arg = {...}
    for i, v in ipairs(arg) do
        if i > 4 then break end
        if     type(v) == "number"   then o.timer = timer:new(v)
        elseif type(v) == "function" then o.test = v
        elseif type(v) == "string"   then o.imgpath = v
        elseif v:typeOf("Transform") then o.transform = v 
        end
    end
    
    return o    
end
