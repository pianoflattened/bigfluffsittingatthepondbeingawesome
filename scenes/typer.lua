typer = {
	basepath = "scenes/typer/",
	cloudanim = {
		timer = timer:new(0.1),
		frame = 1,
		rot = 0,
		rot2 = 0,
		rotspeed = 0.22,
		ratio = {2, 3}, -- i like 11, 43 too
		center = {
			x = 400,
			y = 375,
		},
	},
	talkanim = {
		talking = true,
		timer = timer:new(0.28),
		saywordtimer = timer:new(12),
		wordboxtimer = timer:new(2.5),
		wordboxshow = true,
	},
	points = {},
	keyquads = {
		q = 1, w = 1, e = 1, r = 1, t = 1, f = 1, g = 1,
		a = 2, s = 2, d = 2, z = 2, x = 2, c = 2, v = 2,
		y = 3, h = 3, u = 3, i = 3, o = 3, p = 3,
		j = 4, k = 4, l = 4, b = 4, n = 4, m = 4,
	},
	letters = {},
	lettertimer = timer:new(0.34),
	word = "",
	wordx = 0,
	wordy = 0,
}

function typer:init()
	self.bgs = {}
	local wordsjson = love.filesystem.read(self.basepath.."words.json")
	self.wordlist = json.decode(wordsjson)

	host = guy:new(self.basepath.."hostflex2.png", 179, 263, 400, 300)
	host:addframe(self.basepath.."hostclosed2.png")
	host:addframe(self.basepath.."hostopen2.png")
	host:addframe(self.basepath.."hostswat2.png")
	host.sx, host.sy = 0.5, 0.5

	cloud = guy:new(self.basepath.."CLO-F1.png", 50, 21, 139, 380)
	for i = 2, 5 do cloud:addframe(self.basepath.."CLO-F"..tostring(i)..".png") end
	cloud.sx, cloud.sy = 2, 2

	keycap = effect:new(self.basepath.."keycap.png")
	keycap.sx, keycap.sy = 0.8, 0.8

	deffont = love.graphics.getFont()
	chicagoflf = love.graphics.newFont(self.basepath.."ChicagoFLF.ttf", 45, "mono")

	self.cloudanim.rot = love.math.random()*math.pi*2
	self.cloudanim.rot2 = love.math.random()*math.pi*2
end

function typer:enter()
	self.wins = 0
	local allfiles = love.filesystem.getDirectoryItems(self.basepath)
	for _, file in ipairs(allfiles) do
		local _, _, ext = string.find(file, "%.([A-Za-z0-9]+)")
		if ext == "JPG" then table.insert(self.bgs, file) end
	end

	local choice = trandom(self.bgs)
	self.bg = level:new(self.basepath..choice, {})
	self.bg.sx, self.bg.sy = 1.25, 1.25 -- ben's photos are 640x480 --> 800x600

	typermusic = love.audio.newSource(self.basepath.."palj.mp3", "stream")
	noises = love.audio.newSource(self.basepath.."eb.mp3", "stream")
end

function typer:leave()
	love.audio.stop(typermusic)
	love.audio.stop(noises)
end

local function avg(ratio)
	local a, b = table.unpack(ratio)
	return (a + b)/2
end

local function diff(ratio)
	local a, b = table.unpack(ratio)
	return math.abs(a - b)
end

local function iscoprime(a, b)
	while a ~= b do
		if a > b then a = a - b
		else b = b - a end
	end
	return a == 1
end

-- local function nextcoprimes(ratio)
-- 	local a, b = table.unpack(ratio)
-- 	local ra, rb = a, b
-- 	
-- 	repeat ra = ra + 1 until iscoprime(ra, b)
-- 	repeat rb = rb + 1 until iscoprime(a, rb)
-- 	return ra, rb
-- end
-- 
-- local function prevcoprimes(ratio)
-- 	local a, b = table.unpack(ratio)
-- 	local ra, rb = a, b
-- 
-- 	if a ~= 1 then repeat ra = ra - 1 until iscoprime(ra, b) end
-- 	if b ~= 1 then repeat rb = rb - 1 until iscoprime(a, rb) end 
-- 	return ra, rb
-- end

function typer:keyreleased(key, code)
	local quadrant = self.keyquads[key]

	if quadrant ~= nil then 
		local letter = {
			char = key,
			jx = love.math.random(7)-4,
			jy = love.math.random(7)-4,
		}
		table.insert(self.letters, letter) 
	end
	
	if key == "backspace" then table.remove(self.letters) end
	if key == "return" then -- , "abcdefghijklmnopqrstuvwxyandz"
		local l = {}
		for _, letter in ipairs(self.letters) do table.insert(l, letter.char) end
		if table.concat(l, "") == self.word then 
			self.word = "" 
			self.wins = self.wins + 1
			self.letters = {}
		end
	end

	-- typing changes the equation
	-- doesnt rly matter just thought itd be fun
	-- gcd/coprime stuff ensures fractions are in lowest terms
	if quadrant == 1 then
		local a = self.cloudanim.ratio[1]
		if a ~= 1 then 
			repeat a = a - 1 until iscoprime(a, self.cloudanim.ratio[2])
			self.cloudanim.ratio[1], self.points = a, {} end
	elseif quadrant == 2 then
		local b = self.cloudanim.ratio[2]
		if b ~= 1 then 
			repeat b = b - 1 until iscoprime(self.cloudanim.ratio[1], b)
			self.cloudanim.ratio[2], self.points = b, {} end
	elseif quadrant == 3 then
		local a = self.cloudanim.ratio[1]
		repeat a = a + 1 until iscoprime(a, self.cloudanim.ratio[2])
		self.cloudanim.ratio[1], self.points = a, {}
	elseif quadrant == 4 then
		local b = self.cloudanim.ratio[2]
		repeat b = b + 1 until iscoprime(self.cloudanim.ratio[1], b)
		self.cloudanim.ratio[2], self.points = b, {}
	end
end

function typer:update(dt)
	if not typermusic:isPlaying() then love.audio.play(typermusic) end
	if not noises:isPlaying() then 
		noises:setVolume(math.max(0.9*noises:getVolume(), 0.75))
		love.audio.play(noises) 
	end

	if self.word == "" then
		if love.math.random(2) == 1 then self.word = trandom(self.wordlist.ours)
		else self.word = trandom(self.wordlist.long) end
		self.talkanim.talking = true
		self.talkanim.saywordtimer.clock = 0
	end

	-- first orbit
	cloud.x = self.cloudanim.center.x + 300*math.cos(self.cloudanim.rot)
	cloud.y = self.cloudanim.center.y + 100*math.sin(self.cloudanim.rot)

	-- second orbit
	cloud.x = (cloud.x - self.cloudanim.center.x) * math.cos(self.cloudanim.rot2) + (cloud.y - self.cloudanim.center.y) * math.sin(self.cloudanim.rot2) + self.cloudanim.center.x
	cloud.y = (cloud.y - self.cloudanim.center.y) * math.cos(self.cloudanim.rot2) - (cloud.x - self.cloudanim.center.x) * math.sin(self.cloudanim.rot2) + self.cloudanim.center.y
	
	host.x = cloud.x
	host.y = cloud.y - 49
	
	table.insert(self.points, {
		x = host.x,
		y = host.y,
		color = {
			r = love.math.random(2) - 1,
			g = love.math.random(2) - 1,
			b = love.math.random(2) - 1,
		}
	})

	-- i ought to look at some derivatives to figure teh rotation speed out
	-- ugh
	
	self.cloudanim.rot = (self.cloudanim.rot + 
		self.cloudanim.ratio[1] * dt * 
		self.cloudanim.rotspeed/math.sqrt(diff(self.cloudanim.ratio)/avg(self.cloudanim.ratio))
	) % (2 * math.pi)

	self.cloudanim.rot2 = (self.cloudanim.rot2 + 
		self.cloudanim.ratio[2] * dt * 
		self.cloudanim.rotspeed/math.sqrt(diff(self.cloudanim.ratio)/avg(self.cloudanim.ratio))
	) % (2 * math.pi)

	if self.cloudanim.timer:countdown(dt) then
		self.cloudanim.frame = (self.cloudanim.frame % 4) + 1
		cloud:setframe("CLO-F"..tostring(self.cloudanim.frame))
		self.cloudanim.timer:reset()
	end

	if self.talkanim.saywordtimer:countdown(dt) and not sam:talking() then
		self.talkanim.talking = true
		self.wordx = host.x + 50
		self.wordy = host.y - 50
		
		sam:say(self.word)
		self.talkanim.wordboxtimer:reset()
		self.talkanim.talking = true
		self.talkanim.saywordtimer:reset()
	end

	if self.talkanim.wordboxtimer:countdown(dt) then
		self.talkanim.talking = false
	end

	if self.talkanim.talking and self.talkanim.timer:countdown(dt) then
		if host.frame == "hostopen2" then host:setframe("hostclosed2")
		elseif host.frame == "hostclosed2" then host:setframe("hostopen2") 
		else host:setframe("hostopen2") end
		self.talkanim.timer:reset()
	elseif not self.talkanim.talking then host:setframe() end

	if #self.letters > 0 and self.lettertimer:countdown(dt) then
		for _, l in ipairs(self.letters) do
			l.jx = math.random(5)-3
			l.jy = math.random(5)-3
		end
		self.lettertimer:reset()
	end

	if #self.points > 50 then table.remove(self.points, 1) end
end

function typer:draw()
	if self.bg then self.bg:draw() end
	love.graphics.setColor(love.math.random(2)-1, love.math.random(2)-1, love.math.random(2)-1)

	-- host's movement trail
	if #self.points >= 4 then
		love.graphics.setLineWidth(10)
		for idx, point in ipairs(self.points) do
			local prev = self.points[idx-1]
			if prev == nil then goto continue end
			love.graphics.setColor(point.color.r, point.color.g, point.color.b)
			love.graphics.line(prev.x, prev.y, point.x, point.y)
			::continue::
		end
		love.graphics.setLineWidth(1)
	end

	love.graphics.setColor(0.9, 0.9, 1)
	cloud:draw()
	love.graphics.setColor(1, 1, 1)
	host:draw()

	-- letters
	if #self.letters > 0 then
		local keycapx = 400 - (66*(#self.letters-1)/2)
		for _, l in ipairs(self.letters) do
			keycap:draw(keycapx + l.jx, 300 + l.jy)
			
			local letter = l.char
			local lox = (chicagoflf:getWidth(letter) + 0.8*8)/2
			local loy = (chicagoflf:getHeight(letter) + 0.8*20)/2

			love.graphics.setColor(0, 0, 0)
			love.graphics.print(letter, chicagoflf, keycapx - lox + l.jx, 300 - loy + l.jy)
			love.graphics.setColor(1, 1, 1)

			keycapx = keycapx + 66
		end
	end

	if self.talkanim.talking then
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("fill", self.wordx-5, self.wordy-5, 
			deffont:getWidth(self.word)+10, deffont:getHeight(self.word)+10)
		
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(self.word, self.wordx, self.wordy)
		love.graphics.setColor(1, 1, 1)
	end

	love.graphics.setColor(1, 0, 1)
	love.graphics.print(inspect(self.cloudanim.ratio), 20, 20, 0, 2, 2)
	love.graphics.setColor(1, 1, 1)
end
