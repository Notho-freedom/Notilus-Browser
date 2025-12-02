#ifndef TEXTURE_BRIDGE_HPP
#define TEXTURE_BRIDGE_HPP

#include <flutter/texture_registrar.h>

#include <mutex>
#include <vector>
#include <atomic>
#include <cstdint>

/// Bridge entre CEF et Flutter Texture
/// Convertit les frames BGRA de CEF en texture Flutter
class TextureBridge {
 public:
  TextureBridge(FlutterDesktopTextureRegistrarRef registrar, int width, int height);
  ~TextureBridge();
  
  /// Met à jour la texture avec les données de CEF
  /// [buffer] Buffer BGRA de CEF (width * height * 4 bytes)
  /// [width] Largeur de l'image
  /// [height] Hauteur de l'image
  void UpdateTexture(const void* buffer, int width, int height);
  
  /// Redimensionne la texture
  void SetSize(int width, int height);
  
  /// Obtient l'ID de la texture
  int64_t id() const { return texture_id_; }

 private:
  FlutterDesktopTextureRegistrarRef registrar_;
  int64_t texture_id_;
  
  std::mutex buffer_mutex_;
  std::vector<uint8_t> pixel_buffer_;
  int width_;
  int height_;
  
  FlutterDesktopPixelBuffer pixel_buffer_struct_;
  
  /// Callback pour Flutter qui récupère les pixels
  static const FlutterDesktopPixelBuffer* GetPixelBuffer(
      size_t width, size_t height, void* user_data);
};

#endif  // TEXTURE_BRIDGE_HPP
