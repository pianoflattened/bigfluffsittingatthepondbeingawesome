sam = {
	speed = 72,
	pitch = 64,
	throat = 128,
	mouth = 128,
}

function sam:outpath(path)
	self.path = path
	if love.filesystem.exists(self.path) then
		self.source = love.audio.newSource(path, "stream")
	end
end

function sam:say(input)
	local execpath = "lib/sam"
	if love.system.getOS() == "Windows" then 
		execpath = execpath..".exe" 
	else 
		execpath = "./"..execpath 
		input = "\""..string.gsub(input, "\"", "'").."\""
	end
	
	local cmd = table.concat({execpath, "-debug -wav", self.path, input}, " ")
	local f = io.popen(cmd)
	local o = f:read("*all")
	if self.source == nil then self.source = love.audio.newSource(self.path, "stream") end
	love.audio.play(self.source)
end
