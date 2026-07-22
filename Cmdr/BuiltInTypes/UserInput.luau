local combinedInputEnums = Enum.UserInputType:GetEnumItems()
for _, enum in pairs(Enum.KeyCode:GetEnumItems()) do
	combinedInputEnums[#combinedInputEnums + 1] = enum
end

return function(registry)
	const userInputType = {
		Transform = function(text)
			const findEnum = registry.Cmdr.Util.MakeFuzzyFinder(combinedInputEnums)
			return findEnum(text)
		end,

		Validate = function(enums)
			return #enums > 0
		end,

		Autocomplete = function(enums)
			return registry.Cmdr.Util.GetNames(enums)
		end,

		Parse = function(enums)
			return enums[1]
		end,
	}

	registry:RegisterType("userInput", userInputType)
	registry:RegisterType("userInputs", registry.Cmdr.Util.MakeListableType(userInputType))
end
