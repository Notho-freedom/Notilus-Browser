#include "cef_handler.hpp"

BrowserHandler::BrowserHandler(TextureBridge* bridge)
    : bridge_(bridge),
      width_(1280),
      height_(720),
      is_painting_(false) {
}

void BrowserHandler::GetViewRect(CefRefPtr<CefBrowser> browser, CefRect& rect) {
  std::lock_guard<std::mutex> lock(size_mutex_);
  rect = CefRect(0, 0, width_, height_);
}

void BrowserHandler::OnPaint(CefRefPtr<CefBrowser> browser,
                             PaintElementType type,
                             const RectList& dirtyRects,
                             const void* buffer,
                             int width,
                             int height) {
  // Ne traiter que les peintures de type PET_VIEW
  if (type != PET_VIEW) {
    return;
  }
  
  // Éviter les appels concurrents
  if (is_painting_.exchange(true)) {
    return;
  }
  
  // Mettre à jour la texture Flutter
  if (bridge_) {
    bridge_->UpdateTexture(buffer, width, height);
  }
  
  is_painting_ = false;
}

void BrowserHandler::OnAfterCreated(CefRefPtr<CefBrowser> browser) {
  browser_ = browser;
}

void BrowserHandler::OnTitleChange(CefRefPtr<CefBrowser> browser,
                                   const CefString& title) {
  // Peut être utilisé pour mettre à jour le titre de la fenêtre Flutter
  // si nécessaire
}

bool BrowserHandler::OnBeforePopup(CefRefPtr<CefBrowser> browser,
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
                                   bool* no_javascript_access) {
  // Ouvrir les popups dans le même navigateur
  if (browser) {
    browser->GetMainFrame()->LoadURL(target_url);
  }
  return true;  // Bloque la création d'une nouvelle fenêtre
}

void BrowserHandler::OnLoadStart(CefRefPtr<CefBrowser> browser,
                                 CefRefPtr<CefFrame> frame,
                                 TransitionType transition_type) {
  // Peut être utilisé pour afficher un indicateur de chargement
}

void BrowserHandler::OnLoadEnd(CefRefPtr<CefBrowser> browser,
                               CefRefPtr<CefFrame> frame,
                               int httpStatusCode) {
  // Peut être utilisé pour masquer l'indicateur de chargement
}

void BrowserHandler::OnLoadError(CefRefPtr<CefBrowser> browser,
                                 CefRefPtr<CefFrame> frame,
                                 ErrorCode errorCode,
                                 const CefString& errorText,
                                 const CefString& failedUrl) {
  // Peut être utilisé pour afficher une page d'erreur personnalisée
}

bool BrowserHandler::OnPreKeyEvent(CefRefPtr<CefBrowser> browser,
                                   const CefKeyEvent& event,
                                   CefEventHandle os_event,
                                   bool* is_keyboard_shortcut) {
  // Gérer les raccourcis clavier si nécessaire
  return false;  // Laisser CEF gérer l'événement
}

void BrowserHandler::OnBeforeContextMenu(CefRefPtr<CefBrowser> browser,
                                        CefRefPtr<CefFrame> frame,
                                        CefRefPtr<CefContextMenuParams> params,
                                        CefRefPtr<CefMenuModel> model) {
  // Personnaliser le menu contextuel si nécessaire
  // Par défaut, on laisse CEF gérer
}

bool BrowserHandler::OnContextMenuCommand(CefRefPtr<CefBrowser> browser,
                                          CefRefPtr<CefFrame> frame,
                                          CefRefPtr<CefContextMenuParams> params,
                                          int command_id,
                                          EventFlags event_flags) {
  // Gérer les commandes du menu contextuel
  return false;
}

void BrowserHandler::SetSize(int width, int height) {
  std::lock_guard<std::mutex> lock(size_mutex_);
  width_ = width;
  height_ = height;
  
  if (browser_) {
    browser_->GetHost()->WasResized();
  }
}

