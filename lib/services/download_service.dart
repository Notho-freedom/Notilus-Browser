import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/download_model.dart';

/// Service de gestion des téléchargements
class DownloadService extends ChangeNotifier {
  final List<DownloadModel> _downloads = [];
  final Map<String, http.Client> _activeClients = {};
  final Map<String, bool> _cancelledDownloads = {};

  List<DownloadModel> get downloads => List.unmodifiable(_downloads);
  
  List<DownloadModel> get activeDownloads => _downloads
      .where((d) => d.status == DownloadStatus.downloading || 
                    d.status == DownloadStatus.pending)
      .toList();
  
  List<DownloadModel> get completedDownloads => _downloads
      .where((d) => d.status == DownloadStatus.completed)
      .toList();

  DownloadService() {
    _loadDownloads();
  }

  /// Ajoute un nouveau téléchargement et le démarre
  Future<void> addDownload(String url, {String? fileName}) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final name = fileName ?? _extractFileName(url);
      
      final download = DownloadModel(
        id: id,
        url: url,
        fileName: name,
        startTime: DateTime.now(),
        status: DownloadStatus.pending,
      );

      _downloads.insert(0, download);
      notifyListeners();
      _saveDownloads();

      // Démarrer le téléchargement
      await _startDownload(download);
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du téléchargement: $e');
    }
  }

  /// Démarre un téléchargement
  Future<void> _startDownload(DownloadModel download) async {
    try {
      final index = _downloads.indexWhere((d) => d.id == download.id);
      if (index == -1) return;

      _downloads[index] = download.copyWith(status: DownloadStatus.downloading);
      notifyListeners();

      // Vérifier si le téléchargement a été annulé
      if (_cancelledDownloads[download.id] == true) {
        _downloads[index] = download.copyWith(status: DownloadStatus.cancelled);
        notifyListeners();
        _saveDownloads();
        return;
      }

      final client = http.Client();
      _activeClients[download.id] = client;

      final response = await client.send(http.Request('GET', Uri.parse(download.url)));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      final receivedBytes = <int>[];

      // Obtenir le répertoire de téléchargement
      final directory = await _getDownloadDirectory();
      final fileName = _sanitizeFileName(download.fileName);
      final filePath = path.join(directory.path, fileName);

      // Mettre à jour avec le total de bytes
      _downloads[index] = download.copyWith(
        totalBytes: totalBytes,
        filePath: filePath,
      );
      notifyListeners();

      final file = File(filePath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        // Vérifier si le téléchargement a été annulé
        if (_cancelledDownloads[download.id] == true) {
          await sink.close();
          await file.delete();
          _downloads[index] = download.copyWith(status: DownloadStatus.cancelled);
          notifyListeners();
          _saveDownloads();
          return;
        }

        receivedBytes.addAll(chunk);
        sink.add(chunk);

        // Mettre à jour la progression
        _downloads[index] = download.copyWith(
          receivedBytes: receivedBytes.length,
          totalBytes: totalBytes,
        );
        notifyListeners();
      }

      await sink.close();
      client.close();
      _activeClients.remove(download.id);

      // Téléchargement terminé
      _downloads[index] = download.copyWith(
        status: DownloadStatus.completed,
        receivedBytes: receivedBytes.length,
        endTime: DateTime.now(),
      );
      notifyListeners();
      _saveDownloads();
    } catch (e) {
      final index = _downloads.indexWhere((d) => d.id == download.id);
      if (index != -1) {
        _downloads[index] = download.copyWith(
          status: DownloadStatus.failed,
          error: e.toString(),
          endTime: DateTime.now(),
        );
        notifyListeners();
        _saveDownloads();
      }
      _activeClients.remove(download.id)?.close();
      debugPrint('Erreur lors du téléchargement: $e');
    }
  }

  /// Annule un téléchargement
  void cancelDownload(String id) {
    _cancelledDownloads[id] = true;
    _activeClients.remove(id)?.close();
    
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1 && _downloads[index].status == DownloadStatus.downloading) {
      _downloads[index] = _downloads[index].copyWith(
        status: DownloadStatus.cancelled,
        endTime: DateTime.now(),
      );
      notifyListeners();
      _saveDownloads();
    }
  }

  /// Supprime un téléchargement
  void removeDownload(String id) {
    _downloads.removeWhere((d) => d.id == id);
    _activeClients.remove(id)?.close();
    _cancelledDownloads.remove(id);
    notifyListeners();
    _saveDownloads();
  }

  /// Ouvre le fichier téléchargé
  Future<void> openDownload(String id) async {
    try {
      final download = _downloads.firstWhere((d) => d.id == id);
      if (download.filePath != null && download.status == DownloadStatus.completed) {
        final file = File(download.filePath!);
        if (await file.exists()) {
          final uri = Uri.file(download.filePath!);
          // Utiliser url_launcher pour ouvrir le fichier avec l'application par défaut
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            debugPrint('Impossible d\'ouvrir le fichier: ${download.filePath}');
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture du fichier: $e');
    }
  }

  /// Obtient le répertoire de téléchargement
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['USERPROFILE'] ?? '';
      final downloadDir = Directory(path.join(appData, 'Downloads', 'Notilus'));
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir;
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      final downloadDir = Directory(path.join(home, 'Downloads', 'Notilus'));
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir;
    } else {
      // Linux
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final downloadDir = Directory(path.join(directory.path, 'Notilus'));
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      }
      // Fallback
      final tempDir = await getTemporaryDirectory();
      return Directory(path.join(tempDir.path, 'Notilus'));
    }
  }

  /// Extrait le nom de fichier depuis l'URL
  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final fileName = segments.last;
        if (fileName.isNotEmpty && fileName.contains('.')) {
          return fileName;
        }
      }
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Nettoie le nom de fichier pour éviter les caractères invalides
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  /// Clé de stockage pour SharedPreferences
  static const String _storageKey = 'notilus_downloads';

  /// Charge les téléchargements depuis le stockage
  Future<void> _loadDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getString(_storageKey);
      
      if (downloadsJson != null && downloadsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(downloadsJson);
        final loadedDownloads = decoded
            .map((json) => DownloadModel.fromJson(json as Map<String, dynamic>))
            .where((d) => 
                // Ne pas charger les téléchargements en cours (ils ne peuvent pas être repris)
                d.status == DownloadStatus.completed ||
                d.status == DownloadStatus.failed ||
                d.status == DownloadStatus.cancelled)
            .toList();
        
        _downloads.clear();
        _downloads.addAll(loadedDownloads);
        notifyListeners();
        
        debugPrint('📥 ${loadedDownloads.length} téléchargements chargés depuis le stockage');
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des téléchargements: $e');
    }
  }

  /// Sauvegarde les téléchargements
  Future<void> _saveDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sauvegarder uniquement les téléchargements terminés, échoués ou annulés
      // Les téléchargements en cours ne peuvent pas être repris après un redémarrage
      final downloadsToSave = _downloads
          .where((d) => 
              d.status == DownloadStatus.completed ||
              d.status == DownloadStatus.failed ||
              d.status == DownloadStatus.cancelled)
          .map((d) => d.toJson())
          .toList();
      
      final jsonString = jsonEncode(downloadsToSave);
      await prefs.setString(_storageKey, jsonString);
      
      debugPrint('💾 ${downloadsToSave.length} téléchargements sauvegardés');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des téléchargements: $e');
    }
  }

  /// Efface tous les téléchargements terminés
  void clearCompletedDownloads() {
    _downloads.removeWhere((d) => 
        d.status == DownloadStatus.completed ||
        d.status == DownloadStatus.failed ||
        d.status == DownloadStatus.cancelled);
    notifyListeners();
    _saveDownloads();
  }

  @override
  void dispose() {
    for (final client in _activeClients.values) {
      client.close();
    }
    _activeClients.clear();
    super.dispose();
  }
}
