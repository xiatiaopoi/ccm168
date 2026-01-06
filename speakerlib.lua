-- SPDX-FileCopyrightText: 2021 The CC: Tweaked Developers
--
-- SPDX-License-Identifier: MPL-2.0

-- 全局控制变量
_G.getPlaymax = 0    -- 总时间（秒）
_G.getPlay = 0       -- 当前播放时间（秒）
_G.setPlay = 0       -- 设置播放进度（秒）
_G.Playopen = true   -- 播放开关（false停止）
_G.Playstop = false  -- 暂停控制（true暂停，false恢复）
_G.Playprint = true  -- 信息输出开关（true开，false关）
_G.setVolume = 1     -- 音量控制（0-3）

local API_URL = "http://newgmapi.liulikeji.cn/api/ffmpeg" -- 远程音频转换API
local mypath = "/"..fs.getDir(shell.getRunningProgram())

-- 无线通信配置
local rednet_protocol = "music_player" -- 通信协议名称
local broadcast_interval = 2 -- 播放状态广播间隔（秒）
local rednet_enabled = false -- rednet启用状态

-- 扬声器配置
local speakerlist = {
    main = {},
    left = {},
    right = {}
}

-- 初始化rednet通信
local function initRednet()
    -- 查找并打开所有无线调制解调器
    local modem_sides = {"front", "back", "left", "right", "top", "bottom"}
    for _, side in ipairs(modem_sides) do
        if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
            rednet.open(side)
            rednet_enabled = true
            printlog("Rednet initialized on side: " .. side)
            break
        end
    end
end

-- 关闭rednet通信
local function closeRednet()
    if rednet_enabled then
        rednet.closeAll()
        rednet_enabled = false
        printlog("Rednet closed")
    end
end

local function printlog(...)
    if _G.Playprint then
        print(...)
    end
end

-- 广播播放状态
local function broadcastPlayState()
    if rednet_enabled then
        local play_state = {
            type = "status",
            playing = _G.Playopen and not _G.Playstop,
            paused = _G.Playstop,
            stopped = not _G.Playopen,
            current_time = _G.getPlay,
            total_time = _G.getPlaymax,
            volume = _G.setVolume,
            timestamp = os.time()
        }
        rednet.broadcast(play_state, rednet_protocol)
    end
end

local function loadSpeakerConfig()
    -- 自动连接所有扬声器，无需配置文件
    speakerlist = { main = {}, left = {}, right = {} }
    
    -- 获取所有连接的设备名称
    local device_names = peripheral.getNames()
    for _, device_name in ipairs(device_names) do
        -- 检查设备是否为扬声器类型
        if peripheral.hasType(device_name, "speaker") then
            -- 将扬声器包装为可用对象
            local speaker = peripheral.wrap(device_name)
            if speaker then
                -- 将所有扬声器添加到main组
                table.insert(speakerlist.main, speaker)
            end
        end
    end
    
    printlog("Found " .. #speakerlist.main .. " speakers")
end

-- 处理接收到的rednet消息
local function handleRednetMessage(id, message, protocol)
    if protocol == rednet_protocol and type(message) == "table" then
        if message.type == "command" then
            -- 处理远程控制命令
            if message.command == "play" then
                printlog("Received play command from " .. id)
                _G.Playstop = false
            elseif message.command == "pause" then
                printlog("Received pause command from " .. id)
                _G.Playstop = true
            elseif message.command == "stop" then
                printlog("Received stop command from " .. id)
                _G.Playopen = false
            elseif message.command == "volume" then
                if message.volume then
                    _G.setVolume = math.max(0, math.min(3, tonumber(message.volume) or _G.setVolume))
                    printlog("Volume set to " .. _G.setVolume .. " from " .. id)
                end
            elseif message.command == "seek" then
                if message.position then
                    _G.setPlay = tonumber(message.position) or _G.getPlay
                    printlog("Seek to " .. _G.setPlay .. "s from " .. id)
                end
            end
        end
    end
end

-- 监听rednet消息的协程
local function rednetListener()
    while rednet_enabled and _G.Playopen do
        local id, message, protocol = rednet.receive(rednet_protocol, 0.5)
        if id then
            handleRednetMessage(id, message, protocol)
        end
        os.sleep(0.1)
    end
end

local function Get_dfpwm_url(INPUT_URL, args)
    local requestData = {
        input_url = INPUT_URL,
        args = args,
        output_format = "dfpwm"
    }

    local response, err = http.post(
        API_URL,
        textutils.serializeJSON(requestData),
        { ["Content-Type"] = "application/json" }
    )

    if not response then 
        error("HTTP Request Failure: "..(err or "Unknown error")) 
    end
    
    local responseData = textutils.unserializeJSON(response.readAll())
    response.close()

    if responseData.status ~= "success" then 
        error("Conversion failed: "..(responseData.error or "Unknown error")) 
    end
    
    return responseData.download_url
end

local function get_total_duration(url)
    if _G.Playprint then printlog("Calculating duration...") end
    local handle, err = http.get(url)
    if not handle then
        error("Could not get duration: " .. (err or "Unknown error"))
    end
    
    local data = handle.readAll()
    handle.close()
    
    -- DFPWM: 每字节8个样本，48000采样率
    local total_length = (#data * 8) / 48000
    return total_length, #data
end

local function play_audio_chunk(speakers, buffer)
    if #speakers > 0 and buffer and #buffer > 0 then
        for _, speaker in pairs(speakers) do
            local success = false
            while not success and _G.Playopen do
                success = speaker.playAudio(buffer, _G.setVolume)
                if not success then
                    os.pullEvent("speaker_audio_empty")
                end
            end
        end
    end
end

local cmd = ...

if cmd == "stop" then
    -- 设置停止标志
    _G.Playopen = false
    _G.Playstop = false
    
    -- 发送停止状态
    broadcastPlayState()
    
    -- 停止所有扬声器
    local all_speakers = {}
    for _, group in pairs(speakerlist) do
        for _, speaker in pairs(group) do
            table.insert(all_speakers, speaker)
        end
    end
    
    for _, speaker in pairs(all_speakers) do
        speaker.stop()
    end
    
    -- 关闭rednet通信
    closeRednet()
elseif cmd == "play" then
    local _, file = ...
    if not file then
        error("Usage: speaker play <url>", 0)
    end

    if not http or not file:match("^https?://") then
        error("Only HTTP/HTTPS URLs are supported", 0)
    end

    -- 初始化rednet通信
    initRednet()

    -- 加载扬声器配置
    loadSpeakerConfig()

    -- 检查是否有扬声器
    local has_speakers = false
    for _, group in pairs(speakerlist) do
        if #group > 0 then
            has_speakers = true
            break
        end
    end
    
    if not has_speakers then
        closeRednet()
        error("No speakers attached", 0)
    end

    -- 启动rednet监听器协程
    local rednet_coroutine = coroutine.create(rednetListener)

    -- 获取DFPWM转换URL
    local main_dfpwm_url, left_dfpwm_url, right_dfpwm_url
    local main_httpfile, left_httpfile, right_httpfile
    
    if _G.Playprint then printlog("Converting audio...") end
    
    if #speakerlist.main > 0 then
        main_dfpwm_url = Get_dfpwm_url(file, { "-vn", "-ar", "48000", "-ac", "1" })
    end

    if #speakerlist.left > 0 then
        left_dfpwm_url = Get_dfpwm_url(file, { "-vn", "-ar", "48000", "-filter_complex", "pan=mono|c0=FL" })
    end

    if #speakerlist.right > 0 then
        right_dfpwm_url = Get_dfpwm_url(file, { "-vn", "-ar", "48000", "-filter_complex", "pan=mono|c0=FR" })
    end

    -- 计算总时长（使用任意一个通道）
    local total_length, total_size
    if main_dfpwm_url then
        total_length, total_size = get_total_duration(main_dfpwm_url)
    elseif left_dfpwm_url then
        total_length, total_size = get_total_duration(left_dfpwm_url)
    elseif right_dfpwm_url then
        total_length, total_size = get_total_duration(right_dfpwm_url)
    else
        error("No audio channels available", 0)
    end

    -- 设置总时间
    _G.getPlaymax = total_length
    _G.getPlay = 0

    if _G.Playprint then
        printlog("Playing " .. file .. " (" .. math.ceil(total_length) .. "s)")
    end

    -- 创建HTTP连接
    if main_dfpwm_url then
        main_httpfile = http.get(main_dfpwm_url)
        if not main_httpfile then
            error("Could not open main audio stream")
        end
    end

    if left_dfpwm_url then
        left_httpfile = http.get(left_dfpwm_url)
        if not left_httpfile then
            error("Could not open left audio stream")
        end
    end

    if right_dfpwm_url then
        right_httpfile = http.get(right_dfpwm_url)
        if not right_httpfile then
            error("Could not open right audio stream")
        end
    end

    -- 初始化DFPWM解码器
    local decoder = require "cc.audio.dfpwm".make_decoder()
    local left_decoder = require "cc.audio.dfpwm".make_decoder()
    local right_decoder = require "cc.audio.dfpwm".make_decoder()

    -- 每次读取的字节数（DFPWM: 每秒6000字节）
    local chunk_size = 6000
    local bytes_read = 0

    -- 初始化播放位置
    if _G.setPlay > 0 then
        local skip_bytes = math.floor(_G.setPlay * 6000)
        if skip_bytes < total_size then
            -- 跳过指定字节数
            local skipped = 0
            while skipped < skip_bytes and _G.Playopen do
                local to_skip = math.min(8192, skip_bytes - skipped)
                if main_httpfile then main_httpfile.read(to_skip) end
                if left_httpfile then left_httpfile.read(to_skip) end
                if right_httpfile then right_httpfile.read(to_skip) end
                skipped = skipped + to_skip
                bytes_read = bytes_read + to_skip
            end
            _G.getPlay = _G.setPlay
            _G.setPlay = 0
        end
    end

    -- 主播放循环
    local last_broadcast_time = 0
    while bytes_read < total_size and _G.Playopen do
        -- 检查是否需要设置播放位置
        if _G.setPlay > 0 then
            -- 重新打开所有连接并跳转
            if main_httpfile then main_httpfile.close() end
            if left_httpfile then left_httpfile.close() end
            if right_httpfile then right_httpfile.close() end

            if main_dfpwm_url then
                main_httpfile = http.get(main_dfpwm_url)
                if not main_httpfile then error("Could not reopen main stream") end
            end

            if left_dfpwm_url then
                left_httpfile = http.get(left_dfpwm_url)
                if not left_httpfile then error("Could not reopen left stream") end
            end

            if right_dfpwm_url then
                right_httpfile = http.get(right_dfpwm_url)
                if not right_httpfile then error("Could not reopen right stream") end
            end

            local skip_bytes = math.floor(_G.setPlay * 6000)
            if skip_bytes < total_size then
                local skipped = 0
                while skipped < skip_bytes and _G.Playopen do
                    local to_skip = math.min(8192, skip_bytes - skipped)
                    if main_httpfile then main_httpfile.read(to_skip) end
                    if left_httpfile then left_httpfile.read(to_skip) end
                    if right_httpfile then right_httpfile.read(to_skip) end
                    skipped = skipped + to_skip
                    bytes_read = skip_bytes
                end
                _G.getPlay = _G.setPlay
                _G.setPlay = 0
            end
        end

        -- 检查暂停状态
        while _G.Playstop and _G.Playopen do
            -- 暂停时也需要处理rednet消息和广播状态
            if rednet_enabled then
                coroutine.resume(rednet_coroutine)
                local current_time = os.time()
                if current_time - last_broadcast_time >= broadcast_interval then
                    broadcastPlayState()
                    last_broadcast_time = current_time
                end
            end
            os.sleep(0.1)
        end

        -- 检查停止状态
        if not _G.Playopen then
            break
        end

        -- 处理rednet消息
        if rednet_enabled then
            coroutine.resume(rednet_coroutine)
        end

        -- 定期广播播放状态
        local current_time = os.time()
        if rednet_enabled and current_time - last_broadcast_time >= broadcast_interval then
            broadcastPlayState()
            last_broadcast_time = current_time
        end

        -- 读取音频数据（在读取前再次检查停止标志）
        if not _G.Playopen then
            break
        end
        
        local main_chunk, left_chunk, right_chunk
        local main_buffer, left_buffer, right_buffer

        if main_httpfile then
            main_chunk = main_httpfile.read(chunk_size)
        end

        if left_httpfile then
            left_chunk = left_httpfile.read(chunk_size)
        end

        if right_httpfile then
            right_chunk = right_httpfile.read(chunk_size)
        end
        
        -- 读取后再次检查停止标志
        if not _G.Playopen then
            break
        end

        -- 检查是否所有通道都没有数据
        if (not main_chunk or #main_chunk == 0) and 
           (not left_chunk or #left_chunk == 0) and 
           (not right_chunk or #right_chunk == 0) then
            break
        end

        -- 解码音频数据
        if main_chunk and #main_chunk > 0 then
            main_buffer = decoder(main_chunk)
        end

        if left_chunk and #left_chunk > 0 then
            left_buffer = left_decoder(left_chunk)
        end

        if right_chunk and #right_chunk > 0 then
            right_buffer = right_decoder(right_chunk)
        end

        -- 并行播放所有通道
        parallel.waitForAll(
            function() 
                if main_buffer and #main_buffer > 0 then
                    play_audio_chunk(speakerlist.main, main_buffer)
                end
            end,
            function() 
                if right_buffer and #right_buffer > 0 then
                    play_audio_chunk(speakerlist.right, right_buffer)
                end
            end,
            function() 
                if left_buffer and #left_buffer > 0 then
                    play_audio_chunk(speakerlist.left, left_buffer)
                end
            end
        )

        -- 更新进度
        local max_chunk_size = math.max(
            main_chunk and #main_chunk or 0,
            left_chunk and #left_chunk or 0,
            right_chunk and #right_chunk or 0
        )
        bytes_read = bytes_read + max_chunk_size
        _G.getPlay = bytes_read / 6000
    end

    -- 关闭HTTP连接
    if main_httpfile then main_httpfile.close() end
    if left_httpfile then left_httpfile.close() end
    if right_httpfile then right_httpfile.close() end

    -- 发送最终播放状态
    broadcastPlayState()

    -- 关闭rednet通信
    closeRednet()

    if _G.Playprint and _G.Playopen then
        printlog("Playback finished.")
    end
    
    -- 重置播放状态
    _G.Playopen = true
    _G.Playstop = false
    _G.getPlay = 0
else
    local programName = arg[0] or fs.getName(shell.getRunningProgram())
    printlog("Usage:")
    printlog(programName .. " play <url>")
    printlog(programName .. " stop")
end
