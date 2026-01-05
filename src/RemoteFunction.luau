local FunctionThreads = {}

---- Services ----

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---- Modules ----

local Buffer = require(script.Parent.Buffer)

---- Variables ----

local remotes = ReplicatedStorage.Remotes

---- Functions ----

local function RemoteFunctionErrorHandler(err: string)
	local errorExecutionTime = tostring(DateTime.now():FormatLocalTime("LTS", "en-us"))
	error(`\n['RemoteFunction]: \n {err} \nexecuted at {errorExecutionTime}`)
end

local function ReturnProcessedCallback(eventName: string?, exhaustTime: number)
	local begin = os.clock()
	repeat
		task.wait()
		local elapsed = (os.clock() - begin)
		if elapsed > exhaustTime then
			RemoteFunctionErrorHandler("remote function never returned an object")
		end
	until FunctionThreads[eventName]
	return table.unpack(FunctionThreads[eventName])
end

---- Types ----

export type RemoteFunc = { Invoke: (self: any) -> () }

---- Construction ----

local constructor = {
	new = function(name: string, callbackFn: RBXScriptConnection?)
		if RunService:IsClient() then
			local self = {}

			self.Function = remotes.Functions:FindFirstChild(name) :: RemoteEvent
			if self.Function then
				self.Function.OnClientEvent:Connect(function(method: string, ...)
					if method == "Client" then
						local buffed = Buffer.new(...)
						FunctionThreads[name] = buffed
					else
						local returnedProcessed = callbackFn(table.unpack(...))
						if not returnedProcessed then
							RemoteFunctionErrorHandler("remote callback does not return at least 1 value")
						end
						self.Function:FireServer("Server", table.pack(returnedProcessed))
					end
				end)

				function self:Invoke(...: any)
					local packed = table.pack(...)
					local buffed = Buffer.new(packed)
					self.Function:FireServer("Client", buffed)
					return ReturnProcessedCallback(name, 4)
				end

				return self :: RemoteFunc
			end
		else
			local self = {}
			if not remotes.Functions:FindFirstChild(name) then
				self.Function = Instance.new("RemoteEvent")
				self.Function.Name = name
				self.Function.Parent = remotes.Functions
			else
				self.Function = remotes.Functions[name]
			end
			function self:Invoke(player: Player?, ...: any)
				local packed = table.pack(...)
				local buffed = Buffer.new(packed)
				self.Function:FireClient(player, "Server", buffed)
				return ReturnProcessedCallback(name, 4)
			end
			self.Function.OnServerEvent:Connect(function(player: Player?, method: string, ...)
				if method == "Client" then
					local returnedProcessed = callbackFn(player, table.unpack(...))
					if not returnedProcessed then
						RemoteFunctionErrorHandler("remote callback does not return at least 1 value")
					end
					self.Function:FireClient(player, "Client", table.pack(returnedProcessed))
				else
					local buffed = Buffer.new(...)
					FunctionThreads[name] = buffed
				end
			end)
			return self :: typeof(self)
		end
	end,
}

return constructor
