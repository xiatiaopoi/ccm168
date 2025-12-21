-----------------------------------------------------------------系统启动阶段-------------------------------------------------------------------------------------------------
--*获取程序所在目录

local mypath = "/"..fs.getDir(shell.getRunningProgram())
if not fs.exists(mypath.."/lib/basalt.lua") then shell.run("wget https://gitee.com/xiatiaopoi/ccm168/blob/master/lib/basalt.lua "..mypath.."/lib/basalt.lua") end
if not fs.exists(mypath.."/speakerlib.lua") then shell.run("wget https://gitee.com/xiatiaopoi/ccm168/blob/master/speakerlib.lua "..mypath.."/speakerlib.lua") end
if not fs.exists(mypath.."/MusicLyrics.lua") then shell.run("wget https://gitee.com/xiatiaopoi/ccm168/blob/master/MusicLyrics.lua "..mypath.."/MusicLyrics.lua") end

--*GUI库导入
basalt = require(mypath.."/lib/basalt")
--*初始化GUI框架
local mainf = basalt.createFrame()
main  = {
    mainf:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h"):setBackground(colors.red),
}
_G.Playprint = false
_G.Playopen =false
--*GUI框架配置表
local sub = {
    ["UI"] = {
        main[1]:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h -2"):setBackground(colors.red),
        main[1]:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h -2"):setBackground(colors.white):hide(),
        main[1]:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h -2"):setBackground(colors.white):hide(),
        main[1]:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h -2"):setBackground(colors.red):hide(),
        main[1]:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h -2"):setBackground(colors.white):hide(),
    },
    ["menu"] ={
        main[1]:addFrame():setPosition(1, "parent.h"):setSize("parent.w", 1):setBackground(colors.lightGray),
    },
    ["BF"] = {
        mainf:addFrame():setPosition(1, "parent.h + 1"):setSize("parent.w", "parent.h"):setBackground(colors.red),
        main[1]:addFrame():setPosition(1, "parent.h - 1"):setSize("parent.w", 1):setBackground(colors.lightGray):hide(),
    },
    ["play_table"] = {
        mainf:addFrame():setPosition(2, "parent.h + 1"):setSize("parent.w-2", 13):setBackground(colors.orange),
    }
}
--创建动画
play_Gui_UP = mainf:addAnimation():setObject(sub["BF"][1]):move(1,1,0.3)
play_Gui_DO = mainf:addAnimation():setObject(sub["BF"][1]):move(1,mainf:getHeight()+1,1)
play_table_Gui_UP = mainf:addAnimation():setObject(sub["play_table"][1]):move(2,mainf:getHeight()-12,0.3)
play_table_Gui_DO = mainf:addAnimation():setObject(sub["play_table"][1]):move(2,mainf:getHeight()+1,1)
--play_Gui_UP:play()
--main[1]:hide()
--main[1]:addAnimation():setObject(sub["BF"][1]):move(1,"parent.h+1",1.5):play()
--创建播放界面
play_name = "NO Music"
play_id = "NO Music"
play_Gui = {
    sub["BF"][1]:addButton():setPosition(1,1):setSize(3, 1):setText("V"):onClick(function() play_Gui_DO:play() play_GUI_state=false main[1]:enable() end):setBackground(colors.red):setForeground(colors.white),
    sub["BF"][1]:addLabel():setText("NO Music"):setPosition(sub["BF"][1]:getWidth()/2 - #play_name/2,1):setBackground(colors.red):setForeground(colors.white),
    sub["BF"][1]:addLabel():setText("NO Music"):setPosition(sub["BF"][1]:getWidth()/2 - #play_id/2,2):setBackground(colors.red):setForeground(colors.white),
    sub["BF"][1]:addProgram():setPosition(2,2):setSize("parent.w-2", "parent.h-4"),
    1,--sub["BF"][1]:addButton():setPosition(3,"parent.h-5"):setSize(1, 1):setText("\3"):onClick(function() end):setForeground(colors.white):setBackground(colors.red),
    1,--sub["BF"][1]:addButton():setPosition(8,"parent.h-5"):setSize(1, 1):setText("\25"):onClick(function() end):setForeground(colors.white):setBackground(colors.red),
    1,--sub["BF"][1]:addButton():setPosition("parent.w/2","parent.h-5"):setSize(2, 1):setText("+-"):onClick(function() end):setForeground(colors.white):setBackground(colors.red),
    1,--sub["BF"][1]:addButton():setPosition("parent.w-3","parent.h-5"):setSize(1, 1):setText("@"):onClick(function() end):setForeground(colors.white):setBackground(colors.red),
    1,--sub["BF"][1]:addButton():setPosition("parent.w-8","parent.h-5"):setSize(1, 1):setText("E"):onClick(function() end):setForeground(colors.white):setBackground(colors.red),
    sub["BF"][1]:addProgressbar():setPosition(3, "parent.h - 2"):setSize("parent.w - 4", 1):setProgressBar(colors.red, "=", colors.white):setBackground(colors.red):setBackgroundSymbol("-"):setForeground(colors.white),
    sub["BF"][1]:addLabel():setText("00:00"):setPosition("3", "parent.h - 1"):setSize(5, 1):setForeground(colors.white),
    sub["BF"][1]:addLabel():setText("00:00"):setPosition("parent.w - 6", "parent.h - 1"):setSize(5, 1):setForeground(colors.white),
    sub["BF"][1]:addButton():setPosition(3, "parent.h - 0"):setSize(3, 1):setText("=O="):onClick(function() _G.play_mode_loop = not _G.play_mode_loop end):setForeground(colors.white):setBackground(colors.red),
    sub["BF"][1]:addButton():setPosition("parent.w /2 - 4","parent.h - 0"):setSize(2, 1):setText("|\17"):onClick(function() play_set_1() end):setForeground(colors.white):setBackground(colors.red),
    sub["BF"][1]:addButton():setPosition("parent.w / 2 ", "parent.h - 0"):setSize(2, 1):setText("I>"):onClick(function()  
        if play_data_table["play"] then 
            -- 暂停逻辑
            play_data_table["play"] = false
            _G.Playstop = true  -- 只设置暂停标志，不停止扬声器线程
        else 
            -- 恢复播放逻辑
            play_data_table["play"] = true
            _G.Playstop = false  -- 只清除暂停标志，让扬声器线程继续播放
        end 
    end):setForeground(colors.white):setBackground(colors.red),
    sub["BF"][1]:addButton():setPosition("parent.w / 2 +4", "parent.h - 0"):setSize(2, 1):setText("\16|"):onClick(function() play_set_0() end):setForeground(colors.white):setBackground(colors.red),
    sub["BF"][1]:addButton():setPosition("parent.w - 4", "parent.h - 0"):setSize(3, 1):setText("=T="):onClick(function() play_table_Gui_UP:play() main[1]:disable() sub["BF"][1]:disable() end):setForeground(colors.white):setBackground(colors.red),
    sub["BF"][1]:addSlider():setPosition(3, "parent.h - 2"):setSize("parent.w - 4", 1):setMaxValue(100):setBackground(colors.red):setForeground(colors.white),--:setBackgroundSymbol("\x8c"):setSymbol(" "),
}
--创建播放UI
play_column_Gui = {
    sub["BF"][2]:addLabel():setText(""):setPosition(1,1):setSize("parent.w-7",1):setBackground(colors.lightGray):setForeground(colors.white),
    sub["BF"][2]:addButton():setPosition("parent.w -4 ", 1):setSize(2, 1):setText("I>"):onClick(function()  if play_data_table["play"] then _G.Playstop = true play_data_table["play"]=false else play_data_table["play"]=true end end):setForeground(colors.white):setBackground(colors.lightGray),
    sub["BF"][2]:addButton():setPosition("parent.w-1", 1):setSize(1, 1):setText("T"):onClick(function() play_table_Gui_UP:play() main[1]:disable() end):setForeground(colors.white):setBackground(colors.lightGray),
    sub["BF"][2]:addButton():setPosition(1, 1):setSize("parent.w -5", 1):setText(""):onClick(function() play_Gui_UP:play() play_GUI_state=true main[1]:disable() end):setBackground(colors.lights),
}
play_table_Gui = {
    sub["play_table"][1]:addButton():setPosition("parent.w-3",1):setSize(3, 1):setText("V"):onClick(function() if not play_GUI_state then main[1]:enable() end sub["BF"][1]:enable() play_table_Gui_DO:play() end):setBackground(colors.no):setForeground(colors.white),
    sub["play_table"][1]:addLabel():setText("PlayTable"):setPosition(1,1):setForeground(colors.white),
    sub["play_table"][1]:addList():setPosition(2,3):setSize("parent.w-2", "parent.h-2"):setScrollable(true),
}
--创建菜单栏
menuBut = {
    sub["menu"][1]:addButton():setPosition(3,1):setSize(3, 1):setText("{Q}"):onClick(function() for index, value in ipairs(menuBut) do value:setBackground(colors.lightGray) end menuBut[1]:setBackground(colors.red) for index, value in ipairs(sub["UI"]) do value:hide() end sub["UI"][1]:show() end):setForeground(colors.white):setBackground(colors.red),
    sub["menu"][1]:addButton():setPosition(8,1):setSize(3, 1):setText("{T}"):onClick(function() for index, value in ipairs(menuBut) do value:setBackground(colors.lightGray) end menuBut[2]:setBackground(colors.red) for index, value in ipairs(sub["UI"]) do value:hide() end sub["UI"][2]:show() end):setForeground(colors.white):setBackground(colors.lightGray),
    sub["menu"][1]:addButton():setPosition(12,1):setSize(4, 1):setText("{PH}"):onClick(function() for index, value in ipairs(menuBut) do value:setBackground(colors.lightGray) end menuBut[3]:setBackground(colors.red) for index, value in ipairs(sub["UI"]) do value:hide() end sub["UI"][3]:show() end):setForeground(colors.white):setBackground(colors.lightGray),
    sub["menu"][1]:addButton():setPosition(17,1):setSize(3, 1):setText("{G}"):onClick(function() for index, value in ipairs(menuBut) do value:setBackground(colors.lightGray) end menuBut[4]:setBackground(colors.red) for index, value in ipairs(sub["UI"]) do value:hide() end sub["UI"][4]:show() end):setForeground(colors.white):setBackground(colors.lightGray),
    sub["menu"][1]:addButton():setPosition(22,1):setSize(3, 1):setText("{Z}"):onClick(function() for index, value in ipairs(menuBut) do value:setBackground(colors.lightGray) end menuBut[5]:setBackground(colors.red) for index, value in ipairs(sub["UI"]) do value:hide() end sub["UI"][5]:show() end):setForeground(colors.white):setBackground(colors.lightGray),
}
-----------------------------------------------------------------DATA---------------------------------------------------------------------------------------------------------
play_data_table = { ["music"] = {} ,  ["play"] = false  ,["play_table"] = {}, ["play_table_index"] = 0, ["mode"] = "" , }
-- 分页状态变量
_G.playlist_pagination = {
    ["current_page"] = 0,
    ["playlist_id"] = "",
    ["has_more"] = true,
    ["loading"] = false
}
_G.Playopen = false
_G.getPlay = 0
_G.getPlaymax = 0
_G.setPlay = nil
_G.music168_current_playing_id = nil  -- 当前正在播放的音乐ID
_G.play_mode_loop = true  -- 循环播放模式（true=循环，false=单曲）
-----------------------------------------------------------------模块---------------------------------------------------------------------------------------------------------

--音乐+
function play_set_1()
    _G.music168_playopen = false os.queueEvent("music168_play_stop") 
    _G.getPlay = 0
    _G.Playopen = false
    _G.Playstop = false
    table_index = play_table_Gui[3]:getItemIndex() 
    if table_index <= 1 then 
        play_table_Gui[3]:selectItem(play_table_Gui[3]:getItemCount()) 
    else 
        play_table_Gui[3]:selectItem(table_index-1) 
    end
end
--音乐-
function play_set_0()
    _G.music168_playopen = false os.queueEvent("music168_play_stop")
    _G.getPlay = 0
    _G.Playopen = false
    _G.Playstop = false
    table_index = play_table_Gui[3]:getItemIndex() 
    if table_index >= play_table_Gui[3]:getItemCount() then 
        play_table_Gui[3]:selectItem(1) 
    else 
        play_table_Gui[3]:selectItem(table_index+1) 
    end
end
-- GetmusicUrl函数已被移除，直接使用server_url构建音乐URL
--dfpwm转码
--播放
function playmusic(music_name,music_id,play_table,index)
    -- 简化playmusic函数，只设置必要的状态
    _G.getPlay = 0
    _G.getPlaymax = 0
    _G.Playopen = true  -- 允许播放
    _G.music168_playopen = true  -- 开始播放标志
    _G.Playstop = false  -- 不暂停

    local safe_music_name = music_name or "Unknown Song"
    local safe_music_id = tostring(music_id or "Unknown ID")
    
    -- 更新GUI显示
    play_Gui[2]:setText(safe_music_name):setPosition(sub["BF"][1]:getWidth()/2 +1 - utf8len(safe_music_name)/2,1)
    play_Gui[3]:setText(safe_music_id):setPosition(sub["BF"][1]:getWidth()/2 +1 - #safe_music_id/2,2)
    play_column_Gui[1]:setText(safe_music_name.." | "..safe_music_id)
    
    -- 更新播放数据
    play_data_table["music"] = { ["music_id"] = music_id, ["music_name"] = music_name }
    play_data_table["play_table"] = play_table
    play_data_table["play_table_index"] = index
    play_data_table["play"] = true
    
    -- 更新播放列表
    play_table_Gui[3]:clear()
    for index, value in ipairs(play_table) do
        local safe_name = value["name"] or "Unknown Song"
        local safe_id = tostring(value["id"] or "Unknown ID")
        play_table_Gui[3]:addItem(safe_name.." | "..safe_id)
    end
    
    play_table_Gui[3]:selectItem(index)
    _G.music168_music_id = music_id
end

-- UTF-8字符串长度计算函数
function utf8len(str)
    local len = 0
    local i = 1
    while i <= #str do
        local byte = string.byte(str:sub(i, i))
        if byte < 128 then
            -- ASCII字符，占1个字符位置
            len = len + 1
            i = i + 1
        else
            -- UTF-8字符，占1个字符位置
            len = len + 1
            if byte >= 0xC0 and byte < 0xE0 then
                i = i + 2
            elseif byte >= 0xE0 and byte < 0xF0 then
                i = i + 3
            elseif byte >= 0xF0 then
                i = i + 4
            else
                i = i + 1
            end
        end
    end
    return len
end

-- 完整实现printUtf8函数，支持中文显示
-- 基于ComputerCraft UTF-8显示原理
function printUtf8(text, fgColor, bgColor)
    -- 保存当前颜色设置
    local oldFg = term.getTextColor()
    local oldBg = term.getBackgroundColor()
    
    -- 设置新颜色
    if fgColor then term.setTextColor(fgColor) end
    if bgColor then term.setBackgroundColor(bgColor) end
    
    -- 处理UTF-8字符
    local i = 1
    while i <= #text do
        local c = text:sub(i, i)
        local byte = string.byte(c)
        
        if byte < 128 then
            -- ASCII字符，直接输出
            term.write(c)
            i = i + 1
        else
            -- UTF-8字符，处理多字节
            local length
            if byte >= 0xC0 and byte < 0xE0 then
                length = 2
            elseif byte >= 0xE0 and byte < 0xF0 then
                length = 3
            elseif byte >= 0xF0 then
                length = 4
            end
            
            if length then
                local utf8char = text:sub(i, i + length - 1)
                -- 尝试直接输出UTF-8字符
                term.write(utf8char)
                i = i + length
            else
                -- 无法识别的字符，跳过
                i = i + 1
            end
        end
    end
    
    -- 恢复原颜色设置
    term.setTextColor(oldFg)
    term.setBackgroundColor(oldBg)
end
--搜索
server_url = "https://api.qijieya.cn/meting/"
-- 网易云音乐官方搜索API
netease_search_url = "https://music.163.com/api/search/get/web"

-- URL编码函数（处理中文搜索）
function urlEncode(str)
    local result = ""
    for i = 1, #str do
        local byte = string.byte(str, i)
        if (byte >= 48 and byte <= 57) or  -- 0-9
           (byte >= 65 and byte <= 90) or  -- A-Z
           (byte >= 97 and byte <= 122) or -- a-z
           byte == 45 or byte == 95 or byte == 46 or byte == 126 then -- - _ . ~
            result = result .. string.char(byte)
        elseif byte == 32 then
            result = result .. "+"
        else
            -- UTF-8编码
            if byte < 128 then
                result = result .. string.format("%%%02X", byte)
            else
                -- 处理多字节UTF-8字符
                local bytes = {}
                if byte >= 0xC0 and byte < 0xE0 then
                    table.insert(bytes, byte)
                    if i + 1 <= #str then
                        table.insert(bytes, string.byte(str, i + 1))
                        i = i + 1
                    end
                elseif byte >= 0xE0 and byte < 0xF0 then
                    table.insert(bytes, byte)
                    if i + 2 <= #str then
                        table.insert(bytes, string.byte(str, i + 1))
                        table.insert(bytes, string.byte(str, i + 2))
                        i = i + 2
                    end
                elseif byte >= 0xF0 then
                    table.insert(bytes, byte)
                    if i + 3 <= #str then
                        table.insert(bytes, string.byte(str, i + 1))
                        table.insert(bytes, string.byte(str, i + 2))
                        table.insert(bytes, string.byte(str, i + 3))
                        i = i + 3
                    end
                end
                for _, b in ipairs(bytes) do
                    result = result .. string.format("%%%02X", b)
                end
            end
        end
    end
    return result
end

-- 获取歌曲信息的辅助函数
function getSongInfo(song_id, info_type)
    -- 使用pcall包裹HTTP请求，防止崩溃
    local success, http_response_or_error = pcall(http.get, server_url.."?type="..info_type.."&id="..song_id)
    if success then
        local http = http_response_or_error
        if http then
            local result = http.readAll()
            http.close()
            if result and result ~= "" and result ~= "error" then
                return result
            end
        end
    end
    return nil
end

-- 刷新播放列表显示
-- 简化版本，不再需要这个函数，直接在Search中处理显示
function refreshPlaylistDisplay(GUI_in, songs_table, current_page, has_more)
    -- 调用Search函数重新请求当前页数据，简化逻辑
    Search(_G.playlist_pagination.playlist_id, GUI_in, "playlist")
end

-- 使用网易云音乐官方API搜索歌曲
function searchNeteaseMusic(keyword, limit)
    limit = limit or 20  -- 默认返回20条结果
    local encoded_keyword = urlEncode(keyword)
    -- 构建搜索URL：https://music.163.com/api/search/get/web?csrf_token=hlpretag=&hlposttag=&s={keyword}&type=1&offset=0&total=true&limit={limit}
    local search_api_url = netease_search_url .. "?csrf_token=hlpretag=&hlposttag=&s=" .. encoded_keyword .. "&type=1&offset=0&total=true&limit=" .. tostring(limit)
    
    -- 使用pcall包裹HTTP请求，防止崩溃
    local success, http_response_or_error = pcall(http.get, search_api_url)
    if success then
        local http_response = http_response_or_error
        if http_response then
            local response_code = http_response.getResponseCode()
            if response_code == 200 then
                local json_str = http_response.readAll()
                http_response.close()
                
                if json_str and json_str ~= "" and json_str ~= "error" then
                    -- 检查返回的数据是否是加密的（result字段是字符串而不是对象）
                    local parse_success, result = pcall(textutils.unserialiseJSON, json_str)
                    if parse_success and result then
                        -- 检查result字段是否是加密字符串
                        if type(result.result) == "string" then
                            -- 如果result是加密字符串，说明需要解密
                            -- 这种情况下可能需要使用代理API或解密库
                            -- 暂时返回nil，让调用者知道需要处理
                            return nil
                        elseif type(result.result) == "table" and result.result.songs then
                            -- 返回的是解密后的JSON数据
                            return result
                        end
                    end
                end
            else
                http_response.close()
            end
        end
    end
    
    return nil
end

function Search(input_str,GUI_in,api,is_load_more)
    -- 检查输入是否有效
    if not input_str or input_str == "" then
        -- 清空显示
        if play_lib_F then play_lib_F:remove() end
        play_lib_F = GUI_in[3]:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h"):setBackground(colors.white)
        play_lib_F:addLabel():setText("No content found"):setPosition(2, 2)
        return
    end
    
    -- 每次请求都清空现有数据，重新获取当前页数据
    Search_table = {}
    
    while true do
        kg_a=false
        if api=="search" then
            -- 判断输入是数字（ID）还是字符串（歌曲名）
            local is_numeric = true
            for i = 1, #input_str do
                local byte = string.byte(input_str, i)
                if byte < 48 or byte > 57 then
                    is_numeric = false
                    break
                end
            end
            
            if is_numeric and #input_str > 0 then
                -- 输入的是歌曲ID，使用原有逻辑
                local song_id = input_str
                local song_name = getSongInfo(song_id, "name") or "Unknown Song"
                local artist_name = getSongInfo(song_id, "artist") or "Unknown Artist"
                
                if song_name and song_name ~= "Unknown Song" then
                    kg_a = true
                    local out_table = {["id"] = song_id, ["name"] = song_name, ["artists_id"] = 0, ["artists_name"] = artist_name}
                    Search_table[1] = out_table
                end
            else
                -- 输入的是歌曲名，使用搜索API
                if #input_str > 0 then
                    local search_result = searchNeteaseMusic(input_str, 20)
                    -- 官方API返回格式：{"result":{"songs":[...],"songCount":300},"code":200}
                    if search_result and search_result.result and search_result.result.songs and #search_result.result.songs > 0 then
                        kg_a = true
                        for index, song in ipairs(search_result.result.songs) do
                            local song_id = song.id or song["id"]
                            local song_name = song.name or song["name"] or "Unknown Song"
                            local artists = song.artists or song["artists"] or {}
                            local artist_name = "Unknown Artist"
                            local artist_id = 0
                            if #artists > 0 then
                                artist_name = artists[1].name or artists[1]["name"] or "Unknown Artist"
                                artist_id = artists[1].id or artists[1]["id"] or 0
                            end
                            local out_table = {
                                ["id"] = song_id,
                                ["name"] = song_name,
                                ["artists_id"] = artist_id,
                                ["artists_name"] = artist_name
                            }
                            Search_table[index] = out_table
                        end
                    elseif search_result and search_result.songs and #search_result.songs > 0 then
                        -- 处理直接返回songs数组的格式（备用）
                        kg_a = true
                        for index, song in ipairs(search_result.songs) do
                            local song_id = song.id or song["id"]
                            local song_name = song.name or song["name"] or "Unknown Song"
                            local artists = song.artists or song["artists"] or {}
                            local artist_name = "Unknown Artist"
                            local artist_id = 0
                            if #artists > 0 then
                                artist_name = artists[1].name or artists[1]["name"] or "Unknown Artist"
                                artist_id = artists[1].id or artists[1]["id"] or 0
                            end
                            local out_table = {
                                ["id"] = song_id,
                                ["name"] = song_name,
                                ["artists_id"] = artist_id,
                                ["artists_name"] = artist_name
                            }
                            Search_table[index] = out_table
                        end
                    end
                end
            end
        elseif api=="playlist" then
            -- 使用新的歌单API：https://apis.netstart.cn/music/playlist/track/all?id={歌单ID}&limit=5&offset=1
            if #input_str > 0 then
                local playlist_id = input_str
                -- 保存播放列表ID用于后续分页加载
                _G.playlist_pagination.playlist_id = playlist_id
                
                -- 计算分页参数
                local limit = 10
                local offset = _G.playlist_pagination.current_page * limit
                
                -- 如果正在加载，防止重复请求
                if _G.playlist_pagination.loading then
                    break
                end
                _G.playlist_pagination.loading = true
                
                local playlist_api_url = "https://apis.netstart.cn/music/playlist/track/all?id=" .. playlist_id .. "&limit=" .. limit .. "&offset=" .. offset
                
                -- 使用pcall包裹HTTP请求，防止崩溃
                local success, http_response_or_error = pcall(http.get, playlist_api_url)
                if success then
                    local http_response = http_response_or_error
                    if http_response then
                        local response_code = http_response.getResponseCode()
                        if response_code == 200 then
                            local json_str = http_response.readAll()
                            http_response.close()
                            
                            if json_str and json_str ~= "" and json_str ~= "error" then
                                local parse_success, playlist_data = pcall(textutils.unserialiseJSON, json_str)
                                if parse_success and playlist_data and type(playlist_data) == "table" and playlist_data.songs then
                                    kg_a = true
                                    _G.playlist_pagination.loading = false
                                    
                                    -- 检查是否还有更多数据
                                    if #playlist_data.songs < limit then
                                        _G.playlist_pagination.has_more = false
                                    else
                                        _G.playlist_pagination.has_more = true
                                    end
                                    
                                    -- 解析歌单数据，格式：{"songs":[{"name":"...","id":"...","ar":[{"name":"..."}],...},...]}                
                                    -- 直接替换当前页数据，不追加
                                    for index, song in ipairs(playlist_data.songs) do
                                        local song_id = song.id or song["id"]
                                        local song_name = song.name or song["name"] or "Unknown Song"
                                        local artist_name = "Unknown Artist"
                                        
                                        -- 获取艺术家名称
                                        local artists = song.ar or song["ar"] or song.artists or song["artists"] or {}
                                        if #artists > 0 then
                                            artist_name = artists[1].name or artists[1]["name"] or "Unknown Artist"
                                        end
                                        
                                        if song_id then
                                            local out_table = {
                                                ["id"] = song_id,
                                                ["name"] = song_name,
                                                ["artists_id"] = 0,
                                                ["artists_name"] = artist_name
                                            }
                                            Search_table[index] = out_table
                                        end
                                    end
                                else
                                    _G.playlist_pagination.loading = false
                                end
                            else
                                _G.playlist_pagination.loading = false
                            end
                        else
                            http_response.close()
                            _G.playlist_pagination.loading = false
                        end
                    else
                        _G.playlist_pagination.loading = false
                    end
                else
                    _G.playlist_pagination.loading = false
                    -- HTTP请求失败，不处理，防止崩溃
                end
            end
        end
        if kg_a then
            a=2
            if play_lib_F then play_lib_F:remove() end
            play_lib_F = GUI_in[3]:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h"):setBackground(colors.white)
            
            -- 创建歌曲列表容器（可滚动）
            local songs_container = play_lib_F:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h - 1"):setBackground(colors.white):setScrollable()
            
            -- 添加分页按钮
            -- 上一页按钮
            local prevpage_button = play_lib_F:addButton():setPosition("parent.w/2 - 15", "parent.h"):setSize(5, 1):setText("Prev"):setForeground(colors.white):setBackground(colors.orange):hide()
            -- 下一页按钮
            local nextpage_button = play_lib_F:addButton():setPosition("parent.w/2 + 10", "parent.h"):setSize(5, 1):setText("Next"):setForeground(colors.white):setBackground(colors.blue):hide()
            
            -- 只在歌单搜索时显示分页控件
            if api == "playlist" then
                -- 添加页码显示（可点击跳页）
                local page_info = play_lib_F:addButton():setPosition("parent.w/2 - 3", "parent.h"):setSize(7, 1):setText("page " .. (_G.playlist_pagination.current_page + 1)):setForeground(colors.white):setBackground(colors.gray):onClick(function()
                    -- 创建页码输入对话框
                    local dialog = play_lib_F:addFrame():setPosition("parent.w/2 - 10", "parent.h/2 - 2"):setSize(20, 5):setBackground(colors.gray):setForeground(colors.white):setZIndex(10)
                    dialog:addLabel():setText("Enter page:"):setPosition(2, 1):setForeground(colors.white):setBackground(colors.gray)
                    
                    -- 输入框
                    local page_input = dialog:addInput():setPosition(2, 2):setSize(16, 1):setForeground(colors.black):setBackground(colors.white):onKey(function(self, event, key)
                        -- 支持Enter键确认
                        if key == 257 then
                            local page_num = tonumber(self:getValue())
                            if page_num and page_num > 0 then
                                -- 转换为0-based索引
                                _G.playlist_pagination.current_page = page_num - 1
                                -- 清除当前显示
                                if play_lib_F then play_lib_F:remove() end
                                -- 重新加载指定页码
                                Search(_G.playlist_pagination.playlist_id, GUI_in, "playlist")
                            end
                            -- 关闭对话框
                            dialog:remove()
                        end
                    end)
                    
                    -- 确认按钮
                    local confirm_btn = dialog:addButton():setPosition(2, 4):setSize(7, 1):setText("Confirm"):setForeground(colors.white):setBackground(colors.green):onClick(function()
                        local page_num = tonumber(page_input:getValue())
                        if page_num and page_num > 0 then
                            -- 转换为0-based索引
                            _G.playlist_pagination.current_page = page_num - 1
                            -- 清除当前显示
                            if play_lib_F then play_lib_F:remove() end
                            -- 重新加载指定页码
                            Search(_G.playlist_pagination.playlist_id, GUI_in, "playlist")
                        end
                        -- 关闭对话框
                        dialog:remove()
                    end)
                    
                    -- 取消按钮
                    local cancel_btn = dialog:addButton():setPosition(11, 4):setSize(7, 1):setText("Cancel"):setForeground(colors.white):setBackground(colors.red):onClick(function()
                        dialog:remove()
                    end)
                end)
                
                -- 显示上一页按钮（只有在非第一页时显示）
                if _G.playlist_pagination.current_page > 0 then
                    prevpage_button:show()
                    prevpage_button:onClick(function() 
                        -- 加载上一页
                        if _G.playlist_pagination.current_page > 0 then
                            _G.playlist_pagination.current_page = _G.playlist_pagination.current_page - 1
                            -- 重新请求上一页数据
                            Search(_G.playlist_pagination.playlist_id, GUI_in, "playlist")
                        end
                    end)
                end
                
                -- 显示下一页按钮
                if _G.playlist_pagination.has_more then
                    nextpage_button:show()
                    nextpage_button:onClick(function() 
                        -- 加载下一页
                        _G.playlist_pagination.current_page = _G.playlist_pagination.current_page + 1
                        Search(_G.playlist_pagination.playlist_id, GUI_in, "playlist")
                    end)
                end
            end
            
            for index, value in ipairs(Search_table) do
                local frame = songs_container:addFrame():setPosition(2, a):setSize("parent.w-2", 3):setBackground(colors.lightBlue):onClick(function() 
                    -- 如果正在播放，先停止当前播放
                    if play_data_table["play"] or _G.music168_current_playing_id then 
                        -- 设置停止标志并发送停止事件
                        _G.Playopen = false
                        _G.music168_playopen = false
                        _G.music168_current_playing_id = nil
                        play_data_table["play"] = false
                        -- 发送停止事件，这会中断parallel.waitForAny中的speaker_thread
                        os.queueEvent("music168_play_stop")
                        -- 停止扬声器
                        shell.run(mypath.."/speakerlib.lua stop")
                        -- 短暂等待，确保停止事件被处理
                        sleep(0.1)
                    end
                    -- 显示播放界面
                    play_Gui_UP:play() 
                    play_GUI_state = true 
                    main[1]:disable()
                    -- 传递当前页面的所有歌曲，以便playtable显示完整列表
                    playmusic(value["name"], value["id"], Search_table, index)
                end)
                local textf = frame:addFrame():setPosition(1, 1):setSize("parent.w", 2)
                textf:addProgram():setPosition(1, 1):setSize("parent.w + 200", 2):execute(function ()
                    term.setBackgroundColor(colors.lightGray)
                    term.clear()
                    printUtf8(value["name"],colors.white,colors.lightGray)
                end):injectEvent("char", false, "w"):disable()
                local song_name = value["name"] or "Unknown Song"
                local song_id = value["id"] or "Unknown ID"
                local artists_name = value["artists_name"] or "Unknown Artist"
                frame:addLabel():setText("🎵 "..song_name.."  [ID:"..song_id.."]  歌手:"..artists_name):setPosition(1, 3):setForeground(colors.black)
                a=a+4
            end
            break;
        else
            frame = GUI_in[3]:addFrame():setPosition(2, 2):setSize("parent.w-2", 3):setBackground(colors.lightBlue)
            frame:addLabel():setText("No content found"):setPosition(1, 1)
            break;
        end
    end
end

play_Gui[4]:onError(function(self, event, err)

end)

play_Gui[4]:onDone(function()

end)

-----------------------------------------------------------------渲染界面阶段-------------------------------------------------------------------------------------------------
GUI = {
    {
        sub["UI"][1]:addInput():setPosition(2,1):setSize("parent.w-3", 1):setForeground(colors.gray):setBackground(colors.lightGray):onKey(function(self, event, key) if key == 257 then local input = self:getValue() if input and input ~= "" then Search(input,GUI[1],"search") end end end):onClick(function(self, event, button, x, y) if button == 2 then self:setValue("") end end),
        sub["UI"][1]:addButton():setPosition("parent.w-1",1):setSize(1, 1):setText("Q"):onClick(function() Search(GUI[1][1]:getValue(),GUI[1],"search") end):setForeground(colors.white):setBackground(colors.lightGray),
        sub["UI"][1]:addFrame():setPosition(1, 3):setSize("parent.w", "parent.h -3"):setBackground(colors.white)
    },
    {
        sub["UI"][4]:addInput():setPosition(2,1):setSize("parent.w-3", 1):setForeground(colors.gray):setBackground(colors.lightGray):onKey(function(self, event, key) if key == 257 then local input = self:getValue() if input and input ~= "" then Search(input,GUI[2],"playlist", false) end end end):onClick(function(self, event, button, x, y) if button == 2 then self:setValue("") end end),
        sub["UI"][4]:addButton():setPosition("parent.w-1",1):setSize(1, 1):setText("Q"):onClick(function() Search(GUI[2][1]:getValue(),GUI[2],"playlist", false) end):setForeground(colors.white):setBackground(colors.lightGray),
        sub["UI"][4]:addFrame():setPosition(1, 3):setSize("parent.w", "parent.h -3"):setBackground(colors.white)
    },
}

function thread2()
    while true do
        local screenWidth, _ = term.getSize()
        
        -- 处理用户拖动进度条设置播放位置
        w,h = term.getSize()
        if w >= 100 and h >= 30 then px = "--12px" else px = "--8px" end

        if play_Gui[18]:getIndex() ~= 1 then
            local sliderValue = play_Gui[18]:getValue() or 0
            _G.setPlay = _G.getPlaymax * (sliderValue / 100)
            play_Gui[18]:setIndex(1)
        end
        
        sleep(0.1)
        
        -- 更新播放进度条和时间显示
        -- speakerlib会自动更新_G.getPlay和_G.getPlaymax
        if _G.getPlay ~= nil and _G.getPlaymax ~= nil and _G.getPlaymax > 0 then 
            play_Gui[10]:setProgress((_G.getPlay / _G.getPlaymax) * 100)
            
            -- 更新当前播放时间显示
            local current = _G.getPlay or 0
            local total = _G.getPlaymax or 0
            local currentTimeStr = string.format("%02d:%02d", math.floor(current / 60), current % 60)
            local totalTimeStr = string.format("%02d:%02d", math.floor(total / 60), total % 60)
            
            play_Gui[11]:setText(currentTimeStr)     -- 当前播放时间
            play_Gui[12]:setText(totalTimeStr)       -- 总时间
            
            -- 检测播放完成，自动播放下一首（循环播放）
            if play_data_table["play"] and play_data_table["play_table"] and 
               #play_data_table["play_table"] > 0 and play_data_table["play_table_index"] > 0 then
                -- 检查是否播放完成（当前时间接近总时间，允许1秒误差）
                if current >= total - 1 and total > 0 then
                    -- 播放完成，自动播放下一首
                    local current_index = play_data_table["play_table_index"]
                    local next_index = current_index + 1
                    
                    -- 如果超过列表长度，根据循环模式决定
                    if next_index > #play_data_table["play_table"] then
                        if _G.play_mode_loop then
                            -- 循环模式：播放第一首
                            next_index = 1
                        else
                            -- 非循环模式：停止播放
                            play_data_table["play"] = false
                            _G.music168_playopen = false
                            _G.music168_music_id = nil
                            _G.music168_current_playing_id = nil
                        end
                    end
                    
                    -- 如果还有下一首，播放它
                    if next_index <= #play_data_table["play_table"] then
                        local next_song = play_data_table["play_table"][next_index]
                        if next_song then
                            -- 停止当前播放
                            _G.Playopen = false
                            _G.music168_playopen = false
                            shell.run(mypath.."/speakerlib.lua stop")
                            os.queueEvent("music168_play_stop")
                            sleep(0.2)
                            -- 播放下一首
                            playmusic(next_song["name"], next_song["id"], play_data_table["play_table"], next_index)
                        end
                    end
                end
            end
        end
        
        -- 更新播放按钮状态
        if play_data_table["play"]== true then
            play_Gui[15]:setText("II")
            play_column_Gui[2]:setText("II")
            sub["BF"][2]:show()
        else
            play_Gui[15]:setText("I>")
            play_column_Gui[2]:setText("I>")
        end
        
        -- 更新循环播放模式按钮显示
        if _G.play_mode_loop then
            play_Gui[13]:setBackground(colors.green)  -- 循环模式：绿色
        else
            play_Gui[13]:setBackground(colors.red)  -- 单曲模式：红色
        end
        
        -- 处理播放列表选择变化
        if play_data_table["play_table_index"] ~= 0 then
            if play_data_table["play_table_index"] ~= play_table_Gui[3]:getItemIndex() then
                index = play_table_Gui[3]:getItemIndex()
                if play_data_table["play"] then 
                    -- 停止当前播放
                    shell.run(mypath.."/speakerlib.lua stop")
                    play_data_table["play"]=false 
                end 
                -- 播放新选择的歌曲
                playmusic(play_data_table["play_table"][index]["name"],play_data_table["play_table"][index]["id"],play_data_table["play_table"],index)
            end
        end
    end
end

function paste()
    while true do
        local event, text = os.pullEvent("paste")
        GUI[1][1]:setValue(text)
        GUI[2][1]:setValue(text)
    end
end

function speakerp()
    function speaker_thread()
        if _G.music168_music_id then
            local current_music_id = _G.music168_music_id
            
            -- 如果已经有音乐在播放，先停止
            if _G.music168_current_playing_id and _G.music168_current_playing_id ~= current_music_id then
                _G.Playopen = false
                shell.run(mypath.."/speakerlib.lua stop")
                sleep(0.2)
            end
            
            -- 检查是否仍然要播放这个音乐（可能在停止过程中被取消了）
            if _G.music168_playopen and _G.music168_music_id == current_music_id then
                -- 标记当前正在播放的音乐ID
                _G.music168_current_playing_id = current_music_id
                
                -- 重置播放状态
                _G.getPlay = 0
                _G.getPlaymax = 0
                _G.Playopen = true
                _G.Playstop = false
                
                -- 显示歌词
                play_Gui[4]:stop()
                play_Gui[4]:execute(function ()
                    shell.run(mypath.."/MusicLyrics.lua "..server_url.."?type=lrc&id="..current_music_id.." "..px)
                end)
                play_Gui[4]:injectEvent("char","w")
                sleep(0.1)
                
                -- 直接构建音乐URL并播放
                local music_url = server_url.."?type=url&id="..current_music_id
                
                -- 使用shell.run直接调用speakerlib播放
                shell.run(mypath.."/speakerlib.lua play "..music_url)
                
                -- 播放完成后检查是否自动跳转下一首
                if _G.music168_playopen and _G.music168_music_id == current_music_id then
                    -- 检查是否有播放列表且需要循环播放
                    if play_data_table["play_table"] and #play_data_table["play_table"] > 0 and 
                       play_data_table["play_table_index"] > 0 then
                        -- 有播放列表，自动播放下一首
                        local current_index = play_data_table["play_table_index"]
                        local next_index = current_index + 1
                        
                        -- 如果超过列表长度，根据循环模式决定
                        if next_index > #play_data_table["play_table"] then
                            if _G.play_mode_loop then
                                -- 循环模式：播放第一首
                                next_index = 1
                            else
                                -- 非循环模式：停止播放
                                _G.music168_playopen = false
                                _G.music168_music_id = nil
                                _G.music168_current_playing_id = nil
                                play_data_table["play"] = false
                                return
                            end
                        end
                        
                        -- 播放下一首
                        local next_song = play_data_table["play_table"][next_index]
                        if next_song then
                            sleep(0.3)  -- 短暂延迟，确保状态更新
                            playmusic(next_song["name"], next_song["id"], play_data_table["play_table"], next_index)
                            return
                        end
                    end
                    
                    -- 没有播放列表或播放完成，停止播放
                    _G.music168_playopen = false
                    _G.music168_music_id = nil
                    _G.music168_current_playing_id = nil
                end
            end
        end
    end
    
    function while_thread() 
        os.pullEvent("music168_play_stop")
        -- 停止播放
        _G.Playopen = false
        shell.run(mypath.."/speakerlib.lua stop")
        _G.getPlay = 0
        _G.getPlaymax = 0
        _G.music168_current_playing_id = nil
        play_Gui[4]:stop()
    end
    
    while true do
        if _G.music168_playopen then 
            -- 使用parallel.waitForAny，这样当收到停止事件时可以立即中断播放线程
            parallel.waitForAny(speaker_thread, while_thread)
            sleep(0.1)
        end
        sleep(0.01)
    end
end

function gc()
    while true do
        play_Gui[4]:injectEvent(os.pullEvent())
    end
    
end
_G.music168_playopen = false os.queueEvent("music168_play_stop")
-----------------------------------------------------------------启动循环渲染器-----------------------------------------------------------------------------------------------
parallel.waitForAll(basalt.autoUpdate, thread2, paste, speakerp,gc)
-----------------------------------------------------------------以下结束-----------------------------------------------------------------------------------------------------
