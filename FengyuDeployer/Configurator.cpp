#include "stdafx.h"
#include "FengyuDeployer.h"
#include "Configurator.h"
#include "SwitcherSettingsDialog.h"
#include "UIStyleSettings.h"
#include "UIStyleSettingsDialog.h"
#include "DictManagementDialog.h"
#include <FengyuConstants.h>
#include <FengyuIPC.h>
#include <FengyuIPCData.h>
#include <FengyuUtility.h>
#pragma warning(disable : 4005)
#include <rime_api.h>
#include <rime_levers_api.h>
#pragma warning(default : 4005)
#include <filesystem>
#include <fstream>
#include "FengyuDeployer.h"

static void CreateFileIfNotExist(std::string filename) {
  std::filesystem::path file_path = FengyuUserDataPath() / u8tow(filename);
  DWORD dwAttrib = GetFileAttributes(file_path.c_str());
  if (!(INVALID_FILE_ATTRIBUTES != dwAttrib &&
        0 == (dwAttrib & FILE_ATTRIBUTE_DIRECTORY))) {
    std::wofstream o(file_path.c_str(), std::ios::app);
    o.close();
  }
}
Configurator::Configurator() {
  CreateFileIfNotExist("default.custom.yaml");
  CreateFileIfNotExist("fengyu.custom.yaml");
}

void Configurator::Initialize() {
  RIME_STRUCT(RimeTraits, fengyu_traits);
  std::string shared_dir = wtou8(FengyuSharedDataPath().wstring());
  std::string user_dir = wtou8(FengyuUserDataPath().wstring());
  fengyu_traits.shared_data_dir = shared_dir.c_str();
  fengyu_traits.user_data_dir = user_dir.c_str();
  fengyu_traits.prebuilt_data_dir = fengyu_traits.shared_data_dir;
  std::string distribution_name = wtou8(get_fengyu_ime_name());
  fengyu_traits.distribution_name = distribution_name.c_str();
  fengyu_traits.distribution_code_name = FENGYU_CODE_NAME;
  fengyu_traits.distribution_version = FENGYU_VERSION;
  fengyu_traits.app_name = "rime.fengyu";
  std::string log_dir = FengyuLogPath().u8string();
  fengyu_traits.log_dir = log_dir.c_str();
  RimeApi* rime_api = rime_get_api();
  assert(rime_api);
  rime_api->setup(&fengyu_traits);
  LOG(INFO) << "FengyuDeployer reporting.";
  rime_api->deployer_initialize(NULL);
}

static bool configure_switcher(RimeLeversApi* api,
                               RimeSwitcherSettings* switchcer_settings,
                               bool* reconfigured) {
  RimeCustomSettings* settings = (RimeCustomSettings*)switchcer_settings;
  if (!api->load_settings(settings))
    return false;
  SwitcherSettingsDialog dialog(switchcer_settings);
  if (dialog.DoModal() == IDOK) {
    if (api->save_settings(settings))
      *reconfigured = true;
    return true;
  }
  return false;
}

static bool configure_ui(RimeLeversApi* api,
                         UIStyleSettings* ui_style_settings,
                         bool* reconfigured) {
  RimeCustomSettings* settings = ui_style_settings->settings();
  if (!api->load_settings(settings))
    return false;
  UIStyleSettingsDialog dialog(ui_style_settings);
  if (dialog.DoModal() == IDOK) {
    if (api->save_settings(settings))
      *reconfigured = true;
    return true;
  }
  return false;
}

int Configurator::Run(bool installing) {
  RimeModule* levers = rime_get_api()->find_module("levers");
  if (!levers)
    return 1;
  RimeLeversApi* api = (RimeLeversApi*)levers->get_api();
  if (!api)
    return 1;

  bool reconfigured = false;

  RimeSwitcherSettings* switcher_settings = api->switcher_settings_init();
  UIStyleSettings ui_style_settings;

  bool skip_switcher_settings =
      installing && !api->is_first_run((RimeCustomSettings*)switcher_settings);
  bool skip_ui_style_settings =
      installing && !api->is_first_run(ui_style_settings.settings());

  (skip_switcher_settings ||
   configure_switcher(api, switcher_settings, &reconfigured)) &&
      (skip_ui_style_settings ||
       configure_ui(api, &ui_style_settings, &reconfigured));

  api->custom_settings_destroy((RimeCustomSettings*)switcher_settings);

  if (installing || reconfigured) {
    return UpdateWorkspace(reconfigured);
  }
  return 0;
}

int Configurator::UpdateWorkspace(bool report_errors) {
  HANDLE hMutex = CreateMutex(NULL, TRUE, FENGYU_DEPLOYER_MUTEX);
  if (!hMutex) {
    LOG(ERROR) << "Error creating FengyuDeployerMutex.";
    return 1;
  }
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    LOG(WARNING) << "another deployer process is running; aborting operation.";
    CloseHandle(hMutex);
    if (report_errors) {
      // MessageBox(NULL,
      // L"正在執行另一項部署任務，方纔所做的修改將在輸入法再次啓動後生效。",
      // L"【風語輸入法】", MB_OK | MB_ICONINFORMATION);
      MSG_BY_IDS(IDS_STR_DEPLOYING_RESTARTREQ, IDS_STR_FENGYU,
                 MB_OK | MB_ICONINFORMATION);
    }
    return 1;
  }

  fengyu::Client client;
  if (client.Connect()) {
    LOG(INFO) << "Turning FengyuServer into maintenance mode.";
    client.StartMaintenance();
  }

  {
    RimeApi* rime = rime_get_api();
    // initialize default config, preset schemas
    rime->deploy();
    // initialize fengyu config
    rime->deploy_config_file("fengyu.yaml", "config_version");
  }

  CloseHandle(hMutex);  // should be closed before resuming service.

  if (client.Connect()) {
    LOG(INFO) << "Resuming service.";
    client.EndMaintenance();
  }
  return 0;
}

int Configurator::DictManagement() {
  HANDLE hMutex = CreateMutex(NULL, TRUE, FENGYU_DEPLOYER_MUTEX);
  if (!hMutex) {
    LOG(ERROR) << "Error creating FengyuDeployerMutex.";
    return 1;
  }
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    LOG(WARNING) << "another deployer process is running; aborting operation.";
    CloseHandle(hMutex);
    // MessageBox(NULL, L"正在執行另一項部署任務，請稍候再試。", L"【風語輸入法】",
    // MB_OK | MB_ICONINFORMATION);
    MSG_BY_IDS(IDS_STR_DEPLOYING_WAIT, IDS_STR_FENGYU,
               MB_OK | MB_ICONINFORMATION);
    return 1;
  }

  fengyu::Client client;
  if (client.Connect()) {
    LOG(INFO) << "Turning FengyuServer into maintenance mode.";
    client.StartMaintenance();
  }

  {
    RimeApi* rime = rime_get_api();
    if (RIME_API_AVAILABLE(rime, run_task)) {
      rime->run_task("installation_update");  // setup user data sync dir
    }
    DictManagementDialog dlg;
    dlg.DoModal();
  }

  CloseHandle(hMutex);  // should be closed before resuming service.

  if (client.Connect()) {
    LOG(INFO) << "Resuming service.";
    client.EndMaintenance();
  }
  return 0;
}

int Configurator::SyncUserData() {
  HANDLE hMutex = CreateMutex(NULL, TRUE, FENGYU_DEPLOYER_MUTEX);
  if (!hMutex) {
    LOG(ERROR) << "Error creating FengyuDeployerMutex.";
    return 1;
  }
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    LOG(WARNING) << "another deployer process is running; aborting operation.";
    CloseHandle(hMutex);
    // MessageBox(NULL, L"正在執行另一項部署任務，請稍候再試。", L"【風語輸入法】",
    // MB_OK | MB_ICONINFORMATION);
    MSG_BY_IDS(IDS_STR_DEPLOYING_WAIT, IDS_STR_FENGYU,
               MB_OK | MB_ICONINFORMATION);
    return 1;
  }

  fengyu::Client client;
  if (client.Connect()) {
    LOG(INFO) << "Turning FengyuServer into maintenance mode.";
    client.StartMaintenance();
  }

  {
    RimeApi* rime = rime_get_api();
    if (!rime->sync_user_data()) {
      LOG(ERROR) << "Error synching user data.";
      CloseHandle(hMutex);
      return 1;
    }
    rime->join_maintenance_thread();
  }

  CloseHandle(hMutex);  // should be closed before resuming service.

  if (client.Connect()) {
    LOG(INFO) << "Resuming service.";
    client.EndMaintenance();
  }
  return 0;
}
