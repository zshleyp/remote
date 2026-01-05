--!strict

local RemoteProcess = {
	Started = false,
	ProcessQueue = {},
}

---- Services ----

local RunService = game:GetService("RunService")

---- Types ----

export type processPacket = {
	Data: { any? },
	Identifier: string,
	Unreliable: boolean,
	Event: any,
}

---- Functions ----

function RemoteProcess.InsertProcessQueue(
	event: RemoteEvent | UnreliableRemoteEvent,
	identifier: string,
	unreliable: boolean,
	data: { any? }
)
	RemoteProcess.ProcessQueue[identifier] = {
		Data = data,
		Event = event,
		Unreliable = unreliable,
		Identifier = identifier,
	} :: processPacket
end

function RemoteProcess.RemoveProcessFromQueue(identifier: string)
	if not RemoteProcess.ProcessQueue[identifier] then
		return
	end
	RemoteProcess.ProcessQueue[identifier] = nil
end

function RemoteProcess.Start(...)
	RunService.PostSimulation:Connect(function(...)
		for identifier: string, processPacket: processPacket in RemoteProcess.ProcessQueue do
			if processPacket.Data then
				if processPacket.Unreliable then
					local unreliableEvent: UnreliableRemoteEvent = processPacket.Event
					local identifier = processPacket.Identifier

					unreliableEvent:FireServer(identifier, table.unpack(processPacket.Data))

					RemoteProcess.RemoveProcessFromQueue(identifier)
				else
					local event: RemoteEvent = processPacket.Event
					local identifier = processPacket.Identifier

					event:FireServer(identifier, table.unpack(processPacket.Data))

					RemoteProcess.RemoveProcessFromQueue(identifier)
				end
			end
		end
	end)
end

return RemoteProcess
