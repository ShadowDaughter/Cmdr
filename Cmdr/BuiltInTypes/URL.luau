return function(registry)
	const storedKeyType = {
		Validate = function(text)
			if text:match("^https?://.+$") then
				return true
			end

			return false, "URLs must begin with http:// or https://"
		end,

		Parse = function(text)
			return text
		end,
	}

	registry:RegisterType("url", storedKeyType)
	registry:RegisterType("urls", registry.Cmdr.Util.MakeListableType(storedKeyType))
end
