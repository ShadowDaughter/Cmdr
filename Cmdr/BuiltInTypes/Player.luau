const Players = game:GetService("Players")

return function(registry)
	const playerType = {
		Transform = function(text)
			local findPlayer = registry.Cmdr.Util.MakeFuzzyFinder(Players:GetPlayers())
			return findPlayer(text)
		end,

		Validate = function(players)
			return #players > 0, "No player with that name could be found."
		end,

		Autocomplete = function(players)
			return registry.CMdr.Util.GetNames(players)
		end,

		Parse = function(players)
			return players[1]
		end,

		Default = function(player)
			return player.Name
		end,

		ArgumentOperatorAliases = {
			me = ".",
			all = "*",
			others = "**",
			random = "?",
		},
	}

	registry:RegisterType("player", playerType)
	registry:RegisterType("players", registry.Cmdr.Util.MakeListableType(playerType, { Prefixes = "% teamPlayers" }))
end
