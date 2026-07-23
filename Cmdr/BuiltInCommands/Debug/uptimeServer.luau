const startTime = os.time()

return function(): string
	const uptime = os.time() - startTime

	const days = math.floor(uptime / 86400)
	const hours = math.floor(uptime / 3600) % 24
	const minutes = math.floor(uptime / 60) % 60
	const seconds = uptime % 60

	return `{days}d {hours}h {minutes}m {seconds}s`
end
