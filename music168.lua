-----------------------------------------------------------------系统启动阶段-------------------------------------------------------------------------------------------------
--*获取程序所在目录

local mypath = "/"..fs.getDir(shell.getRunningProgram())
if not fs.exists(mypath.."/lib/basalt.lua") then shell.run("wget https://git.liulikeji.cn/GitHub/Basalt/releases/download/v1.6.6/basalt.lua "..mypath.."/lib/basalt.lua") end
if not fs.exists(mypath.."/speakerlib.lua") then shell.run("wget https://git.liulikeji.cn/xingluo/ComputerCraft-Music168-Player/raw/branch/main/speakerlib.lua "..mypath.."/speakerlib.lua") end
if not fs.exists(mypath.."/MusicLyrics.lua") then shell.run("wget https://git.liulikeji.cn/xingluo/ComputerCraft-Music168-Player/raw/branch/main/MusicLyrics.lua "..mypath.."/MusicLyrics.lua") end

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
    sub["BF"][1]:addButton():setPosition(3, "parent.h - 0"):setSize(3, 1):setText("=O="):onClick(function()  end):setForeground(colors.white):setBackground(colors.red),
    sub["BF"][1]:addButton():setPosition("parent.w /2 - 4","parent.h - 0"):setSize(2, 1):setText("|\17"):onClick(function() play_set_1() end):setForeground(colors.white):setBackground(colors.red),
    sub["BF"][1]:addButton():setPosition("parent.w / 2 ", "parent.h - 0"):setSize(2, 1):setText("I>"):onClick(function()  if play_data_table["play"] then _G.Playstop = true play_data_table["play"]=false else play_data_table["play"]=true end end):setForeground(colors.white):setBackground(colors.red),
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
    sub["play_table"][1]:addLabel():setText("PlyaTable"):setPosition(1,1):setForeground(colors.white),
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
_G.Playopen = false
_G.getPlay = 0
_G.getPlaymax = 0
_G.setPlay = nil
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
    -- 完全停止当前播放
    shell.run(mypath.."/speakerlib.lua stop")
    
    -- 停止当前歌词显示
    play_Gui[4]:stop()
    
    -- 重置所有播放状态
    _G.music168_playopen = false
    _G.music168_music_id = nil
    _G.Playopen = false
    _G.getPlay = 0
    _G.getPlaymax = 0
    _G.Playstop = false
    play_data_table["play"] = false
    
    -- 设置新的播放状态
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

-- 获取歌曲信息的辅助函数
function getSongInfo(song_id, info_type)
    local http = http.get(server_url.."?type="..info_type.."&id="..song_id)
    if http then
        local result = http.readAll()
        if result and result ~= "" and result ~= "error" then
            return result
        end
    end
    return nil
end

function Search(input_str,GUI_in,api)
    Search_table = {}
    while true do
        kg_a=false
        if api=="search" then
            -- 根据用户要求，搜索框直接输入歌曲ID
            local song_id = input_str
            -- 获取歌曲名
            local song_name = getSongInfo(song_id, "name") or "Unknown Song"
            -- 获取歌手名
            local artist_name = getSongInfo(song_id, "artist") or "Unknown Artist"
            
            if song_name and song_name ~= "Unknown Song" then
                kg_a = true
                -- 构建搜索结果
                local out_table = {["id"] = song_id, ["name"] = song_name, ["artists_id"] = 0, ["artists_name"] = artist_name}
                Search_table[1] = out_table
            end
        elseif api=="playlist" then
            -- 歌单功能暂时保留原有逻辑，后续可以根据新API调整
            kg_a = false
        end
        if kg_a then
            a=2
            if play_lib_F then play_lib_F:remove() end
            play_lib_F = GUI_in[3]:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h"):setBackground(colors.white):setScrollable()
            for index, value in ipairs(Search_table) do
                local frame = play_lib_F:addFrame():setPosition(2, a):setSize("parent.w-2", 4):setBackground(colors.lightBlue):onClick(function() 
                    -- 完全停止当前播放
                    shell.run(mypath.."/speakerlib.lua stop")
                    
                    -- 停止当前歌词显示
                    play_Gui[4]:stop()
                    
                    -- 重置所有播放状态
                    _G.music168_playopen = false
                    _G.music168_music_id = nil
                    _G.Playopen = false
                    _G.getPlay = 0
                    _G.getPlaymax = 0
                    _G.Playstop = false
                    play_data_table["play"] = false
                    
                    -- 播放新音乐
                    play_Gui_UP:play()
                    play_GUI_state = true
                    main[1]:disable()
                    playmusic(value["name"], value["id"], Search_table, index)
                end)
                local textf = frame:addFrame():setPosition(1, 1):setSize("parent.w", 3)
                textf:addProgram():setPosition(1, 1):setSize("parent.w + 200", 4):execute(function ()
                    term.setBackgroundColor(colors.lightGray)
                    term.clear()
                    printUtf8(value["name"],colors.white,colors.lightGray)
                end):injectEvent("char", false, "w"):disable()
                local song_name = value["name"] or "Unknown Song"
                local song_id = value["id"] or "Unknown ID"
                local artists_name = value["artists_name"] or "Unknown Artist"
                frame:addLabel():setText("name:"..song_name.."  id:"..song_id.."  artists:"..artists_name):setPosition(1, 4)
                a=a+5
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
        sub["UI"][1]:addInput():setPosition(2,1):setSize("parent.w-3", 1):setForeground(colors.gray):setBackground(colors.lightGray),
        sub["UI"][1]:addButton():setPosition("parent.w-1",1):setSize(1, 1):setText("Q"):onClick(function() Search(GUI[1][1]:getValue(),GUI[1],"search") end):setForeground(colors.white):setBackground(colors.lightGray),
        sub["UI"][1]:addFrame():setPosition(1, 3):setSize("parent.w", "parent.h -3"):setBackground(colors.white)
    },
    {
        sub["UI"][4]:addInput():setPosition(2,1):setSize("parent.w-3", 1):setForeground(colors.gray):setBackground(colors.lightGray),
        sub["UI"][4]:addButton():setPosition("parent.w-1",1):setSize(1, 1):setText("Q"):onClick(function() Search(GUI[1][1]:getValue(),GUI[2],"playlist") end):setForeground(colors.white):setBackground(colors.lightGray),
        sub["UI"][4]:addFrame():setPosition(1, 3):setSize("parent.w", "parent.h -3"):setBackground(colors.white)
    },
}

function thread2()
    while true do
        local screenWidth, _ = term.getSize()
        
        -- 处理用户拖动进度条设置播放位置
        w,h = term.getSize()
        if w >= 100 and h >= 30 then px = "--12px" else px = "--8px" end

        -- 简化播放控制，移除复杂的进度条拖动处理
        
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
    -- 创建一个播放控制协程
    local play_coroutine = coroutine.create(function()
        while true do
            -- 等待播放请求
            local event, music_id = os.pullEvent("music168_play")
            
            if event == "music168_play" and music_id then
                -- 停止当前播放
                shell.run(mypath.."/speakerlib.lua stop")
                
                -- 显示歌词
                play_Gui[4]:stop()
                play_Gui[4]:execute(function ()
                    shell.run(mypath.."/MusicLyrics.lua "..server_url.."?type=lrc&id="..music_id.." "..px)
                end)
                play_Gui[4]:injectEvent("char","w")
                
                -- 播放音乐
                local music_url = server_url.."?type=url&id="..music_id
                print("Playing music with ID: "..music_id)
                print("Directly playing URL: "..music_url)
                
                -- 播放音乐
                shell.run(mypath.."/speakerlib.lua play "..music_url)
                
                -- 播放完成后重置状态
                if _G.music168_music_id == music_id then
                    _G.music168_music_id = nil
                end
            end
        end
    end)
    
    -- 启动协程
    coroutine.resume(play_coroutine)
    
    -- 主循环，处理播放请求
    while true do
        if _G.music168_playopen and _G.music168_music_id then
            -- 触发播放事件
            os.queueEvent("music168_play", _G.music168_music_id)
            
            -- 重置播放状态
            _G.music168_playopen = false
        end
        
        -- 等待一段时间，让其他事件有机会处理
        sleep(0.1)
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
