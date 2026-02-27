require 'scenes.typer.math'

local typer = {}
local basepath = "scenes/typer/"

local bg
local bgs = {}
local allfiles = love.filesystem.getDirectoryItems(basepath)
for _, file in ipairs(allfiles) do
	local _, _, ext = string.find(file, "%.([A-Za-z0-9]+)")
	if ext == "JPG" then bgs[#bgs+1] = file end
end

local wordsjson = love.filesystem.read(basepath.."words.json")
local wordlist = json.decode(wordsjson)
local samfiles = love.filesystem.getDirectoryItems(basepath.."samwords/")
local samwords = {}
for _, wav in ipairs(samfiles) do
	local word = stripfilename(wav)
	samwords[word] = love.audio.newSource(basepath.."samwords/"..wav, "static")
end

local points = {}
local keyquads = {
	q = 1, w = 1, e = 1, r = 1, t = 1, f = 1, g = 1,
	a = 2, s = 2, d = 2, z = 2, x = 2, c = 2, v = 2,
	y = 3, h = 3, u = 3, i = 3, o = 3, p = 3,
	j = 4, k = 4, l = 4, b = 4, n = 4, m = 4,
}

local cloud = actor:new(basepath, "CLO-F1", {ox = 50, oy = 21, sx = 2})
for i = 2, 5 do cloud:addcostume(basepath, "CLO-F"..tostring(i)) end
cloud.actions.anim = action:new({
	{time = 0.1, costume = "CLO-F1"},
	{time = 0.1, costume = "CLO-F2"},
	{time = 0.1, costume = "CLO-F3"},
	{time = 0.1, costume = "CLO-F4"},
	{time = 0.1, costume = "CLO-F5"},
}, true)
cloud:start("anim")
cloud.ratio = {2, 3}
cloud.center = {
	x = 400,
	y = 375,
}

local word = ""
local wordx = 0
local wordy = 0
local wins = 0

local host = actor:new(basepath, "hostswat2", {ox = 179, oy = 263, sx = 0.5})
host.x, host.y = 400, 300
host:addcostumes(basepath, "hostclosed2", "hostopen2", "hostflex2")
host.actions = {
	talking = action:new({
		{time = 0.28, costume = "hostopen2"},
		{time = 0.28, costume = "hostclosed2"},
	}, true),

	stoptalking = action:new({
		{time = 0.28, costume = "hostflex2"},
		{time = 2, costume = "hostswat2"}
	}),
}

local keycap = effect:new(basepath, "keycap", {sx = 0.8, ox = 0, oy = 0})
keycap.actions.jitter = action:new({
	{time = 0.33},
	{
		transform = function(letter)
			letter.transform.dx = math.random(7)-4
			letter.transform.dy = math.random(7)-4
		end,
	}
}, true)

local sayword = timer:new(10)

local deffont = love.graphics.getFont()
local chicagoflf = love.graphics.newFont(basepath.."ChicagoFLF.ttf", 45, "mono")

local typermusic = love.audio.newSource(basepath.."palj.mp3", "stream")
local noises = love.audio.newSource(basepath.."eb.mp3", "stream")

function typer.enter()
	local choice = trandom(bgs)
	bg = level:new(basepath, choice, {})
	bg.transform.sx, bg.transform.sy = 1.25, 1.25 -- ben's photos are 640x480 --> 800x600
	cloud.rot = love.math.random()*math.pi*2
	cloud.rot2 = love.math.random()*math.pi*2
	love.keyboard.setTextInput(true)
end

function typer.leave()
	wins = 0
	love.audio.stop(typermusic, noises)
	love.keyboard.setTextInput(false)
end

function typer.textinput(t)
	-- removes non-letter characters and splits into lowercase letters
	local alphaonly = string.gsub(string.lower(t), '%A', '')
	for i = 1, #alphaonly do
		local key = string.sub(alphaonly, i, i)
		local quadrant = keyquads[key]
		if quadrant ~= nil then
			local la = keycap:spawn(-100, 300, {
				dx = love.math.random(7)-4, 
				dy = love.math.random(7)-4,
			})
			la.letter = key
			la:start("jitter")

			local changedidx = quadrant%2+1
			local sameidx = 3-changedidx
			local a = cloud.ratio[changedidx]
			-- next coprime down
			if math.floor((quadrant-1)/2) == 0 then
				if a ~= 1 then
					repeat a = a - 1 until iscoprime(a, cloud.ratio[sameidx])
				end
			else -- next coprime up
				repeat a = a + 1 until iscoprime(a, cloud.ratio[sameidx])
			end
			cloud.ratio[changedidx], points = a, {}
			if cloud.ratio[1] == cloud.ratio[2] == 1 then
				cloud.ratio[1] = 2
			end
		end
	end
end

function typer.keypressed(k)
	if k == "backspace" then table.remove(keycap.spots) end
	if k == "return" then
		local l = {}
		for _, cap in ipairs(keycap.spots) do l[#l+1] = cap.letter end
		if table.concat(l, "") == word then
			love.audio.stop(samwords[word])
			word = ""
			wins = wins + 1
			keycap.spots = {}
		end
	end
end

function typer.update(dt)
	if wins >= 15 then return fishinhole, 1 end

	if not typermusic:isPlaying() then love.audio.play(typermusic) end
	if not noises:isPlaying() then
		noises:setVolume(math.max(0.9*noises:getVolume(), 0.75))
		love.audio.play(noises)
	end

	if word == "" then
		if love.math.random(2) == 1 then word = trandom(wordlist.ours)
		else word = trandom(wordlist.long) end
		sayword.clock = 0
	end

	if sayword:countdown(dt) and not samwords[word]:isPlaying() then
		host:start("talking")
		wordx, wordy = host.x + 50, host.y - 50
		if wins < 15 then love.audio.play(samwords[word]) end
		sayword:reset()
	elseif not samwords[word]:isPlaying() then
		host:stop("talking")
		host:start("stoptalking") -- this loops by accident but its like fine probably better this way
	end

	local oldx, oldy, oldrot, oldrot2 = cloud.x, cloud.y, cloud.rot, cloud.rot2
	cloud.rot = cloud.rot % (2*math.pi)
	cloud.rot2 = cloud.rot2 % (2*math.pi)
	-- first orbit
	cloud.x = cloud.center.x + 300*math.cos(cloud.rot) 
	cloud.y = cloud.center.y + 100*math.sin(cloud.rot)
	-- second orbit
	cloud.x = (cloud.x - cloud.center.x)*math.cos(cloud.rot2) + (cloud.y - cloud.center.y)*math.sin(cloud.rot2) + cloud.center.x
	cloud.y = (cloud.y - cloud.center.y)*math.cos(cloud.rot2) + (cloud.x - cloud.center.x)*math.sin(cloud.rot2) + cloud.center.y

	assert(cloud.x == cloud.x and cloud.y == cloud.y, "GOT NAN! FIX THIS !!!!!")
	
	host.x, host.y = cloud.x, cloud.y - 49
	points[#points+1] = {
		x = host.x,
		y = host.y,
		color = {
			r = love.math.random(2) - 1,
			g = love.math.random(2) - 1,
			b = love.math.random(2) - 1,
		}
	}

	cloud.rot = cloud.rot +	cloud.ratio[1] * dt * 0.22/math.sqrt(diff(cloud.ratio)/avg(cloud.ratio))
	cloud.rot2 = cloud.rot2 + cloud.ratio[2] * dt * 0.22/math.sqrt(diff(cloud.ratio)/avg(cloud.ratio))

	cloud:update(dt)
	host:update(dt)
	local keycapx = 400 - (65 * (#keycap.spots - 1)/2)
	for _, cap in ipairs(keycap.spots) do
		cap.x = keycapx
		cap.lox = (63*0.8 - chicagoflf:getWidth(cap.letter))/2
		cap.loy = (63*0.8 - chicagoflf:getHeight(cap.letter))/2
		cap:update(dt) 
		keycapx = keycapx + 65
	end
	if #points > 50 then table.remove(points, 1) end
end

function typer.draw()
	if bg then bg:draw() end

	-- movement trail
	if #points >= 4 then
		love.graphics.setLineWidth(10)
		for idx, point in ipairs(points) do
			local prev = points[idx-1]
			if not prev then goto continue end
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
	
	-- draw keycaps
	for _, cap in ipairs(keycap.spots) do
		cap:draw()
		love.graphics.setColor(0, 1, 0)
		cap:rect():draw("line")
		love.graphics.setColor(1, 0, 0)
		love.graphics.rectangle("line", cap.x + cap.lox, 300 + cap.loy, chicagoflf:getWidth(cap.letter), chicagoflf:getHeight(cap.letter)) 
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(cap.letter, chicagoflf, cap.x + cap.lox + cap.transform.dx, 300 + cap.loy + cap.transform.dy)
		love.graphics.setColor(1, 1, 1)
	end

	if #host.state ~= 0 then
		love.graphics.rectangle("fill", wordx-5, wordy-5, deffont:getWidth(word)+10, deffont:getHeight(word)+10)
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(word, wordx, wordy)
		love.graphics.setColor(1, 1, 1)
	end

	love.graphics.setColor(1, 0, 1)
	love.graphics.print(inspect(cloud.ratio), 20, 20, 0, 2, 2)
	love.graphics.print(inspect({math.floor(host.x), math.floor(host.y)}), 20, 40, 0, 2, 2)
	love.graphics.setColor(1, 1, 1)
end

return typer
