local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)
    self.connections = {}
    return self
end

function Signal:connect(connection)
    table.insert(self.connections, connection)
    return connection
end

function Signal:disconnect(connection)
    for i, l in ipairs(self.connections) do
        if l == connection then
            table.remove(self.connections, i)
            break
        end
    end
end

function Signal:fire(...)
    for _, connection in ipairs(self.connections) do
        connection(...)
    end
end

return Signal
