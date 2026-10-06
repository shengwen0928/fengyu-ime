#pragma once
#include <FengyuIPC.h>
#include <FengyuUI.h>
#include <map>
#include <string>

#include <rime_api.h>

struct CaseInsensitiveCompare {
  bool operator()(const std::string& str1, const std::string& str2) const {
    std::string str1Lower, str2Lower;
    std::transform(str1.begin(), str1.end(), std::back_inserter(str1Lower),
                   [](char c) { return std::tolower(c); });
    std::transform(str2.begin(), str2.end(), std::back_inserter(str2Lower),
                   [](char c) { return std::tolower(c); });
    return str1Lower < str2Lower;
  }
};

typedef std::map<std::string, bool> AppOptions;
typedef std::map<std::string, AppOptions, CaseInsensitiveCompare>
    AppOptionsByAppName;

struct SessionStatus {
  SessionStatus() : style(fengyu::UIStyle()), __synced(false), session_id(0) {
    RIME_STRUCT(RimeStatus, status);
  }
  fengyu::UIStyle style;
  RimeStatus status;
  bool __synced;
  RimeSessionId session_id;
};
typedef std::map<DWORD, SessionStatus> SessionStatusMap;
typedef DWORD FengyuSessionId;
class RimeWithFengyuHandler : public fengyu::RequestHandler {
 public:
  RimeWithFengyuHandler(fengyu::UI* ui);
  virtual ~RimeWithFengyuHandler();
  virtual void Initialize();
  virtual void Finalize();
  virtual DWORD FindSession(FengyuSessionId ipc_id);
  virtual DWORD AddSession(LPWSTR buffer, EatLine eat = 0);
  virtual DWORD RemoveSession(FengyuSessionId ipc_id);
  virtual BOOL ProcessKeyEvent(fengyu::KeyEvent keyEvent,
                               FengyuSessionId ipc_id,
                               EatLine eat);
  virtual void CommitComposition(FengyuSessionId ipc_id);
  virtual void ClearComposition(FengyuSessionId ipc_id);
  virtual void SelectCandidateOnCurrentPage(size_t index,
                                            FengyuSessionId ipc_id);
  virtual bool HighlightCandidateOnCurrentPage(size_t index,
                                               FengyuSessionId ipc_id,
                                               EatLine eat);
  virtual bool ChangePage(bool backward, FengyuSessionId ipc_id, EatLine eat);
  virtual void FocusIn(DWORD param, FengyuSessionId ipc_id);
  virtual void FocusOut(DWORD param, FengyuSessionId ipc_id);
  virtual void UpdateInputPosition(RECT const& rc, FengyuSessionId ipc_id);
  virtual void StartMaintenance();
  virtual void EndMaintenance();
  virtual void SetOption(FengyuSessionId ipc_id,
                         const std::string& opt,
                         bool val);
  virtual void UpdateColorTheme(BOOL darkMode);

  void OnUpdateUI(std::function<void()> const& cb);

 private:
  void _Setup();
  bool _IsDeployerRunning();
  void _UpdateUI(FengyuSessionId ipc_id);
  void _LoadSchemaSpecificSettings(FengyuSessionId ipc_id,
                                   const std::string& schema_id);
  void _LoadAppInlinePreeditSet(FengyuSessionId ipc_id,
                                bool ignore_app_name = false);
  bool _ShowMessage(fengyu::Context& ctx, fengyu::Status& status);
  bool _Respond(FengyuSessionId ipc_id, EatLine eat);
  void _ReadClientInfo(FengyuSessionId ipc_id, LPWSTR buffer);
  void _GetCandidateInfo(fengyu::CandidateInfo& cinfo, RimeContext& ctx);
  void _GetStatus(fengyu::Status& stat,
                  FengyuSessionId ipc_id,
                  fengyu::Context& ctx);
  void _GetContext(fengyu::Context& ctx, RimeSessionId session_id);
  void _UpdateShowNotifications(RimeConfig* config, bool initialize = false);

  bool _IsSessionTSF(RimeSessionId session_id);
  void _UpdateInlinePreeditStatus(FengyuSessionId ipc_id);

  RimeSessionId to_session_id(FengyuSessionId ipc_id) {
    return m_session_status_map[ipc_id].session_id;
  }
  SessionStatus& get_session_status(FengyuSessionId ipc_id) {
    return m_session_status_map[ipc_id];
  }
  SessionStatus& new_session_status(FengyuSessionId ipc_id) {
    return m_session_status_map[ipc_id] = SessionStatus();
  }

  AppOptionsByAppName m_app_options;
  fengyu::UI* m_ui;  // reference
  DWORD m_active_session;
  bool m_disabled;
  std::string m_last_schema_id;
  std::string m_last_app_name;
  fengyu::UIStyle m_base_style;
  std::map<std::string, bool> m_show_notifications;
  std::map<std::string, bool> m_show_notifications_base;
  std::function<void()> _UpdateUICallback;

  static void OnNotify(void* context_object,
                       uintptr_t session_id,
                       const char* message_type,
                       const char* message_value);
  static std::string m_message_type;
  static std::string m_message_value;
  static std::string m_message_label;
  static std::string m_option_name;
  SessionStatusMap m_session_status_map;
  bool m_current_dark_mode;
  bool m_global_ascii_mode;
  int m_show_notifications_time;
  DWORD m_pid;
};
