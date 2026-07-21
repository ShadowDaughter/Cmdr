const RunService = game:GetService("RunService")

if not RunService:IsClient() then
	error("[Cmdr] The Cmdr client library cannot be required by the server. Please require the server libary instead.")
end

const Registry = require("@self/Shared/Registry")
const Dispatcher = require("@self/Shared/Dispatcher")
const Util = require("@self/Shared/Util")

const CmdrInterface = require("@self/CmdrInterface")
const DefaultEventHandlers = require("@self/DefaultEventHandlers")

type Signal = {
	Fire: (self: Signal, ...any) -> (),
	Connect: (self: Signal, callback: (...any) -> ()) -> RBXScriptConnection,
}

const function createSignal(): Signal
	const event = Instance.new("BindableEvent")

	return {
		Fire = function(_, ...)
			event:Fire(...)
		end,

		Connect = function(_, callback)
			return event.Event:Connect(callback)
		end,
	}
end

--[=[
	@class CmdrClient
	@client

	The Cmdr client singleton and entry point.
]=]

--[=[
	@within CmdrClient
	@readonly

	@prop Registry Registry

	Refers to the command Registry.
]=]

--[=[
	@within CmdrClient
	@readonly

	@prop Dispatcher Dispatcher

	Refers to the command Dispatcher.
]=]

--[=[
	@within CmdrClient
	@readonly

	@prop Util Util

	Refers to a table containing many useful utility functions.
]=]

--[=[
	@within CmdrClient
	@readonly

	@prop Gui ScreenGui

	Refers to the current Cmdr GUI.
]=]

--[=[
	@within CmdrClient
	@readonly

	@prop Toggled { Connect: (self: Toggled, callback: (visible: boolean) -> ()) -> RBXScriptConnection, Fire: (self: Toggled, visible: boolean) -> () }

	A signal that fires when the Cmdr window is toggled.
]=]

--[=[
	@within CmdrClient
	@readonly
	@private

	@prop _interface CmdrInterface

	Refers to the CmdrInterface object.
]=]

--[=[
	@within CmdrClient
	@readonly
	@private

	@prop _remoteEvent RemoteEvent

	Refers to the CmdrEvent RemoteEvent found within CmdrClient.
]=]

--[=[
	@within CmdrClient
	@readonly
	@private

	@prop _remoteFunction RemoteFunction

	Refers to the CmdrFunction RemoteFunction found within CmdrClient.
]=]

--[=[
	@within CmdrClient
	@readonly
	@private

	@prop _enabled boolean

	Whether or not Cmdr is enabled (will show via the defined activation keys). Use [`CmdrClient:SetEnabled`](#SetEnabled) to change.
]=]

--[=[
	@within CmdrClient
	@readonly
	@private

	@prop _activationKeys { [Enum.KeyCode] = true }

	The list of key codes that will show or hide Cmdr. Use [`CmdrClient:SetActivationKeys`](#SetActivationKeys) to change.
]=]

--[=[
	@within CmdrClient
	@readonly
	@private

	@prop _events { [string]: (any) -> () }

	A collection of event callbacks used by Cmdr.
]=]

local CmdrClient = {
	Registry = nil :: Registry.Registry?,
	Dispatcher = nil :: any,
	Util = Util,

	Gui = nil :: ScreenGui?,
	Toggled = createSignal(),

	_interface = nil :: any,

	_remoteEvent = script:WaitForChild("CmdrEvent") :: RemoteEvent,
	_remoteFunction = script:WaitForChild("CmdrFunction") :: RemoteFunction,

	_enabled = true,
	_activationKeys = { Enum.KeyCode.F2 },

	_events = {} :: { [string]: (any) -> () },
}

--[=[
	@within CmdrClient
	Sets whether or not Cmdr can be shown via the defined activation keys. Useful for when you want users to opt-in to show the console, for instance in a settings menu.
]=]
function CmdrClient:SetEnabled(enabled: boolean)
	self._enabled = enabled
end

--[=[
	@within CmdrClient
	Sets the key codes that will used to toggle Cmdr.
]=]
function CmdrClient:SetActivationKeys(keys: { Enum.KeyCode })
	self._activationKeys = keys
end

const function initialize()
	CmdrClient.Registry = Registry(CmdrClient)
	CmdrClient.Dispatcher = Dispatcher(CmdrClient)

	CmdrClient._interface = CmdrInterface(CmdrClient)
	CmdrClient.Gui = CmdrClient._interface.Gui

	CmdrClient._remoteEvent.OnClientEvent:Connect(function(eventName: string, ...)
		if not CmdrClient._events[eventName] then
			return
		end

		CmdrClient._events[eventName](...)
	end)

	DefaultEventHandlers(CmdrClient)
end

initialize()

return table.freeze(setmetatable(CmdrClient, {
	__index = function(self, key)
		const dispatcher = rawget(self, "Dispatcher")
		const value = dispatcher and dispatcher[key]

		if type(value) == "function" then
			if not script:GetAttribute("HasShownProxyCallWarning") then
				warn(debug.traceback(`[Cmdr] [APIUsage::ProxyCalls] Method calls should be performed by their respective modules rather than the Cmdr object.`, 2))
				script:SetAttribute("HasShownProxyCallWarning", true)
			end

			return function(_, ...)
				return value(dispatcher, ...)
			end
		end

		return nil
	end,
}))
