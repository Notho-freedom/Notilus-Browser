// notilus_cef_plugin.cpp
// Bridge léger Flutter (MD) - Pas de dépendance CEF directe
// Communique avec cef_worker.exe via Shared Memory et Named Pipes

#include "notilus_cef_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/texture_registrar.h>

#include "flutter_texture_registrar.h"
#include "flutter_plugin_registrar.h"

#include "shared_texture.h"

#include <windows.h>
#include <memory>
#include <string>
#include <thread>
#include <mutex>
#include <sstream>

namespace {

class NotilusCefPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar);

  NotilusCefPlugin(FlutterDesktopPluginRegistrarRef registrar);
  virtual ~NotilusCefPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void InitCEF(int width, int height);
  void LoadURL(const std::string& url);
  void SendMouseClick(double x, double y, int button, bool down);
  void SendMouseMove(double x, double y);
  void SendKey(int key_code, bool down);
  void SendText(const std::string& text);
  void Resize(int width, int height);
  void StopCEFWorker();

  void SendCommandToWorker(const std::string& command);

  FlutterDesktopPluginRegistrarRef registrar_;
  FlutterDesktopTextureRegistrarRef texture_registrar_;
  std::unique_ptr<SharedTexture> shared_texture_;
  HANDLE shared_memory_{INVALID_HANDLE_VALUE};
  HANDLE worker_process_{INVALID_HANDLE_VALUE};
  int64_t texture_id_{-1};
  int texture_width_{1280};
  int texture_height_{720};
  std::mutex command_mutex_;
};

// Static
void NotilusCefPlugin::RegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  auto plugin = std::make_unique<NotilusCefPlugin>(registrar);
  
  auto* windows_registrar = flutter::PluginRegistrarManager::GetInstance()
      ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar);
  
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

NotilusCefPlugin::NotilusCefPlugin(FlutterDesktopPluginRegistrarRef registrar)
    : registrar_(registrar) {
  texture_registrar_ = FlutterDesktopRegistrarGetTextureRegistrar(registrar);
}

NotilusCefPlugin::~NotilusCefPlugin() {
  StopCEFWorker();
  
  if (texture_id_ != -1 && texture_registrar_) {
    FlutterDesktopTextureRegistrarUnregisterExternalTexture(
        texture_registrar_, texture_id_, nullptr, nullptr);
  }
  
  if (shared_memory_ != INVALID_HANDLE_VALUE) {
    CloseHandle(shared_memory_);
  }
}

void NotilusCefPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());

  if (method_call.method_name() == "init") {
    int width = texture_width_;
    int height = texture_height_;
    
    if (args) {
      auto width_it = args->find(flutter::EncodableValue("width"));
      auto height_it = args->find(flutter::EncodableValue("height"));
      
      if (width_it != args->end()) {
        if (auto w = std::get_if<int>(&width_it->second)) {
          width = *w;
        }
      }
      if (height_it != args->end()) {
        if (auto h = std::get_if<int>(&height_it->second)) {
          height = *h;
        }
      }
    }
    
    InitCEF(width, height);
    result->Success(flutter::EncodableValue(texture_id_));
  }
  else if (method_call.method_name() == "loadUrl") {
    std::string url = "about:blank";
    if (args) {
      auto url_it = args->find(flutter::EncodableValue("url"));
      if (url_it != args->end()) {
        if (auto u = std::get_if<std::string>(&url_it->second)) {
          url = *u;
        }
      }
    }
    LoadURL(url);
    result->Success();
  }
  else if (method_call.method_name() == "mouseClick") {
    double x = 0, y = 0;
    int button = 0;
    bool down = true;
    
    if (args) {
      auto x_it = args->find(flutter::EncodableValue("x"));
      auto y_it = args->find(flutter::EncodableValue("y"));
      auto btn_it = args->find(flutter::EncodableValue("button"));
      auto down_it = args->find(flutter::EncodableValue("down"));
      
      if (x_it != args->end() && std::holds_alternative<double>(x_it->second)) {
        x = std::get<double>(x_it->second);
      }
      if (y_it != args->end() && std::holds_alternative<double>(y_it->second)) {
        y = std::get<double>(y_it->second);
      }
      if (btn_it != args->end() && std::holds_alternative<int>(btn_it->second)) {
        button = std::get<int>(btn_it->second);
      }
      if (down_it != args->end() && std::holds_alternative<bool>(down_it->second)) {
        down = std::get<bool>(down_it->second);
      }
    }
    
    SendMouseClick(x, y, button, down);
    result->Success();
  }
  else if (method_call.method_name() == "mouseMove") {
    double x = 0, y = 0;
    
    if (args) {
      auto x_it = args->find(flutter::EncodableValue("x"));
      auto y_it = args->find(flutter::EncodableValue("y"));
      
      if (x_it != args->end() && std::holds_alternative<double>(x_it->second)) {
        x = std::get<double>(x_it->second);
      }
      if (y_it != args->end() && std::holds_alternative<double>(y_it->second)) {
        y = std::get<double>(y_it->second);
      }
    }
    
    SendMouseMove(x, y);
    result->Success();
  }
  else if (method_call.method_name() == "keyEvent") {
    int key_code = 0;
    bool down = true;
    
    if (args) {
      auto key_it = args->find(flutter::EncodableValue("keyCode"));
      auto down_it = args->find(flutter::EncodableValue("down"));
      
      if (key_it != args->end() && std::holds_alternative<int>(key_it->second)) {
        key_code = std::get<int>(key_it->second);
      }
      if (down_it != args->end() && std::holds_alternative<bool>(down_it->second)) {
        down = std::get<bool>(down_it->second);
      }
    }
    
    SendKey(key_code, down);
    result->Success();
  }
  else if (method_call.method_name() == "sendText") {
    std::string text;
    if (args) {
      auto text_it = args->find(flutter::EncodableValue("text"));
      if (text_it != args->end() && std::holds_alternative<std::string>(text_it->second)) {
        text = std::get<std::string>(text_it->second);
      }
    }
    SendText(text);
    result->Success();
  }
  else if (method_call.method_name() == "resize") {
    int width = texture_width_;
    int height = texture_height_;
    
    if (args) {
      auto width_it = args->find(flutter::EncodableValue("width"));
      auto height_it = args->find(flutter::EncodableValue("height"));
      
      if (width_it != args->end() && std::holds_alternative<int>(width_it->second)) {
        width = std::get<int>(width_it->second);
      }
      if (height_it != args->end() && std::holds_alternative<int>(height_it->second)) {
        height = std::get<int>(height_it->second);
      }
    }
    
    Resize(width, height);
    result->Success();
  }
  else if (method_call.method_name() == "dispose") {
    StopCEFWorker();
    result->Success();
  }
  else {
    result->NotImplemented();
  }
}

void NotilusCefPlugin::InitCEF(int width, int height) {
  texture_width_ = width;
  texture_height_ = height;
  
  // Créer shared memory
  size_t frame_size = sizeof(SharedFrame) + (width * height * 4);
  shared_memory_ = CreateFileMapping(
      INVALID_HANDLE_VALUE,
      NULL,
      PAGE_READWRITE,
      0,
      static_cast<DWORD>(frame_size),
      TEXT("CEF_SHARED_PIXELS"));

  if (!shared_memory_ || shared_memory_ == INVALID_HANDLE_VALUE) {
    return;
  }

  // Lancer le worker CEF
  std::wstring exe_path = L"cef_worker.exe";
  std::wstringstream args;
  args << exe_path << L" "
       << reinterpret_cast<uintptr_t>(shared_memory_) << L" "
       << width << L" " << height;

  STARTUPINFO si = { sizeof(si) };
  PROCESS_INFORMATION pi;

  if (CreateProcess(
          exe_path.c_str(),
          const_cast<LPWSTR>(args.str().c_str()),
          NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
    worker_process_ = pi.hProcess;
    CloseHandle(pi.hThread);
  }

  // Créer la texture partagée
  shared_texture_ = std::make_unique<SharedTexture>(shared_memory_, width, height);
  
  // Enregistrer la texture Flutter
  FlutterDesktopTextureInfo texture_info;
  texture_info.type = kFlutterDesktopPixelBufferTexture;
  texture_info.pixel_buffer_config.callback = SharedTexture::GetPixelBuffer;
  texture_info.pixel_buffer_config.user_data = shared_texture_.get();

  texture_id_ = FlutterDesktopTextureRegistrarRegisterExternalTexture(
      texture_registrar_, &texture_info);

  // Callback pour notifier les nouvelles frames
  shared_texture_->SetFrameCallback([this]() {
    if (texture_id_ != -1 && texture_registrar_) {
      FlutterDesktopTextureRegistrarMarkExternalTextureFrameAvailable(
          texture_registrar_, texture_id_);
    }
  });
}

void NotilusCefPlugin::LoadURL(const std::string& url) {
  SendCommandToWorker("LOAD_URL:" + url);
}

void NotilusCefPlugin::SendMouseClick(double x, double y, int button, bool down) {
  std::stringstream cmd;
  cmd << "MOUSE_CLICK:" << static_cast<int>(x) << "," 
      << static_cast<int>(y) << "," << button << "," << (down ? "1" : "0");
  SendCommandToWorker(cmd.str());
}

void NotilusCefPlugin::SendMouseMove(double x, double y) {
  std::stringstream cmd;
  cmd << "MOUSE_MOVE:" << static_cast<int>(x) << "," << static_cast<int>(y);
  SendCommandToWorker(cmd.str());
}

void NotilusCefPlugin::SendKey(int key_code, bool down) {
  std::stringstream cmd;
  cmd << "KEY:" << key_code << "," << (down ? "1" : "0");
  SendCommandToWorker(cmd.str());
}

void NotilusCefPlugin::SendText(const std::string& text) {
  SendCommandToWorker("TEXT:" + text);
}

void NotilusCefPlugin::Resize(int width, int height) {
  texture_width_ = width;
  texture_height_ = height;
  std::stringstream cmd;
  cmd << "RESIZE:" << width << "," << height;
  SendCommandToWorker(cmd.str());
}

void NotilusCefPlugin::StopCEFWorker() {
  if (worker_process_ != INVALID_HANDLE_VALUE) {
    SendCommandToWorker("EXIT:");
    TerminateProcess(worker_process_, 0);
    WaitForSingleObject(worker_process_, 5000);
    CloseHandle(worker_process_);
    worker_process_ = INVALID_HANDLE_VALUE;
  }
}

void NotilusCefPlugin::SendCommandToWorker(const std::string& command) {
  std::lock_guard<std::mutex> lock(command_mutex_);
  
  HANDLE pipe = CreateFile(
      TEXT("\\\\.\\pipe\\CEF_COMMAND_PIPE"),
      GENERIC_WRITE,
      0,
      NULL,
      OPEN_EXISTING,
      0,
      NULL);

  if (pipe != INVALID_HANDLE_VALUE) {
    DWORD written;
    WriteFile(pipe, command.c_str(), static_cast<DWORD>(command.size()), &written, NULL);
    FlushFileBuffers(pipe);
    CloseHandle(pipe);
  }
}

}  // namespace

void NotilusCefPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  NotilusCefPlugin::RegisterWithRegistrar(registrar);
}

