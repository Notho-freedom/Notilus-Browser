// cef_worker.cpp
// Processus CEF autonome compilé avec MT (Multi-threaded static)
// Communique avec Flutter via Shared Memory et Named Pipes

#define CEF_USE_SANDBOX 0

#include "include/cef_app.h"
#include "include/cef_client.h"
#include "include/cef_render_handler.h"
#include "include/cef_browser.h"
#include "include/cef_frame.h"
#include "include/cef_keyboard_handler.h"
#include "include/cef_life_span_handler.h"
#include "include/cef_load_handler.h"

#include <windows.h>
#include <iostream>
#include <string>
#include <thread>
#include <mutex>
#include <atomic>

// Shared Memory Structure pour pixels
#pragma pack(push, 1)
struct SharedFrame {
    int width;
    int height;
    std::atomic<bool> frame_ready{false};
    std::atomic<bool> should_exit{false};
    // Les pixels commencent juste après cette structure
    // Accès via: reinterpret_cast<BYTE*>(frame) + sizeof(SharedFrame)
};
#pragma pack(pop)

// Named Pipe pour commandes
const char* PIPE_NAME = "\\\\.\\pipe\\CEF_COMMAND_PIPE";

class OffscreenRenderer : public CefClient,
                          public CefRenderHandler,
                          public CefLifeSpanHandler,
                          public CefLoadHandler,
                          public CefKeyboardHandler {
public:
    OffscreenRenderer(HANDLE shared_mem, int initial_width, int initial_height)
        : shared_memory_(shared_mem),
          width_(initial_width),
          height_(initial_height) {
        
        // Mapper la shared memory
        size_t frame_size = sizeof(SharedFrame) + (width_ * height_ * 4);
        frame_ = reinterpret_cast<SharedFrame*>(MapViewOfFile(
            shared_memory_, FILE_MAP_ALL_ACCESS, 0, 0, frame_size));
        
        if (frame_) {
            frame_->width = width_;
            frame_->height = height_;
        }
        
        // Créer l'event pour signaler les nouvelles frames
        texture_ready_ = CreateEvent(NULL, FALSE, FALSE, TEXT("CEF_TEXTURE_READY"));
    }

    ~OffscreenRenderer() {
        if (frame_) {
            UnmapViewOfFile(frame_);
        }
        if (texture_ready_) {
            CloseHandle(texture_ready_);
        }
    }

    // CefRenderHandler
    virtual void GetViewRect(CefRefPtr<CefBrowser> browser, CefRect& rect) override {
        rect = CefRect(0, 0, width_, height_);
    }

    virtual void OnPaint(CefRefPtr<CefBrowser> browser,
                        PaintElementType type,
                        const RectList& dirtyRects,
                        const void* buffer,
                        int width, int height) override {
        if (!frame_ || type != PET_VIEW) return;
        
        // Copier RGBA directement dans shared memory
        size_t pixel_count = width * height * 4;
        if (pixel_count <= (width_ * height_ * 4)) {
            BYTE* pixel_ptr = reinterpret_cast<BYTE*>(frame_) + sizeof(SharedFrame);
            memcpy(pixel_ptr, buffer, pixel_count);
            frame_->frame_ready.store(true);
            SetEvent(texture_ready_);
        }
    }

    // CefLifeSpanHandler
    virtual void OnAfterCreated(CefRefPtr<CefBrowser> browser) override {
        browser_ = browser;
    }

    virtual bool DoClose(CefRefPtr<CefBrowser> browser) override {
        return false;
    }

    virtual void OnBeforeClose(CefRefPtr<CefBrowser> browser) override {
        browser_ = nullptr;
    }

    // CefLoadHandler
    virtual void OnLoadStart(CefRefPtr<CefBrowser> browser,
                            CefRefPtr<CefFrame> frame,
                            TransitionType transition_type) override {
    }

    virtual void OnLoadEnd(CefRefPtr<CefBrowser> browser,
                          CefRefPtr<CefFrame> frame,
                          int httpStatusCode) override {
    }

    // CefKeyboardHandler
    virtual bool OnPreKeyEvent(CefRefPtr<CefBrowser> browser,
                              const CefKeyEvent& event,
                              CefEventHandle os_event,
                              bool* is_keyboard_shortcut) override {
        return false;
    }

    void LoadURL(const std::string& url) {
        if (browser_ && browser_->GetMainFrame()) {
            browser_->GetMainFrame()->LoadURL(url);
        }
    }

    void Resize(int width, int height) {
        width_ = width;
        height_ = height;
        if (frame_) {
            frame_->width = width;
            frame_->height = height;
        }
        if (browser_) {
            browser_->GetHost()->WasResized();
        }
    }

    void SendMouseClick(int x, int y, int button, bool down) {
        if (!browser_) return;
        
        CefMouseEvent mouse_event;
        mouse_event.x = x;
        mouse_event.y = y;
        mouse_event.modifiers = 0;
        
        CefBrowserHost::MouseButtonType btn_type = 
            (button == 0) ? MBT_LEFT : (button == 1) ? MBT_MIDDLE : MBT_RIGHT;
        
        browser_->GetHost()->SendMouseClickEvent(mouse_event, btn_type, !down, 1);
    }

    void SendMouseMove(int x, int y) {
        if (!browser_) return;
        
        CefMouseEvent mouse_event;
        mouse_event.x = x;
        mouse_event.y = y;
        mouse_event.modifiers = 0;
        
        browser_->GetHost()->SendMouseMoveEvent(mouse_event, false);
    }

    void SendKey(int key_code, bool down) {
        if (!browser_) return;
        
        CefKeyEvent key_event;
        key_event.windows_key_code = key_code;
        key_event.native_key_code = key_code;
        key_event.type = down ? KEYEVENT_KEYDOWN : KEYEVENT_KEYUP;
        key_event.modifiers = 0;
        
        browser_->GetHost()->SendKeyEvent(key_event);
    }

    void SendText(const std::string& text) {
        if (!browser_) return;
        
        for (char c : text) {
            CefKeyEvent key_event;
            key_event.windows_key_code = c;
            key_event.native_key_code = c;
            key_event.type = KEYEVENT_CHAR;
            key_event.modifiers = 0;
            
            browser_->GetHost()->SendKeyEvent(key_event);
        }
    }

    bool ShouldExit() const {
        return frame_ ? frame_->should_exit.load() : false;
    }

    IMPLEMENT_REFCOUNTING(OffscreenRenderer);

private:
    HANDLE shared_memory_;
    SharedFrame* frame_;
    HANDLE texture_ready_;
    int width_;
    int height_;
    CefRefPtr<CefBrowser> browser_;
};

class QuantumCefApp : public CefApp, public CefBrowserProcessHandler {
public:
    QuantumCefApp() {}

    virtual CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() override {
        return this;
    }

    IMPLEMENT_REFCOUNTING(QuantumCefApp);
};

// Thread pour écouter les commandes via Named Pipe
void CommandListenerThread(OffscreenRenderer* renderer) {
    while (!renderer->ShouldExit()) {
        HANDLE pipe = CreateNamedPipe(
            TEXT("\\\\.\\pipe\\CEF_COMMAND_PIPE"),
            PIPE_ACCESS_INBOUND,
            PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
            1,
            4096,
            4096,
            0,
            NULL);

        if (pipe == INVALID_HANDLE_VALUE) {
            Sleep(100);
            continue;
        }

        if (ConnectNamedPipe(pipe, NULL) || GetLastError() == ERROR_PIPE_CONNECTED) {
            char buffer[4096];
            DWORD bytes_read;
            
            if (ReadFile(pipe, buffer, sizeof(buffer) - 1, &bytes_read, NULL)) {
                buffer[bytes_read] = '\0';
                std::string command(buffer);
                
                // Parser les commandes
                if (command.find("LOAD_URL:") == 0) {
                    std::string url = command.substr(9);
                    renderer->LoadURL(url);
                }
                else if (command.find("MOUSE_CLICK:") == 0) {
                    // Format: MOUSE_CLICK:x,y,button,down
                    // Parser et appeler SendMouseClick
                }
                else if (command.find("MOUSE_MOVE:") == 0) {
                    // Format: MOUSE_MOVE:x,y
                    // Parser et appeler SendMouseMove
                }
                else if (command.find("KEY:") == 0) {
                    // Format: KEY:keycode,down
                    // Parser et appeler SendKey
                }
                else if (command.find("TEXT:") == 0) {
                    std::string text = command.substr(5);
                    renderer->SendText(text);
                }
                else if (command.find("RESIZE:") == 0) {
                    // Format: RESIZE:width,height
                    // Parser et appeler Resize
                }
            }
            
            DisconnectNamedPipe(pipe);
        }
        
        CloseHandle(pipe);
        Sleep(10);
    }
}

int main(int argc, char* argv[]) {
    if (argc < 4) {
        std::cerr << "Usage: cef_worker.exe <shared_mem_handle> <width> <height>" << std::endl;
        return 1;
    }

    // Récupérer les arguments
    HANDLE shared_mem = reinterpret_cast<HANDLE>(std::stoull(argv[1]));
    int width = std::stoi(argv[2]);
    int height = std::stoi(argv[3]);

    // Initialiser CEF
    CefMainArgs main_args(GetModuleHandle(NULL));
    CefSettings settings;
    settings.multi_threaded_message_loop = true;
    settings.windowless_rendering_enabled = true;
    settings.no_sandbox = true;
    settings.log_severity = LOGSEVERITY_WARNING;

    CefRefPtr<QuantumCefApp> app(new QuantumCefApp());

    if (!CefInitialize(main_args, settings, app.get(), nullptr)) {
        std::cerr << "Failed to initialize CEF" << std::endl;
        return 1;
    }

    // Créer le renderer
    CefRefPtr<OffscreenRenderer> handler = new OffscreenRenderer(shared_mem, width, height);

    // Démarrer le thread de commandes
    std::thread command_thread(CommandListenerThread, handler.get());

    // Créer le browser
    CefWindowInfo window_info;
    window_info.SetAsWindowless(NULL);

    CefBrowserSettings browser_settings;
    browser_settings.windowless_frame_rate = 144;

    CefBrowserHost::CreateBrowser(
        window_info,
        handler.get(),
        "about:blank",
        browser_settings,
        nullptr,
        nullptr);

    // Message loop
    CefRunMessageLoop();

    // Nettoyage
    command_thread.join();
    CefShutdown();

    return 0;
}

