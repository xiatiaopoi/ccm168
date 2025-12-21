-- dos.lua - DOS-like shell UI for CC:Tweaked
-- Features: header/status bar, scrollback, command line, dir/cd/type/run/cls/help/exit
-- Works on: CC:Tweaked computers (advanced or normal)

local term = term
local fs = fs
local shell = shell
local colors = colors
local keys = keys

-- ===== UI + state =====
local w, h = term.getSize()
local HEADER_H = 1
local STATUS_H = 1
local VIEW_TOP = HEADER_H + 1
local VIEW_BOTTOM = h - STATUS_H - 1 -- one line for input
local VIEW_H = VIEW_BOTTOM - VIEW_TOP + 1

local prompt = "C:\\>"
local cwd = shell.dir()

local scrollback = {}
local scroll = 0

local function clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

local function pushLine(s)
  -- wrap long lines
  s = tostring(s or "")
  local i = 1
  while i <= #s do
    table.insert(scrollback, s:sub(i, i + w - 1))
    i = i + w
  end
  if #s == 0 then table.insert(scrollback, "") end

  -- auto-scroll to bottom
  scroll = 0
end

local function setPromptFromDir()
  cwd = shell.dir()
  -- DOS-ish: show root as C:\, otherwise C:\path\...
  if cwd == "" then
    prompt = "C:\\>"
  else
    prompt = "C:\\" .. cwd:gsub("/", "\\") .. ">"
  end
end

local function drawHeader()
  if term.isColor() then
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
  else
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
  end
  term.setCursorPos(1, 1)
  local title = " DOS Shell (CC:Tweaked) "
  term.write(title .. string.rep(" ", math.max(0, w - #title)))
end

local function drawStatus(msg)
  msg = msg or ""
  if term.isColor() then
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.black)
  else
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
  end
  term.setCursorPos(1, h)
  local right = (" %d lines "):format(#scrollback)
  local left = " " .. msg
  local space = w - #left - #right
  if space < 1 then
    left = left:sub(1, w - #right - 1)
    space = 1
  end
  term.write(left .. string.rep(" ", space) .. right)
end

local function drawView()
  -- background for view
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  for y = VIEW_TOP, VIEW_BOTTOM do
    term.setCursorPos(1, y)
    term.write(string.rep(" ", w))
  end

  -- determine which lines to show based on scroll
  local total = #scrollback
  local lastIndex = total - scroll
  local firstIndex = lastIndex - VIEW_H + 1

  for row = 0, VIEW_H - 1 do
    local idx = firstIndex + row
    local line = scrollback[idx]
    if line then
      term.setCursorPos(1, VIEW_TOP + row)
      term.write(line)
    end
  end
end

local function drawInput(input, cursor)
  -- input line is h-1
  local y = h - 1
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.setCursorPos(1, y)
  term.write(string.rep(" ", w))
  term.setCursorPos(1, y)

  local shown = prompt .. input
  if #shown > w then
    -- show tail so cursor stays visible
    local start = #shown - w + 1
    shown = shown:sub(start)
  end

  term.write(shown)

  -- cursor position within whole shown text
  local curPos = #prompt + cursor + 1
  if #prompt + #input + 1 > w then
    -- shift if trimmed
    local trim = (#prompt + #input) - w
    curPos = curPos - trim
  end
  curPos = clamp(curPos, 1, w)
  term.setCursorPos(curPos, y)
  term.setCursorBlink(true)
end

local function redraw(statusMsg, input, cursor)
  w, h = term.getSize()
  VIEW_BOTTOM = h - STATUS_H - 1
  VIEW_H = VIEW_BOTTOM - VIEW_TOP + 1
  term.setCursorBlink(false)
  drawHeader()
  drawView()
  drawStatus(statusMsg)
  drawInput(input or "", cursor or 0)
end

-- ===== Command implementations =====
local function cmd_help()
  pushLine("Available commands:")
  pushLine("  dir / ls                List files")
  pushLine("  cd <path>               Change directory")
  pushLine("  type / cat <file>       Show file contents")
  pushLine("  run <program> [args..]  Run a program")
  pushLine("  cls                     Clear screen")
  pushLine("  pwd                     Show current dir")
  pushLine("  exit                    Quit this shell")
  pushLine("Tips: Use Up/Down for history. PageUp/PageDown to scroll.")
end

local function cmd_cls()
  scrollback = {}
  scroll = 0
end

local function listDir(path)
  local p = path and #path > 0 and shell.resolve(path) or shell.resolve(".")
  if not fs.exists(p) then
    pushLine("File Not Found: " .. tostring(path))
    return
  end
  if not fs.isDir(p) then
    pushLine("Not a directory: " .. tostring(path))
    return
  end

  local items = fs.list(p)
  table.sort(items, function(a,b) return a:lower() < b:lower() end)

  pushLine(" Directory of " .. (path and #path > 0 and path or "."))
  pushLine("")
  for _, name in ipairs(items) do
    local full = fs.combine(p, name)
    if fs.isDir(full) then
      pushLine(("<DIR>  %s"):format(name))
    else
      local size = fs.getSize(full)
      pushLine(("%6d %s"):format(size, name))
    end
  end
  pushLine("")
end

local function changeDir(path)
  if not path or #path == 0 then
    pushLine(shell.dir() == "" and "C:\\" or ("C:\\" .. shell.dir():gsub("/", "\\")))
    return
  end
  local resolved = shell.resolve(path)
  if fs.exists(resolved) and fs.isDir(resolved) then
    shell.setDir(resolved)
    setPromptFromDir()
  else
    pushLine("The system cannot find the path specified.")
  end
end

local function typeFile(path)
  if not path or #path == 0 then
    pushLine("Usage: type <file>")
    return
  end
  local resolved = shell.resolve(path)
  if not fs.exists(resolved) or fs.isDir(resolved) then
    pushLine("File not found: " .. path)
    return
  end
  local f = fs.open(resolved, "r")
  if not f then
    pushLine("Cannot open: " .. path)
    return
  end
  while true do
    local line = f.readLine()
    if line == nil then break end
    pushLine(line)
  end
  f.close()
end

local function runProgram(args)
  if #args < 1 then
    pushLine("Usage: run <program> [args..]")
    return
  end
  local prog = args[1]
  local resolved = shell.resolveProgram(prog) or shell.resolve(prog)
  if not resolved or not fs.exists(resolved) then
    pushLine("Bad command or file name: " .. prog)
    return
  end

  -- run inside this UI: capture prints by redirecting term? We'll just execute and let it draw after.
  -- Best compromise: temporarily restore the normal terminal, run, then redraw.
  term.setCursorBlink(false)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1,1)

  local ok, err = pcall(function()
    shell.run(prog, table.unpack(args, 2))
  end)

  pushLine("")
  if not ok then
    pushLine("Program error: " .. tostring(err))
  else
    pushLine("[Program finished]")
  end
end

local function splitArgs(line)
  -- basic splitting with quotes support: "a b" stays together
  local out = {}
  local i = 1
  while i <= #line do
    while i <= #line and line:sub(i,i):match("%s") do i = i + 1 end
    if i > #line then break end
    local c = line:sub(i,i)
    if c == '"' then
      local j = i + 1
      while j <= #line and line:sub(j,j) ~= '"' do j = j + 1 end
      table.insert(out, line:sub(i+1, j-1))
      i = j + 1
    else
      local j = i
      while j <= #line and not line:sub(j,j):match("%s") do j = j + 1 end
      table.insert(out, line:sub(i, j-1))
      i = j
    end
  end
  return out
end

local function execute(line)
  local args = splitArgs(line)
  local cmd = (args[1] or ""):lower()
  table.remove(args, 1)

  if cmd == "" then return true end

  if cmd == "help" or cmd == "?" then cmd_help()
  elseif cmd == "dir" or cmd == "ls" then listDir(args[1] or "")
  elseif cmd == "cd" then changeDir(args[1] or "")
  elseif cmd == "type" or cmd == "cat" then typeFile(args[1] or "")
  elseif cmd == "cls" then cmd_cls()
  elseif cmd == "pwd" then
    pushLine(shell.dir() == "" and "C:\\" or ("C:\\" .. shell.dir():gsub("/", "\\")))
  elseif cmd == "run" then
    runProgram(args)
  elseif cmd == "exit" then
    return false
  else
    -- allow direct program run like DOS: try shell.run on unknown cmd
    local prog = shell.resolveProgram(cmd)
    if prog then
      runProgram({cmd, table.unpack(args)})
    else
      pushLine("Bad command or file name.")
    end
  end

  return true
end

-- ===== Input handling with history =====
local history = {}
local histIndex = 0

local function addHistory(line)
  if line and #line > 0 then
    if history[#history] ~= line then
      table.insert(history, line)
    end
  end
  histIndex = #history + 1
end

local function getHistory(i)
  if i < 1 or i > #history then return nil end
  return history[i]
end

-- ===== Main loop =====
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
setPromptFromDir()
pushLine("Microsoft(R) ComputerCraft DOS Shell")
pushLine("Type 'help' for commands.")
pushLine("")

local input = ""
local cursor = 0
local statusMsg = "Ready"

redraw(statusMsg, input, cursor)

local running = true
while running do
  local e, p1 = os.pullEvent()

  if e == "term_resize" then
    redraw(statusMsg, input, cursor)

  elseif e == "mouse_scroll" then
    -- p1 is direction: 1 down, -1 up
    local maxScroll = math.max(0, #scrollback - VIEW_H)
    scroll = clamp(scroll + p1, 0, maxScroll)
    redraw(statusMsg, input, cursor)

  elseif e == "key" then
    local k = p1
    if k == keys.enter then
      pushLine(prompt .. input)
      addHistory(input)
      local ok = execute(input)
      if not ok then
        running = false
      end
      input = ""
      cursor = 0
      statusMsg = running and "Ready" or "Bye"
      redraw(statusMsg, input, cursor)

    elseif k == keys.backspace then
      if cursor > 0 then
        input = input:sub(1, cursor - 1) .. input:sub(cursor + 1)
        cursor = cursor - 1
      end
      redraw(statusMsg, input, cursor)

    elseif k == keys.delete then
      if cursor < #input then
        input = input:sub(1, cursor) .. input:sub(cursor + 2)
      end
      redraw(statusMsg, input, cursor)

    elseif k == keys.left then
      cursor = clamp(cursor - 1, 0, #input)
      redraw(statusMsg, input, cursor)

    elseif k == keys.right then
      cursor = clamp(cursor + 1, 0, #input)
      redraw(statusMsg, input, cursor)

    elseif k == keys.home then
      cursor = 0
      redraw(statusMsg, input, cursor)

    elseif k == keys["end"] then
      cursor = #input
      redraw(statusMsg, input, cursor)

    elseif k == keys.up then
      if #history > 0 then
        histIndex = clamp(histIndex - 1, 1, #history)
        input = getHistory(histIndex) or input
        cursor = #input
        redraw("History", input, cursor)
      end

    elseif k == keys.down then
      if #history > 0 then
        histIndex = clamp(histIndex + 1, 1, #history + 1)
        local v = getHistory(histIndex)
        if v then
          input = v
        else
          input = ""
        end
        cursor = #input
        redraw("History", input, cursor)
      end

    elseif k == keys.pageUp then
      local maxScroll = math.max(0, #scrollback - VIEW_H)
      scroll = clamp(scroll + VIEW_H, 0, maxScroll)
      redraw("Scroll", input, cursor)

    elseif k == keys.pageDown then
      local maxScroll = math.max(0, #scrollback - VIEW_H)
      scroll = clamp(scroll - VIEW_H, 0, maxScroll)
      redraw("Scroll", input, cursor)
    end

  elseif e == "char" then
    local ch = p1
    input = input:sub(1, cursor) .. ch .. input:sub(cursor + 1)
    cursor = cursor + 1
    redraw(statusMsg, input, cursor)
  end
end

term.setCursorBlink(false)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1,1)
print("Exited DOS shell.")
