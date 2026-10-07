-- 風語輸入法：中英混打免切換（按鍵處理）
-- 輸入碼結尾是一段英文時：
--   空白鍵 → 送出（前面的中文 +）英文 + 空格；但若剛好是注音一聲音節（如 ru＝ㄐㄧ），維持注音
--   Enter  → 送出（前面的中文 +）英文
-- 輸入碼結尾是一段數字時（如 2026、3.14）：
--   空白鍵／Enter → 送出（前面的中文 +）數字，不加空格
--   接著打注音字母 → 先送出數字，再照常輸入
-- Caps Lock 開著時，功能鍵會帶 Lock 修飾，引擎的編輯鍵（刪除、Enter、空白…）不認得 → 去掉 Lock 再處理
-- 有多個選項（或不會直接送出）的標點，按下時自動顯示候選框
local mixed = require("fengyu_mixed")

local kRejected, kAccepted, kNoop = 0, 1, 2

-- 數字鍵盤（Num Lock 開）按鍵 → 字元
local KEYPAD = {
  KP_0 = "0", KP_1 = "1", KP_2 = "2", KP_3 = "3", KP_4 = "4",
  KP_5 = "5", KP_6 = "6", KP_7 = "7", KP_8 = "8", KP_9 = "9",
  KP_Decimal = ".", KP_Add = "+", KP_Subtract = "-", KP_Multiply = "*", KP_Divide = "/",
}

-- 讀取標點設定：
--   menu   ＝有多個選項的鍵（如 ? [ $），按下時顯示候選框
--   direct ＝只有一個值的鍵（如 + = ~），直接送出，不留在組字區等待
--   {commit: …} 本來就直接送出；成對符號（" '）與反查鍵 ` 維持原樣
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

-- 送出前段中文的最佳轉換，再送出 text
local function commit_mixed(env, ctx, prefix, text)
  if prefix ~= "" then
    ctx.input = prefix
    ctx:commit()
  else
    ctx:clear()
  end
  env.engine:commit_text(text)
  if text:match("%a%s*$") then mixed.last_kind = "en" end
end

-- 候選框預設隱藏（仿華碩／微軟注音；預設值由方案的 fengyu_hide_menu 開關設定）
-- 組字中按 ↓ 才顯示，送出文字後再隱藏。
-- 注意：不可在每次按鍵時 set_option，會觸發通知、造成 TSF 按鍵順序錯亂。
local function init(env)
  local context = env.engine.context
  env.menu_puncts, env.direct_puncts = load_puncts(env.engine.schema.config)
  env.on_commit = context.commit_notifier:connect(function(ctx)
    if not ctx:get_option("fengyu_hide_menu") then
      ctx:set_option("fengyu_hide_menu", true)
    end
    -- 記住送出的是中文還是英文（判斷下一段有衝突的按鍵用）
    local text = ctx:get_commit_text()
    local chinese = text:match("[\128-\255]") ~= nil
    if chinese then
      mixed.last_kind = "zh"
    elseif text:match("%a") then
      mixed.last_kind = "en"
    end
    -- 使用者按 ↓ 把英文改成中文、並送出同一段輸入 → 學起來，下次這組字母直接給中文
    if mixed.forced_zh_run and chinese and ctx.input == mixed.forced_zh then
      mixed.learn(mixed.forced_zh_run, "zh")
    end
    mixed.forced_zh, mixed.forced_zh_run = nil, nil
  end)
  -- 只有混打一種模式：任何方式切到英文模式（快捷鍵、工作列圖示）都立刻切回
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

  -- Caps Lock：功能鍵去掉 Lock 重新處理；字母（單一字元）照常輸出大寫
  if key:caps() then
    local base = key:repr():gsub("Lock%+", "")
    if #base > 1 then
      return env.engine:process_key(KeyEvent(base)) and kAccepted or kNoop
    end
  end

  local k = key:repr()
  local ctx = env.engine.context
  -- 離開組字（送出或清除）後，↓ 要求的中文不再適用
  if not ctx:is_composing() then mixed.forced_zh, mixed.forced_zh_run = nil, nil end

  if k == "Down" and ctx:is_composing() then
    -- 結尾被判成英文、使用者按 ↓：改給中文候選（選定後會學起來）
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

  -- 候選框顯示中：數字鍵 1～9 直接選當頁候選（數字鍵平常是注音鍵，只有候選框打開時才拿來選字）
  local code0 = key.keycode
  if code0 >= 0x31 and code0 <= 0x39 and ctx:is_composing()
      and not ctx:get_option("fengyu_hide_menu") and ctx:has_menu() then
    local page = env.engine.schema.page_size
    local seg = ctx.composition:back()
    local idx = math.floor(seg.selected_index / page) * page + (code0 - 0x31)
    ctx:select(idx)
    return kAccepted
  end

  -- 數字鍵盤：沒在組字時引擎不處理、直接輸入；組字中則先送出組字區（數字原樣、中文送最佳轉換），再輸入該字元
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

  -- Caps Lock 開著打注音（如 SU3＝ㄋㄧˇ）：結尾一段大寫字母後接聲調鍵，且轉小寫拼得成注音
  -- → 視為注音，改回小寫再交給後面處理；英文單字中間不會夾聲調鍵，大寫英文不受影響
  if ch and ch:match("[3467]") and ctx:is_composing() then
    local prefix, run = ctx.input:match("^(.-)(%u+)$")
    if run and (prefix == "" or prefix:match("[ 3467]$"))
        and mixed.zhuyin_possible(run:lower()) then
      ctx.input = prefix .. run:lower()
    end
  end

  -- 有多個選項的標點：顯示候選框（交給後面的 punctuator 處理）
  if ch and env.menu_puncts[ch] and ctx:get_option("fengyu_hide_menu") then
    ctx:set_option("fengyu_hide_menu", false)
    return kNoop
  end
  -- 只有一個值的標點：先送出組字中的文字，再直接送出這個標點
  if ch and env.direct_puncts[ch] then
    if ctx:is_composing() then ctx:commit() end
    env.engine:commit_text(env.direct_puncts[ch])
    return kAccepted
  end

  if k ~= "space" and k ~= "Return" then
    -- 數字後面接著打注音字母：先送出數字，再照常處理這個鍵
    if ch and ch:match("[%a,/;%-]") and ctx:is_composing() then
      local prefix, run, is_number = mixed.split(ctx.input)
      if is_number then commit_mixed(env, ctx, prefix, run) end
    end
    -- 英文後面直接接注音（如 bom表）：整段是 3 個以上小寫字母、被判為英文，接著按數字列的注音鍵
    -- （聲母 1 2 5、韻母 8 9 0 -；聲調鍵 3 4 6 7 除外，不影響 su3 這類打法）→ 先送出英文，再開始打注音
    if ch and ch:match("^[125890%-]$") and ctx:is_composing() and ctx.input:match("^%l%l%l+$") then
      local prefix, run, is_number = mixed.split(ctx.input)
      if run and not is_number and prefix == "" then commit_mixed(env, ctx, "", run) end
    end
    return kNoop
  end
  if not ctx:is_composing() then return kNoop end
  -- 整段都是數字鍵、又沒有聲調鍵（如 1、50、88）時，Enter 送出數字；有聲調的（如 104＝辦）照常送中文
  if k == "Return" and ctx.input:match("^[%d.]+$") and not ctx.input:match("[3467]") then
    commit_mixed(env, ctx, "", ctx.input)
    return kAccepted
  end
  -- 整段都是小寫字母、卻被判成中文時按 Enter：送出原本的英文字母，並學起來（下次空白也給英文）
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
  -- 有衝突的字（剛好是注音一聲音節，如 up＝ㄧㄣ）：空白預設給中文，除非學過或前後文是英文
  local conflict = not mixed.space_commits(word) or #word == 1
  if k == "space" and conflict and not mixed.prefer_english(word, prefix) then return kNoop end
  -- 有衝突的字用 Enter 送出英文 → 使用者明確要英文，學起來
  if k == "Return" and conflict and not word:match("%u") then mixed.learn(word, "en") end

  commit_mixed(env, ctx, prefix, k == "space" and (word .. " ") or word)
  return kAccepted
end

return { init = init, func = func, fini = fini }
