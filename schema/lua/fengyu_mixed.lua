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

-- 這串按鍵能不能拆成注音音節（最後一個可以只打一半）
local function zhuyin_possible(run)
  local n = #run
  local ok = { [0] = true }
  for i = 0, n - 1 do
    if ok[i] then
      if syl_prefix[run:sub(i + 1)] then return true end
      for len = 1, 4 do
        if i + len <= n and english.syllables[run:sub(i + 1, i + len)] then ok[i + len] = true end
      end
    end
  end
  return ok[n] == true
end

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

-- 將輸入碼拆成「前段注音」與「結尾英文」；結尾不像英文則回傳 nil
-- 前段必須是空的，或以聲調鍵（空白 3 4 6 7）結尾，確保英文不是某個注音音節的後半
-- 由候選判斷出「轉成中文也不成詞」而改判英文的輸入碼（filter 記錄、processor 讀取）
M.forced_input = nil

function M.split(input)
  local prefix, run = input:match("^(.-)(%a+)$")
  if not run then return nil end
  -- 含大寫字母一定是英文（注音按鍵都是小寫）；全小寫再判斷像不像英文
  if not run:match("%u") and not M.looks_english(run) and input ~= M.forced_input then return nil end
  if prefix ~= "" and not prefix:match("[ 3467]$") then return nil end
  return prefix, run
end

return M
