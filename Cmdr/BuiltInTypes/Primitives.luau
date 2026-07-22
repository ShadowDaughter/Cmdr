const stringType = {
	Validate = function(value)
		return value ~= nil
	end,

	Parse = function(value)
		return tostring(value)
	end,
}

const numberType = {
	Transform = function(text)
		return tonumber(text)
	end,

	Validate = function(value)
		return value ~= nil
	end,

	Parse = function(value)
		return value
	end,
}

const intType = {
	Transform = function(text)
		return tonumber(text)
	end,

	Validate = function(value)
		return value ~= nil and value == math.floor(value), "Only whole numbers are valid."
	end,

	Parse = function(value)
		return value
	end,
}

const positiveIntType = {
	Transform = function(text)
		return tonumber(text)
	end,

	Validate = function(value)
		return value ~= nil and value == math.floor(value) and value > 0, "Only positive whole numbers are valid."
	end,

	Parse = function(value)
		return value
	end,
}

const nonNegativeIntType = {
	Transform = function(text)
		return tonumber(text)
	end,

	Validate = function(value)
		return value ~= nil and value == math.floor(value) and value >= 0, "Only non-negative whole numbers are valid."
	end,

	Parse = function(value)
		return value
	end,
}

const byteType = {
	Transform = function(text)
		return tonumber(text)
	end,

	Validate = function(value)
		return value ~= nil and value == math.floor(value) and value >= 0 and value <= 255, "Only bytes are valid."
	end,

	Parse = function(value)
		return value
	end,
}

const digitType = {
	Transform = function(text)
		return tonumber(text)
	end,

	Validate = function(value)
		return value ~= nil and value == math.floor(value) and value >= 0 and value <= 9, "Only digits are valid."
	end,

	Parse = function(value)
		return value
	end,
}

return function(registry)
	const truthy = registry.Cmdr.Util.MakeDictionary({ "true", "t", "yes", "y", "on", "enable", "enabled", "1", "+" })
	const falsy = registry.Cmdr.Util.MakeDictionary({ "false", "f", "no", "n", "off", "disable", "disabled", "0", "-" })
	const boolType = {
		Transform = function(text)
			return text:lower()
		end,

		Validate = function(value)
			return truthy[value] ~= nil or falsy[value] ~= nil, "Please use true/yes/on or false/no/off."
		end,

		Parse = function(value)
			if truthy[value] then
				return true
			elseif falsy[value] then
				return false
			else
				return nil
			end
		end,
	}

	registry:RegisterType("string", stringType)
	registry:RegisterType("number", numberType)
	registry:RegisterType("integer", intType)
	registry:RegisterType("positiveInteger", positiveIntType)
	registry:RegisterType("nonNegativeInteger", nonNegativeIntType)
	registry:RegisterType("byte", byteType)
	registry:RegisterType("digit", digitType)
	registry:RegisterType("boolean", boolType)

	registry:RegisterType("strings", registry.Cmdr.Util.MakeListableType(stringType))
	registry:RegisterType("numbers", registry.Cmdr.Util.MakeListableType(numberType))
	registry:RegisterType("integers", registry.Cmdr.Util.MakeListableType(intType))
	registry:RegisterType("positiveIntegers", registry.Cmdr.Util.MakeListableType(positiveIntType))
	registry:RegisterType("nonNegativeIntegers", registry.Cmdr.Util.MakeListableType(nonNegativeIntType))
	registry:RegisterType("bytes", registry.Cmdr.Util.MakeListableType(byteType))
	registry:RegisterType("digits", registry.Cmdr.Util.MakeListableType(digitType))
	registry:RegisterType("booleans", registry.Cmdr.Util.MakeListableType(boolType))
end
