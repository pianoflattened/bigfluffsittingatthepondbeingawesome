local fishcurve = require 'scenes.fishinhole.fishcurve'

local fishinhole = {}
local basepath = "scenes/fishinhole/"

local bigfluff = actor:new(basepath, "bigfluff", {ox = 99, oy = 165})
bigfluff.x, bigfluff.y = 610, 397
bigfluff.rect = rect:new(-42, 93, 87, 32)
bigfluff.speed = 200
bigfluff.grunting = false

local rod = actor:new(basepath, "rod", {ox = 193, oy = 210})
rod.actions.casting = action:new({
	{ -- frame 1
		transform = function(rod)
			rod.transform.dr = 0.57*math.pi
			rod.transform.oy = rod.transform.init.oy + 50
			rod.transform.ox = rod.transform.init.ox + 10
		end
	},
	{ -- frame 2
		test = function()
			return not love.keyboard.isDown("lctrl")
		end
		-- hold back until release
	},
	{ time = 0.2 }, -- frame 3; no change for a little bit. delay emulates swing time
	{ -- frame 4
		transform = function(rod)
			rod.transform.dr = 0
			rod.transform.oy = rod.transform.init.oy
			rod.transform.ox = rod.transform.init.ox
		end
	}
})

local line = actor:new(basepath, "line", {ox = 233, oy = 208})
line.scaledheight = 0.01
-- example calculation of scale & offset for stretch :D
line.transform.sy = line.scaledheight / line.height
line.transform.oy = line.transform.init.oy / line.transform.sy
line.speed = 400
line.actions = {
	reeling = action:new({
		{}, -- :start calls the first frame & i want casting to interrupt reeling
		{ 
			transform = function(line, dt)
				line.scaledheight = line.scaledheight - (dt * line.speed)
				line.transform.sy = line.scaledheight / line.height
				line.transform.oy = line.transform.init.oy / line.transform.sy
			end,

			test = function(line, dt)
				if love.keyboard.isDown("lshift") and line.scaledheight - (dt * line.speed) > 0 then return true, 0 
				else return true, 1 end
			end,
		}
	}),

	casting = action:new({
		{ -- frame 1
			transform = function(line)
				line.transform.dr = 0.57*math.pi
				line.transform.oy = line.transform.init.oy + 50
				line.transform.ox = line.transform.init.ox + 10
			end,
		},
		{ -- frame 2
			test = function()
				return not love.keyboard.isDown("lctrl")
			end,
			-- hold back until release
		},
		{ time = 0.2 }, -- frame 3, in sync with rod
		{ -- frame 4
			transform = function(line)
				line.scaledheight = math.min(line.scaledheight + line.height, line.height * 5)
				line.transform.sy = line.scaledheight / line.height
				line.transform.oy = line.transform.init.oy / line.transform.sy
			
				line.transform.dr = 0
				line.transform.ox = line.transform.init.ox
			end
		}
	}),

	grunting = action:new({
		{ -- frame 1
			transform = function(line)
				line.transform.dx = 20 * (love.math.random() - 0.5)
				line.transform.dy = 20 * (love.math.random() - 0.5)
			end
		}
	})
}

local ripple = actor:new(basepath, "ripple", {ox = 32, oy = 9})
ripple.inwater = false

local splash = effect:new(basepath, "splash", {ox = 35, oy = 40})
splash.actions = {
	decaying = action:new({
		{ time = 3.6 },
		{ transform = effect.destroy }
	}),
	
	pulling = action:new({
		{ time = 1 },
		{ transform = effect.destroy }
	})
}

local firstsplash = timer:new(2)
local dtaccum = 0

local function pickspawnpoint(rects)
	local weights = {}
	for _, r in ipairs(rects) do weights[#weights+1] = r:area() end
	local whichrect = weightedrandom(rects, weights)
	return whichrect:randpoint()
end

local loudsplash = love.audio.newSource(basepath.."splash.mp3", "static")
local function spawnsplash(...)
	splash:spawn(...)
	love.audio.play(loudsplash)
	splash.spots[#splash.spots]:start("decaying")
end

local lake = level:new(basepath, "level", {
	rect:new(114, 273, 121, 86),
	rect:new(180, 291, 208, 195),
	rect:new(132, 354, 54, 97),
	rect:new(362, 344, 290, 111),
	rect:new(383, 300, 41, 186),
	rect:new(424, 455, 90, 22),
	rect:new(145, 451, 35, 29),
	rect:new(298, 279, 82, 12),
	rect:new(538, 327, 107, 17),
	rect:new(514, 455, 105, 17),
	rect:new(651, 351, 28, 101),
	rect:new(135, 450, 14, 20),
})

local screenwalls = {
	rect:new(-5, -5, width+210, 5), 	   -- top
	rect:new(-5, -5, 5, height+10), 	   -- left
	rect:new(width+200, -5, 5, height+10), -- right
	rect:new(width, height, width+210, 5), -- bottom
}

local caughtfishes = {}
local fishactions = {
	catchcurve = action:new({
		{ -- frame 1
			transform = function(thisfish, dt, thistimer)
				local x1, y1 = thisfish.transform.init.ox, thisfish.transform.init.oy
				local x2, y2 = bigfluff.x, bigfluff.y - bigfluff.height / 3
				local curve = fishcurve(x1, y1, x2, y2)
				thisfish.x, thisfish.y = curve:evaluate(1-thistimer:progress())
				-- funny rotates
				-- 1+(abs(0.5-timer:progress)) is to make it spin slower at the peak
				thisfish.transform.dr = thisfish.transform.dr + 4*math.pi*dt*(math.abs(0.5-thistimer:progress())+1)^2
			end,

			time = 0.75
		},
	})
}

local function pickfish()
	local fishesinorder = keys(fishes)
	local fishweights = {}
	for i, k in ipairs(fishesinorder) do fishweights[i] = fishes[k].rarity end
	return weightedrandom(fishesinorder, fishweights)
end

local crawdadhole = love.audio.newSource(basepath.."bigfluff.wav", "stream")
local grunts = {
	love.audio.newSource(basepath.."alangrunt.mp3", "static"),
	love.audio.newSource(basepath.."macygrunt.mp3", "static"),
	love.audio.newSource(basepath.."jackgrunt.mp3", "static"),
	love.audio.newSource(basepath.."junegrunt.mp3", "static"),
}
-- function fishinhole.enter() end
function fishinhole.leave() 
	love.audio.stop(crawdadhole)
	for _, grunt in ipairs(grunts) do love.audio.stop(grunt) end
end

function fishinhole.update(dt)
	if not crawdadhole:isPlaying() then love.audio.play(crawdadhole) end

	local dx, dy = 0, 0
	local p = function(x, dt, s) return x + dt * s end
	if love.keyboard.isDown("up")    then dy = p(dy, dt, -bigfluff.speed) end
	if love.keyboard.isDown("down")  then dy = p(dy, dt, bigfluff.speed) end
	if love.keyboard.isDown("left")  then dx = p(dx, dt, -bigfluff.speed) end
	if love.keyboard.isDown("right") then dx = p(dx, dt, bigfluff.speed) end
	
	if bigfluff.rect:at(bigfluff.x + dx, bigfluff.y + dy):collidesrects(lake.rects, screenwalls) then 
		if bigfluff.rect:at(bigfluff.x + dx, bigfluff.y):collidesrects(lake.rects, screenwalls) then dx = 0 end
		if bigfluff.rect:at(bigfluff.x, bigfluff.y + dy):collidesrects(lake.rects, screenwalls) then dy = 0 end
	end

	bigfluff.x, bigfluff.y = bigfluff.x + dx, bigfluff.y + dy

	if love.keyboard.isDown("lshift") and line.scaledheight - (dt * line.speed) > 0 then 
		line:start("reeling", dt)
	end

	if love.keyboard.isDown("lctrl") then 
		line:stop("reeling")
		rod:start("casting")
		line:start("casting")
	end

	rod.x, rod.y = bigfluff.x, bigfluff.y
	line.x, line.y = rod.x, rod.y
	ripple.x = line.x - line.transform.init.ox
	ripple.y = line.y - line.transform.init.oy + line.scaledheight
	ripple.inwater = pointinrects(ripple.x, ripple.y, lake.rects) and line.scaledheight >= 12

	-- fish spawning
	-- guarantees a spawn within first 2 seconds
	if firstsplash and firstsplash:countdown(dt) then
		firstsplash = nil -- destroy timer
		spawnsplash(pickspawnpoint(lake.rects))
	else
		local fishchance = math.ceil(1500/(dtaccum/120+5))
		if love.math.random(1, fishchance) == 1 then
			spawnsplash(pickspawnpoint(lake.rects))
		end
	end

	if dtaccum + dt <= 65535 then dtaccum = dtaccum + dt end
	
	-- here we check to see if the ripple collides with any of the splash points
	-- used to be a bug where finding multiple spots would freeze the rod
	-- this picks the closest one
	local collidedidx, collidedspot = nil, nil
	local collideddist = math.huge
	for idx, spot in ipairs(splash.spots) do
		local collides = ripple:rect():haspoint(spot.x, spot.y)
		local distance = distance(ripple:rect():center(), {spot.x, spot.y})
		if collides and distance < collideddist then
			collideddist = distance
			collidedidx = idx
		end
	end

	if collidedidx then collidedspot = splash.spots[collidedidx] end

	local tofish = nil
	if collidedidx and line:is("reeling") then
		collidedspot:stop("decaying")
		collidedspot:start("pulling")
		line.speed = 0

		local gruntplaying = false
		for _, grunt in ipairs(grunts) do
			if grunt:isPlaying() then gruntplaying = true end
		end
		if not gruntplaying then love.audio.play(trandom(grunts)) end
		
		line:start("grunting")

		if collidedspot.frame.pulling == 2 then
			tofish = pickfish()
			line.transform.dx, line.transform.dy = 0, 0
			line.speed = 400
			line:stop("grunting")
		end

	elseif collidedidx then -- clean up after a fail
		collidedspot:stop("pulling")
		collidedspot:start("decaying")
		line:stop("grunting")
		line.transform.dx, line.transform.dy = 0, 0
		line.speed = 400
	end

	line:update(dt)
	rod:update(dt)
	for i = #splash.spots, 1, -1 do
		if splash.spots[i].destroy then table.remove(splash.spots, i)
		else splash.spots[i]:update(dt) end
	end

	if tofish then
		local fishx, fishy = collidedspot.x, collidedspot.y
		local f = fishes[tofish]
		
		local fa = actor:new("fish/", tofish, {sx = f.scale, ox = f.len/2, oy = f.height/2})
		fa.x, fa.y = fishx, fishy
		fa.transform.init.ox, fa.transform.init.oy = fishx, fishy
		fa.actions = copy(fishactions)
		fa:start("catchcurve", dt)
		caughtfishes[#caughtfishes+1] = fa
	end

	if tofish and scenes[tofish] then 
		return scenes[tofish] -- switch to scene
	else
		for i = #caughtfishes, 1, -1 do
			caughtfishes[i]:update(dt)
			if #caughtfishes[i].state == 0 then 
				table.remove(caughtfishes, i)
			end
		end
	end
end

function fishinhole.draw()
	lake:draw(0, 0)
	if not rod:is("casting") and ripple.inwater then ripple:draw() end
	for _, spot in ipairs(splash.spots) do spot:draw() end
	line:draw()
	bigfluff:draw()
	rod:draw()
	for _, caughtfish in ipairs(caughtfishes) do caughtfish:draw() end
end

return fishinhole
