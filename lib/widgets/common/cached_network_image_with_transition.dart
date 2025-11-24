import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedNetworkImageWithTransition extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final ColorFilter? colorFilter;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedNetworkImageWithTransition({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.colorFilter,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      colorFilter: colorFilter,
      placeholder: (context, url) => placeholder ?? Container(
        color: Colors.black.withOpacity(0.3),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF2D55)),
          ),
        ),
      ),
      errorWidget: (context, url, error) => errorWidget ?? Container(
        color: Colors.black.withOpacity(0.3),
      ),
      fadeInDuration: const Duration(milliseconds: 600),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }
}

