// shared_texture.cpp
#include "shared_texture.h"
#include <iostream>
#include <cstring>

SharedTexture::SharedTexture(HANDLE shared_mem, int width, int height)
    : shared_memory_(shared_mem),
      width_(width),
      height_(height),
      mapped_frame_(nullptr) {
    
    // Ouvrir l'event créé par le worker
    texture_ready_ = OpenEvent(EVENT_MODIFY_STATE | SYNCHRONIZE, FALSE, TEXT("CEF_TEXTURE_READY"));
    
    if (!texture_ready_) {
        std::cerr << "Failed to open texture_ready event" << std::endl;
    }
    
    // Mapper la shared memory
    size_t frame_size = sizeof(SharedFrame) + (width_ * height_ * 4);
    mapped_frame_ = reinterpret_cast<SharedFrame*>(
        MapViewOfFile(shared_memory_, FILE_MAP_READ, 0, 0, frame_size));
    
    if (!mapped_frame_) {
        std::cerr << "Failed to map shared memory" << std::endl;
    }
    
    // Thread pour surveiller les nouvelles frames
    monitor_thread_ = std::thread(&SharedTexture::MonitorThread, this);
}

SharedTexture::~SharedTexture() {
    stop_monitor_ = true;
    if (texture_ready_) {
        SetEvent(texture_ready_);  // Réveiller le thread
    }
    
    if (monitor_thread_.joinable()) {
        monitor_thread_.join();
    }
    
    if (mapped_frame_) {
        UnmapViewOfFile(mapped_frame_);
    }
    
    if (texture_ready_) {
        CloseHandle(texture_ready_);
    }
}

void SharedTexture::SetFrameCallback(std::function<void()> callback) {
    on_frame_available_ = callback;
}

void SharedTexture::MonitorThread() {
    while (!stop_monitor_) {
        if (texture_ready_ && WaitForSingleObject(texture_ready_, 100) == WAIT_OBJECT_0) {
            if (on_frame_available_ && mapped_frame_ && mapped_frame_->frame_ready.load()) {
                on_frame_available_();
                mapped_frame_->frame_ready.store(false);
            }
        }
    }
}

const FlutterDesktopPixelBuffer* SharedTexture::GetPixelBuffer(
    size_t /*width*/, size_t /*height*/, void* user_data) {
    SharedTexture* self = static_cast<SharedTexture*>(user_data);
    std::lock_guard<std::mutex> lock(self->buffer_mutex_);
    
    if (!self->mapped_frame_) {
        return nullptr;
    }
    
    // Configurer le pixel buffer depuis la shared memory
    BYTE* pixel_ptr = reinterpret_cast<BYTE*>(self->mapped_frame_) + sizeof(SharedFrame);
    self->pixel_buffer_.buffer = pixel_ptr;
    self->pixel_buffer_.width = self->mapped_frame_->width;
    self->pixel_buffer_.height = self->mapped_frame_->height;
    self->pixel_buffer_.release_callback = nullptr;
    self->pixel_buffer_.release_context = nullptr;
    
    return &self->pixel_buffer_;
}

