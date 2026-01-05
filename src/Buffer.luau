local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[[
	@Flipitagainpls
	12/27/2024
	Easy buffer util that does all the buffing for you

	Example:

	local Buffer = requireq(path.to.buffer)

	local buff = Buffer.new{
		str = 'my string',
		num = 1245
	} :: {a table with optimized values}

	--@and thats it, complete buff!
]]

local BufferEncoder = require(script.Parent.Parent.Packages.BufferEncoder)

local bufferFunctions = {
	BuffNumber = function(num: number, writeType: buffer, readType: buffer)
		local buff = buffer.create(5)
		writeType(buff, 0, num)
		return readType(buff, 0)
	end,

	BuffString = function(str: string)
		local length = string.len(str)
		local buff = buffer.create(length)
		buffer.writestring(buff, 0, str)
		return buffer.readstring(buff, 0, length)
	end,

	BuffFloat = function(float: number)
		local buff = buffer.create(100)
		buffer.writef64(buff, 0, float)
		return buffer.readf64(buff, 0)
	end,
}

local numberBuffLimits = {
	signed = {
		[-127] = buffer.writei8,
		[-32768] = buffer.writei16,
		[-2147483647] = buffer.writei32,
	},

	unsigned = {
		[255] = buffer.writeu8,
		[65535] = buffer.writeu16,
		[4294967295] = buffer.writeu32,
	},
}

local readTypes = {
	[buffer.writei8] = buffer.readi8,
	[buffer.writei16] = buffer.readi16,
	[buffer.writei32] = buffer.readi32,
	[buffer.writeu8] = buffer.readu8,
	[buffer.writeu16] = buffer.readu16,
	[buffer.writeu32] = buffer.readu32,
}

local function isBetween(number, lowerBound, upperBound)
	return number >= lowerBound and number <= upperBound
end

local function findBufferTypeForNumber(n: number)
	if n > 0 then
		for b, t in numberBuffLimits.unsigned do
			if isBetween(n, 0, b) then
				return n, t, readTypes[t]
			end
		end
	else
		for b, t in numberBuffLimits.signed do
			if isBetween(n, b, 0) then
				return n, t, readTypes[t]
			end
		end
	end
end

--@buffs out the given value if its a string, float, or number
local function BuffGivenValue(value: any)
	if type(value) == "string" then
		return bufferFunctions.BuffString(value)
	elseif type(value) == "number" then
		if value ~= math.round(value) then
			return bufferFunctions.BuffFloat(value)
		end
		--@buffs a number based on the specific values so it has the correct bufff
		return bufferFunctions.BuffNumber(findBufferTypeForNumber(value))
	end
	--@returns the value if it is not a string, number, or float
	return value
end

local Buffer = {
	-- uses a table and buffs all of the values then returns a new table with the optimized data
	--[[new = function(b: { any })
		if #b == 0 or b.n == 0 then return b end
		local n: any = {}
		for k, v in b do
			n[k] = BuffGivenValue(v)
		end
		return n
	end,]]

	new = function(b: { any })
		local option = BufferEncoder.write(b)
		return BufferEncoder.read(option)
	end,
}

return Buffer
