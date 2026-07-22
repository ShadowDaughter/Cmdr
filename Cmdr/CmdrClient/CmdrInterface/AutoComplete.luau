const VALID_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
const INVALID_TEXT_COLOR = Color3.fromRGB(255, 73, 73)

return function(CmdrClient)
	const autoCompleteFrame = CmdrClient.Gui:WaitForChild("Autocomplete") :: ScrollingFrame
	const defaultBarThickness = CmdrClient.self._guiScrollbarThickness :: number

	const AutoComplete = {
		_gui = autoCompleteFrame,
		_autoItem = autoCompleteFrame:WaitForChild("TextButton") :: TextButton,
		_title = autoCompleteFrame:WaitForChild("Title") :: TextLabel,
		_description = autoCompleteFrame:WaitForChild("Description") :: TextLabel,
		_entry = CmdrClient.Gui:WaitForChild("Entry") :: Frame,

		_guiScrollBarThickness = nil :: number?,

		Items = {},
		SelectedItem = 1,

		Prefix = "",
		LastItem = false,

		Command = nil,
		Arg = nil,
		NumArgs = nil,
		IsPartial = false,
	}

	--[=[
		@within Window
		@private

		Sets the text of the provided object.
	]=]
	function AutoComplete:_setText(object: GuiObject, textObject: TextLabel, text: string?, sizeFromContents: boolean)
		object.Visible = text ~= nil
		textObject.Text = text or ""

		if sizeFromContents then
			textObject.Size = UDim2.new(0, CmdrClient.Util.GetTextSize(text or "", textObject, Vector2.new(1000, 1000), 1, 0).X, object.Size.Y.Scale, object.Size.Y.Offset)
		end
	end

	--[=[
		@within Window
		@private

		Updates the size of the AutoComplete frame.
	]=]
	function AutoComplete:_updateContainerSize()
		self._self._guiSize = UDim2.fromOffset(
			math.max(self._title.Field.TextBounds.X + self._title.Field.Type.TextBounds.X, self._self._guiSize.X.Offset),
			math.min(self._self._guiUIListLayout.AbsoluteContentSize.Y, self._self._guiParent.AbsoluteSize.Y - self._self._guiAbsolutePosition.Y - 10)
		)
	end

	--[=[
		@within Window
		@private

		Updates the displayed auto completion info.
	]=]
	function AutoComplete:_updateInfoDisplay(options)
		self:_setText(self._title, self._title.Field, options.name, true)
		self:_setText(self._title.Field.Type, self._title.Field.Type, options.type and ": " .. options.type:sub(1, 1):upper() .. options.type:sub(2))
		self:_setText(self._description, self._description.Label, options.description)

		self._description.Label.TextColor3 = options.invalid and INVALID_TEXT_COLOR or VALID_TEXT_COLOR
		self._description.Size = UDim2.new(1, 0, 0, 40)

		while not self._description.Label.TextFits do
			self._description.Size = self._description.Size + UDim2.fromOffset(0, 2)

			if self._description.Size.Y.Offset > 500 then
				break
			end
		end

		task.wait()
		self._self._guiUIListLayout:ApplyLayout()
		self:_updateContainerSize()
		self._self._guiScrollBarThickness = defaultBarThickness
	end

	--[=[
		@within AutoComplete
		Shows the autocomplete menu.
	]=]
	function AutoComplete:Show(items, options)
		options = options or {}

		for _, item in ipairs(self.Items) do
			if item.gui then
				item.gui:Destroy()
			end
		end

		self.SelectedItem = 1
		self.Items = items

		self.Prefix = options.prefix or ""
		self.LastItem = options.isLast or false

		self.Command = options.command
		self.Arg = options.arg
		self.NumArgs = options.numArgs
		self.IsPartial = options.isPartial

		local autocompleteWidth = 200
		self._guiScrollBarThickness = 0

		for index, item in ipairs(items) do
			const typedText = item[1]
			const suggestionText = item[2]
			const button = self._autoItem:Clone()

			button.Name = typedText .. suggestionText
			button.BackgroundTransparency = if index == self.SelectedItem then 0.5 else 1

			local start, stop = suggestionText:lower():find(typedText:lower(), 1, true)
			if not start then
				start = 1
				stop = #suggestionText
			end

			button.Typed.Text = string.rep(" ", start - 1) .. typedText

			button.Suggest.Text = suggestionText:sub(1, start - 1) .. string.rep(" ", #typedText) .. suggestionText:sub(stop + 1)

			button.LayoutOrder = index
			button.Parent = self.Gui

			autocompleteWidth = math.max(autocompleteWidth, button.Typed.TextBounds.X + button.Suggest.TextBounds.X + 20)

			item.gui = button
		end

		self._guiUIListLayout:ApplyLayout()

		const text = self._entry.TextBox.Text
		local words = CmdrClient.Util.SplitString(text)
		if text:sub(#text, #text) == " " and not options.at then
			words[#words + 1] = "e"
		end

		table.remove(words, #words)

		local offset = (options.at or (#table.concat(words, " ") + 1)) * 7
		self._guiPosition = UDim2.fromOffset(self._entry.TextBox.AbsolutePosition.X - 10 + offset, self._entry.TextBox.AbsolutePosition.Y + 30)
		self._guiSize = UDim2.fromOffset(autocompleteWidth, self._guiUIListLayout.AbsoluteContentSize.Y)
		self._guiVisible = true
		self:_updateInfoDisplay(self.Items[1] and self.Items[1].options or options)
	end

	--[=[
		@within AutoComplete
		Returns the selected autocomplete item.
	]=]
	function AutoComplete:GetSelectedItem()
		if not self._gui.Visible then
			return nil
		end

		return self.Items[self.SelectedItem]
	end

	--[=[
		@within AutoComplete
		Hides the autocomplete menu.
	]=]
	function AutoComplete:Hide()
		self._gui.Visible = false
	end

	--[=[
		@within AutoComplete
		Returns whether autocomplete is visible.
	]=]
	function AutoComplete:IsVisible()
		return self._gui.Visible
	end

	--[=[
		@within AutoComplete
		Changes the current selection.
	]=]
	function AutoComplete:Select(delta)
		if not self._gui.Visible then
			return
		end

		self.SelectedItem += delta

		if self.SelectedItem > #self.Items then
			self.SelectedItem = 1
		elseif self.SelectedItem < 1 then
			self.SelectedItem = #self.Items
		end

		for index, item in ipairs(self.Items) do
			item.gui.BackgroundTransparency = if index == self.SelectedItem then 0.5 else 1
		end

		self._gui.CanvasPosition = Vector2.new(0, math.max(0, self._title.Size.Y.Offset + self._description.Size.Y.Offset + self.SelectedItem * self._autoItem.Size.Y.Offset - self._gui.Size.Y.Offset))

		const selectedItem = self.Items[self.SelectedItem]
		if selectedItem and selectedItem.options then
			self:_updateInfoDisplay(selectedItem.options)
		end
	end

	AutoComplete._autoItem.Parent = nil
	AutoComplete._gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(AutoComplete._updateContainerSize(AutoComplete))

	return AutoComplete
end
