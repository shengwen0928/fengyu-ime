-- 風語輸入法：中英混打按鍵處理
local mixed = require("fengyu_mixed")

local kRejected, kAccepted, kNoop = 0, 1, 2

local KEYPAD = {
  KP_0 = "0", KP_1 = "1", KP_2 = "2", KP_3 = "3", KP_4 = "4",
  KP_5 = "5", KP_6 = "6", KP_7 = "7", KP_8 = "8", KP_9 = "9",
  KP_Decimal = ".", KP_Add = "+", KP_Subtract = "-", KP_Multiply = "*", KP_Divide = "/",
}

local function load_puncts(config)
  local menu, direct = {}, {}
  local map = config:get_map("punctuator/half_shape")
  if not map then return menu, direct end
  for _, k in ipairs(map:keys()) do
    local item = map:get(k)
    if item and item:get_list() then
      menu[k] = true
    elseif item and item:get_value() and k ~= "`" then
      direct[k] = item:get_value():get_string()
    end
  end
  return menu, direct
end

local function commit_mixed(env, ctx, prefix, text)
  if prefix ~= "" then
    ctx.input = prefix
    ctx:commit()
  else
    ctx:clear()
  end
  env.engine:commit_text(text)
  if text:match("%a%s*$") then mixed.set_kind("en") end
end

-- 注意：不可每次按鍵都 set_option，會觸發通知、造成 TSF 按鍵順序錯亂
local function init(env)
  local context = env.engine.context
  env.menu_puncts, env.direct_puncts = load_puncts(env.engine.schema.config)
  env.on_commit = context.commit_notifier:connect(function(ctx)
    if not ctx:get_option("fengyu_hide_menu") then
      ctx:set_option("fengyu_hide_menu", true)
    end
    local text = ctx:get_commit_text()
    local chinese = text:match("[\128-\255]") ~= nil
    if chinese then
      mixed.set_kind("zh")
    elseif text:match("%a") then
      mixed.set_kind("en")
    end
    if mixed.forced_zh_run and chinese and ctx.input == mixed.forced_zh then
      mixed.learn(mixed.forced_zh_run, "zh")
    end
    mixed.forced_zh, mixed.forced_zh_run = nil, nil
  end)
  env.on_option = context.option_update_notifier:connect(function(ctx, name)
    if name == "ascii_mode" and ctx:get_option("ascii_mode") then
      ctx:set_option("ascii_mode", false)
    end
  end)
end

local function fini(env)
  env.on_commit:disconnect()
  env.on_option:disconnect()
end

local function func(key, env)
  if key:release() or key:ctrl() or key:alt() then return kNoop end

  if key:caps() then
    local base = key:repr():gsub("Lock%+", "")
    if #base > 1 then
      return env.engine:process_key(KeyEvent(base)) and kAccepted or kNoop
    end
  end

  local k = key:repr()
  local ctx = env.engine.context
  mixed.app = ctx:get_property("client_app") or ""
  if not ctx:is_composing() then
    mixed.forced_zh, mixed.forced_zh_run = nil, nil
    if not ctx:get_option("fengyu_hide_menu") then ctx:set_option("fengyu_hide_menu", true) end
  end

  if k == "Down" and ctx:is_composing() then
    local _, run, is_number = mixed.split(ctx.input)
    if run and not is_number then
      mixed.forced_zh, mixed.forced_zh_run = ctx.input, run
      if ctx:get_option("fengyu_hide_menu") then ctx:set_option("fengyu_hide_menu", false) end
      ctx:refresh_non_confirmed_composition()
      return kAccepted
    end
    if ctx:get_option("fengyu_hide_menu") then
      ctx:set_option("fengyu_hide_menu", false)
      return kAccepted
    end
  end

  local code0 = key.keycode
  if code0 >= 0x31 and code0 <= 0x39 and ctx:is_composing()
      and not ctx:get_option("fengyu_hide_menu") and ctx:has_menu() then
    local page = env.engine.schema.page_size
    local seg = ctx.composition:back()
    local idx = math.floor(seg.selected_index / page) * page + (code0 - 0x31)
    ctx:select(idx)
    ctx:set_option("fengyu_hide_menu", true)
    return kAccepted
  end
  if code0 >= 0x61 and code0 <= 0x7a and ctx:is_composing() and not ctx:get_option("fengyu_hide_menu") then
    ctx:set_option("fengyu_hide_menu", true)
  end

  local kp = KEYPAD[k]
  if kp then
    if not ctx:is_composing() then return kNoop end
    local prefix, run, is_number = mixed.split(ctx.input)
    if is_number then
      commit_mixed(env, ctx, prefix, run)
    else
      ctx:commit()
    end
    env.engine:commit_text(kp)
    return kAccepted
  end

  local code = key.keycode
  local ch = (code > 0x20 and code < 0x7f) and string.char(code) or nil

  -- Caps Lock 打注音（SU3＝ㄋㄧˇ）：大寫段需拼成完整音節，MS365、A4 仍是英文
  if ch and ch:match("[3467]") and ctx:is_composing() then
    local prefix, run = ctx.input:match("^(.-)(%u+)$")
    if run and (prefix == "" or prefix:match("[ 3467]$"))
        and mixed.zhuyin_possible(run:lower(), true) then
      ctx.input = prefix .. run:lower()
    end
  end

  if ch and env.menu_puncts[ch] and ctx:get_option("fengyu_hide_menu") then
    ctx:set_option("fengyu_hide_menu", false)
    return kNoop
  end
  if ch and env.direct_puncts[ch] then
    if ctx:is_composing() then ctx:commit() end
    env.engine:commit_text(env.direct_puncts[ch])
    return kAccepted
  end

  if k ~= "space" and k ~= "Return" then
    if ch and ch:match("[%a,/;%-]") and ctx:is_composing() then
      local prefix, run, is_number = mixed.split(ctx.input)
      if is_number then commit_mixed(env, ctx, prefix, run) end
    end
    -- bom表：英文後接數字列的注音聲母／韻母鍵
    if ch and ch:match("^[125890%-]$") and ctx:is_composing() and ctx.input:match("^%l%l%l+$") then
      local prefix, run, is_number = mixed.split(ctx.input)
      if run and not is_number and prefix == "" then commit_mixed(env, ctx, "", run) end
    end
    -- BOM表：大寫字後的數字再接注音字母時才拆開（COVID19 不受影響）
    if ch and ch:match("[%l,/;%.%-]") and ctx:is_composing() then
      local en, rest = ctx.input:match("^(%u[%a%-_+.']+)([125890%-]%d*)$")
      if en then
        commit_mixed(env, ctx, "", en)
        ctx.input = rest
      end
    end
    return kNoop
  end
  if not ctx:is_composing() then return kNoop end
  if ctx.input:match("^%u[%a%-_+.']*%d*$") then
    commit_mixed(env, ctx, "", k == "space" and (ctx.input .. " ") or ctx.input)
    return kAccepted
  end
  if k == "Return" and ctx.input:match("^[%d.]+$") and not ctx.input:match("[3467]") then
    commit_mixed(env, ctx, "", ctx.input)
    return kAccepted
  end
  if k == "space" and ctx.input:match("^%l+$") and not mixed.split(ctx.input)
      and ctx.input ~= mixed.forced_zh and not mixed.zhuyin_possible(ctx.input, true) then
    commit_mixed(env, ctx, "", ctx.input .. " ")
    return kAccepted
  end
  if k == "Return" and ctx.input:match("^%l+$") and not mixed.split(ctx.input)
      and ctx.input ~= mixed.forced_zh then
    mixed.learn(ctx.input, "en")
    commit_mixed(env, ctx, "", ctx.input)
    return kAccepted
  end
  local prefix, word, is_number = mixed.split(ctx.input)
  if not word then return kNoop end
  if is_number then
    commit_mixed(env, ctx, prefix, word)
    return kAccepted
  end
  local conflict = not mixed.space_commits(word) or #word == 1
  if k == "space" and conflict and not mixed.prefer_english(word, prefix) then return kNoop end
  if k == "Return" and conflict and not word:match("%u") then mixed.learn(word, "en") end

  commit_mixed(env, ctx, prefix, k == "space" and (word .. " ") or word)
  return kAccepted
end

return { init = init, func = func, fini = fini }
