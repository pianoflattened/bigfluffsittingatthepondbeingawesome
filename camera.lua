camera = {
	zoom = 1,
	zoomx = 0,
	zoomy = 0,
}

function camera:zoomBy(amt)
	self.zoom = self.zoom*amt
end

function camera:zoomTo(amt)
	self.zoom = amt
end

-- x & y are the top left corner of frame
function camera:panTo(x, y)
	self.zoomx = x
	self.zoomy = y
end

function camera:pan(dx, dy)
	self.zoomx = zoomx + dx
	self.zoomy = zoomy + dy
end

function camera:reset()
	self.zoom = 1
	self.zoomx = 0
	self.zoomy = 0
end
