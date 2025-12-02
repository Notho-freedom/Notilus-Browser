// shared_texture.h
// Texture Flutter qui lit depuis Shared Memory

#ifndef SHARED_TEXTURE_H_
#define SHARED_TEXTURE_H_

#include "flutter_texture_registrar.h"
#include <windows.h>
#include <atomic>
#include <thread>
#include <functional>
#include <mutex>

// Structure partagée avec le worker CEF
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

class SharedTexture {
public:
    SharedTexture(HANDLE shared_mem, int width, int height);
    ~SharedTexture();

    void SetFrameCallback(std::function<void()> callback);
    
    // Callback pour Flutter Desktop API
    static const FlutterDesktopPixelBuffer* GetPixelBuffer(
        size_t width, size_t height, void* user_data);

private:
    void MonitorThread();

    HANDLE shared_memory_;
    HANDLE texture_ready_;
    int width_;
    int height_;
    std::function<void()> on_frame_available_;
    std::thread monitor_thread_;
    std::atomic<bool> stop_monitor_{false};
    std::mutex buffer_mutex_;
    SharedFrame* mapped_frame_;
    FlutterDesktopPixelBuffer pixel_buffer_;
};

#endif  // SHARED_TEXTURE_H_

