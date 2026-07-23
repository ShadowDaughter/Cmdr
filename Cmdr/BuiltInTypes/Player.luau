const Players = game:GetService("Players")

return function(registry)
	const playerType = {
		Transform = function(text: string): Player
			local findPlayer = registry.Cmdr.Util.MakeFuzzyFinder(Players:GetPlayers())
			return findPlayer(text)
		end,

		Validate = function(players: { Player }): boolean
			return #players > 0, "No player with that name could be found."
		end,

		Autocomplete = function(players: { Player }): { string }
			return registry.Cmdr.Util.GetNames(players)
		end,

		Parse = function(players: { Player }): Player?
			return players[1]
		end,

		Default = function(player: Player): string
			return if player.DisplayName == player.Name then player.Name else `{player.DisplayName} (@{player.Name})`
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
