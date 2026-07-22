return function(registry)
	const typeType = {
		Transform = function(text)
			const findCommand = registry.Cmdr.Util.MakeFuzzyFinder(registry:GetTypeNames())
			return findCommand(text)
		end,

		Validate = function(commands)
			return #commands > 0, "No type with that name could be found."
		end,

		Autocomplete = function(commands)
			return commands
		end,

		Parse = function(commands)
			return commands[1]
		end,
	}

	registry:RegisterType("type", typeType)
	registry:RegisterType("types", registry.Cmdr.Util.MakeListableType(typeType))
end
