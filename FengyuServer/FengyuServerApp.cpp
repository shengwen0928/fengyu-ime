#include "stdafx.h"
#include "FengyuServerApp.h"
#include <filesystem>

FengyuServerApp::FengyuServerApp()
    : m_handler(std::make_unique<RimeWithFengyuHandler>(&m_ui)),
      tray_icon(m_ui) {
  // m_handler.reset(new RimeWithFengyuHandler(&m_ui));
  m_server.SetRequestHandler(m_handler.get());
  SetupMenuHandlers();
}

FengyuServerApp::~FengyuServerApp() {}

int FengyuServerApp::Run() {
  if (!m_server.Start())
    return -1;

  // win_sparkle_set_appcast_url("http://localhost:8000/fengyu/update/appcast.xml");
  win_sparkle_set_registry_path("Software\\Fengyu\\IME\\Updates");
  if (GetThreadUILanguage() ==
      MAKELANGID(LANG_CHINESE, SUBLANG_CHINESE_TRADITIONAL))
    win_sparkle_set_lang("zh-TW");
  else if (GetThreadUILanguage() ==
           MAKELANGID(LANG_CHINESE, SUBLANG_CHINESE_SIMPLIFIED))
    win_sparkle_set_lang("zh-CN");
  else
    win_sparkle_set_lang("en");
  // 風語輸入法：客製版本，停用風語輸入法官方自動更新
  win_sparkle_set_automatic_check_for_updates(0);
  win_sparkle_init();
  m_ui.Create(m_server.GetHWnd());

  m_handler->Initialize();
  m_handler->OnUpdateUI([this]() { tray_icon.Refresh(); });

  tray_icon.Create(m_server.GetHWnd());
  tray_icon.Refresh();

  int ret = m_server.Run();

  m_handler->Finalize();
  m_ui.Destroy();
  tray_icon.RemoveIcon();
  win_sparkle_cleanup();

  return ret;
}

void FengyuServerApp::SetupMenuHandlers() {
  std::filesystem::path dir = install_dir();
  m_server.AddMenuHandler(ID_FENGYUTRAY_QUIT,
                          [this] { return m_server.Stop() == 0; });
  m_server.AddMenuHandler(ID_FENGYUTRAY_DEPLOY,
                          std::bind(execute, dir / L"FengyuDeployer.exe",
                                    std::wstring(L"/deploy")));
  m_server.AddMenuHandler(
      ID_FENGYUTRAY_SETTINGS,
      std::bind(execute, dir / L"FengyuDeployer.exe", std::wstring()));
  m_server.AddMenuHandler(
      ID_FENGYUTRAY_DICT_MANAGEMENT,
      std::bind(execute, dir / L"FengyuDeployer.exe", std::wstring(L"/dict")));
  m_server.AddMenuHandler(
      ID_FENGYUTRAY_SYNC,
      std::bind(execute, dir / L"FengyuDeployer.exe", std::wstring(L"/sync")));
  m_server.AddMenuHandler(ID_FENGYUTRAY_WIKI,
                          std::bind(open, L"https://rime.im/docs/"));
  m_server.AddMenuHandler(ID_FENGYUTRAY_HOMEPAGE,
                          std::bind(open, L"https://rime.im/"));
  m_server.AddMenuHandler(ID_FENGYUTRAY_FORUM,
                          std::bind(open, L"https://rime.im/discuss/"));
  m_server.AddMenuHandler(ID_FENGYUTRAY_CHECKUPDATE, check_update);
  m_server.AddMenuHandler(ID_FENGYUTRAY_INSTALLDIR, std::bind(explore, dir));
  m_server.AddMenuHandler(ID_FENGYUTRAY_USERCONFIG,
                          std::bind(explore, FengyuUserDataPath()));
  m_server.AddMenuHandler(ID_FENGYUTRAY_LOGDIR,
                          std::bind(explore, FengyuLogPath()));
}
