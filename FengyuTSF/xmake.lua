target("FengyuTSF")
  set_kind("shared")
  add_files("./*.cpp", "FengyuTSF.def")
  add_rules("add_rcfiles", "use_fengyuconstants")
  add_deps("FengyuIPC", "FengyuUI")
  local fname = ''
  if is_arch("x86") then
    fname = "fengyu.dll"
  elseif is_arch("x64") then
    fname = "fengyux64.dll"
  elseif is_arch("arm") then
    fname = "fengyuARM.dll"
  elseif is_arch("arm64") then
    fname = "fengyuARM64.dll"
  end
  set_filename(fname)

  add_files("$(projectdir)/PerMonitorHighDPIAware.manifest")
  add_shflags("/DEBUG /OPT:REF /OPT:ICF")
  before_build(function(target)
    local target_dir = path.join(target:targetdir(), target:name())
    if not os.exists(target_dir) then
      os.mkdir(target_dir)
    end
    target:set("targetdir", target_dir)
  end)

  after_build(function(target)
    os.cp(path.join(target:targetdir(), "fengyu*.dll"), "$(projectdir)/output")
    os.cp(path.join(target:targetdir(), "fengyu*.pdb"), "$(projectdir)/output")
  end)
