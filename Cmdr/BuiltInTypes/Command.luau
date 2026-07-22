return function(registry)
	const commandType = {
		Transform = function(text)
			local findCommand = registry.Cmdr.Util.MakeFuzzyFinder(registry:GetCommandNames())

			return findCommand(text)
		end,

		Validate = function(commands)
			return #commands > 0, "No command with that name could be found."
		end,

		Autocomplete = function(commands)
			return commands
		end,

		Parse = function(commands)
			return commands[1]
		end,
	}

	registry:RegisterType("command", commandType)
	registry:RegisterType("commands", registry.Cmdr.Util.MakeListableType(commandType))
end
