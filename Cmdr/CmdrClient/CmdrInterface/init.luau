const CreateGui = require("@self/CreateGui")
const WindowModule = require("@self/Window")
const AutoCompleteModule = require("@self/AutoComplete")

return function(CmdrClient)
	const AutoComplete = AutoCompleteModule(CmdrClient)
	const Window = WindowModule(CmdrClient, AutoComplete)

	return {
		Window = Window,
		AutoComplete = AutoComplete,
		Gui = CreateGui(),
	}
end
