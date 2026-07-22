const startTime = os.time()

return function(): string
	const uptime = os.time() - startTime
<<<<<<< HEAD

	const days = math.floor(uptime / 86400)
	const hours = math.floor(uptime / 3600) % 24
	const minutes = math.floor(uptime / 60) % 60
	const seconds = uptime % 60

	return `{days}d {hours}h {minutes}m {seconds}s`
=======
	return ("%dd %dh %dm %ds"):format(math.floor(uptime / (60 * 60 * 24)), math.floor(uptime / (60 * 60)) % 24, math.floor(uptime / 60) % 60, math.floor(uptime) % 60)
>>>>>>> 73c350f (refactor: finalize Dispatcher.luau, commands and types)
end
