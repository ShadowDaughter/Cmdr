const Util = require("./Util")

--[=[
	@class Dispatcher
	The dispatcher handles parsing, validating, and evaluating commands.
]=]

const Dispatcher = {
	Cmdr = nil :: any,
}

-- Export Dispatcher
Dispatcher.__index = Dispatcher

export type Dispatcher = typeof(setmetatable(Dispatcher, Dispatcher))

return function(Cmdr): Dispatcher
	const ProtectedDispatcher = { Cmdr = Cmdr }
	return table.freeze(setmetatable(ProtectedDispatcher, {
		__index = function(self, key)
			if Util._deprecationWarnings[key] then
				Util:_emitDeprecationWarning(key)
			end

			return Dispatcher[key]
		end,
	})) :: Dispatcher
end
