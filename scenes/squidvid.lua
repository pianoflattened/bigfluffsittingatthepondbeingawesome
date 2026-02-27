local squidvid = {}
local basepath = "scenes/squidvid/"
local played = false
local video = love.graphics.newVideo(self.basepath.."squidvid.ogv")
local sx, sy = 800/video:getWidth(), 600/video:getHeight()

function squidvid.enter()
	played = false
end

function squidvid.update(dt)
	if not video:isPlaying() and not played then 
		video:play()
		played = true
	else return fishinhole, 1 end
end

function squidvid.draw()
	love.graphics.draw(video, 0, 0, 0, sx, sy)
end

return squidvid
