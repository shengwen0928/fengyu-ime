#pragma once
#include <FengyuUI.h>
#include <FengyuIPC.h>
#include "SystemTraySDK.h"

#define WM_FENGYU_TRAY_NOTIFY (FENGYU_IPC_LAST_COMMAND + 100)

class FengyuTrayIcon : public CSystemTray {
 public:
  enum FengyuTrayMode {
    INITIAL,
    ZHUNG,
    ASCII,
    DISABLED,
  };

  FengyuTrayIcon(fengyu::UI& ui);

  BOOL Create(HWND hTargetWnd);
  void Refresh();

 protected:
  virtual void CustomizeMenu(HMENU hMenu);

  fengyu::UIStyle& m_style;
  fengyu::Status& m_status;
  FengyuTrayMode m_mode;
  std::wstring m_schema_zhung_icon;
  std::wstring m_schema_ascii_icon;
  bool m_disabled;
};
