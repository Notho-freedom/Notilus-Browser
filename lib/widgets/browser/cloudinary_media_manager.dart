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
    } else if (widget.resourceType == CloudinaryResourceType.video) {
      _selectedUrls = List.from(_settings.selectedVideos);
    } else if (widget.resourceType == CloudinaryResourceType.raw) {
      final music = _settings.selectedMusic;
      if (music != null) _selectedUrls = [music];
    }
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
    } else if (widget.resourceType == CloudinaryResourceType.video) {
      result = await FilePicker.platform.pickFiles(
        type: FileType.video,
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
            : widget.resourceType == CloudinaryResourceType.video
                ? 'videos'
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
    bool? videoHasAudio;

    await GxFuturisticDialog.show(
      context: context,
      title: 'Prévisualisation',
      titleIcon: widget.resourceType == CloudinaryResourceType.image
          ? CupertinoIcons.photo
          : widget.resourceType == CloudinaryResourceType.video
              ? CupertinoIcons.play_circle
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
            
            // Si c'est une vidéo avec son activé, désactiver la musique de fond
            if (widget.resourceType == CloudinaryResourceType.video && 
                videoHasAudio == true) {
              final backgroundMusic = Provider.of<BackgroundMusicService>(context, listen: false);
              if (backgroundMusic.isPlaying) {
                await backgroundMusic.pause();
              }
            }
            
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
        onAudioStateChanged: widget.resourceType == CloudinaryResourceType.video
            ? (hasAudio) => videoHasAudio = hasAudio
            : null,
      ),
    );
  }

  Future<void> _saveSelection() async {
    if (widget.resourceType == CloudinaryResourceType.image) {
      await _settings.setSelectedBackgrounds(List.from(_selectedUrls));
    } else if (widget.resourceType == CloudinaryResourceType.video) {
      await _settings.setSelectedVideos(List.from(_selectedUrls));
    } else if (widget.resourceType == CloudinaryResourceType.raw) {
      await _settings.setSelectedMusic(_selectedUrls.isNotEmpty ? _selectedUrls.first : null);
    }
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
            : widget.resourceType == CloudinaryResourceType.video
                ? service.uploadedVideos
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
                  ? CachedNetworkImage(
                      imageUrl: media.secureUrl,
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
                    )
                  : resourceType == CloudinaryResourceType.video
                      ? _VideoThumbnail(
                          media: media,
                          gxRed: gxRed,
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
    // Générer l'URL de thumbnail Cloudinary
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
  Player? _videoPlayer;
  VideoController? _videoController;
  bool _isPlaying = false;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  bool _isVideoInitialized = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _videoVolume = 1.0;
  bool _isVideoMuted = false;
  double _audioVolume = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.resourceType == CloudinaryResourceType.raw) {
      _audioPlayer = AudioPlayer();
      _initAudioPlayer();
    } else if (widget.resourceType == CloudinaryResourceType.video) {
      _initVideoPlayer();
    }
  }

  Future<void> _initVideoPlayer() async {
    try {
      // Créer le player avec configuration optimisée
      _videoPlayer = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 500 * 1024 * 1024, // 500MB – anti freeze
        ),
      );
      
      _videoController = VideoController(_videoPlayer!);

      // Annuler les anciennes subscriptions si elles existent
      _playingSubscription?.cancel();
      _positionSubscription?.cancel();

      // Écouter les changements d'état
      _playingSubscription = _videoPlayer!.stream.playing.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });

      _positionSubscription = _videoPlayer!.stream.position.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _videoPlayer!.stream.duration.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Vérifier d'abord si la vidéo est en cache
      final cacheService = CloudinaryCacheService();
      await cacheService.initialize();
      final cachedFile = await cacheService.getCachedFile(widget.media.secureUrl);
      
      // Utiliser le fichier en cache s'il existe, sinon utiliser l'URL
      final mediaSource = cachedFile != null 
          ? Media(cachedFile.path)
          : Media(widget.media.secureUrl);
      
      // Ouvrir la vidéo
      await _videoPlayer!.open(mediaSource, play: false);
      
      // Si pas en cache, démarrer le cache en arrière-plan
      if (cachedFile == null) {
        _cacheVideoInBackground(cacheService);
      }
      
      // Configurer le volume et le mute (media_kit n'a pas setMuted, utiliser setVolume)
      await _videoPlayer!.setVolume(_isVideoMuted ? 0.0 : _videoVolume);
      
      _updateAudioState();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation du lecteur vidéo (media_kit): $e');
      // Nettoyer le player en cas d'erreur
      try {
        await _videoPlayer?.dispose();
      } catch (_) {}
      _videoPlayer = null;
      _videoController = null;
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  /// Cache la vidéo en arrière-plan pour la prochaine utilisation
  void _cacheVideoInBackground(CloudinaryCacheService cacheService) {
    // Télécharger en streaming en arrière-plan sans bloquer
    cacheService.cacheFileStreaming(
      widget.media.secureUrl,
      onProgress: (progress) {
        // Optionnel : afficher la progression du téléchargement
        if (progress >= 1.0) {
          debugPrint('Vidéo mise en cache: ${widget.media.publicId}');
        }
      },
    );
  }

  Future<void> _toggleVideoPlayPause() async {
    if (_videoPlayer == null || !_isVideoInitialized) return;

    if (_isPlaying) {
      await _videoPlayer!.pause();
    } else {
      await _videoPlayer!.play();
    }
  }

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
  
  Future<void> _setVideoVolume(double volume) async {
    _videoVolume = volume.clamp(0.0, 1.0);
    if (_videoPlayer != null) {
      // media_kit n'a pas setMuted, utiliser setVolume
      await _videoPlayer!.setVolume(_isVideoMuted ? 0.0 : _videoVolume);
      _updateAudioState();
      setState(() {});
    }
  }
  
  Future<void> _setVideoMuted(bool muted) async {
    _isVideoMuted = muted;
    if (_videoPlayer != null) {
      // media_kit n'a pas setMuted, utiliser setVolume
      await _videoPlayer!.setVolume(muted ? 0.0 : _videoVolume);
      _updateAudioState();
      setState(() {});
    }
  }
  
  void _updateAudioState() {
    final hasAudio = !_isVideoMuted && _videoVolume > 0;
    widget.onAudioStateChanged?.call(hasAudio);
  }
  
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
    // Annuler les subscriptions
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _playingSubscription = null;
    _positionSubscription = null;
    
    _audioPlayer?.dispose();
    _videoPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Hauteur adaptative selon le type de média
    final previewHeight = widget.resourceType == CloudinaryResourceType.image
        ? (screenSize.height * 0.6).clamp(400.0, 600.0) // Images : 60% de l'écran, max 600px
        : widget.resourceType == CloudinaryResourceType.video
            ? 300.0 // Vidéos : hauteur fixe
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
              child: widget.resourceType == CloudinaryResourceType.image
                  ? _buildImagePreview()
                  : _buildVideoPreview(),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints.expand(),
        child: CachedNetworkImage(
          imageUrl: widget.media.secureUrl,
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

  Widget _buildVideoPreview() {
    if (!_isVideoInitialized || _videoController == null) {
      return SizedBox(
        height: 300,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.bgColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.gxRed.withOpacity(0.3)),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: widget.gxRed),
                const SizedBox(height: 16),
                Text(
                  'Chargement de la vidéo...',
                  style: NotilusFonts.rajdhani(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Si le chargement est trop long, la vidéo peut ne pas être supportée sur cette plateforme.',
                  style: NotilusFonts.rajdhani(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.gxRed.withOpacity(0.3)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lecteur vidéo (media_kit)
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Video(
              controller: _videoController!,
              controls: null, // Contrôles custom
              fill: Colors.black,
              alignment: Alignment.center,
            ),
          ),
          
          // Contrôles overlay (play/pause au centre, mais pas sur les contrôles)
          Positioned.fill(
            child: Stack(
              children: [
                // Zone cliquable pour play/pause (sauf en bas où sont les contrôles)
                Positioned.fill(
                  bottom: 120, // Laisser de l'espace pour les contrôles en bas
                  child: GestureDetector(
                    onTap: _toggleVideoPlayPause,
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Icon(
                          _isPlaying ? CupertinoIcons.pause_circle_fill : CupertinoIcons.play_circle_fill,
                          size: 64,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Barre de progression en bas avec contrôles de volume
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    // Contrôles de volume (vidéo uniquement) - Plus visibles
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.gxRed.withOpacity(0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isVideoMuted ? CupertinoIcons.speaker_slash : CupertinoIcons.speaker_2,
                              size: 20,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () => _setVideoMuted(!_isVideoMuted),
                            tooltip: _isVideoMuted ? 'Activer le son' : 'Désactiver le son',
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Slider(
                              value: _videoVolume,
                              min: 0.0,
                              max: 1.0,
                              activeColor: widget.gxRed,
                              inactiveColor: widget.gxRed.withOpacity(0.3),
                              onChanged: (value) => _setVideoVolume(value),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 35,
                            child: Text(
                              '${(_videoVolume * 100).toInt()}%',
                              style: NotilusFonts.rajdhani(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Slider de progression
                    if (_duration != Duration.zero)
                      Slider(
                        value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                        min: 0,
                        max: _duration.inSeconds.toDouble(),
                        activeColor: widget.gxRed,
                        inactiveColor: widget.gxRed.withOpacity(0.3),
                        onChanged: (value) {
                          _videoPlayer?.seek(Duration(seconds: value.toInt()));
                        },
                      ),
                    
                    // Temps
                    if (_duration != Duration.zero)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: NotilusFonts.rajdhani(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: NotilusFonts.rajdhani(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          
          // Contrôle de volume (audio)
          Row(
            children: [
              Icon(
                CupertinoIcons.speaker_2,
                size: 20,
                color: widget.gxRed,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: _audioVolume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: widget.gxRed,
                  inactiveColor: widget.gxRed.withOpacity(0.3),
                  onChanged: (value) => _setAudioVolume(value),
                ),
              ),
            ],
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