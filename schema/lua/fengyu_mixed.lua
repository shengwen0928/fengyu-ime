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

local function char_class(chars)
  return "[" .. chars:gsub("[%%%-%]%^]", "%%%0") .. "]"
end

-- 聲調鍵取自方案 speller/finals；可開始一個音節的非字母鍵取自音節表
function M.configure(config)
  local finals = config and config:get_string("speller/finals") or " 3467"
  local tones = finals:gsub(" ", "")
  M.tone_class = char_class(tones)
  M.tone_end = char_class(" " .. tones) .. "$"
  local starts = {}
  for s in pairs(english.syllables) do
    local c = s:sub(1, 1)
    if not c:match("%a") and not starts[c] then starts[c] = true end
  end
  local keys = {}
  for c in pairs(starts) do keys[#keys + 1] = c end
  M.start_class = char_class(table.concat(keys))
end
M.configure(nil)

-- complete：最後一個音節也須完整
local function zhuyin_possible(run, complete)
  local n = #run
  local ok = { [0] = true }
  for i = 0, n - 1 do
    if ok[i] then
      if not complete and syl_prefix[run:sub(i + 1)] then return true end
      for len = 1, 4 do
        if i + len <= n and english.syllables[run:sub(i + 1, i + len)] then
          ok[i + len] = true
          if run:sub(i + len + 1, i + len + 1):match(M.tone_class) then ok[i + len + 1] = true end
        end
      end
    end
  end
  return ok[n] == true
end
M.zhuyin_possible = zhuyin_possible

function M.looks_english(run)
  return word_prefix[run] or #run >= 4 or not zhuyin_possible(run)
end

function M.space_commits(run)
  return not english.tone1[run]
end

M.app = ""
local kinds = {}
function M.set_kind(kind) kinds[M.app] = kind end
function M.last_kind() return kinds[M.app] end

M.forced_zh = nil
M.forced_zh_run = nil

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

-- true＝英文、false＝中文、nil＝無意見
function M.prefer_english(run, prefix)
  local p = prefs[run:lower()]
  if p then return p == "en" end
  if prefix == "" and M.last_kind() == "en" and (english.words[run] or #run == 1) then
    return true
  end
  return nil
end

M.forced_input = nil

function M.looks_number(run, input)
  return #run >= 2 and (not zhuyin_possible(run) or (input ~= nil and input == M.forced_input))
end

-- 回傳 prefix, run, is_number
function M.split(input)
  local prefix, run = input:match("^(.-)(%a+)$")
  if run then
    if input == M.forced_zh then return nil end
    local pref = nil
    if not run:match("%u") then pref = M.prefer_english(run, prefix) end
    if pref == false then return nil end
    if not run:match("%u") and not pref and not M.looks_english(run) and input ~= M.forced_input then return nil end
    if prefix ~= "" and not prefix:match(M.tone_end) then return nil end
    return prefix, run, false
  end
  local tail = input:match("[%d.]+$")
  if not tail then return nil end
  for i = 1, #tail do
    local r = tail:sub(i)
    local p = input:sub(1, #input - #r)
    if r:match("^%d") and (p == "" or p:match(M.tone_end))
        and M.looks_number(r, p == "" and input or nil) then
      return p, r, true
    end
  end
  return nil
end

return M
