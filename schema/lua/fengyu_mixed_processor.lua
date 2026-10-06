-- 風語輸入法：中英混打免切換（按鍵處理）
-- 輸入碼結尾是一段英文時：
--   空白鍵 → 送出（前面的中文 +）英文 + 空格；但若剛好是注音一聲音節（如 ru＝ㄐㄧ），維持注音
--   Enter  → 送出（前面的中文 +）英文
local mixed = require("fengyu_mixed")

local kRejected, kAccepted, kNoop = 0, 1, 2

-- 候選框預設隱藏（仿華碩／微軟注音；預設值由方案的 fengyu_hide_menu 開關設定）
-- 組字中按 ↓ 才顯示，送出文字後再隱藏。
-- 注意：不可在每次按鍵時 set_option，會觸發通知、造成 TSF 按鍵順序錯亂。
local function init(env)
  local context = env.engine.context
  env.on_commit = context.commit_notifier:connect(function(ctx)
    if not ctx:get_option("fengyu_hide_menu") then
      ctx:set_option("fengyu_hide_menu", true)
    end
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
  local k = key:repr()
  local ctx = env.engine.context

  if k == "Down" and ctx:is_composing() and ctx:get_option("fengyu_hide_menu") then
    ctx:set_option("fengyu_hide_menu", false)
    return kAccepted
  end

  if k ~= "space" and k ~= "Return" then return kNoop end
  if not ctx:is_composing() then return kNoop end
  local prefix, word = mixed.split(ctx.input)
  if not word then return kNoop end
  if k == "space" and not mixed.space_commits(word) then return kNoop end

  if prefix ~= "" then
    ctx.input = prefix
    ctx:commit()  -- 先送出前面中文的最佳轉換
  else
    ctx:clear()
  end
  env.engine:commit_text(k == "space" and (word .. " ") or word)
  return kAccepted
end

return { init = init, func = func, fini = fini }
