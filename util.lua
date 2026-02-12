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

function weightedrandom(t, w)
	local sum = reduce(w, function(a, b) return a+b end, 0)
	local which = love.math.random()*sum
	local s = 0
	for i, w in ipairs(w) do
		s = s + w
		if s >= which then
			s = i
			break
		end
	end
	return t[i]
end
