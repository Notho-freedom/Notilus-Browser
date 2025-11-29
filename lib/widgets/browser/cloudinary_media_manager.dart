import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../services/cloudinary_service.dart';
import '../../services/settings_service.dart';
import '../../core/services/color_theme_manager.dart';
import '../../core/constants/notilus_fonts.dart';
import '../../services/gx_notification_service.dart';
import '../common/gx_futuristic_components.dart';

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
      _selectedUrls = _settings.selectedBackgrounds;
    } else if (widget.resourceType == CloudinaryResourceType.video) {
      _selectedUrls = _settings.selectedVideos;
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
      for (final file in result.files) {
        if (file.path != null) {
          final fileObj = File(file.path!);
          final folder = widget.resourceType == CloudinaryResourceType.image
              ? 'backgrounds'
              : widget.resourceType == CloudinaryResourceType.video
                  ? 'videos'
                  : 'music';

          final media = await _cloudinaryService.uploadFile(
            file: fileObj,
            resourceType: widget.resourceType,
            folder: folder,
          );

          if (media != null) {
            GxNotificationService().showSuccess(
              title: 'Upload réussi',
              message: 'Le fichier a été uploadé avec succès.',
              context: context,
            );
          } else {
            GxNotificationService().showError(
              title: 'Erreur d\'upload',
              message: _cloudinaryService.error ?? 'Une erreur est survenue.',
              context: context,
            );
          }
        }
      }
    }
  }

  void _toggleSelection(String url) {
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
      _saveSelection();
    });
  }

  Future<void> _saveSelection() async {
    if (widget.resourceType == CloudinaryResourceType.image) {
      await _settings.setSelectedBackgrounds(_selectedUrls);
    } else if (widget.resourceType == CloudinaryResourceType.video) {
      await _settings.setSelectedVideos(_selectedUrls);
    } else if (widget.resourceType == CloudinaryResourceType.raw) {
      await _settings.setSelectedMusic(_selectedUrls.isNotEmpty ? _selectedUrls.first : null);
    }
  }

  Future<void> _deleteMedia(CloudinaryMedia media) async {
    final colorThemeManager = Provider.of<ColorThemeManager>(context, listen: false);
    final gxRed = colorThemeManager.nativeSecondaryColor;
    final bgColor = colorThemeManager.nativeBackgroundColor;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor.withOpacity(0.95),
        title: Text(
          'Supprimer le média',
          style: NotilusFonts.orbitron(color: gxRed),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ce média de Cloudinary ?',
          style: NotilusFonts.rajdhani(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: NotilusFonts.rajdhani(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer', style: NotilusFonts.rajdhani(color: gxRed)),
          ),
        ],
      ),
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
                  onPressed: service.isLoading ? null : _uploadFile,
                ),
                if (service.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: gxRed,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Liste des médias
            if (mediaList.isEmpty)
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
            else
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
                    onTap: () => _toggleSelection(media.secureUrl),
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
            // Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: resourceType == CloudinaryResourceType.image
                  ? Image.network(
                      media.secureUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[900],
                        child: Icon(
                          CupertinoIcons.photo,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: Icon(
                        resourceType == CloudinaryResourceType.video
                            ? CupertinoIcons.play_circle
                            : CupertinoIcons.music_note,
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

