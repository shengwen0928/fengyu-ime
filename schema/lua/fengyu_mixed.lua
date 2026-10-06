-- 風語輸入法：中英混打共用判斷
local english = require("fengyu_english")

local M = {}

-- 英文單字的所有開頭（he、hel、hell…）
local word_prefix = {}
for w in pairs(english.words) do
  for i = 2, #w do word_prefix[w:sub(1, i)] = true end
end

-- 注音音節按鍵的所有開頭（打到一半的音節）
local syl_prefix = {}
for s in pairs(english.syllables) do
  for i = 1, #s do syl_prefix[s:sub(1, i)] = true end
end

-- 這串按鍵能不能拆成注音音節（最後一個可以只打一半；每個音節後可接一個聲調鍵 3 4 6 7）
local function zhuyin_possible(run)
  local n = #run
  local ok = { [0] = true }
  for i = 0, n - 1 do
    if ok[i] then
      if syl_prefix[run:sub(i + 1)] then return true end
      for len = 1, 4 do
        if i + len <= n and english.syllables[run:sub(i + 1, i + len)] then
          ok[i + len] = true
          if run:sub(i + len + 1, i + len + 1):match("[3467]") then ok[i + len + 1] = true end
        end
      end
    end
  end
  return ok[n] == true
end
M.zhuyin_possible = zhuyin_possible

-- 一段純字母看起來是英文：
--   是英文單字（或開頭）
--   或連續 4 個以上字母沒有聲調鍵（單一注音音節最多 3 個字母鍵，打注音一定會打聲調；如 github）
--   或根本拼不成注音
function M.looks_english(run)
  return word_prefix[run] or #run >= 4 or not zhuyin_possible(run)
end

-- 空白鍵要不要送出英文：剛好是注音一聲音節（如 ru＝ㄐㄧ）時維持注音
function M.space_commits(run)
  return not english.tone1[run]
end

-- 上一次送出的是中文（zh）還是英文（en），由 processor 更新；用來判斷有衝突的按鍵
M.last_kind = nil
-- 使用者在英文上按 ↓ 要求改成中文的輸入碼與那段字母
M.forced_zh = nil
M.forced_zh_run = nil

-- 學習：使用者對某組字母的偏好（en／zh），存在使用者資料夾的 fengyu_mixed_learn.txt
local prefs = {}
local learn_path = nil
do
  local ok, dir = pcall(function() return rime_api.get_user_data_dir() end)
  if ok and dir and dir ~= "" then
    learn_path = dir .. "/fengyu_mixed_learn.txt"
    local f = io.open(learn_path, "r")
    if f then
      for line in f:lines() do
        local run, kind = line:match("^(%l+)\t(%l+)$")
        if run then prefs[run] = kind end
      end
      f:close()
    end
  end
end

function M.learn(run, kind)
  run = run:lower()
  if prefs[run] == kind then return end
  prefs[run] = kind
  if not learn_path then return end
  local f = io.open(learn_path, "w")
  if not f then return end
  for r, k in pairs(prefs) do f:write(r, "\t", k, "\n") end
  f:close()
end

-- 依學習與前後文判斷這段字母要不要當英文：true＝英文、false＝中文、nil＝沒有意見
--   學過的照學到的；否則若前面沒有中文、上一次送出的是英文，英文單字（含單一字母）就當英文
function M.prefer_english(run, prefix)
  local p = prefs[run:lower()]
  if p then return p == "en" end
  if prefix == "" and M.last_kind == "en" and (english.words[run] or #run == 1) then
    return true
  end
  return nil
end

-- 將輸入碼拆成「前段注音」與「結尾英文」；結尾不像英文則回傳 nil
-- 前段必須是空的，或以聲調鍵（空白 3 4 6 7）結尾，確保英文不是某個注音音節的後半
-- 由候選判斷出「轉成中文也不成詞」而改判英文的輸入碼（filter 記錄、processor 讀取）
M.forced_input = nil

-- 一段數字（可含小數點）看起來是數字：至少 2 碼，且拼不成注音（如 2026、3.14），
-- 或由候選判斷出「轉成中文也不成詞」（如 100＝ㄅㄢ ㄢ，見 filter 的 forced_input）
function M.looks_number(run, input)
  return #run >= 2 and (not zhuyin_possible(run) or (input ~= nil and input == M.forced_input))
end

-- 回傳 prefix, run, is_number；結尾不是英文也不是數字則回傳 nil
function M.split(input)
  local prefix, run = input:match("^(.-)(%a+)$")
  if run then
    -- 使用者按 ↓ 要求改成中文
    if input == M.forced_zh then return nil end
    -- 含大寫字母一定是英文（注音按鍵都是小寫）；全小寫依學習／前後文，再判斷像不像英文
    local pref = nil
    if not run:match("%u") then pref = M.prefer_english(run, prefix) end
    if pref == false then return nil end
    if not run:match("%u") and not pref and not M.looks_english(run) and input ~= M.forced_input then return nil end
    if prefix ~= "" and not prefix:match("[ 3467]$") then return nil end
    return prefix, run, false
  end
  -- 結尾一段數字：數字鍵也是注音鍵（ㄅㄉˇˋㄓˊ˙ㄚㄞㄢ），由長到短找出可當數字的尾段，
  -- 前段須是空的或以聲調鍵結尾（避免把前一個字的聲調鍵算進數字）
  local tail = input:match("[%d.]+$")
  if not tail then return nil end
  for i = 1, #tail do
    local r = tail:sub(i)
    local p = input:sub(1, #input - #r)
    if r:match("^%d") and (p == "" or p:match("[ 3467]$"))
        and M.looks_number(r, p == "" and input or nil) then
      return p, r, true
    end
  end
  return nil
end

return M
