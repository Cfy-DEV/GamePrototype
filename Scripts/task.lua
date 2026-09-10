local module = {}
task = {}
local active_delays = {}

function module.load()
    game.updateThreads.threads.objects:add(function (dt)
        task.update(dt)
    end, "task")
end

function task.wait(seconds)
    local currentCoroutine = coroutine.running()
    local elapsed = 0
    local function callback(dt)
        elapsed = elapsed + dt
        if elapsed >= seconds then
            -- Remove from updates and resume coroutine
            for i, cb in ipairs(active_delays) do
                if cb == callback then
                    table.remove(active_delays, i)
                    break
                end
            end
            coroutine.resume(currentCoroutine)
        end
    end
    table.insert(active_delays, callback)
    return coroutine.yield()
end

function task.delay(seconds, func)
    local elapsed = 0
    local function callback(dt)
        elapsed = elapsed + dt
        if elapsed >= seconds then
            for i, cb in ipairs(active_delays) do
                if cb == callback then
                    table.remove(active_delays, i)
                    break
                end
            end
            func()
        end
    end
    table.insert(active_delays, callback)
end

function task.update(dt)
    -- Iterate backwards to safely remove elements if needed
    for i = #active_delays, 1, -1 do
        active_delays[i](dt)
    end
end

return module