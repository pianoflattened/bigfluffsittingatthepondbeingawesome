function domovement(player, level, dt)
	local dx, dy = 0, 0

	if love.keyboard.isDown("up")    then dy = dy - player.speed*dt end
	if love.keyboard.isDown("down")  then dy = dy + player.speed*dt end
	if love.keyboard.isDown("left")  then dx = dx - player.speed*dt end
	if love.keyboard.isDown("right") then dx = dx + player.speed*dt end

	if player.rect:at(player.x + dx, player.y + dy):collidesrects(level.rects) then
		if player.rect:at(player.x, player.y + dy):collidesrects(level.rects) then dy = 0 end
		if player.rect:at(player.x + dx, player.y):collidesrects(level.rects) then dx = 0 end
	end
	
	return dx, dy
end
