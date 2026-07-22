return function(_, players: { Player }): string
	for _, player: Player in pairs(players) do
		const character = player.Character
		const humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if not character or not humanoid then
			continue
		end

		humanoid.Health = 0
	end

	return `Killed {#players} players.`
end
