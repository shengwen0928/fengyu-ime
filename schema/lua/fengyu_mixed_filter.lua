-- 風語輸入法：中英混打候選
local mixed = require("fengyu_mixed")

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
    if ctx.input ~= mixed.forced_zh and junk_chinese(ctx.input, first) then
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
