inspect = require 'inspect'
json = require 'json'

timer = { duration = 0 }
timer.__index = timer
function timer:new(duration)
	local o = setmetatable({}, self)
	o.duration = duration
	o.clock = duration
	return o
end

function timer:reset()
	self.clock = self.duration
end

function timer:countdown(dt)
	self.clock = self.clock - dt
	return self.clock <= 0
end

function timer:progress()
	return math.max(math.min(1, self.clock/self.duration), 0)
end

function string.split(inputstr, sep)
	local mp = "([^"..sep.."]+)"
	if sep and #sep > 1 then 
		mp = "(.-)("..sep..")"
		inputstr = inputstr + sep
	end
	if sep == nil then sep = "%s" end
	
	local t = {}
	for str in string.gmatch(inputstr, mp) do table.insert(t, str) end
	return t
end


function copy(obj, seen)
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
	return res
end

function reduce(list, fn, init)
    local acc = init
    for k, v in ipairs(list) do
        if 1 == k and not init then acc = v
        else acc = fn(acc, v) end
    end
    return acc
end

function keys(t)
	local k = {}
	for ky, _ in pairs(t) do
		table.insert(k, ky)
	end
	return k
end

function math.atanh(x)
	if x <= -1 or x >= 1 then return 0/0 end
	return 0.5*math.log((1+x)/(1-x))
end

function dictrandom(d)
	local k = keys(d)
	return d[k[love.math.random(#k)]]
end

function trandom(t)
	return t[love.math.random(#t)]
end

function weightedrandom(t, w)
	local sum = reduce(w, function(a, b) return a+b end, 0)
	local which = love.math.random()*sum
	local s = 0
	local idx = 1
	for i, w in ipairs(w) do
		s = s + w
		if s >= which then
			idx = i
			break
		end
	end
	return t[idx]
end

function last(t, i)
	local l = #t
	return t[l+i+1]
end

function fileextension(n)
	return last(string.split(n, "."), -1)
end

function switch(i, cases)
	local match = cases[i] or cases.default or function() end
	return match()
end

function table.contains(t, i)
	for _, v in pairs(t) do
		if v == i then return true end
	end
	return false
end
