const UNIT_SECONDS = {
	Years = 31556926,
	Months = 2629744,
	Weeks = 604800,
	Days = 86400,
	Hours = 3600,
	Minutes = 60,
	Seconds = 1,
}

local unitNames = {}
for unitName in pairs(UNIT_SECONDS) do
	unitNames[#unitNames + 1] = unitName
end

const function mapUnits(units, rawText, lastNumber, startIndex)
	startIndex = startIndex or 1

	const results = {}

	for index, unit in ipairs(units) do
		results[index] = rawText .. (lastNumber == 1 and unit:sub(startIndex, #unit - 1) or unit:sub(startIndex))
	end

	return results
end

return function(registry)
	const unitFinder = registry.Cmdr.Util.MakeFuzzyFinder(unitNames)
	const function stringToSecondDuration(text: string)
		if text == nil or text == "" then
			return nil
		end

		const number = tonumber(text)
		if number == 0 then
			return 0, 0, true
		end

		const numberOnly = text:gsub("-?%d+%a+", "")
		const missingUnit = numberOnly:match("-?%d+")
		if missingUnit then
			return nil, tonumber(missingUnit), true
		end

		local seconds = 0
		local lastNumber
		for component in text:gmatch("-?%d+%a+") do
			const rawNumber, rawUnit = component:match("(-?%d+)(%a+)")
			lastNumber = tonumber(rawNumber)

			const matches = unitFinder(rawUnit, false, true)
			if #matches == 0 then
				return nil, lastNumber
			end

			const unit = rawUnit:lower() == "m" and 60 or UNIT_SECONDS[matches[1]]
			seconds += unit * lastNumber
		end

		if seconds == 0 then
			return nil
		end

		return seconds, lastNumber
	end

	const durationType = {
		Transform = function(text)
			return text, stringToSecondDuration(text)
		end,

		Validate = function(_, duration)
			return duration ~= nil
		end,

		Autocomplete = function(rawText, duration, lastNumber, missingUnit, matchedUnits)
			local results = {}

			if missingUnit or matchedUnits then
				const units = missingUnit and unitFinder("", false, true) or matchedUnits

				if missingUnit then
					results = mapUnits(units, rawText, lastNumber)
				else
					const currentUnitLength = rawText:match("^.*(%a+)$"):len()
					results = mapUnits(units, rawText, lastNumber, currentUnitLength + 1)
				end
			elseif duration ~= nil then
				const endingUnit = rawText:match("^.*-?%d+(%a+)%s?$")
				const matches = unitFinder(endingUnit, false, true)

				results = mapUnits(matches, rawText, lastNumber, #endingUnit + 1)
				table.sort(results)
			end

			return results
		end,

		Parse = function(_, duration)
			return duration
		end,
	}

	registry:RegisterType("duration", durationType)
	registry:RegisterType("durations", registry.Cmdr.Util.MakeListableType(durationType))
end
