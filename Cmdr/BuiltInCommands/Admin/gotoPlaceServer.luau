const TeleportService = game:GetService("TeleportService")

return function(context: any, players: { Player }, placeId: number, jobId: string): string
	if placeId <= 0 then
		return "Invalid place ID"
	elseif jobId == "-" then
		return "Invalid job ID"
	end

	context:Reply("Commencing teleport...")

	if jobId then
		for _, player: Player in ipairs(players) do
			TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
		end
	else
		TeleportService:TeleportAsync(placeId, players)
	end

	return "Teleported."
end
