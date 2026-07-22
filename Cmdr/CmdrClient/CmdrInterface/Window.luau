const Players = game:GetService("Players")
const TextChatService = game:GetService("TextChatService")
const UserInputService = game:GetService("UserInputService")
const GuiService = game:GetService("GuiService")

const WINDOW_MAX_HEIGHT = 300
const MOUSE_TOUCH_INPUTS = { Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.Touch }

const VALID_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
const INVALID_TEXT_COLOR = Color3.fromRGB(255, 73, 73)
const PROCESSING_TEXT_COLOR = Color3.fromRGB(255, 153, 153)

const Player = Players.LocalPlayer

-- Checks if a screen position lies outside a given GUI bounds
const function isPositionOutsideGui(position: Vector3, gui: GuiObject): boolean
	local absolutePosition = gui.AbsolutePosition
	local absoluteSize = gui.AbsoluteSize
	return position.X < absolutePosition.X or position.X > absolutePosition.X + absoluteSize.X or position.Y < absolutePosition.Y or position.Y > absolutePosition.Y + absoluteSize.Y
end

-- Constructs auto-completed text string from command argument definitions
local function buildAutoCompleteText(command, lastArg, replace: string): string
	local newText = command.Alias

	for _, argument in command.Arguments do
		local segments = argument.RawSegments

		if argument == lastArg then
			segments[#segments] = replace
		end

		local argumentText = argument.Prefix .. table.concat(segments, ",")

		if argumentText:find(" ") or argumentText == "" then
			argumentText = ("%q"):format(argumentText)
		end

		newText = ("%s %s"):format(newText, argumentText)

		if argument == lastArg then
			break
		end
	end

	return newText
end

--[=[
	@class Window
	Handles the Cmdr command bar interface.
]=]

return function(CmdrClient, AutoComplete)
	const Window = {
		_entry = CmdrClient.Gui:WaitForChild("Entry"),
		_lineTemplate = CmdrClient.Gui:WaitForChild("Line"),

		_previousChatWindowEnabled = nil :: boolean?,
		_previousChatInputBarEnabled = nil :: boolean?,
		_previousChannelTabsEnabled = nil :: boolean?,
		_previousMouseBehavior = nil :: boolean?,
		_lastClosedTime = nil :: number?,

		_valid = true,
		_errorText = nil :: string?,

		_historyState = nil :: { Position: number, InitialText: string }?,

		_hasLostFocus = false,

		_pressCount = 0,
		_lastPressTime = 0,
		_openedByMash = false,
	}

	--[=[
		@within Window
		Get the text entry label
	]=]
	function Window:GetLabelText()
		return self._entry.TextLabel.Text
	end

	--[=[
		@within Window
		Updates the command prompt label.
	]=]
	function Window:UpdateLabelText()
		const placeName = CmdrClient.PlaceName
		self._entry.TextLabel.Text = `{Player.Name}{if placeName and placeName ~= "" then `@{placeName}` else ""}$`
	end

	--[=[
		@within Window
		Recalculate the window height
	]=]
	function Window:UpdateWindowHeight()
		const layout = CmdrClient.Gui.UIListLayout
		const padding = CmdrClient.Gui.UIPadding
		const height = layout.AbsoluteContentSize.Y + padding.PaddingTop.Offset + padding.PaddingBottom.Offset

		CmdrClient.Gui.Size = UDim2.new(CmdrClient.Gui.Size.X.Scale, CmdrClient.Gui.Size.X.Offset, 0, math.clamp(height, 0, WINDOW_MAX_HEIGHT))
		CmdrClient.Gui.CanvasPosition = Vector2.new(0, height)
	end

	--[=[
		@within Window
		@private

		Sets the command entry text.
	]=]
	function Window:_setEntryText(text: string)
		self._entry.TextBox.Text = text

		if not self:IsVisible() then
			return
		end

		self._entry.TextBox:CaptureFocus()
		self._entry.TextBox.CursorPosition = #text + 1

		self:UpdateWindowHeight()
	end

	--[=[
		@within Window
		Returns the current command prompt label.
	]=]
	function Window:GetEntryText(): string
		return self._entry.TextBox.Text:gsub("\t", "")
	end

	--[=[
		@within Window
		Adds a line to the command output.
	]=]
	function Window:AddLine(text: any, options)
		options = options or {}
		text = tostring(text)

		if typeof(options) == "Color3" then
			options = { Color = options }
		end

		if text == "" then
			self:UpdateWindowHeight()
			return
		end

		const line = self._lineTemplate:Clone()
		line.Text = CmdrClient.Util.EmulateTabstops(text, 8)
		line.TextColor3 = options.Color or line.TextColor3
		line.RichText = options.RichText or false
		line.Parent = CmdrClient.Gui
	end

	--[=[
		@within Window
		@private

		Sets the visibility of the Roblox chat interface.
	]=]
	function Window:_setChatEnabled(enabled: boolean)
		if not enabled then
			-- Save previous state before disabling
			self._previousChatWindowEnabled = TextChatService.ChatWindowConfiguration.Enabled
			self._previousChatInputBarEnabled = TextChatService.ChatInputBarConfiguration.Enabled
			self._previousChannelTabsEnabled = TextChatService.ChannelTabsConfiguration.Enabled

			TextChatService.ChatWindowConfiguration.Enabled = false
			TextChatService.ChatInputBarConfiguration.Enabled = false
			TextChatService.ChannelTabsConfiguration.Enabled = false
		else
			-- Restore previous state
			TextChatService.ChatWindowConfiguration.Enabled = if not self._previousChatWindowEnabled then self._previousChatWindowEnabled else true
			TextChatService.ChatInputBarConfiguration.Enabled = if not self._previousChatInputBarEnabled then self._previousChatInputBarEnabled else true
			TextChatService.ChannelTabsConfiguration.Enabled = if not self._previousChannelTabsEnabled then self._previousChannelTabsEnabled else true
		end
	end

	--[=[
		@within Window
		@private

		Sets or restores the mouse behavior while Cmdr is open.
	]=]
	function Window:_setMouseUnlocked(unlock: boolean)
		if unlock then
			if not CmdrClient._activationUnlocksMouse then
				return
			end

			self._previousMouseBehavior = UserInputService.MouseBehavior
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		else
			if not self._previousMouseBehavior then
				return
			end

			UserInputService.MouseBehavior = self._previousMouseBehavior
			self._previousMouseBehavior = nil
		end
	end

	--[=[
		@within Window
		Sets whether the command bar is visible.
	]=]
	function Window:SetVisible(visible: boolean)
		CmdrClient.Gui.Visible = visible

		if visible then
			self:_setChatEnabled(false)
			self:_setMouseUnlocked(true)

			self:_setEntryText("")
			self._entry.TextBox:CaptureFocus()
		else
			self._lastClosedTime = os.clock()

			self:_setChatEnabled(true)
			self:_setMouseUnlocked(false)

			self._entry.TextBox:ReleaseFocus()
			AutoComplete:Hide()
		end

		CmdrClient.Toggled:Fire(visible)
	end

	--[=[
		@within Window
		Returns whether the command bar is currently visible.
	]=]
	function Window:IsVisible(): boolean
		return CmdrClient.Gui.Visible
	end

	--[=[
		@within Window
		Hides the command bar.
	]=]
	function Window:Hide()
		self:SetVisible(false)
	end

	--[=[
		@within Window
		Shows the command bar.
	]=]
	function Window:Show()
		self:SetVisible(true)
	end

	--[=[
		@within Window
		@private

		Sets whether the current input is valid.
	]=]
	function Window:_setIsValidInput(isValid: boolean, errorText: string?)
		self._entry.TextBox.TextColor3 = if isValid then VALID_TEXT_COLOR else INVALID_TEXT_COLOR
		self.Valid = isValid
		self._errorText = errorText
	end

	--[=[
		@within Window
		Clears the invalid input visual state.
	]=]
	function Window:HideInvalidState()
		self._entry.TextBox.TextColor3 = VALID_TEXT_COLOR
	end

	--[=[
		@within Window
		@private

		Navigates through the command history buffer using an index delta.
	]=]
	function Window:_traverseHistory(delta: number)
		const history = CmdrClient.Dispatcher:GetHistory()
		if not self._historyState then
			self._historyState = {
				Position = #history + 1,
				InitialText = self:GetEntryText(),
			}
		end

		self._historyState.Position = math.clamp(self._historyState.Position + delta, 1, #history + 1)
		self:_setEntryText(self._historyState.Position == #history + 1 and self._historyState.InitialText or history[self._historyState.Position])
	end

	--[=[
		@within Window
		@private

		Resets the stored command history navigation state.
	]=]
	function Window:_clearHistoryState()
		self._historyState = nil
	end

	--[=[
		@within Window
		@private

		Handles vertical directional navigation.
	]=]
	function Window:_selectVertical(delta)
		if AutoComplete:IsVisible() and not self._historyState then
			AutoComplete:Select(delta)
		else
			self:_traverseHistory(delta)
		end
	end

	--[=[
		@within Window
		@private

		Trims the input command text.
	]=]
	function Window._processEntry(text)
		text = CmdrClient.Util.TrimString(text)

		if #text == 0 then
			return
		end

		Window:AddLine(Window:GetLabelText() .. " " .. text, PROCESSING_TEXT_COLOR)
		Window:AddLine(CmdrClient.Dispatcher:EvaluateAndRun(text, Player, { IsHuman = true }))
	end

	--[=[
		@within Window
		@private

		Handles user input when the box is focused.
	]=]
	function Window:_loseFocus(submit)
		if self._hasLostFocus then
			return
		end

		const text = self._entry.TextBox.Text
		self:_clearHistoryState()

		if self:IsVisible() and not GuiService.MenuIsOpen and not UserInputService.TouchEnabled then
			self._entry.TextBox:CaptureFocus()
		elseif self:IsVisible() and GuiService.MenuIsOpen then
			self:Hide()
		end

		if submit then
			self._hasLostFocus = true

			if self.Valid then
				self:_setEntryText("")
				self._processEntry(text)
			else
				self:AddLine(self._errorText, Color3.fromRGB(255, 153, 153))
			end

			self._hasLostFocus = false
		end
	end

	--[=[
		@within Window
		@private

		Process activation toggle keys.
	]=]
	function Window:_handleActivationKey()
		if not CmdrClient._enabled then
			return
		end

		local currentTime = os.clock()
		if CmdrClient._mashToOpen then
			if self:IsVisible() then
				-- Prevent leftover mash presses from instantly closing Cmdr
				if self._openedByMash and currentTime - self._lastPressTime <= 0.5 then
					return
				end

				self:SetVisible(false)
				self._openedByMash = false
				return
			end

			-- Allow reopening without mashing for 10 seconds after closing
			if self._lastClosedTime and currentTime - self._lastClosedTime < 10 then
				self:SetVisible(true)
				self._pressCount = 0
				self._lastPressTime = currentTime
				self._openedByMash = false
				return
			end

			-- Increment mash counter if pressed within 1 second window
			self._pressCount = if currentTime - self._lastPressTime < 1 then self._pressCount + 1 else 1
			self._lastPressTime = currentTime

			if self._pressCount >= 5 then
				self:SetVisible(true)
				self._pressCount = 0
				self._openedByMash = true
			end
		else
			self:SetVisible(not self:IsVisible())
			self._openedByMash = false
		end
	end

	--[=[
		@within Window
		@private

		Handles Tab key auto-completion logic.
	]=]
	function Window:_handleTabCompletion()
		local item = AutoComplete:GetSelectedItem()
		local text = self:GetEntryText()

		if not item or (text:sub(#text, #text):match("%s") and AutoComplete.LastItem) then
			task.wait()
			self:_setEntryText(text)
			return
		end

		local replace = item[2]
		local newText
		local insertSpace = true
		local command = AutoComplete.Command

		if command then
			insertSpace = AutoComplete.NumArgs ~= #command.ArgumentDefinitions and not AutoComplete.IsPartial
			newText = buildAutoCompleteText(command, AutoComplete.Arg, replace)
		else
			newText = replace
		end

		task.wait()
		self:_setEntryText(newText .. (insertSpace and " " or ""))
	end

	--[=[
		@within Window
		@private

		Event handler for text box focus lost.
	]=]
	function Window:_beginInput(input: InputObject, gameProcessed: boolean)
		if GuiService.MenuIsOpen then
			self:Hide()
		end

		if gameProcessed and not self:IsVisible() then
			return
		end

		-- Check for activation shortcut keys
		if CmdrClient._activationKeys[input.KeyCode] then
			self:_handleActivationKey()
			return
		end

		-- Guard against disabled client state or hidden window
		if not CmdrClient._enabled then
			if self:IsVisible() then
				self:Hide()
			end

			return
		end

		if not self:IsVisible() then
			return
		end

		-- Check for mouse clicks outside window boundaries
		if CmdrClient._hideOnLostFocus and table.find(MOUSE_TOUCH_INPUTS, input.UserInputType) then
			if isPositionOutsideGui(input.Position, CmdrClient.Gui) then
				self:Hide()
			end
			return
		end

		-- Key action mappings
		if input.KeyCode == Enum.KeyCode.Down then
			self:_selectVertical(1)
		elseif input.KeyCode == Enum.KeyCode.Up then
			self:_selectVertical(-1)
		elseif input.KeyCode == Enum.KeyCode.Return then
			task.wait()
			self:_setEntryText(self:GetEntryText():gsub("\n", ""):gsub("\r", ""))
		elseif input.KeyCode == Enum.KeyCode.Tab then
			self:_handleTabCompletion()
		else
			self:ClearHistoryState()
		end
	end

	--[=[
		@within Window
		@private

		Processes autocomplete for command arguments once a command name is active.
	]=]
	function Window._handleArgumentAutoComplete(command, arguments: { string }, text: string, hasTrailingSpace: boolean, atEnd: boolean)
		const commandValid, commandError = command:Validate()
		Window:_setIsValidInput(commandValid, ("Validation errors: %s"):format(commandError or ""))

		const lastArgument = command:GetArgument(#arguments)
		if not lastArgument then
			return
		end

		local autocompleteItems = {}
		const typedText = lastArgument.TextSegmentInProgress
		local isPartial = false

		if lastArgument.RawSegmentsAreAutocomplete then
			for index, segment in ipairs(lastArgument.RawSegments) do
				autocompleteItems[index] = { segment, segment }
			end
		else
			local items, options = lastArgument:GetAutocomplete()
			options = options or {}
			isPartial = options.IsPartial or false

			for index, item in ipairs(items) do
				autocompleteItems[index] = { typedText, item }
			end
		end

		local argumentValid = true
		local argumentError

		if #typedText > 0 then
			argumentValid, argumentError = lastArgument:Validate()
		end

		if not atEnd and argumentValid then
			Window:HideInvalidState()
		end

		return AutoComplete:Show(autocompleteItems, {
			at = atEnd and #text - #typedText + (hasTrailingSpace and -1 or 0),
			prefix = #lastArgument.RawSegments == 1 and lastArgument.Prefix or "",
			isLast = #command.Arguments == #command.ArgumentDefinitions and #typedText > 0,
			numArgs = #arguments,
			command = command,
			arg = lastArgument,
			name = lastArgument.Name .. (lastArgument.Required and "" or "?"),
			type = lastArgument.Type.DisplayName,
			description = argumentValid and lastArgument.Object.Description or argumentError,
			invalid = not argumentValid,
			isPartial = isPartial,
		})
	end

	--[=[
		@within Window
		@private

		Processes autocomplete for initial command name lookup.
	]=]
	function Window._handleCommandAutoComplete(commandText: string, command)
		Window:_setIsValidInput(true)

		local exactCommand = CmdrClient.Registry:GetCommand(commandText)
		local exactMatch

		if exactCommand then
			exactMatch = {
				exactCommand.Name,
				exactCommand.Name,
				options = {
					name = exactCommand.Name,
					description = exactCommand.Description,
				},
			}

			local argument = exactCommand.Args and exactCommand.Args[1]
			if type(argument) == "function" then
				argument = argument(command)
			end

			if argument and not argument.Optional and argument.Default == nil then
				Window:_setIsValidInput(false, "This command has required arguments.")
				Window:HideInvalidState()
			end
		else
			Window:_setIsValidInput(false, ("%q is not a valid command name. Use the help command to see all available commands."):format(commandText))
		end

		local autocompleteItems = { exactMatch }
		for _, commandName in ipairs(CmdrClient.Registry:GetCommandNames()) do
			if commandText:lower() == commandName:lower():sub(1, #commandText) then
				if not exactMatch or exactMatch[1] ~= commandName then
					local commandObject = CmdrClient.Registry:GetCommand(commandName)

					autocompleteItems[#autocompleteItems + 1] = {
						commandText,
						commandName,
						options = {
							name = commandObject.Name,
							description = commandObject.Description,
						},
					}
				end
			end
		end

		return AutoComplete:Show(autocompleteItems)
	end

	--[=[
		@within Window
		@private

		Fired whenever the command input text changes. Validates inputs and updates the autocomplete view.
	]=]
	function Window._onTextChanged(text: string)
		const command = CmdrClient.Dispatcher:Evaluate(text, Player, true)
		local arguments = CmdrClient.Util.SplitString(text)
		const commandText = table.remove(arguments, 1)

		const hasTrailingSpace = text:sub(#text, #text):match("%s") ~= nil
		local atEnd = false

		if command then
			arguments = CmdrClient.Util.MashExcessArguments(arguments, #command.Object.Args)
			atEnd = #arguments == #command.Object.Args
		end

		local entryComplete = commandText and #arguments > 0
		if hasTrailingSpace and not atEnd then
			entryComplete = true
			arguments[#arguments + 1] = ""
		end

		if command and entryComplete then
			return Window._handleArgumentAutoComplete(command, arguments, text, hasTrailingSpace, atEnd)
		end

		if commandText and #arguments == 0 then
			return Window._handleCommandAutoComplete(commandText, command)
		end

		Window:_setIsValidInput(false, "Use the help command to see all available commands.")
		AutoComplete:Hide()

		return nil
	end

	Window._entry.TextBox.FocusLost:Connect(function(submit)
		Window:_loseFocus(submit)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		Window:_beginInput(input, gameProcessed)
	end)

	Window._entry.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		CmdrClient.Gui.CanvasPosition = Vector2.new(0, CmdrClient.Gui.AbsoluteCanvasSize.Y)

		if Window._entry.TextBox.Text:match("\t") then
			Window._entry.TextBox.Text = Window._entry.TextBox.Text:gsub("\t", "")
			return
		end

		Window._entry._onTextChanged(Window._entry.TextBox.Text)
	end)

	CmdrClient.Gui.ChildAdded:Connect(function(child: Instance)
		task.defer(Window.UpdateWindowHeight, Window)
	end)

	return Window
end
