import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/cloudinary_service.dart';
import '../../services/cloudinary_cache_service.dart';
import '../../services/settings_service.dart';
import '../../core/services/background_music_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/gx_notification_service.dart';
import '../common/gx_futuristic_components.dart';
import '../common/gx_futuristic_dialog.dart';

/// Widget pour gérer les uploads et sélection de médias Cloudinary
class CloudinaryMediaManager extends StatefulWidget {
  final CloudinaryResourceType resourceType;
  final String title;
  final bool allowMultiple;

  const CloudinaryMediaManager({
    super.key,
    required this.resourceType,
    required this.title,
    this.allowMultiple = true,
  });

  @override
  State<CloudinaryMediaManager> createState() => _CloudinaryMediaManagerState();
}

class _CloudinaryMediaManagerState extends State<CloudinaryMediaManager> {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final SettingsService _settings = SettingsService();
  List<String> _selectedUrls = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedMedia();
    _cloudinaryService.initialize();
  }

  void _loadSelectedMedia() {
    if (widget.resourceType == CloudinaryResourceType.image) {
      _selectedUrls = List.from(_settings.selectedBackgrounds);
    } else if (widget.resourceType == CloudinaryResourceType.raw) {
      final music = _settings.selectedMusic;
      if (music != null) _selectedUrls = [music];
    }
    // Plus de support pour les vidéos
  }

  Future<void> _uploadFile() async {
    if (!_cloudinaryService.isConfigured) {
      GxNotificationService().showError(
        title: 'Cloudinary non configuré',
        message: 'Veuillez configurer vos credentials Cloudinary dans les paramètres.',
        context: context,
      );
      return;
    }

    FilePickerResult? result;
    
    if (widget.resourceType == CloudinaryResourceType.image) {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: widget.allowMultiple,
      );
    } else if (widget.resourceType == CloudinaryResourceType.raw) {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a', 'aac'],
        allowMultiple: false,
      );
    }

    if (result != null && result.files.isNotEmpty) {
      // Lancer tous les uploads en parallèle
      final uploadFutures = result.files.where((file) => file.path != null).map((file) {
        final fileObj = File(file.path!);
        final folder = widget.resourceType == CloudinaryResourceType.image
            ? 'backgrounds'
            : 'music';

        return _cloudinaryService.uploadFile(
          file: fileObj,
          resourceType: widget.resourceType,
          folder: folder,
        );
      }).toList();

      // Attendre que tous les uploads soient terminés
      final results = await Future.wait(uploadFutures, eagerError: false);
      
      int successCount = 0;
      int errorCount = 0;
      
      for (final result in results) {
        if (result != null) {
          successCount++;
        } else {
          errorCount++;
        }
      }
      
      // Afficher les résultats
      if (errorCount == 0) {
        GxNotificationService().showSuccess(
          title: 'Uploads réussis',
          message: '$successCount fichier(s) uploadé(s) avec succès.',
          context: context,
        );
      } else if (successCount > 0) {
        GxNotificationService().showWarning(
          title: 'Uploads partiels',
          message: '$successCount succès, $errorCount échec(s).',
          context: context,
        );
      } else {
        GxNotificationService().showError(
          title: 'Échec des uploads',
          message: _cloudinaryService.error ?? 'Tous les uploads ont échoué.',
          context: context,
        );
      }
    }
  }

  Future<void> _toggleSelection(String url) async {
    setState(() {
      if (_selectedUrls.contains(url)) {
        _selectedUrls.remove(url);
      } else {
        if (widget.allowMultiple) {
          _selectedUrls.add(url);
        } else {
          _selectedUrls = [url];
        }
      }
    });
    // Sauvegarder après la mise à jour de l'état
    await _saveSelection();
  }

  Future<void> _showPreview(CloudinaryMedia media) async {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final bgColor = colorThemeManager.nativeBackgroundColor;
    final isSelected = _selectedUrls.contains(media.secureUrl);

    await GxFuturisticDialog.show(
      context: context,
      title: 'Prévisualisation',
      titleIcon: widget.resourceType == CloudinaryResourceType.image
          ? CupertinoIcons.photo
          : CupertinoIcons.music_note,
      accentColor: gxRed,
      width: 700,
      height: null, // Hauteur automatique basée sur le contenu
      disableScroll: true, // Pas de scroll, la modal s'adapte au contenu
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: gxRed,
          onPressed: () => Navigator.of(context).pop(),
        ),
        GxFuturisticButton(
          label: isSelected ? 'Désélectionner' : 'Appliquer',
          icon: isSelected ? CupertinoIcons.xmark_circle : CupertinoIcons.checkmark,
          variant: GxFuturisticButtonVariant.primary,
          accentColor: gxRed,
          onPressed: () async {
            Navigator.of(context).pop();
            await _toggleSelection(media.secureUrl);
            
            GxNotificationService().showSuccess(
              title: isSelected ? 'Média désélectionné' : 'Média appliqué',
              message: isSelected 
                  ? 'Le média a été désélectionné.'
                  : 'Le média a été appliqué avec succès.',
              context: context,
            );
          },
        ),
      ],
      child: _MediaPreview(
        media: media,
        resourceType: widget.resourceType,
        gxRed: gxRed,
        bgColor: bgColor,
        onAudioStateChanged: null, // Plus de support vidéo
      ),
    );
  }

  Future<void> _saveSelection() async {
    if (widget.resourceType == CloudinaryResourceType.image) {
      await _settings.setSelectedBackgrounds(List.from(_selectedUrls));
    } else if (widget.resourceType == CloudinaryResourceType.raw) {
      await _settings.setSelectedMusic(_selectedUrls.isNotEmpty ? _selectedUrls.first : null);
    }
    // Plus de support pour les vidéos
    // Forcer une mise à jour de l'UI
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteMedia(CloudinaryMedia media) async {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    
    final confirmed = await GxFuturisticDialog.show<bool>(
      context: context,
      title: 'Supprimer le média',
      titleIcon: CupertinoIcons.delete,
      accentColor: Colors.red,
      width: 400,
      child: Text(
        'Êtes-vous sûr de vouloir supprimer ce média de Cloudinary ?',
        style: NotilusFonts.rajdhani(
          fontSize: 13,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
      actions: [
        GxFuturisticButton(
          label: 'Annuler',
          variant: GxFuturisticButtonVariant.secondary,
          accentColor: gxRed,
          onPressed: () => Navigator.pop(context, false),
        ),
        GxFuturisticButton(
          label: 'Supprimer',
          icon: CupertinoIcons.delete,
          variant: GxFuturisticButtonVariant.danger,
          accentColor: Colors.red,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );

    if (confirmed == true) {
      final success = await _cloudinaryService.deleteMedia(media);
      if (success) {
        GxNotificationService().showSuccess(
          title: 'Média supprimé',
          message: 'Le média a été supprimé avec succès.',
          context: context,
        );
      } else {
        GxNotificationService().showError(
          title: 'Erreur',
          message: _cloudinaryService.error ?? 'Impossible de supprimer le média.',
          context: context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorThemeManager = Provider.of<ColorThemeManager>(context);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final bgColor = colorThemeManager.nativeBackgroundColor;

    return Consumer<CloudinaryService>(
      builder: (context, service, _) {
        final mediaList = widget.resourceType == CloudinaryResourceType.image
            ? service.uploadedBackgrounds
            : service.uploadedMusic;

        // Utilise isLoading avec le type spécifique
        final isLoading = service.isLoading(widget.resourceType);
        
        // Filtre les uploads en cours pour ce type seulement
        final currentUploadsForThisType = service.getCurrentUploads(widget.resourceType);
        final uploadsForThisType = service.uploadProgressMap.entries
            .where((entry) => currentUploadsForThisType.contains(entry.key))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec bouton upload
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: NotilusFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: gxRed,
                    ),
                  ),
                ),
                GxFuturisticButton(
                  label: 'Uploader',
                  icon: CupertinoIcons.cloud_upload,
                  variant: GxFuturisticButtonVariant.primary,
                  // Désactivé seulement si ce type spécifique est en chargement
                  onPressed: isLoading ? null : _uploadFile,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Liste des uploads en cours POUR CE TYPE SEULEMENT
            if (uploadsForThisType.isNotEmpty)
              Column(
                children: [
                  ...uploadsForThisType.map((entry) {
                    final progress = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: gxRed.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.cloud_upload,
                                size: 16,
                                color: gxRed,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  progress.fileName,
                                  style: NotilusFonts.rajdhani(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${(progress.progress * 100).toStringAsFixed(0)}%',
                                style: NotilusFonts.rajdhani(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: gxRed,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GxFuturisticProgress(
                            value: progress.progress,
                            accentColor: gxRed,
                            height: 6,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
              ),

            // Liste des médias
            if (mediaList.isEmpty && uploadsForThisType.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gxRed.withOpacity(0.2)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.cloud,
                        size: 48,
                        color: gxRed.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun média uploadé',
                        style: NotilusFonts.rajdhani(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (mediaList.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: mediaList.length,
                itemBuilder: (context, index) {
                  final media = mediaList[index];
                  final isSelected = _selectedUrls.contains(media.secureUrl);

                  return _MediaItem(
                    media: media,
                    isSelected: isSelected,
                    resourceType: widget.resourceType,
                    onTap: () => _showPreview(media),
                    onDelete: () => _deleteMedia(media),
                    gxRed: gxRed,
                    bgColor: bgColor,
                  );
                },
              ),

            // Message d'erreur
            if (service.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GxFuturisticAlert(
                  title: 'Erreur',
                  message: service.error!,
                  type: GxFuturisticAlertType.error,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MediaItem extends StatelessWidget {
  final CloudinaryMedia media;
  final bool isSelected;
  final CloudinaryResourceType resourceType;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Color gxRed;
  final Color bgColor;

  const _MediaItem({
    required this.media,
    required this.isSelected,
    required this.resourceType,
    required this.onTap,
    required this.onDelete,
    required this.gxRed,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? gxRed : gxRed.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: bgColor.withOpacity(0.3),
        ),
        child: Stack(
          children: [
            // Preview avec thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: resourceType == CloudinaryResourceType.image
                  ? Builder(
                      builder: (context) {
                        // Vérifier que l'URL n'est pas une vidéo
                        final url = media.secureUrl;
                        final isVideoUrl = url.contains('.mp4') || 
                                           url.contains('video/upload') ||
                                           url.endsWith('.webm') ||
                                           url.endsWith('.mov') ||
                                           url.endsWith('.avi');
                        
                        if (isVideoUrl) {
                          return Container(
                            color: Colors.grey[900],
                            child: Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              color: Colors.grey[600],
                            ),
                          );
                        }
                        
                        return CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[900],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: gxRed,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[900],
                            child: Icon(
                              CupertinoIcons.photo,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                          color: Colors.grey[900],
                          child: Icon(
                            CupertinoIcons.music_note,
                            size: 32,
                            color: gxRed,
                          ),
                        ),
            ),

            // Overlay de sélection
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: gxRed.withOpacity(0.3),
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    color: gxRed,
                    size: 32,
                  ),
                ),
              ),

            // Bouton supprimer
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.delete,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour afficher le thumbnail d'une vidéo
class _VideoThumbnail extends StatefulWidget {
  final CloudinaryMedia media;
  final Color gxRed;

  const _VideoThumbnail({
    required this.media,
    required this.gxRed,
  });

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  String? _thumbnailUrl;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  void _loadThumbnail() {
    // Générer l'URL de thumbnail Cloudinary avec so_1 pour extraire une frame à 1 seconde
    _thumbnailUrl = CloudinaryCacheService.getThumbnailUrl(
      widget.media.secureUrl,
      width: 300,
      height: 300,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail
        if (_thumbnailUrl != null)
          CachedNetworkImage(
            imageUrl: _thumbnailUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Container(
              color: Colors.grey[900],
              child: Center(
                child: CircularProgressIndicator(
                  color: widget.gxRed,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[900],
              child: Icon(
                CupertinoIcons.play_circle,
                size: 32,
                color: widget.gxRed,
              ),
            ),
          )
        else
          Container(
            color: Colors.grey[900],
            child: Center(
              child: CircularProgressIndicator(
                color: widget.gxRed,
                strokeWidth: 2,
              ),
            ),
          ),
        
        // Overlay avec icône play
        Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Icon(
              CupertinoIcons.play_circle_fill,
              size: 40,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour prévisualiser un média Cloudinary
class _MediaPreview extends StatefulWidget {
  final CloudinaryMedia media;
  final CloudinaryResourceType resourceType;
  final Color gxRed;
  final Color bgColor;
  final Function(bool hasAudio)? onAudioStateChanged;

  const _MediaPreview({
    required this.media,
    required this.resourceType,
    required this.gxRed,
    required this.bgColor,
    this.onAudioStateChanged,
  });

  @override
  State<_MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<_MediaPreview> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _audioVolume = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.resourceType == CloudinaryResourceType.raw) {
      _audioPlayer = AudioPlayer();
      _initAudioPlayer();
    }
    // Plus de support pour les vidéos
  }

  // Plus de support pour les vidéos - méthodes supprimées

  void _initAudioPlayer() async {
    if (_audioPlayer == null) return;
    
    _audioPlayer!.setVolume(_audioVolume);
    
    _audioPlayer!.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    _audioPlayer!.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _audioPlayer!.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }
  
  // Plus de support pour les vidéos - méthodes supprimées
  
  Future<void> _setAudioVolume(double volume) async {
    _audioVolume = volume.clamp(0.0, 1.0);
    if (_audioPlayer != null) {
      await _audioPlayer!.setVolume(_audioVolume);
      setState(() {});
    }
  }

  Future<void> _togglePlayPause() async {
    if (_audioPlayer == null) return;

    if (_isPlaying) {
      await _audioPlayer!.pause();
    } else {
      if (_position == Duration.zero) {
        // Vérifier d'abord si l'audio est en cache
        final cacheService = CloudinaryCacheService();
        await cacheService.initialize();
        final cachedFile = await cacheService.getCachedFile(widget.media.secureUrl);
        
        // Utiliser le fichier en cache s'il existe, sinon utiliser l'URL
        if (cachedFile != null) {
          await _audioPlayer!.setSource(DeviceFileSource(cachedFile.path));
        } else {
          await _audioPlayer!.setSource(UrlSource(widget.media.secureUrl));
          // Mettre en cache en arrière-plan
          cacheService.cacheFile(widget.media.secureUrl);
        }
      }
      await _audioPlayer!.resume();
    }
    
    if (mounted) {
      setState(() => _isPlaying = !_isPlaying);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Hauteur adaptative selon le type de média
    final previewHeight = widget.resourceType == CloudinaryResourceType.image
        ? (screenSize.height * 0.6).clamp(400.0, 600.0) // Images : 60% de l'écran, max 600px
        : 250.0; // Audio : hauteur fixe
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Afficher le nom du fichier (sauf pour audio)
          if (widget.resourceType != CloudinaryResourceType.raw)
            Text(
              widget.media.publicId.split('/').last,
              style: NotilusFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.gxRed,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          if (widget.resourceType != CloudinaryResourceType.raw)
            const SizedBox(height: 20),
          
          // Contenu selon le type avec hauteur adaptative
          if (widget.resourceType == CloudinaryResourceType.raw)
            _buildAudioPreview()
          else
            SizedBox(
              height: previewHeight,
              child: _buildImagePreview(),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    // Vérifier que l'URL n'est pas une vidéo avant d'afficher
    final url = widget.media.secureUrl;
    final isVideoUrl = url.contains('.mp4') || 
                       url.contains('video/upload') ||
                       url.endsWith('.webm') ||
                       url.endsWith('.mov') ||
                       url.endsWith('.avi');
    
    if (isVideoUrl) {
      return Container(
        color: widget.bgColor.withOpacity(0.3),
        child: Center(
          child: Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: widget.gxRed.withOpacity(0.5),
          ),
        ),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints.expand(),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            color: widget.bgColor.withOpacity(0.3),
            child: Center(
              child: CircularProgressIndicator(color: widget.gxRed),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: widget.bgColor.withOpacity(0.3),
            child: Center(
              child: Icon(
                CupertinoIcons.photo,
                size: 64,
                color: widget.gxRed.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Plus de support pour les vidéos - méthode _buildVideoPreview supprimée

  Widget _buildAudioPreview() {
    // Intégration full dans la dialog sans conteneur visible
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bouton play/pause
          IconButton(
            onPressed: _togglePlayPause,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              _isPlaying ? CupertinoIcons.pause_circle_fill : CupertinoIcons.play_circle_fill,
              size: 64,
              color: widget.gxRed,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Contrôle de volume (audio) - Amélioré
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.gxRed.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _audioVolume > 0.5
                          ? CupertinoIcons.speaker_3_fill
                          : (_audioVolume > 0
                              ? CupertinoIcons.speaker_2_fill
                              : CupertinoIcons.speaker_slash_fill),
                      size: 20,
                      color: widget.gxRed,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: _audioVolume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: widget.gxRed,
                          inactiveColor: widget.gxRed.withOpacity(0.3),
                          onChanged: (value) => _setAudioVolume(value),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 45,
                      child: Text(
                        '${(_audioVolume * 100).toInt()}%',
                        style: TextStyle(
                          color: widget.gxRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Barre de progression
          if (_duration != Duration.zero) ...[
            Slider(
              value: _position.inSeconds.toDouble(),
              min: 0,
              max: _duration.inSeconds.toDouble(),
              activeColor: widget.gxRed,
              inactiveColor: widget.gxRed.withOpacity(0.3),
              onChanged: (value) {
                _audioPlayer?.seek(Duration(seconds: value.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: NotilusFonts.rajdhani(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: NotilusFonts.rajdhani(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}