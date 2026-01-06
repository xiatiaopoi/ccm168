-- SPDX-FileCopyrightText: 2021 The CC: Tweaked Developers
--
-- SPDX-License-Identifier: MPL-2.0

local MODEM_CHANNEL = 65535
local mypath = "/"..fs.getDir(shell.getRunningProgram())

_G.remotePlay = false
_G.remoteMusicId = nil
_G.remoteTimestamp = nil

_G.remoteModem = nil
_G.remoteModemInitialized = false
_G.currentDfPwmUrl = nil

local API_URL = "http://newgmapi.liulikeji.cn/api/ffmpeg"

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

local function ensureModem()
    if _G.remoteModem and _G.remoteModemInitialized then
        local name = peripheral.getName(_G.remoteModem)
        local testP = peripheral.wrap(name)
        if testP and testP.transmit then
            return true
        end
    end
    
    local modem, name = findModem()
    if modem then
        _G.remoteModem = modem
        modem.open(MODEM_CHANNEL)
        _G.remoteModemInitialized = true
        return true
    end
    return false
end

local function broadcast(data)
    if not ensureModem() then
        return false, "No modem found"
    end
    
    local msg = textutils.serializeJSON(data)
    local success, err = pcall(function()
        _G.remoteModem.transmit(MODEM_CHANNEL, MODEM_CHANNEL, msg)
    end)
    
    if success then
        return true
    else
        _G.remoteModemInitialized = false
        _G.remoteModem = nil
        return false, err
    end
end

local function Get_dfpwm_url(INPUT_URL)
    local requestData = {
        input_url = INPUT_URL,
        args = { "-vn", "-ar", "48000", "-ac", "1" },
        output_format = "dfpwm"
    }

    local response, err = http.post(
        API_URL,
        textutils.serializeJSON(requestData),
        { ["Content-Type"] = "application/json" }
    )

    if not response then 
        return nil, "HTTP Request Failure: "..(err or "Unknown error")
    end
    
    local responseData = textutils.unserializeJSON(response.readAll())
    response.close()

    if responseData.status ~= "success" then 
        return nil, "Conversion failed: "..(responseData.error or "Unknown error")
    end
    
    return responseData.download_url
end

local function getMusicUrl(songApiUrl)
    local response, err = http.get(songApiUrl)
    if not response then
        return nil, "Failed to get song info: " .. tostring(err)
    end
    
    local body = response.readAll()
    response.close()
    
    local success, data = pcall(textutils.unserializeJSON, body)
    if not success or type(data) ~= "table" or #data == 0 then
        return nil, "Invalid song info response"
    end
    
    local songInfo = data[1]
    if songInfo and songInfo.url then
        return songInfo.url
    end
    
    return nil, "No URL in song info"
end

function remotePlay(url, loop, volume)
    _G.remotePlay = true
    _G.remoteMusicId = url
    _G.remoteTimestamp = os.time()
    
    local musicUrl = url
    
    if url:find("type=song") then
        print("Getting music URL from song API...")
        local realUrl, err = getMusicUrl(url)
        if not realUrl then
            printError("Failed to get music URL: " .. tostring(err))
            return false
        end
        musicUrl = realUrl
        print("Got music URL: " .. musicUrl:sub(1, 80) .. "...")
    end
    
    print("Converting audio...")
    local dfpwmUrl, err = Get_dfpwm_url(musicUrl)
    if not dfpwmUrl then
        printError(err or "Audio conversion failed")
        return false
    end
    
    print("Audio converted successfully")
    _G.currentDfPwmUrl = dfpwmUrl
    
    return broadcast({
        cmd = "play",
        url = url,
        dfpwm_url = dfpwmUrl,
        timestamp = _G.remoteTimestamp,
        loop = loop or false,
        volume = volume or 2
    })
end

function remotePause()
    broadcast({
        cmd = "pause",
        timestamp = os.time()
    })
end

function remoteResume()
    broadcast({
        cmd = "resume",
        timestamp = os.time()
    })
end

function remoteStop()
    _G.remotePlay = false
    _G.remoteMusicId = nil
    _G.remoteTimestamp = nil
    _G.currentDfPwmUrl = nil
    broadcast({
        cmd = "stop",
        timestamp = os.time()
    })
end

function remoteSeek(position)
    if _G.currentDfPwmUrl then
        broadcast({
            cmd = "seek",
            dfpwm_url = _G.currentDfPwmUrl,
            position = position,
            timestamp = os.time()
        })
    end
end

function remoteVolume(vol)
    broadcast({
        cmd = "volume",
        volume = vol,
        timestamp = os.time()
    })
end

local cmd = ...

if cmd == "init" then
    if ensureModem() then
        print("Modem initialized on channel " .. MODEM_CHANNEL)
        print("Modem name: " .. tostring(peripheral.getName(_G.remoteModem)))
        _G.remoteModemInitialized = true
    else
        printError("No modem found!")
    end
elseif cmd == "play" then
    local url = select(2, ...)
    if not url then
        print("Usage: remote play <url> [loop] [volume]")
        return
    end
    local loop = select(3, ...) == "true"
    local volume = tonumber(select(4, ...)) or 2
    
    if remotePlay(url, loop, volume) then
        print("Broadcasting play command...")
    else
        printError("Failed to broadcast")
    end
elseif cmd == "pause" then
    remotePause()
    print("Broadcasting pause command...")
elseif cmd == "resume" then
    remoteResume()
    print("Broadcasting resume command...")
elseif cmd == "stop" then
    remoteStop()
    print("Broadcasting stop command...")
elseif cmd == "seek" then
    local pos = tonumber(select(2, ...))
    if pos then
        remoteSeek(pos)
        print("Broadcasting seek command...")
    else
        print("Usage: remote seek <position>")
    end
elseif cmd == "volume" then
    local vol = tonumber(select(2, ...))
    if vol then
        remoteVolume(vol)
        print("Broadcasting volume command...")
    else
        print("Usage: remote volume <0-3>")
    end
elseif cmd == "test" then
    print("Testing modem detection...")
    local modem, name = findModem()
    if modem then
        print("Found modem: " .. name)
        print("Testing transmit...")
        modem.open(MODEM_CHANNEL)
        local success, err = pcall(function()
            modem.transmit(MODEM_CHANNEL, MODEM_CHANNEL, "test message")
        end)
        print("Transmit test: " .. tostring(success))
        if not success then
            print("Error: " .. tostring(err))
        end
    else
        print("No modem found")
    end
elseif cmd == "convert" then
    local url = select(2, ...)
    if not url then
        print("Usage: remote convert <url>")
        return
    end
    print("Testing conversion...")
    
    local musicUrl = url
    if url:find("type=song") then
        print("Getting music URL first...")
        local realUrl, err = getMusicUrl(url)
        if not realUrl then
            printError("Failed to get music URL: " .. tostring(err))
            return
        end
        musicUrl = realUrl
        print("Music URL: " .. musicUrl:sub(1, 80) .. "...")
    end
    
    local dfpwmUrl, err = Get_dfpwm_url(musicUrl)
    if dfpwmUrl then
        print("Success! DFPWM URL: " .. dfpwmUrl)
    else
        printError("Failed: " .. tostring(err))
    end
elseif cmd == "geturl" then
    local url = select(2, ...)
    if not url then
        print("Usage: remote geturl <song_api_url>")
        return
    end
    print("Getting music URL...")
    local realUrl, err = getMusicUrl(url)
    if realUrl then
        print("Success! URL: " .. realUrl)
    else
        printError("Failed: " .. tostring(err))
    end
else
    print("Usage:")
    print("  remote init               - Initialize modem")
    print("  remote play <url> [loop] [volume]  - Play music")
    print("  remote pause              - Pause playback")
    print("  remote resume             - Resume playback")
    print("  remote stop               - Stop playback")
    print("  remote seek <position>    - Seek to position")
    print("  remote volume <0-3>       - Set volume")
    print("  remote test               - Test modem")
    print("  remote convert <url>      - Test audio conversion")
    print("  remote geturl <song_url>  - Get music URL from song API")
end
