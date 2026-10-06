-- 風語輸入法：中英混打（候選字）
-- 仿華碩混打：結尾一段看起來是英文（或數字）時，組字區直接顯示原始字母，不跳注音候選
--   整段都是英文／數字 → 不給候選（組字區顯示原始字母）
--   前面有中文         → 只給一個「中文 + 英文／數字」的候選
local mixed = require("fengyu_mixed")

-- 整段是 2～3 個沒有聲調的字母（如 gt、gth）時，看最佳候選：
-- 若只是把單字硬湊成句（type 為 sentence）或蓋不住整段，代表轉成中文也不成詞 → 改判英文
-- 整段都是數字（2 碼以上，如 100＝ㄅㄢ ㄢ→「班安」）時同理 → 改判數字
local function junk_chinese(input, first)
  if not input:match("^%l%l%l?$") and not input:match("^%d[%d.]+$") then return false end
  if not first then return true end
  return first.type == "sentence" or first._end < #input
end

return function(input, env)
  local ctx = env.engine.context
  local prefix, run = mixed.split(ctx.input)
  if not run then
    local first
    for cand in input:iter() do first = cand; break end
    if junk_chinese(ctx.input, first) then
      mixed.forced_input = ctx.input
      return  -- 不給候選，組字區顯示原始字母
    end
    if first then yield(first) end
    for cand in input:iter() do yield(cand) end
    return
  end
  if prefix == "" then return end
  for cand in input:iter() do
    if cand._end == #prefix then
      local text = cand.text .. run
      local c = Candidate("mixed", 0, #ctx.input, text, "")
      c.preedit = text
      yield(c)
      return
    end
  end
end
