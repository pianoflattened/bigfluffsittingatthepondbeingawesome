local handshake = {}
local basepath = "scenes/handshake/"

local friendhand = actor:new(basepath, "friendhand", {ox = 84, oy = 96})
friendhand.x, friendhand.y = 315, 453
-- friendhand.show = false
friendhand.rect = rect:new(315, 453, 63, 46)

local friendhouse = level:new(basepath, "friendshouse", {
	rect:new(315, 453, 63, 46)
})

local dooropens = actor:new(basepath, "dooropens")
dooropens.actions.intro = action:new({
	{ time = 1.2 },
	{ transform = function(dooropens) dooropens.show = true end }
})
-- dooropens.show = false

local arm = actor:new(basepath, "arm", {oy = 77})
-- arm.x, arm.y = 600, 520
arm:addcostume(basepath, "armwarts")
-- arm.speed = 0
arm.rect = rect:new(81, -27, 12, 59)

local friend = actor:new(basepath, "friendnohand")
friend.x, friend.y = 229, 253
-- friend.opacity = 0
friend.actions.intro = action:new({
	{ time = 1.4 },
	{ 
		transform = function(friend, dt) 
			friend.opacity = math.min(1, friend.opacity + 0.025) 
		end,
		
    	test = function(friend) 
    		return friend.opacity == 1 
    	end 
    },
	{
		transform = function()
			friendhand.show = true
			arm.speed = 50
		end
	}
})

local airplane = actor:new(basepath, "airplane")
airplane.x, airplane.y = 800, 20
airplane.speed = 800/30
airplane.actions.woosh = action:new({
	{
		test = function(airplane)
			return airplane.x <= -airplane.width
		end,

		transform = function(airplane, dt)
			airplane.x = airplane.x - airplane.speed*dt
		end
	}
})

local timeaccum, camwalls, shakelist, failtimer, failcount

local awesomevideogamemusic = love.audio.newSource(basepath.."epiceurobeat.mp3", "stream")

local airplanewoosh = love.audio.newSource(basepath.."airplane.mp3", "stream")
local splat = love.audio.newSource(basepath.."splat.mp3", "stream")
local knock = love.audio.newSource(basepath.."knock.mp3", "stream")
local dooropen = love.audio.newSource(basepath.."dooropen.mp3", "stream")
local heartbeat = love.audio.newSource(basepath.."heartbeat.mp3", "stream")
local teethchatter = love.audio.newSource(basepath.."teethchatter.mp3", "stream")
local breathing = love.audio.newSource(basepath.."breathing.mp3", "stream")


function handshake.enter() 
	timeaccum = 0
	camwalls = {}
	shakelist = {}
	failtimer = timer:new(0.3)
	failcount = 0
	
	friend.opacity = 0
	friendhand.show = false
	dooropens.show = false
	arm.x, arm.y = 600, 520
	arm.speed = 0
	arm.costume = "arm"
	airplane:stop("woosh")
end

function handshake.leave() 
	love.audio.stop(awesomevideogamemusic, airplanewoosh, heartbeat, teethchatter, breathing)
	camera:reset()
end

function handshake.update(dt) 
	if not awesomevideogamemusic:isPlaying() then love.audio.play(awesomevideogamemusic) end
	if not airplane:is("woosh") and love.math.random(400) == 1 then
		airplane.x = 800
		airplane:start("woosh", dt)
		love.audio.play(airplanewoosh)
	end

	airplane:update(dt)

	local dx, dy = 0, 0
	if love.keyboard.isDown("up")    then dy = dy - arm.speed*dt end
	if love.keyboard.isDown("down")  then dy = dy + arm.speed*dt end
	if love.keyboard.isDown("left")  then dx = dx - arm.speed*dt end
	if love.keyboard.isDown("right") then dx = dx + arm.speed*dt end

	-- arm shake
	local jx = math.random(10*dt*arm.speed)*(love.math.random(3)-2)
	local jy = math.random(10*dt*arm.speed)*(love.math.random(3)-2)

	local fail = false
	if love.keyboard.isDown("rshift") and arm.costume == "armwarts" and
	   arm.rect:at(arm.x + dx + jx, arm.y + dy + jy):collides(friendhand.rect) then
		friendhand.y = arm.y + dy - 17

		jx = jx/16
		jy = jy/16
		dx = 0

		if love.keyboard.isDown("down") == love.keyboard.isDown("up") then
			if failtimer:countdown(dt) then fail = true end
			if #shakelist > 0 then
				local last = shakelist[#shakelist]
				last.duration = last.duration + dt
			end
		else
			dy = dy*2
			-- failtimer:reset()
			local shake = { duration = 0 }
			if love.keyboard.isDown("down") then shake.direction = -1 end
			if love.keyboard.isDown("up") then shake.direction = 1 end

			if #shakelist == 0 then shakelist[#shakelist+1] = shake end

			local last = shakelist[#shakelist]
			-- if current direction is opposite of last
			-- & we were going in current direction for a good amt of time
			-- add it to the stack
			if last.direction == shake.direction then
				last.duration = last.duration + dt
				if last.duration > 0.8 then fail = true end
			else
				if last.duration > 0.25 then shakelist[#shakelist+1] = shake
				else fail = true end
			end
		end
	end

	-- doing a fail when the list is empty -> fails on every update after one fail
	if fail and #shakelist > 0 then
		failtimer:reset()
		shakelist = {}
		love.audio.play(splat)
		failcount = failcount + 1
	end

	dx = dx + jx
	dy = dy + jy

	local rects = {}
	for _, wall in ipairs(camwalls) do rects[#rects+1] = wall end
	if arm.rect:at(arm.x + dx, arm.y + dy):collidesrects(rects) then
		if arm.rect:at(arm.x, arm.y + dy):collidesrects(rects) then dy = 0 end
		if arm.rect:at(arm.x + dx, arm.y):collidesrects(rects) then dx = 0 end
	end

	arm.x = arm.x + dx
	arm.y = arm.y + dy

	if timeaccum == 0 then 
		love.audio.play(knock) 
		dooropens:start("intro")
		friend:start("intro")
	end

	friend:update(dt)
	dooropens:update(dt)

	if not friend:is("intro") then -- after all intro anim stuff
		if love.math.random(30) == 1 and not heartbeat:isPlaying() then love.audio.play(heartbeat) end
		if love.math.random(30) == 1 and not teethchatter:isPlaying() then love.audio.play(teethchatter) end
		if love.math.random(30) == 1 and not breathing:isPlaying() then love.audio.play(breathing) end
	end

	if arm.x <= 388 and arm.y > 416 and arm.y < 566 then -- zoom in
		arm.costume = "armwarts"
		camera:zoomTo(4)
		camera:panTo(300, 416)
		
		-- invisible walls so u cant leave the zoom area
		camwalls = rect:new(camera.zoomx, camera.zoomy-50, 
							width/camera.zoom, height/camera.zoom+100):wallsaround(5)
	end

	timeaccum = timeaccum + dt

	if #shakelist == 6 then return fishinhole, 1 end
	if failcount > 3 then return fishinhole end
end

function handshake.draw()
	friendhouse:draw()
	if dooropens.show then dooropens:draw() end
	if airplane:is("woosh") then airplane:draw() end

	love.graphics.setColor(1, 1, 1, friend.opacity)
	friend:draw()
	if friendhand.show then friendhand:draw() end
	arm:draw()
	love.graphics.setColor(1, 1, 1, 1)
end

return handshake
