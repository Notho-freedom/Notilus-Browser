import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Widget vidéo ultra-robuste basé sur media_kit (MPV)
/// Cross-platform, stable, performant
class GXVideoPlayer extends StatefulWidget {
  final String url;
  final bool autoplay;
  final bool loop;
  final double? volume;
  final bool muted;
  final Function(bool isPlaying)? onPlayingChanged;
  final Function(Duration position, Duration duration)? onProgressChanged;
  final Function(bool hasAudio)? onAudioStateChanged;

  const GXVideoPlayer({
    super.key,
    required this.url,
    this.autoplay = true,
    this.loop = false,
    this.volume,
    this.muted = false,
    this.onPlayingChanged,
    this.onProgressChanged,
    this.onAudioStateChanged,
  });

  @override
  State<GXVideoPlayer> createState() => _GXVideoPlayerState();
}

class _GXVideoPlayerState extends State<GXVideoPlayer> {
  late final Player _player;
  late final VideoController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _hasAudio = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _player = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 500 * 1024 * 1024, // 500MB – anti freeze
        ),
      );
      
      _controller = VideoController(_player);

      // Écouter les changements d'état
      _player.stream.playing.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
          widget.onPlayingChanged?.call(playing);
        }
      });

      _player.stream.position.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
          widget.onProgressChanged?.call(position, _duration);
        }
      });

      _player.stream.duration.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Ouvrir la vidéo
      await _player.open(Media(widget.url), play: widget.autoplay);
      
      // Configurer le volume et le mute
      if (widget.volume != null) {
        await _player.setVolume(widget.volume!);
      }
      if (widget.muted) {
        await _player.setMuted(true);
      }
      
      // Configurer la boucle
      await _player.setPlaylistMode(widget.loop ? PlaylistMode.loop : PlaylistMode.none);

      // Vérifier si la vidéo a de l'audio
      _hasAudio = !widget.muted && (widget.volume ?? 1.0) > 0;
      widget.onAudioStateChanged?.call(_hasAudio);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du lecteur vidéo media_kit: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> togglePlayPause() async {
    if (!_isInitialized) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    if (!_isInitialized) return;
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;
    await _player.setVolume(volume.clamp(0.0, 1.0));
    _hasAudio = volume > 0 && !widget.muted;
    widget.onAudioStateChanged?.call(_hasAudio);
  }

  Future<void> setMuted(bool muted) async {
    if (!_isInitialized) return;
    await _player.setMuted(muted);
    _hasAudio = !muted && (widget.volume ?? 1.0) > 0;
    widget.onAudioStateChanged?.call(_hasAudio);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Video(
      controller: _controller,
      controls: null, // Contrôles custom
      fill: Colors.black,
      scale: 1.0,
      alignment: Alignment.center,
    );
  }
}

