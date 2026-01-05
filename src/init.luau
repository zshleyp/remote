local ReplicatedStorage = game:GetService("ReplicatedStorage")
--wally reupload by zshleyp, original author is Flipitagainpls

--[[
	Author: Flipitagainpls
	Completed: 1/5/2025
	Version: 1.0.5 (4/9/2025)

	Remote is a modular system that handles the firing of
	remote events and remote functions. RemoteEvent module uses
	a runtime based firing system which allows for a more dynamic
	and easy fire system, as well as buffing the transferred data.
	Remote function however uses 5uphi's remote function method by
	creating remote functions using remote events since its a more safer process,
	then the data is buffed and transferred between events to process the correct info.

	Newest Fixes:
		New Version 1.0.5
		Date: (4/9/2025)

	Updated to buffer encoder: https://devforum.roblox.com/t/bufferencoder-very-efficient-table-to-buffer-serializer-that-doesn%E2%80%99t-use-schemas/3584699
	events & function are sent faster and more optimized than before
	removed buffer converter
]]

local function Folder(name, instance)
	local fold = Instance.new("Folder")
	fold.Name = name
	fold.Parent = instance
	return fold
end

local remotes = Folder("Remotes", ReplicatedStorage)
local events = Folder("Events", remotes)
Folder("Functions", remotes)
Folder("Data", events)

local RemoteEvent = require(script.RemoteEvent)
local RemoteFunction = require(script.RemoteFunction)

local ClientProcess = require(script.RemoteEvent.ClientProcess)
local ServerProcess = require(script.RemoteEvent.ServerProcess)

ClientProcess.Start()
ServerProcess.Start()

return {
	RemoteEvent = RemoteEvent,
	RemoteFunction = RemoteFunction,
}
