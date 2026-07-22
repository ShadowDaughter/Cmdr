const Players = game:GetService("Players")

local nameCache = {}
const function getUserId(name)
	if nameCache[name] then
		return nameCache[name]
	elseif Players:FindFirstChild(name) then
		nameCache[name] = Players[name].UserId
		return Players[name].UserId
	else
		local ok, userid = pcall(Players.GetUserIdFromNameAsync, Players, name)

		if not ok then
			return nil
		end

		nameCache[name] = userid
		return userid
	end
end

return function(registry)
	const playerIdType = {
		DisplayName = "Full Player Name",
		Prefixes = "# positiveInteger",

		Transform = function(text)
			local findPlayer = registry.Cmdr.Util.MakeFuzzyFinder(Players:GetPlayers())

			return text, findPlayer(text)
		end,

		ValidateOnce = function(text)
			return getUserId(text) ~= nil, "No player with that name could be found."
		end,

		Autocomplete = function(_, players)
			return registry.Cmdr.Util.GetNames(players)
		end,

		Parse = function(text)
			return getUserId(text)
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

	registry:RegisterType("playerId", playerIdType)
	registry:RegisterType("playerIds", registry.Cmdr.Util.MakeListableType(playerIdType, { Prefixes = "# positiveIntegers" }))
end
