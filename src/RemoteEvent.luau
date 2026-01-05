local RemoteEvent = {}
RemoteEvent.__index = RemoteEvent

---- Services ----

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---- Variables ----

local utils = script.Parent.Utils
local packages = script.Parent.Packages
local remotes = ReplicatedStorage.Remotes

local Signal = require(packages.Signal)
local Buffer = require(packages.Buffer)

local ClientProcess = require(script.ClientProcess)
local ServerProcess = require(script.ServerProcess)

---- Functions ----

local function RemoteEventErrorHandler(err: string)
	local errorExecutionTime = tostring(DateTime.now():FormatLocalTime("LTS", "en-us"))
	error(`\n['RemoteEvent]: \n {err} \nexecuted at {errorExecutionTime}`)
end

local function CreateEventPacket(eventName: string, unreliable: boolean?)
	if not remotes.Events.Data:FindFirstChild(eventName) then
		local strVal = Instance.new("StringValue")
		strVal.Parent = remotes.Events.Data
		strVal.Name = eventName
		strVal:SetAttribute("Unreliable", unreliable)
	end
end

local function GetEventPacket(eventName: string)
	local rem: StringValue? = remotes.Events.Data:FindFirstChild(eventName)
	if rem then
		return rem:GetAttribute("Unreliable")
	else --@the first param will be unreliable[bool?], if more data is needed to be shared then it will
		return nil
	end
end

if RunService:IsClient() then
	function RemoteEvent.new(eventName: string)
		assert(eventName, `given value 'eventName' is missing or nil`)
		assert(type(eventName) == "string", `given value 'eventName' is not a string`)

		local unreliable = GetEventPacket(eventName)

		if unreliable ~= nil and remotes.Events:FindFirstChild(eventName) then
			local self = setmetatable({}, RemoteEvent)

			self.unreliable = unreliable
			self.remote = remotes.Events[eventName]

			self.OnFired = Signal.new()
			self.identifier = eventName

			self.remote.OnClientEvent:Connect(function(evName: string, ...)
				if evName == eventName then
					self.OnFired:Fire(...)
				end
			end)

			return self
		else
			RemoteEventErrorHandler("missing event (event not created)")
		end
	end

	function RemoteEvent:Fire(...)
		local packed = table.pack(...)
		local buffed = Buffer.new(packed)
		ClientProcess.InsertProcessQueue(self.remote, self.identifier, self.unreliable, buffed)
	end
else
	function RemoteEvent.new(eventName: string, unreliable: boolean)
		assert(eventName, `given value 'eventName' is missing or nil`)
		assert(type(eventName) == "string", `given value 'eventName' is not a string`)

		if remotes.Events:FindFirstChild(eventName) then
			RemoteEventErrorHandler("EventName already used or created")
		else
			local self = setmetatable({}, RemoteEvent)

			if not unreliable then
				unreliable = false
			end
			if unreliable then
				self.remote = utils.UnreliableEvent:Clone()
				self.remote.Parent = remotes.Events
				self.remote.Name = eventName
			else
				self.remote = utils.Event:Clone()
				self.remote.Parent = remotes.Events
				self.remote.Name = eventName
			end

			self.OnFired = Signal.new()
			self.identifier = eventName
			self.unreliable = unreliable

			self.remote.OnServerEvent:Connect(function(player, evName: string, ...)
				if evName == eventName then
					self.OnFired:Fire(player, ...)
				end
			end)

			CreateEventPacket(eventName, unreliable)
			return self
		end
	end

	function RemoteEvent:Fire(player: Player?, ...)
		local packed = table.pack(...)
		local buffed = Buffer.new(packed)
		ServerProcess.InsertProcessQueue(player, self.remote, self.identifier, self.unreliable, buffed)
	end

	function RemoteEvent:FireAll(...: any?)
		local buffed = Buffer.new(table.pack(...))
		ServerProcess.InsertProcessQueue(nil, self.remote, self.identifier, self.unreliable, buffed)
	end
end

return RemoteEvent
