-- 导入必要的库
local component = require("component")
local event = require("event")
local parallel = require("parallel")

-- 检查是否有调制解调器
if not component.isAvailable("modem") then
    print("请确保调制解调器已连接")
    return
end

-- 获取调制解调器对象
local modem = component.modem

-- 打开一个频率（例如：1234）
local frequency = 1234
modem.open(frequency)

print("调制解调器已打开，频率：" .. frequency)
print("使用以下命令发送消息：")
print("send <消息内容>")
print("输入 'exit' 退出程序")

-- 控制变量
local running = true

-- 发送消息函数
local function sendMessage(message)
    if message and message ~= "" then
        -- 使用 modem.transmit 发送消息
        -- 参数：目标频率，源端口，目标端口，消息内容
        modem.transmit(frequency, 1, 1, message)
        print("已发送：" .. message)
    end
end

-- 监听消息的函数
local function listenForMessages()
    while running do
        -- 等待 modem_message 事件，超时1秒以便检查running状态
        local eventData = {event.pull(1, "modem_message")}
        if eventData[1] == "modem_message" then
            local _, _, senderAddress, senderPort, _, message = table.unpack(eventData)
            if message then
                print("\n收到消息：")
                print("发送者地址：" .. senderAddress)
                print("发送者端口：" .. senderPort)
                print("消息内容：" .. message)
                print("\n输入命令：")
            end
        end
    end
end

-- 处理用户输入的函数
local function handleUserInput()
    while running do
        io.write("输入命令：")
        local input = io.read()
        
        if input == "exit" then
            running = false
            print("正在退出程序...")
        elseif input:sub(1, 5) == "send " then
            local message = input:sub(6)
            sendMessage(message)
        else
            print("无效命令，请使用：")
            print("send <消息内容>")
            print("exit")
        end
    end
end

-- 使用parallel库并行运行监听和输入处理
parallel.waitForAny(
    listenForMessages,
    handleUserInput
)

-- 关闭调制解调器
modem.close(frequency)
print("程序已退出")
