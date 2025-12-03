import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/extension.dart';

class ExtensionService {
  static const String _extensionsKey = 'notilus_extensions';

  /// Charge toutes les extensions
  Future<List<Extension>> getExtensions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final extensionsJsonString = prefs.getString(_extensionsKey);
      if (extensionsJsonString != null) {
        final List<dynamic> extensionsJson = jsonDecode(extensionsJsonString);
        return extensionsJson.map((json) => Extension.fromJson(json)).toList();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  /// Charge une extension par ID
  Future<Extension?> getExtension(String id) async {
    final extensions = await getExtensions();
    try {
      return extensions.firstWhere((ext) => ext.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Ajoute une nouvelle extension
  Future<void> addExtension(Extension extension) async {
    try {
      final extensions = await getExtensions();
      // Vérifier si l'extension existe déjà
      if (extensions.any((ext) => ext.id == extension.id)) {
        return;
      }
      extensions.add(extension);
      await _saveExtensions(extensions);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Met à jour une extension
  Future<void> updateExtension(Extension extension) async {
    try {
      final extensions = await getExtensions();
      final index = extensions.indexWhere((ext) => ext.id == extension.id);
      if (index != -1) {
        extensions[index] = extension;
        await _saveExtensions(extensions);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Supprime une extension
  Future<void> removeExtension(String id) async {
    try {
      final extensions = await getExtensions();
      extensions.removeWhere((ext) => ext.id == id);
      await _saveExtensions(extensions);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Active/désactive une extension
  Future<void> toggleExtension(String id, bool enabled) async {
    final extension = await getExtension(id);
    if (extension != null) {
      await updateExtension(extension.copyWith(enabled: enabled));
    }
  }

  /// Charge les extensions actives
  Future<List<Extension>> getActiveExtensions() async {
    final extensions = await getExtensions();
    return extensions.where((ext) => ext.enabled).toList();
  }

  /// Charge les extensions par type
  Future<List<Extension>> getExtensionsByType(ExtensionType type) async {
    final extensions = await getExtensions();
    return extensions.where((ext) => ext.type == type && ext.enabled).toList();
  }

  /// Sauvegarde les extensions
  Future<void> _saveExtensions(List<Extension> extensions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final extensionsJson = extensions.map((ext) => ext.toJson()).toList();
      await prefs.setString(_extensionsKey, jsonEncode(extensionsJson));
    } catch (e) {
      // Ignore errors
    }
  }

  /// Installe une extension depuis un manifest
  Future<Extension> installFromManifest(Map<String, dynamic> manifest) async {
    final extension = Extension(
      name: manifest['name'] ?? 'Unknown',
      version: manifest['version'] ?? '1.0.0',
      description: manifest['description'] ?? '',
      author: manifest['author'],
      icon: manifest['icons']?['128'] ?? manifest['icons']?['48'],
      permissions: List<String>.from(manifest['permissions'] ?? []),
      type: ExtensionType.contentScript,
      manifest: manifest,
    );
    
    await addExtension(extension);
    return extension;
  }
}

