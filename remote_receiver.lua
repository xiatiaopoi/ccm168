-- SPDX-FileCopyrightText: 2021 The CC: Tweaked Developers
--
-- SPDX-License-Identifier: MPL-2.0

local MODEM_CHANNEL = 65535
local mypath = "/"..fs.getDir(shell.getRunningProgram())

_G.remotePlay = false
_G.remoteMusicId = nil
_G.remoteTimestamp = nil
_G.remotePaused = false

local modem = nil
local decoder = nil
local httpfile = nil
local currentDfPwmUrl = nil
local currentPosition = 0
local currentVolume = 2

local function findModem()
    local names = peripheral.getNames()
    for _, name in ipairs(names) do
        local p = peripheral.wrap(name)
        if p then
            if peripheral.hasType(name, "modem") then
                return p, name
            end
            if p.transmit and p.open then
                return p, name
            end
        end
    end
    return nil, nil
end

local function initModem()
    modem = findModem()
    if modem then
        modem.open(MODEM_CHANNEL)
        return true
    end
    return false
end

local function loadSpeakerConfig()
    local speakerlist = {}
    local device_names = peripheral.getNames()
    for _, device_name in ipairs(device_names) do
        if peripheral.hasType(device_name, "speaker") then
            local speaker = peripheral.wrap(device_name)
            if speaker then
                table.insert(speakerlist, speaker)
            end
        end
    end
    return speakerlist
end

local function play_audio_chunk(speakers, buffer)
    if #speakers > 0 and buffer and #buffer > 0 then
        for _, speaker in pairs(speakers) do
            local success = false
            while not success and _G.Playopen do
                success = speaker.playAudio(buffer, currentVolume)
                if not success then
                    os.pullEvent("speaker_audio_empty")
                end
            end
        end
    end
end

local function startPlayback(dfpwmUrl, loop, volume, startPos)
    if decoder then
        decoder = nil
    end
    if httpfile then
        httpfile.close()
        httpfile = nil
    end
    
    currentDfPwmUrl = dfpwmUrl
    currentVolume = volume or 2
    currentPosition = startPos or 0
    
    local speakers = loadSpeakerConfig()
    if #speakers == 0 then
        print("No speakers found")
        return
    end
    print("Found " .. #speakers .. " speakers")
    print("Opening audio stream...")
    
    httpfile = http.get(dfpwmUrl)
    if not httpfile then
        print("Failed to open audio stream")
        return
    end
    
    decoder = require "cc.audio.dfpwm".make_decoder()
    _G.Playopen = true
    _G.Playstop = false
    _G.remotePlay = true
    _G.remotePaused = false
    _G.remoteMusicId = dfpwmUrl
    _G.remoteTimestamp = os.time()
    
    if startPos and startPos > 0 then
        local skipBytes = math.floor(startPos * 6000)
        httpfile.read(skipBytes)
    end
    
    local chunkSize = 6000
    local bytesRead = 0
    
    print("Starting playback...")
    
    local function playLoop()
        local headerRead = false
        
        while _G.Playopen and _G.remotePlay and httpfile do
            while _G.Playstop and _G.Playopen and _G.remotePlay do
                os.sleep(0.05)
            end
            
            if not _G.Playopen or not _G.remotePlay then
                break
            end
            
            local chunk = httpfile.read(chunkSize)
            if not chunk or #chunk == 0 then
                break
            end
            
            if not headerRead then
                headerRead = true
            end
            
            local buffer = decoder(chunk)
            play_audio_chunk(speakers, buffer)
            bytesRead = bytesRead + #chunk
            currentPosition = bytesRead / 6000
            
            if _G.remoteTimestamp then
                _G.getPlay = currentPosition
            end
        end
        
        if not loop then
            _G.remotePlay = false
            _G.Playopen = false
        end
    end
    
    local function eventLoop()
        while _G.remotePlay and _G.Playopen do
            local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
            if channel == MODEM_CHANNEL then
                local success, data = pcall(textutils.unserializeJSON, message)
                if success and data then
                    handleCommand(data)
                end
            end
        end
    end
    
    while _G.Playopen and _G.remotePlay do
        parallel.waitForAny(
            function()
                if not _G.Playstop then
                    playLoop()
                else
                    os.sleep(0.05)
                end
            end,
            eventLoop
        )
    end
    
    if httpfile then
        httpfile.close()
        httpfile = nil
    end
end

function handleCommand(data)
    local cmd = data.cmd
    local timestamp = data.timestamp
    
    if timestamp and _G.remoteTimestamp and timestamp < _G.remoteTimestamp then
        return
    end
    
    _G.remoteTimestamp = timestamp
    
    if cmd == "play" then
        _G.Playstop = false
        _G.remotePaused = false
        if data.dfpwm_url then
            print("Received play command with DFPWM URL")
            startPlayback(data.dfpwm_url, data.loop, data.volume, 0)
        else
            print("No DFPWM URL in command")
        end
    elseif cmd == "pause" then
        _G.Playstop = true
        _G.remotePaused = true
        print("Paused")
    elseif cmd == "resume" then
        _G.Playstop = false
        _G.remotePaused = false
        print("Resumed")
    elseif cmd == "stop" then
        _G.remotePlay = false
        _G.Playopen = false
        _G.Playstop = false
        _G.remotePaused = false
        _G.remoteMusicId = nil
        currentDfPwmUrl = nil
        currentPosition = 0
        if httpfile then
            httpfile.close()
            httpfile = nil
        end
        print("Playback stopped")
    elseif cmd == "seek" then
        currentPosition = data.position
        if _G.remotePlay and data.dfpwm_url then
            _G.Playopen = false
            os.sleep(0.1)
            startPlayback(data.dfpwm_url, false, currentVolume, data.position)
        end
    elseif cmd == "volume" then
        currentVolume = math.min(3, math.max(0, data.volume or 2))
        print("Volume set to " .. currentVolume)
    end
end

local cmd = ...

if cmd == "init" then
    if initModem() then
        print("Receiver initialized on channel " .. MODEM_CHANNEL)
    else
        printError("No modem found!")
    end
elseif cmd == "test" then
    print("Testing modem detection...")
    local modem, name = findModem()
    if modem then
        print("Found modem: " .. name)
    else
        print("No modem found")
    end
elseif cmd == "listen" then
    if not initModem() then
        printError("No modem found!")
        return
    end
    
    print("Listening for remote commands...")
    print("Press Ctrl+T to stop")
    
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        if channel == MODEM_CHANNEL then
            local success, data = pcall(textutils.unserializeJSON, message)
            if success and data then
                print("Received: " .. data.cmd)
                handleCommand(data)
            end
        end
    end
elseif cmd == "run" then
    if not initModem() then
        printError("No modem found!")
        return
    end
    
    print("Receiver started, waiting for commands...")
    
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        if channel == MODEM_CHANNEL then
            local success, data = pcall(textutils.unserializeJSON, message)
            if success and data then
                handleCommand(data)
            end
        end
    end
else
    print("Usage:")
    print("  remote_receiver init    - Initialize modem")
    print("  remote_receiver test    - Test modem detection")
    print("  remote_receiver listen  - Listen for commands (with output)")
    print("  remote_receiver run     - Listen for commands (silent)")
end
