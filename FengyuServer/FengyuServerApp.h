#pragma once

#include "resource.h"
#include <resource.h>
#include <FengyuIPC.h>
#include <FengyuUI.h>
#include <FengyuBridge.h>
#include <FengyuUtility.h>
#include <filesystem>
#include <functional>
#include <memory>
#include <winsparkle.h>

#include "FengyuTrayIcon.h"

namespace fs = std::filesystem;

class FengyuServerApp {
 public:
  static bool execute(const fs::path& cmd, const std::wstring& args) {
    return (uintptr_t)ShellExecuteW(NULL, NULL, cmd.c_str(), args.c_str(), NULL,
                                    SW_SHOWNORMAL) > 32;
  }

  static bool explore(const fs::path& path) {
    std::wstring quoted_path(L"\"" + path.wstring() + L"\"");
    return (uintptr_t)ShellExecuteW(NULL, L"explore", quoted_path.c_str(), NULL,
                                    NULL, SW_SHOWNORMAL) > 32;
  }

  static bool open(const fs::path& path) {
    return (uintptr_t)ShellExecuteW(NULL, L"open", path.c_str(), NULL, NULL,
                                    SW_SHOWNORMAL) > 32;
  }

  static bool check_update() {
    // 風語輸入法：客製版本不連線風語輸入法官方更新來源
    MessageBoxW(NULL, L"風語輸入法為 AIW 風光Ai窗 客製版本，不提供線上更新。",
                get_fengyu_ime_name().c_str(), MB_OK | MB_ICONINFORMATION);
    return true;
  }

  static fs::path install_dir() {
    WCHAR exe_path[MAX_PATH] = {0};
    GetModuleFileNameW(GetModuleHandle(NULL), exe_path, _countof(exe_path));
    return fs::path(exe_path).remove_filename();
  }

 public:
  FengyuServerApp();
  ~FengyuServerApp();
  int Run();

 protected:
  void SetupMenuHandlers();

  fengyu::Server m_server;
  fengyu::UI m_ui;
  FengyuTrayIcon tray_icon;
  std::unique_ptr<FengyuBridgeHandler> m_handler;
};
