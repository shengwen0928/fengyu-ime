#pragma once
#include <FengyuUI.h>
#include "ctffunc.h"

class FengyuTSF;

class CCandidateList : public ITfIntegratableCandidateListUIElement,
                       public ITfCandidateListUIElementBehavior {
 public:
  CCandidateList(com_ptr<FengyuTSF> pTextService);
  ~CCandidateList();

  // IUnknown
  STDMETHODIMP QueryInterface(REFIID riid, _Outptr_ void** ppvObj);
  STDMETHODIMP_(ULONG) AddRef(void);
  STDMETHODIMP_(ULONG) Release(void);

  // ITfUIElement
  STDMETHODIMP GetDescription(BSTR* pbstr);
  STDMETHODIMP GetGUID(GUID* pguid);
  STDMETHODIMP Show(BOOL showCandidateWindow);
  STDMETHODIMP IsShown(BOOL* pIsShow);

  // ITfCandidateListUIElement
  STDMETHODIMP GetUpdatedFlags(DWORD* pdwFlags);
  STDMETHODIMP GetDocumentMgr(ITfDocumentMgr** ppdim);
  STDMETHODIMP GetCount(UINT* pCandidateCount);
  STDMETHODIMP GetSelection(UINT* pSelectedCandidateIndex);
  STDMETHODIMP GetString(UINT uIndex, BSTR* pbstr);
  STDMETHODIMP GetPageIndex(UINT* pIndex, UINT uSize, UINT* puPageCnt);
  STDMETHODIMP SetPageIndex(UINT* pIndex, UINT uPageCnt);
  STDMETHODIMP GetCurrentPage(UINT* puPage);

  // ITfCandidateListUIElementBehavior methods
  STDMETHODIMP SetSelection(UINT nIndex);
  STDMETHODIMP Finalize(void);
  STDMETHODIMP Abort(void);

  // ITfIntegratableCandidateListUIElement methods
  STDMETHODIMP SetIntegrationStyle(GUID guidIntegrationStyle);
  STDMETHODIMP GetSelectionStyle(
      _Out_ TfIntegratableCandidateListSelectionStyle* ptfSelectionStyle);
  STDMETHODIMP OnKeyDown(_In_ WPARAM wParam,
                         _In_ LPARAM lParam,
                         _Out_ BOOL* pIsEaten);
  STDMETHODIMP ShowCandidateNumbers(_Out_ BOOL* pIsShow);
  STDMETHODIMP FinalizeExactCompositionString();

  /* Update */
  void UpdateUI(const fengyu::Context& ctx, const fengyu::Status& status);
  void UpdateStyle(const fengyu::UIStyle& sty);
  void UpdateInputPosition(RECT const& rc);
  void Destroy();
  void DestroyAll();
  void StartUI();
  void EndUI();

  com_ptr<ITfContext> GetContextDocument();
  bool GetIsReposition() {
    if (_ui)
      return _ui->GetIsReposition();
    else
      return false;
  }

  fengyu::UIStyle& style();

 private:
  // void _UpdateOwner();
  HWND _GetActiveWnd();
  HRESULT _UpdateUIElement();

  // for CCandidateList::EndUI(), after ending composition ||
  // FengyuTSF::_EndUI()
  void _DisposeUIWindow();
  // for CCandidateList::Destroy(), when inputing app exit
  void _DisposeUIWindowAll();
  void _MakeUIWindow();

  std::unique_ptr<fengyu::UI> _ui;
  DWORD _cRef;
  com_ptr<FengyuTSF> _tsf;
  DWORD uiid;
  TfIntegratableCandidateListSelectionStyle _selectionStyle =
      STYLE_ACTIVE_SELECTION;

  BOOL _pbShow;
  fengyu::UIStyle _style;

  com_ptr<ITfContext> _pContextDocument;
};
