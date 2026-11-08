import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
  });

  final String? url;
  final IconData fallbackIcon;

  /// Square size (thumbnails). Use [height] instead for full-width photos.
  final double? size;
  final double? height;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fallback = Container(
      color: c.iceSoft,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: iconSize, color: c.primary),
    );
    final u = url;
    Widget child;
    if (u == null || u.isEmpty) {
      child = fallback;
    } else if (u.startsWith('http')) {
      child = CachedNetworkImage(
        imageUrl: u,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(color: c.iceSoft),
        errorWidget: (_, _, _) => fallback,
      );
    } else {
      child = Image.file(File(u), fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size ?? double.infinity, height: size ?? height, child: child),
    );
  }
}
