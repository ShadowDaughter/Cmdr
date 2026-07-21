const RunService = game:GetService("RunService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

if not RunService:IsServer() then
	error("[Cmdr] The Cmdr server library cannot be required by the client. Please require the client libary instead.")
end

const Registry = require("@self/CmdrClient/Shared/Registry")
const Dispatcher = require("@self/CmdrClient/Shared/Dispatcher")
const Util = require("@self/CmdrClient/Shared/Util")

const function createObject(className: string, name: string, parent: Instance): Instance
	local object = Instance.new(className)
	object.Name = name
	object.Parent = parent

	return object
end

--[=[
	@class Cmdr
	@server

	The Cmdr server singleton and entry point.
]=]

--[=[
	@within Cmdr
	@readonly

	@prop Registry Registry

	Refers to the command Registry.
]=]

--[=[
	@within Cmdr
	@readonly

	@prop Dispatcher Dispatcher

	Refers to the command Dispatcher.
]=]

--[=[
	@within Cmdr
	@readonly

	@prop Util Util

	Refers to a table containing many useful utility functions.
]=]

--[=[
	@within Cmdr
	@readonly
	@private

	@prop _remoteEvent RemoteEvent

	Refers to the CmdrEvent RemoteEvent found within CmdrClient.
]=]

--[=[
	@within Cmdr
	@readonly
	@private

	@prop _remoteFunction RemoteFunction

	Refers to the CmdrFunction RemoteFunction found within CmdrClient.
]=]

--[=[
	@within Cmdr
	@readonly
	@private

	@prop _replicatedRoot ModuleScript
	
	Refers to the CmdrClient modulescript containing all shared functionality.
]=]

--[=[
	@within Cmdr
	@readonly
	@private

	@prop _defaultCommandsFolder Folder

	Refers to the BuiltInCommands folder containing all default commands.
]=]

local Cmdr = {
	Registry = nil :: Registry.Registry?,
	Dispatcher = nil :: any,
	Util = Util,

	_remoteEvent = nil :: RemoteEvent?,
	_remoteFunction = nil :: RemoteFunction?,

	_replicatedRoot = nil :: ModuleScript?,
	_defaultCommandsFolder = script.BuiltInCommands,
}

const function initialize()
	Cmdr.Registry = Registry(Cmdr)
	Cmdr.Dispatcher = Dispatcher(Cmdr)

	createObject("Folder", "Commands", script.CmdrClient)
	createObject("Folder", "Types", script.CmdrClient)

	Cmdr._replicatedRoot = script.CmdrClient
	Cmdr._replicatedRoot.Parent = ReplicatedStorage

	Cmdr._remoteEvent = createObject("RemoteEvent", "CmdrEvent", Cmdr._replicatedRoot)
	Cmdr._remoteFunction = createObject("RemoteFunction", "CmdrFunction", Cmdr._replicatedRoot)

	Cmdr._remoteFunction.OnServerInvoke = function(player: Player, text: string, options: any) -- TODO: Update options type
		if #text > 10000 then
			return "Input too long"
		end

		return -- TODO: Implement EvaluateAndRun
	end
end

initialize()

return table.freeze(setmetatable(Cmdr, {
	__index = function(self, key)
		const registry = rawget(self, "Registry")
		const value = registry and registry[key]

		if type(value) == "function" then
			if not self._replicatedRoot:GetAttribute("HasShownProxyCallWarning") then
				warn(debug.traceback(`[Cmdr] [APIUsage::ProxyCalls] Method calls should be performed by their respective modules rather than the Cmdr object.`, 2))
				self._replicatedRoot:SetAttribute("HasShownProxyCallWarning", true)
			end

			return function(_, ...)
				return value(registry, ...)
			end
		end

		return nil
	end,
}))
