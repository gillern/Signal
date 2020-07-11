local Signal = {}
Signal.__index = Signal

Signal._Bind = require(script:WaitForChild("Bind"))

function Signal.new()
	return setmetatable({}, Signal)
end

function Signal:Bind(BindName, Callback, ...)
	local Arguments = (select("#", ...) > 0 and {...} or nil)
	
	if (typeof(BindName) == "function") then
		if (not self.BindID) then
			self.BindID = 0
		end
		
		self.BindID += 1
		
		if (Callback ~= nil) then
			if (Arguments) then
				table.insert(Arguments, 1, Callback)
			else
				Arguments = {Callback}
			end
		end
		
		BindName, Callback = self.BindID, BindName
	end
	
	if (not self.Binds) then
		self.Binds = {}
	end
	
	local Bind = Signal._Bind.new()
	Bind.Name = BindName
	Bind.Signal = self
	Bind.Callback = Callback
	Bind.Arguments = Arguments
	
	table.insert(self.Binds, Bind)
	
	return Bind
end

function Signal:BindAtPriority(BindName, Priority, Callback, ...)
	local Arguments = (select("#", ...) > 0 and {...} or nil)
	
	if (typeof(BindName) == "number") then
		if (not self.BindID) then
			self.BindID = 0
		end
		
		self.BindID += 1
		
		if (Callback ~= nil) then
			if (Arguments) then
				table.insert(Arguments, 1, Callback)
			else
				Arguments = {Callback}
			end
		end
		
		BindName, Priority, Callback = self.BindID, BindName, Priority
	elseif (typeof(BindName) == "function") then
		if (not self.BindID) then
			self.BindID = 0
		end
		
		self.BindID += 1
		
		if (Callback ~= nil) then
			if (Arguments) then
				table.insert(Arguments, 1, Callback)
			else
				Arguments = {Callback}
			end
		end
		
		if (Priority ~= nil) then
			if (Arguments) then
				table.insert(Arguments, 1, Priority)
			else
				Arguments = {Priority}
			end
		end
		
		BindName, Priority, Callback = self.BindID, 1, BindName
	end
	
	if (not self.Binds) then
		self.Binds = {}
	end
	
	local Bind = Signal._Bind.new()
	Bind.Name = BindName
	Bind.Signal = self
	Bind.Callback = Callback
	Bind.Arguments = Arguments
	Bind.Priority = Priority
	
	local InsertBind = true
	
	for Key, CheckBind in pairs(self.Binds) do
		if (not CheckBind.Priority or Bind.Priority > CheckBind.Priority) then
			table.insert(self.Binds, Key, Bind)
			
			InsertBind = nil
			
			break
		end
	end
	
	if (InsertBind) then
		table.insert(self.Binds, Bind)
	end
	
	return Bind
end

function Signal:Unbind(BindName)
	if (self.Binds) then
		for Key = #self.Binds, 1, -1 do
			local Bind = self.Binds[Key]
			
			if (Bind.Name == BindName) then
				Bind:Disconnect()
			end
		end
	end
end

function Signal:Await(...)
	local Thread = coroutine.running()
	
	if (not self.Theads) then
		self.Threads = {}
	end
	
	table.insert(self.Threads, Thread)
	
	coroutine.yield(...)
end

function Signal:ResumeThreads(...)
	if (self.Threads) then
		for Key = #self.Threads, 1, -1 do
			coroutine.resume(self.Threads[Key], ...)
			
			table.remove(self.Threads, Key)
		end
		
		if (#self.Threads <= 0) then
			self.Threads = nil
		end
	end
end

function Signal:Fire(...)
	return self:FireAsync(...)
end

function Signal:FireSync(...)
	if (self.Binds) then	
		for _, Bind in pairs(self.Binds) do
			if (Bind.Callback) then
				local Success, Response
				
				if (Bind.Arguments) then
					Success, Response = pcall(Bind.Callback, unpack(Bind.Arguments), ...)	
				else
					Success, Response = pcall(Bind.Callback, ...)
				end
				
				if (not Success) then
					warn("Signal: Bind with BindName '" .. tostring(Bind.BindName) .. "' failed, " .. tostring(Response))
				end
			end
		end
	end
	
	self:ResumeThreads(...)
end

function Signal:FireAsync(...)
	if (self.Binds) then	
		for _, Bind in pairs(self.Binds) do
			if (Bind.Callback) then
				if (Bind.Arguments) then
					coroutine.wrap(Bind.Callback)(unpack(Bind.Arguments), ...)
				else
					coroutine.wrap(Bind.Callback)(...)
				end
			end
		end
	end
	
	self:ResumeThreads(...)
end

return Signal
