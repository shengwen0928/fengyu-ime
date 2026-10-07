-- 風語輸入法：中英混打候選
local mixed = require("fengyu_mixed")

local function junk_chinese(input, first)
  if not input:match("^%l%l%l?$") and not input:match("^%d[%d.]+$") then return false end
  if not first then return true end
  return first.type == "sentence" or first._end < #input
end

local function taiwan_tai(text)
  return (text:gsub("臺", "台"))
end

local function emit(cand)
  if cand.text:find("臺", 1, true) then
    yield(ShadowCandidate(cand, cand.type, taiwan_tai(cand.text), cand.comment))
  end
  yield(cand)
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
    if first then emit(first) end
    for cand in input:iter() do emit(cand) end
    return
  end
  if prefix == "" then return end
  for cand in input:iter() do
    if cand._end == #prefix then
      local text = taiwan_tai(cand.text) .. run
      local c = Candidate("mixed", 0, #ctx.input, text, "")
      c.preedit = text
      yield(c)
      return
    end
  end
end
