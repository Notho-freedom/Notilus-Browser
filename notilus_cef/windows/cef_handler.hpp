#ifndef CEF_HANDLER_HPP
#define CEF_HANDLER_HPP

#include "include/cef_client.h"
#include "include/cef_render_handler.h"
#include "include/cef_browser.h"
#include "include/cef_keyboard_handler.h"
#include "include/cef_context_menu_handler.h"
#include "include/cef_display_handler.h"
#include "include/cef_life_span_handler.h"
#include "include/cef_load_handler.h"

#include "texture_bridge.hpp"

#include <mutex>
#include <atomic>

/// Handler principal pour le navigateur CEF
/// Gère le rendu offscreen et la communication avec Flutter
class BrowserHandler : public CefClient,
                       public CefRenderHandler,
                       public CefDisplayHandler,
                       public CefLifeSpanHandler,
                       public CefLoadHandler,
                       public CefKeyboardHandler,
                       public CefContextMenuHandler {
 public:
  explicit BrowserHandler(TextureBridge* bridge);
  
  // CefClient
  CefRefPtr<CefRenderHandler> GetRenderHandler() override { return this; }
  CefRefPtr<CefDisplayHandler> GetDisplayHandler() override { return this; }
  CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override { return this; }
  CefRefPtr<CefLoadHandler> GetLoadHandler() override { return this; }
  CefRefPtr<CefKeyboardHandler> GetKeyboardHandler() override { return this; }
  CefRefPtr<CefContextMenuHandler> GetContextMenuHandler() override { return this; }
  
  // CefRenderHandler - Rendu offscreen
  void GetViewRect(CefRefPtr<CefBrowser> browser, CefRect& rect) override;
  void OnPaint(CefRefPtr<CefBrowser> browser,
               PaintElementType type,
               const RectList& dirtyRects,
               const void* buffer,
               int width,
               int height) override;
  
  // CefDisplayHandler
  void OnTitleChange(CefRefPtr<CefBrowser> browser, const CefString& title) override;
  
  // CefLifeSpanHandler
  void OnAfterCreated(CefRefPtr<CefBrowser> browser) override;
  bool OnBeforePopup(CefRefPtr<CefBrowser> browser,
                     CefRefPtr<CefFrame> frame,
                     const CefString& target_url,
                     const CefString& target_frame_name,
                     WindowOpenDisposition target_disposition,
                     bool user_gesture,
                     const CefPopupFeatures& popupFeatures,
                     CefWindowInfo& windowInfo,
                     CefRefPtr<CefClient>& client,
                     CefBrowserSettings& settings,
                     CefRefPtr<CefDictionaryValue>& extra_info,
                     bool* no_javascript_access) override;
  
  // CefLoadHandler
  void OnLoadStart(CefRefPtr<CefBrowser> browser,
                   CefRefPtr<CefFrame> frame,
                   TransitionType transition_type) override;
  void OnLoadEnd(CefRefPtr<CefBrowser> browser,
                 CefRefPtr<CefFrame> frame,
                 int httpStatusCode) override;
  void OnLoadError(CefRefPtr<CefBrowser> browser,
                   CefRefPtr<CefFrame> frame,
                   ErrorCode errorCode,
                   const CefString& errorText,
                   const CefString& failedUrl) override;
  
  // CefKeyboardHandler
  bool OnPreKeyEvent(CefRefPtr<CefBrowser> browser,
                     const CefKeyEvent& event,
                     CefEventHandle os_event,
                     bool* is_keyboard_shortcut) override;
  
  // CefContextMenuHandler
  void OnBeforeContextMenu(CefRefPtr<CefBrowser> browser,
                           CefRefPtr<CefFrame> frame,
                           CefRefPtr<CefContextMenuParams> params,
                           CefRefPtr<CefMenuModel> model) override;
  bool OnContextMenuCommand(CefRefPtr<CefBrowser> browser,
                            CefRefPtr<CefFrame> frame,
                            CefRefPtr<CefContextMenuParams> params,
                            int command_id,
                            EventFlags event_flags) override;
  
  // Utilitaires
  CefRefPtr<CefBrowser> browser() const { return browser_; }
  void SetSize(int width, int height);
  
  IMPLEMENT_REFCOUNTING(BrowserHandler);

 private:
  TextureBridge* bridge_;
  CefRefPtr<CefBrowser> browser_;
  
  std::mutex size_mutex_;
  int width_;
  int height_;
  
  std::atomic<bool> is_painting_;
};

#endif  // CEF_HANDLER_HPP

