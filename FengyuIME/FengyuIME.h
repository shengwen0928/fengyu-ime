#pragma once
#include <FengyuIPC.h>
#include <KeyEvent.h>

#define MAX_COMPOSITION_SIZE 256

struct CompositionInfo {
  COMPOSITIONSTRING cs;
  WCHAR szCompStr[MAX_COMPOSITION_SIZE];
  WCHAR szResultStr[MAX_COMPOSITION_SIZE];
  void Reset() {
    memset(this, 0, sizeof(*this));
    cs.dwSize = sizeof(*this);
    cs.dwCompStrOffset = (DWORD)((ptrdiff_t)&szCompStr - (ptrdiff_t)this);
    cs.dwResultStrOffset = (DWORD)((ptrdiff_t)&szResultStr - (ptrdiff_t)this);
  }
};

class FengyuIME;

class HIMCMap : public std::map<HIMC, std::shared_ptr<FengyuIME> > {
 public:
  HIMCMap() : m_valid(true) {}
  ~HIMCMap() { m_valid = false; }
  std::mutex& get_mutex() { return m_mutex; }
  bool is_valid() const { return m_valid; }

 private:
  bool m_valid;
  std::mutex m_mutex;
};

class FengyuIME {
 public:
  static HINSTANCE GetModuleInstance();
  static void SetModuleInstance(HINSTANCE hModule);
  static HRESULT RegisterUIClass();
  static HRESULT UnregisterUIClass();
  static LPCWSTR GetUIClassName();
  static LRESULT WINAPI UIWndProc(HWND hWnd, UINT uMsg, WPARAM wp, LPARAM lp);
  static BOOL IsIMEMessage(UINT uMsg);
  static std::shared_ptr<FengyuIME> GetInstance(HIMC hIMC);
  static void Cleanup();

  FengyuIME(HIMC hIMC);
  LRESULT OnIMESelect(BOOL fSelect);
  LRESULT OnIMEFocus(BOOL fFocus);
  LRESULT OnUIMessage(HWND hWnd, UINT uMsg, WPARAM wp, LPARAM lp);
  BOOL ProcessKeyEvent(UINT vKey, KeyInfo kinfo, const LPBYTE lpbKeyState);

 private:
  HRESULT _Initialize();
  HRESULT _Finalize();
  LRESULT _OnIMENotify(LPINPUTCONTEXT lpIMC, WPARAM wp, LPARAM lp);
  HRESULT _StartComposition();
  HRESULT _EndComposition(LPCWSTR composition);
  HRESULT _AddIMEMessage(UINT msg, WPARAM wp, LPARAM lp);
  void _SetCandidatePos(LPINPUTCONTEXT lpIMC);
  void _SetCompositionWindow(LPINPUTCONTEXT lpIMC);
  void _UpdateInputPosition(LPINPUTCONTEXT lpIMC, POINT pt);

 private:
  static HINSTANCE s_hModule;
  static HIMCMap s_instances;
  HIMC m_hIMC;
  bool m_composing;
  bool m_preferCandidatePos;
  fengyu::Client m_client;
};
