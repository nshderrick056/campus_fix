import 'package:equatable/equatable.dart';

/// Result of a photo upload, saved on the incident document.
class UploadedPhoto extends Equatable {
  const UploadedPhoto({required this.url, required this.publicId});

  /// Public HTTPS URL of the stored image (`photoUrl`).
  final String url;

  /// Provider-specific id used for transformations/deletion (`photoPublicId`).
  final String publicId;

  @override
  List<Object> get props => [url, publicId];
}
