const Players = game:GetService("Players")

local nameCache = {}
const function getUserId(username): number?
	username = username:match("%(@([^%)]+)%)") or username

	if nameCache[username] then
		return nameCache[username]
	elseif Players:FindFirstChild(username) then
		nameCache[username] = Players[username].UserId
		return Players[username].UserId
	else
		const success, userid = pcall(Players.GetUserIdFromNameAsync, Players, username)
		if not success then
			return nil
		end

		nameCache[username] = userid
		return userid
	end
end

return function(registry)
	const playerIdType = {
		DisplayName = "Full Player Name",
		Prefixes = "# positiveInteger",

		Transform = function(text): number
			const findPlayer = registry.Cmdr.Util.MakeFuzzyFinder(Players:GetPlayers())
			return text, findPlayer(text)
		end,

		ValidateOnce = function(text): boolean
			return getUserId(text) ~= nil, "No player with that name could be found."
		end,

		Autocomplete = function(_, players: { Player }): string
			return registry.Cmdr.Util.GetNames(players)
		end,

		Parse = function(text: string): number?
			return getUserId(text)
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

	registry:RegisterType("playerId", playerIdType)
	registry:RegisterType("playerIds", registry.Cmdr.Util.MakeListableType(playerIdType, { Prefixes = "# positiveIntegers" }))
end
