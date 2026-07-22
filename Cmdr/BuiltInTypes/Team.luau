const Teams = game:GetService("Teams")

return function(registry)
	const teamType = {
		Transform = function(text)
			const findTeam = registry.Cmdr.Util.MakeFuzzyFinder(Teams:GetTeams())
			return findTeam(text)
		end,

		Validate = function(teams)
			return #teams > 0, "No team with that name could be found."
		end,

		Autocomplete = function(teams)
			return registry.Cmdr.Util.GetNames(teams)
		end,

		Parse = function(teams)
			return teams[1]
		end,
	}

	const teamPlayersType = {
		Listable = true,
		Transform = teamType.Transform,
		Validate = teamType.Validate,
		Autocomplete = teamType.Autocomplete,

		Parse = function(teams)
			return teams[1]:GetPlayers()
		end,
	}

	const teamColorType = {
		Transform = teamType.Transform,
		Validate = teamType.Validate,
		Autocomplete = teamType.Autocomplete,

		Parse = function(teams)
			return teams[1].TeamColor
		end,
	}

	registry:RegisterType("team", teamType)
	registry:RegisterType("teams", registry.Cmdr.Util.MakeListableType(teamType))

	registry:RegisterType("teamPlayers", teamPlayersType)

	registry:RegisterType("teamColor", teamColorType)
	registry:RegisterType("teamColors", registry.Cmdr.Util.MakeListableType(teamColorType))
end
