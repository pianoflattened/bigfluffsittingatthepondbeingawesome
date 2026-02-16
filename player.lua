function domovement(player, rects, dt)
	-- local rects = copy(level.rects)
	-- if enforcewindowborder then
	-- 	table.insert(rects, rect:new(-100, -100, width, 100))
	-- 	table.insert(rects, rect:new(-100, -100, 100, height))
	-- 	table.insert(rects, rect:new(width, 0, 100, height))
	-- 	table.insert(rects, rect:new(0, height, width, 100))
	-- end

	local dx, dy = 0, 0

	if love.keyboard.isDown("up")    then dy = dy - player.speed*dt end
	if love.keyboard.isDown("down")  then dy = dy + player.speed*dt end
	if love.keyboard.isDown("left")  then dx = dx - player.speed*dt end
	if love.keyboard.isDown("right") then dx = dx + player.speed*dt end

	if player.rect:at(player.x + dx, player.y + dy):collidesrects(rects) then
		if player.rect:at(player.x, player.y + dy):collidesrects(rects) then dy = 0 end
		if player.rect:at(player.x + dx, player.y):collidesrects(rects) then dx = 0 end
	end
	
	return dx, dy
end
