return function(_, players: { Player }): string
	for _, player: Player in pairs(players) do
		pcall(player.LoadCharacterAsync, player)
	end

	return `Respawned {#players} players.`
end
