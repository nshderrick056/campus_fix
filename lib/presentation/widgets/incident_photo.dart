import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';

/// Shows an incident photo from a URL (Cloudinary) or a local file path
/// (fake backend / just picked), with a category-icon fallback.
class IncidentPhoto extends StatelessWidget {
  const IncidentPhoto({
    super.key,
    required this.url,
    required this.fallbackIcon,
    this.size,
    this.height,
    this.radius = 12,
    this.iconSize = 28,
    this.expandable = false,
  });

  final String? url;
  final IconData fallbackIcon;

  /// Square size (thumbnails). Use [height] instead for full-width photos.
  final double? size;
  final double? height;
  final double radius;
  final double iconSize;

  /// Tapping opens the photo full screen with pinch-to-zoom.
  final bool expandable;

  bool get _hasPhoto => url != null && url!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fallback = Container(
      color: c.iceSoft,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: iconSize, color: c.primary),
    );
    Widget photo = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size ?? double.infinity,
        height: size ?? height,
        child: _hasPhoto
            ? _photoImage(url!, BoxFit.cover, fallback, placeholderColor: c.iceSoft)
            : fallback,
      ),
    );
    if (!expandable || !_hasPhoto) return photo;
    photo = Hero(tag: url!, child: photo);
    return Semantics(
      button: true,
      label: 'Photo. Tap to view full screen',
      child: GestureDetector(
        onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => _PhotoViewer(url: url!)),
        ),
        child: Stack(children: [
          photo,
          Positioned(
            right: 10,
            bottom: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Symbols.open_in_full_rounded, size: 18, color: Colors.white),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

Widget _photoImage(String u, BoxFit fit, Widget fallback, {Color? placeholderColor}) => u.startsWith('http')
    ? CachedNetworkImage(
        imageUrl: u,
        fit: fit,
        placeholder: (_, _) => Container(color: placeholderColor),
        errorWidget: (_, _, _) => fallback,
      )
    : Image.file(File(u), fit: fit, errorBuilder: (_, _, _) => fallback);

/// Full-screen photo on black; pinch to zoom up to 5x, drag to pan.
class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Symbols.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Hero(
            tag: url,
            child: _photoImage(
              url,
              BoxFit.contain,
              const Icon(Symbols.broken_image_rounded, color: Colors.white54, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
