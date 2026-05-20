local M = {}

function M.read_command_output(command)
    local handle = io.popen(command .. " 2>/dev/null")
    if not handle then
        return nil
    end

    local output = handle:read("*l")
    handle:close()

    if not output then
        return nil
    end

    output = output:gsub("%s+$", "")
    if output == "" then
        return nil
    end

    return output
end

function M.command_exists(command)
    return M.read_command_output("command -v " .. command .. " >/dev/null 2>&1 && printf yes || printf no") == "yes"
end

function M.stop_timer(timer)
    if not timer then
        return
    end

    if timer.stop then
        timer:stop()
    elseif timer.started ~= nil then
        timer.started = false
    end
end

function M.truncate_message(text)
    text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        return nil
    end

    if #text > 240 then
        return text:sub(1, 237) .. "..."
    end

    return text
end

function M.shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

return M
