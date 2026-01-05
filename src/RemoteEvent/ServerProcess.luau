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
	Event: any,
	Player: Player?,
	Identifier: string,
	Unreliable: boolean,
}

---- Functions ----

function RemoteProcess.InsertProcessQueue(
	player: Player,
	event: any,
	identifier: string,
	unreliable: boolean,
	data: { any? }
)
	RemoteProcess.ProcessQueue[identifier] = {
		Data = data,
		Event = event,
		Player = player,
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
				if processPacket.Player then
					if processPacket.Unreliable then
						local player = processPacket.Player
						local identifier = processPacket.Identifier
						local unreliableEvent: UnreliableRemoteEvent = processPacket.Event

						unreliableEvent:FireClient(player, identifier, table.unpack(processPacket.Data))

						RemoteProcess.RemoveProcessFromQueue(identifier)
					else
						local player = processPacket.Player
						local identifier = processPacket.Identifier
						local event: RemoteEvent = processPacket.Event

						event:FireClient(player, identifier, table.unpack(processPacket.Data))

						RemoteProcess.RemoveProcessFromQueue(identifier)
					end
				else --@for a case like fireAllClients
					if processPacket.Unreliable then
						local identifier = processPacket.Identifier
						local unreliableEvent: UnreliableRemoteEvent = processPacket.Event

						unreliableEvent:FireAllClients(identifier, table.unpack(processPacket.Data))

						RemoteProcess.RemoveProcessFromQueue(identifier)
					else
						local identifier = processPacket.Identifier
						local event: RemoteEvent = processPacket.Event

						event:FireAllClients(identifier, table.unpack(processPacket.Data))

						RemoteProcess.RemoveProcessFromQueue(identifier)
					end
				end
			end
		end
	end)
end

return RemoteProcess
