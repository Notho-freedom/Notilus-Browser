#include "include/cef_app.h"
#include "include/cef_client.h"
#include "include/cef_render_handler.h"
#include "include/cef_browser.h"
#include "include/cef_frame.h"
#include "include/cef_keyboard_handler.h"
#include "include/cef_context_menu_handler.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>

// Include C API
#include "flutter_texture_registrar.h"
#include "flutter_plugin_registrar.h"

#include <memory>
#include <string>
#include <thread>
#include <mutex>
#include <atomic>

#include "cef_handler.hpp"
#include "texture_bridge.hpp"

namespace {

class NotilusCefPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar);

  NotilusCefPlugin(FlutterDesktopTextureRegistrarRef texture_registrar);
  virtual ~NotilusCefPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void InitCEF(int width, int height, const std::string& initial_url);
  void LoadURL(const std::string& url);
  void SendMouseClick(double x, double y, int button, bool down);
  void SendMouseMove(double x, double y);
  void SendKey(int key_code, bool down);
  void SendText(const std::string& text);
  void EvaluateJavaScript(const std::string& code, 
                          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void Resize(int width, int height);
  void GoBack();
  void GoForward();
  void Reload();
  void Stop();
  void Dispose();

  FlutterDesktopTextureRegistrarRef texture_registrar_;
  std::unique_ptr<TextureBridge> texture_bridge_;
  CefRefPtr<BrowserHandler> browser_handler_;
  std::atomic<bool> cef_initialized_{false};
  std::mutex cef_mutex_;
  
  int texture_width_;
  int texture_height_;
};

// Helper function pour accéder aux valeurs de la map
template<typename T>
T GetMapValue(const flutter::EncodableMap& map, const std::string& key, const T& default_value) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it != map.end()) {
    if (auto value = std::get_if<T>(&it->second)) {
      return *value;
    }
  }
  return default_value;
}

// Static
void NotilusCefPlugin::RegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // Obtenir le PluginRegistrarWindows à partir du registrar C
  auto* windows_registrar = flutter::PluginRegistrarManager::GetInstance()
      ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar);
  
  // Obtenir le texture registrar via l'API C
  FlutterDesktopTextureRegistrarRef texture_registrar = 
      FlutterDesktopRegistrarGetTextureRegistrar(registrar);
  
  auto plugin = std::make_unique<NotilusCefPlugin>(texture_registrar);
  
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          windows_registrar->messenger(), "notilus_cef",
          &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  windows_registrar->AddPlugin(std::move(plugin));
}

NotilusCefPlugin::NotilusCefPlugin(FlutterDesktopTextureRegistrarRef texture_registrar)
    : texture_registrar_(texture_registrar),
      texture_width_(1280),
      texture_height_(720) {
}

NotilusCefPlugin::~NotilusCefPlugin() {
  Dispose();
}

void NotilusCefPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const auto& method_name = method_call.method_name();
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());

  if (method_name == "init") {
    int width = 1280;
    int height = 720;
    std::string initial_url = "https://flutter.dev";
    
    if (args) {
      width = GetMapValue<int32_t>(*args, "width", width);
      height = GetMapValue<int32_t>(*args, "height", height);
      initial_url = GetMapValue<std::string>(*args, "initialUrl", initial_url);
    }
    
    texture_width_ = width;
    texture_height_ = height;
    InitCEF(width, height, initial_url);
    
    if (texture_bridge_) {
      result->Success(flutter::EncodableValue(static_cast<int64_t>(texture_bridge_->id())));
    } else {
      result->Error("INIT_FAILED", "Échec de l'initialisation CEF");
    }
  }
  else if (method_name == "loadUrl") {
    if (args) {
      std::string url = GetMapValue<std::string>(*args, "url", "");
      if (!url.empty()) {
        LoadURL(url);
        result->Success();
      } else {
        result->Error("INVALID_ARGUMENT", "URL manquante");
      }
    } else {
      result->Error("INVALID_ARGUMENT", "Arguments manquants");
    }
  }
  else if (method_name == "sendMouseClick") {
    if (args) {
      double x = GetMapValue<double>(*args, "x", 0.0);
      double y = GetMapValue<double>(*args, "y", 0.0);
      int button = GetMapValue<int32_t>(*args, "button", 0);
      bool down = GetMapValue<bool>(*args, "down", true);
      
      SendMouseClick(x, y, button, down);
      result->Success();
    } else {
      result->Error("INVALID_ARGUMENT", "Arguments manquants");
    }
  }
  else if (method_name == "sendMouseMove") {
    if (args) {
      double x = GetMapValue<double>(*args, "x", 0.0);
      double y = GetMapValue<double>(*args, "y", 0.0);
      
      SendMouseMove(x, y);
      result->Success();
    } else {
      result->Error("INVALID_ARGUMENT", "Arguments manquants");
    }
  }
  else if (method_name == "sendKey") {
    if (args) {
      int key_code = GetMapValue<int32_t>(*args, "keyCode", 0);
      bool down = GetMapValue<bool>(*args, "down", true);
      
      SendKey(key_code, down);
      result->Success();
    } else {
      result->Error("INVALID_ARGUMENT", "Arguments manquants");
    }
  }
  else if (method_name == "sendText") {
    if (args) {
      std::string text = GetMapValue<std::string>(*args, "text", "");
      if (!text.empty()) {
        SendText(text);
        result->Success();
      } else {
        result->Error("INVALID_ARGUMENT", "Texte manquant");
      }
    } else {
      result->Error("INVALID_ARGUMENT", "Arguments manquants");
    }
  }
  else if (method_name == "evaluateJavaScript") {
    if (args) {
      std::string code = GetMapValue<std::string>(*args, "code", "");
      if (!code.empty()) {
        EvaluateJavaScript(code, std::move(result));
        return; // result sera appelé dans EvaluateJavaScript
      } else {
        result->Error("INVALID_ARGUMENT", "Code JavaScript manquant");
      }
    } else {
      result->Error("INVALID_ARGUMENT", "Arguments manquants");
    }
  }
  else if (method_name == "resize") {
    if (args) {
      int width = GetMapValue<int32_t>(*args, "width", texture_width_);
      int height = GetMapValue<int32_t>(*args, "height", texture_height_);
      
      Resize(width, height);
      result->Success();
    } else {
      result->Error("INVALID_ARGUMENT", "Arguments manquants");
    }
  }
  else if (method_name == "getCurrentUrl") {
    if (browser_handler_ && browser_handler_->browser()) {
      auto frame = browser_handler_->browser()->GetMainFrame();
      if (frame) {
        result->Success(flutter::EncodableValue(frame->GetURL().ToString()));
      } else {
        result->Success(flutter::EncodableValue(""));
      }
    } else {
      result->Success(flutter::EncodableValue(""));
    }
  }
  else if (method_name == "goBack") {
    GoBack();
    result->Success();
  }
  else if (method_name == "goForward") {
    GoForward();
    result->Success();
  }
  else if (method_name == "reload") {
    Reload();
    result->Success();
  }
  else if (method_name == "stop") {
    Stop();
    result->Success();
  }
  else if (method_name == "dispose") {
    Dispose();
    result->Success();
  }
  else {
    result->NotImplemented();
  }
}

void NotilusCefPlugin::InitCEF(int width, int height, const std::string& initial_url) {
  std::lock_guard<std::mutex> lock(cef_mutex_);
  
  if (cef_initialized_) {
    return;
  }

  CefMainArgs main_args(GetModuleHandle(nullptr));
  
  CefSettings settings;
  settings.windowless_rendering_enabled = true;
  settings.no_sandbox = true;
  settings.multi_threaded_message_loop = false;
  settings.log_severity = LOGSEVERITY_WARNING;
  
  // Chemin vers les ressources CEF
  // Les ressources sont dans Resources/, les locales dans Resources/locales/
  std::string cef_path = "cef";
  std::string resources_path = cef_path + "/Resources";
  std::string locales_path = resources_path + "/locales";
  
  CefString(&settings.resources_dir_path).FromASCII(resources_path.c_str());
  CefString(&settings.locales_dir_path).FromASCII(locales_path.c_str());
  
  bool result = CefInitialize(main_args, settings, nullptr, nullptr);
  if (!result) {
    return;
  }
  
  cef_initialized_ = true;
  
  // Créer le bridge de texture
  texture_bridge_ = std::make_unique<TextureBridge>(texture_registrar_, width, height);
  
  // Créer le handler du navigateur
  browser_handler_ = new BrowserHandler(texture_bridge_.get());
  browser_handler_->SetSize(width, height);
  
  // Créer le navigateur
  CefBrowserSettings browser_settings;
  browser_settings.windowless_frame_rate = 60;
  
  CefWindowInfo window_info;
  window_info.SetAsWindowless(nullptr);
  
  CefBrowserHost::CreateBrowser(window_info, browser_handler_.get(),
                                initial_url, browser_settings,
                                nullptr, nullptr);
  
  // Le navigateur sera créé de manière asynchrone
  // OnAfterCreated() sera appelé quand il sera prêt
}

void NotilusCefPlugin::LoadURL(const std::string& url) {
  if (browser_handler_ && browser_handler_->browser()) {
    auto frame = browser_handler_->browser()->GetMainFrame();
    if (frame) {
      frame->LoadURL(url);
    }
  }
}

void NotilusCefPlugin::SendMouseClick(double x, double y, int button, bool down) {
  if (browser_handler_ && browser_handler_->browser()) {
    CefMouseEvent mouse_event;
    mouse_event.x = static_cast<int>(x);
    mouse_event.y = static_cast<int>(y);
    mouse_event.modifiers = 0;
    
    CefBrowserHost::MouseButtonType btn_type = MBT_LEFT;
    if (button == 1) btn_type = MBT_MIDDLE;
    else if (button == 2) btn_type = MBT_RIGHT;
    
    browser_handler_->browser()->GetHost()->SendMouseClickEvent(
        mouse_event, btn_type, !down, 1);
  }
}

void NotilusCefPlugin::SendMouseMove(double x, double y) {
  if (browser_handler_ && browser_handler_->browser()) {
    CefMouseEvent mouse_event;
    mouse_event.x = static_cast<int>(x);
    mouse_event.y = static_cast<int>(y);
    mouse_event.modifiers = 0;
    
    browser_handler_->browser()->GetHost()->SendMouseMoveEvent(mouse_event, false);
  }
}

void NotilusCefPlugin::SendKey(int key_code, bool down) {
  if (browser_handler_ && browser_handler_->browser()) {
    CefKeyEvent key_event;
    key_event.windows_key_code = key_code;
    key_event.native_key_code = key_code;
    key_event.is_system_key = false;
    key_event.type = down ? KEYEVENT_KEYDOWN : KEYEVENT_KEYUP;
    key_event.modifiers = 0;
    
    browser_handler_->browser()->GetHost()->SendKeyEvent(key_event);
  }
}

void NotilusCefPlugin::SendText(const std::string& text) {
  if (browser_handler_ && browser_handler_->browser()) {
    for (char c : text) {
      CefKeyEvent key_event;
      key_event.character = c;
      key_event.unmodified_character = c;
      key_event.native_key_code = static_cast<int>(c);
      key_event.windows_key_code = static_cast<int>(c);
      key_event.type = KEYEVENT_CHAR;
      key_event.modifiers = 0;
      
      browser_handler_->browser()->GetHost()->SendKeyEvent(key_event);
    }
  }
}

void NotilusCefPlugin::EvaluateJavaScript(const std::string& code,
                                         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (browser_handler_ && browser_handler_->browser()) {
    auto frame = browser_handler_->browser()->GetMainFrame();
    if (frame) {
      frame->ExecuteJavaScript(code, frame->GetURL(), 0);
      result->Success();
    } else {
      result->Error("NO_FRAME", "Aucun frame disponible");
    }
  } else {
    result->Error("NO_BROWSER", "Navigateur non initialisé");
  }
}

void NotilusCefPlugin::Resize(int width, int height) {
  texture_width_ = width;
  texture_height_ = height;
  
  if (browser_handler_) {
    browser_handler_->SetSize(width, height);
  }
  
  if (texture_bridge_) {
    texture_bridge_->SetSize(width, height);
  }
}

void NotilusCefPlugin::GoBack() {
  if (browser_handler_ && browser_handler_->browser()) {
    browser_handler_->browser()->GoBack();
  }
}

void NotilusCefPlugin::GoForward() {
  if (browser_handler_ && browser_handler_->browser()) {
    browser_handler_->browser()->GoForward();
  }
}

void NotilusCefPlugin::Reload() {
  if (browser_handler_ && browser_handler_->browser()) {
    browser_handler_->browser()->Reload();
  }
}

void NotilusCefPlugin::Stop() {
  if (browser_handler_ && browser_handler_->browser()) {
    browser_handler_->browser()->StopLoad();
  }
}

void NotilusCefPlugin::Dispose() {
  std::lock_guard<std::mutex> lock(cef_mutex_);
  
  if (browser_handler_) {
    if (browser_handler_->browser()) {
      browser_handler_->browser()->GetHost()->CloseBrowser(true);
    }
    browser_handler_ = nullptr;
  }
  
  texture_bridge_ = nullptr;
  
  if (cef_initialized_) {
    CefShutdown();
    cef_initialized_ = false;
  }
}

}  // namespace

void NotilusCefPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  NotilusCefPlugin::RegisterWithRegistrar(registrar);
}
