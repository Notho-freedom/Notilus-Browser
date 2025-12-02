#include "texture_bridge.hpp"
#include <cstring>
#include <algorithm>

TextureBridge::TextureBridge(FlutterDesktopTextureRegistrarRef registrar,
                             int width, int height)
    : registrar_(registrar),
      width_(width),
      height_(height),
      texture_id_(-1) {
  
  // Initialiser le buffer
  pixel_buffer_.resize(width * height * 4, 0);
  
  // Configurer la structure pixel buffer
  pixel_buffer_struct_.buffer = pixel_buffer_.data();
  pixel_buffer_struct_.width = width;
  pixel_buffer_struct_.height = height;
  pixel_buffer_struct_.release_callback = nullptr;
  pixel_buffer_struct_.release_context = nullptr;
  
  // Configurer la texture info
  FlutterDesktopTextureInfo texture_info;
  texture_info.type = kFlutterDesktopPixelBufferTexture;
  texture_info.pixel_buffer_config.callback = GetPixelBuffer;
  texture_info.pixel_buffer_config.user_data = this;
  
  // Enregistrer la texture
  texture_id_ = FlutterDesktopTextureRegistrarRegisterExternalTexture(
      registrar_, &texture_info);
}

TextureBridge::~TextureBridge() {
  if (registrar_ && texture_id_ != -1) {
    FlutterDesktopTextureRegistrarUnregisterExternalTexture(
        registrar_, texture_id_, nullptr, nullptr);
  }
}

void TextureBridge::UpdateTexture(const void* buffer, int width, int height) {
  std::lock_guard<std::mutex> lock(buffer_mutex_);
  
  // Redimensionner le buffer si nécessaire
  if (width != width_ || height != height_) {
    width_ = width;
    height_ = height;
    pixel_buffer_.resize(width * height * 4);
  }
  
  // Copier les données BGRA de CEF dans notre buffer
  // CEF fournit les pixels en format BGRA (Blue, Green, Red, Alpha)
  // Flutter attend du RGBA, donc on doit convertir
  const uint8_t* src = static_cast<const uint8_t*>(buffer);
  uint8_t* dst = pixel_buffer_.data();
  
  size_t pixel_count = static_cast<size_t>(width) * static_cast<size_t>(height);
  
  // Conversion BGRA -> RGBA
  for (size_t i = 0; i < pixel_count; ++i) {
    size_t idx = i * 4;
    // BGRA -> RGBA: B↔R
    dst[idx + 0] = src[idx + 2];  // R = B (source)
    dst[idx + 1] = src[idx + 1];  // G = G
    dst[idx + 2] = src[idx + 0];  // B = R (source)
    dst[idx + 3] = src[idx + 3];  // A = A
  }
  
  // Mettre à jour la structure pixel buffer
  pixel_buffer_struct_.buffer = pixel_buffer_.data();
  pixel_buffer_struct_.width = width;
  pixel_buffer_struct_.height = height;
  
  // Notifier Flutter qu'une nouvelle frame est disponible
  if (registrar_ && texture_id_ != -1) {
    FlutterDesktopTextureRegistrarMarkExternalTextureFrameAvailable(
        registrar_, texture_id_);
  }
}

void TextureBridge::SetSize(int width, int height) {
  std::lock_guard<std::mutex> lock(buffer_mutex_);
  
  if (width != width_ || height != height_) {
    width_ = width;
    height_ = height;
    pixel_buffer_.resize(width * height * 4, 0);
    
    pixel_buffer_struct_.width = width;
    pixel_buffer_struct_.height = height;
  }
}

const FlutterDesktopPixelBuffer* TextureBridge::GetPixelBuffer(
    size_t /*width*/, size_t /*height*/, void* user_data) {
  TextureBridge* self = static_cast<TextureBridge*>(user_data);
  std::lock_guard<std::mutex> lock(self->buffer_mutex_);
  return &self->pixel_buffer_struct_;
}
