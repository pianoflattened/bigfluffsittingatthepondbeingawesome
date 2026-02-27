scene = {
	callbacks = {
		"draw", "errorhandler", "lowmemory", "quit", "threaderror", "update", 
		"directorydropped", "displayrotated", "filedropped", "focus", "mousefocus", "resize", "visible",
		"keypressed", "keyreleased", "textedited", "textinput",
		"mousemoved", "mousepressed", "mousereleased", "wheelmoved",
		"gamepadaxis", "gamepadpressed", "gamepadreleased", "joystickadded", "joystickpressed", "joystickremoved", 
		"touchmoved", "touchpressed", "touchreleased"
	}
}

local function donothing() end
local function undefinedcallback() error("undefined callback") end

for _, callback in ipairs(scene.callbacks) do scene[callback] = undefinedcallback end

function scene.load(s)
	if scene.leave then scene.leave() end
	for _, callback in ipairs(scene.callbacks) do
		if s[callback] then scene[callback] = s[callback]
		else scene[callback] = donothing end
	end
	if s.leave then scene.leave = s.leave end
	if s.enter then 
		scene.enter = s.enter 
		scene.enter()
	end
end

handshake = require 'scenes.handshake'
typer = require 'scenes.typer'
squidvid = require 'scenes.squidvid'
-- animtest = require 'scenes.animtest'
-- raycasttest = require 'scenes.raycasttest'

scenes = {
	friend = handshake,
	words = typer,
	ugy = squidvid,
}

fishinhole = require 'scenes.fishinhole'

-- return scene
