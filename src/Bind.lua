local Bind = {}
Bind.__index = Bind

function Bind.new()
	return setmetatable({}, Bind)
end

function Bind:Disconnect()
	if (self.Signal) then
		if (self.Signal.Binds) then
			local Index = table.find(self.Signal.Binds, self)
			if (Index) then
				table.remove(self.Signal.Binds, Index)
				
				if (not next(self.Signal.Binds)) then
					self.Signal.Binds = nil
				end
			end
		end
		
		self.Signal = nil
	end
end

return Bind