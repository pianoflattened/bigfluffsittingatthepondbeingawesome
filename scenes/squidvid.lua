squidvid = {
	basepath = "scenes/squidvid/",
	played = false,
}

function squidvid:init()
	video = love.graphics.newVideo(self.basepath.."squidvid.ogv")
	scalex = 800/video:getWidth()
	scaley = 600/video:getHeight()
end

function squidvid:enter()
	self.played = false
end

function squidvid:update(dt)
	if not video:isPlaying() then
		if not self.played then 
			video:play()
			self.played = true
		else gs.switch(fishinhole) end
	end
end

function squidvid:draw()
	love.graphics.draw(video, 0, 0, 0, scalex, scaley)
end

return squidvid
