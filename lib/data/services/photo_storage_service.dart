import 'dart:io';

import '../../models/uploaded_photo.dart';

/// Storage for incident photos. The app depends only on this interface, so
/// the backend (Cloudinary today, Firebase Storage later) is a one-class swap.
abstract interface class PhotoStorageService {
  /// Uploads [file] and returns its public URL and id.
  /// Throws [PhotoUploadException] on failure.
  Future<UploadedPhoto> uploadPhoto(File file);

  /// URL of a resized version of the photo, for lists and thumbnails.
  String thumbnailUrl(String url, {int width = 400});
}

class PhotoUploadException implements Exception {
  const PhotoUploadException(this.message);

  final String message;

  @override
  String toString() => 'PhotoUploadException: $message';
}
