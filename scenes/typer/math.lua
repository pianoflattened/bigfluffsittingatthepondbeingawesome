function avg(ratio)
	local a, b = table.unpack(ratio)
	return (a + b)/2
end

function diff(ratio)
	local a, b = table.unpack(ratio)
	return math.abs(a - b)
end

function iscoprime(a, b)
	while a ~= b do
		if a > b then a = a - b
		else b = b - a end
	end
	return a == 1
end
