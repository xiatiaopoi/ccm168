-- 测试新API的脚本
local server_url = "https://api.qijieya.cn/meting/"

-- 测试获取歌曲信息
local function test_song_api(song_id)
    print("Testing song API with ID: " .. song_id)
    local http = http.get(server_url .. "?type=song&id=" .. song_id)
    if http then
        local json_str = http.readAll()
        print("Response:")
        print(json_str)
        local table = textutils.unserialiseJSON(json_str)
        if table then
            print("Parsed data:")
            for k, v in pairs(table) do
                print("  " .. k .. ": " .. tostring(v))
            end
        end
    else
        print("API request failed")
    end
end

-- 测试获取音乐直链
local function test_url_api(song_id)
    print("\nTesting URL API with ID: " .. song_id)
    local http = http.get(server_url .. "?type=url&id=" .. song_id)
    if http then
        local json_str = http.readAll()
        print("Response:")
        print(json_str)
        local table = textutils.unserialiseJSON(json_str)
        if table and table["url"] then
            print("Music URL: " .. table["url"])
        end
    else
        print("API request failed")
    end
end

-- 运行测试
test_song_api("1965026388")
test_url_api("1965026388")
