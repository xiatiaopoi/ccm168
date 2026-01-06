-- 无线远程控制测试脚本
-- 用于测试speakerlib.lua的无线通信功能

local protocol = "music_player"

-- 初始化rednet
local function initRednet()
    local modem_sides = {"front", "back", "left", "right", "top", "bottom"}
    for _, side in ipairs(modem_sides) do
        if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
            rednet.open(side)
            print("Rednet initialized on side: " .. side)
            return true
        end
    end
    print("No wireless modem found!")
    return false
end

-- 显示帮助信息
local function showHelp()
    print("\n=== Music Player Remote Control ===")
    print("Commands:")
    print("  help     - Show this help")
    print("  status   - Show current playback status")
    print("  play     - Resume playback")
    print("  pause    - Pause playback")
    print("  stop     - Stop playback")
    print("  volume <0-3> - Set volume")
    print("  seek <time>  - Seek to time (seconds)")
    print("  exit     - Exit the program")
    print("==================================")
end

-- 发送命令
local function sendCommand(command, params)
    local message = {
        type = "command",
        command = command,
        timestamp = os.time()
    }
    
    -- 添加参数
    if params then
        for k, v in pairs(params) do
            message[k] = v
        end
    end
    
    rednet.broadcast(message, protocol)
    print("Command sent: " .. command)
end

-- 接收并显示状态
local function receiveStatus()
    print("\nListening for playback status...")
    print("Press any key to stop listening.")
    
    local event = {}
    while true do
        parallel.waitForAny(
            function()
                local id, message, proto = rednet.receive(protocol, 0.5)
                if id and message.type == "status" then
                    print("\n=== Playback Status ===")
                    print("From: " .. id)
                    print("Playing: " .. tostring(message.playing))
                    print("Paused: " .. tostring(message.paused))
                    print("Stopped: " .. tostring(message.stopped))
                    print("Current Time: " .. string.format("%.2f", message.current_time) .. "s")
                    print("Total Time: " .. string.format("%.2f", message.total_time) .. "s")
                    print("Volume: " .. message.volume)
                    print("Timestamp: " .. os.date("%H:%M:%S", message.timestamp))
                    print("====================")
                end
            end,
            function()
                event = {os.pullEventRaw("key")}
            end
        )
        
        if event[1] == "key" then
            break
        end
    end
end

-- 主程序
local function main()
    print("Music Player Remote Control")
    print("Initializing...")
    
    if not initRednet() then
        return
    end
    
    showHelp()
    
    while true do
        write("\n> ")
        local input = read()
        local parts = {}  
        for part in string.gmatch(input, "[^%s]+") do
            table.insert(parts, part)
        end
        
        if #parts == 0 then
            showHelp()
        else
            local cmd = string.lower(parts[1])
            
            if cmd == "help" then
                showHelp()
            elseif cmd == "status" then
                receiveStatus()
            elseif cmd == "play" then
                sendCommand("play")
            elseif cmd == "pause" then
                sendCommand("pause")
            elseif cmd == "stop" then
                sendCommand("stop")
            elseif cmd == "volume" and #parts == 2 then
                local volume = tonumber(parts[2])
                if volume and volume >= 0 and volume <= 3 then
                    sendCommand("volume", {volume = volume})
                else
                    print("Invalid volume. Must be between 0 and 3.")
                end
            elseif cmd == "seek" and #parts == 2 then
                local time = tonumber(parts[2])
                if time and time >= 0 then
                    sendCommand("seek", {position = time})
                else
                    print("Invalid time. Must be a positive number.")
                end
            elseif cmd == "exit" or cmd == "quit" then
                break
            else
                print("Unknown command. Type 'help' for a list of commands.")
            end
        end
    end
    
    -- 关闭rednet
    rednet.closeAll()
    print("\nProgram exited.")
end

-- 运行主程序
main()