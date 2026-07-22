const HttpService = game:GetService("HttpService")

return function(_, url: string): string
	return HttpService:GetAsync(url)
end
