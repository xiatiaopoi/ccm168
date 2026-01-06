-- 简单的调制解调器通信示例
-- 展示如何发送和接收消息

local component = require("component")
local event = require("event")

-- 确保调制解调器已连接
if not component.isAvailable("modem") then
    print("错误：未检测到调制解调器")
    return
end

local modem = component.modem
local frequency = 5678

-- 打开频率
modem.open(frequency)

print("简单调制解调器示例")
print("频率：" .. frequency)
print("=" .. string.rep("-", 30) .. "=")

-- 发送消息示例
print("发送消息示例：")
modem.transmit(frequency, 1, 1, "你好，这是一条测试消息！")
print("已发送测试消息")

-- 接收消息示例
print("\n等待接收消息...")
print("（按Ctrl+C停止）")

while true do
    local _, _, from, port, _, message = event.pull("modem_message")
    if message then
        print("\n收到消息：")
        print("来自：" .. from)
        print("端口：" .. port)
        print("内容：" .. message)
        print("\n继续等待消息...")
    end
end
