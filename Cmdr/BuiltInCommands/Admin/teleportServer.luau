return function(_, fromPlayers: { Player }, destination: Player | Vector3): string
	local cFrame
<<<<<<< HEAD
	if typeof(destination) == "Instance" then
=======
	if typeof(destination) == "Player" then
>>>>>>> 73c350f (refactor: finalize Dispatcher.luau, commands and types)
		if destination.Character and destination.Character:FindFirstChild("HumanoidRootPart") then
			cFrame = destination.Character:GetPivot()
		else
			return "Target player has no character."
		end
	elseif typeof(destination) == "Vector3" then
		cFrame = CFrame.new(destination)
	end

	for _, player: Player in ipairs(fromPlayers) do
		const character = player.Character
		const humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if not character or not humanoid then
			continue
		end

		if humanoid.SeatPart then
			humanoid.Sit = false
			humanoid:GetPropertyChangedSignal("SeatPart"):Wait()
		end

		character:PivotTo(cFrame)
	end

<<<<<<< HEAD
	return `Teleported {#fromPlayers} players.`
=======
	return ("Teleported %d players."):format(#fromPlayers)
>>>>>>> 73c350f (refactor: finalize Dispatcher.luau, commands and types)
end
