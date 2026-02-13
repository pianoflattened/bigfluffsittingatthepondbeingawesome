enum = {}
enum.__index = enum

function enum:new(...)
	local arg = {...}
	local o = setmetatable({}, self)
	for i, v in ipairs(arg) do o[v] = i end
	o.__default = arg[0]
	return o
end
