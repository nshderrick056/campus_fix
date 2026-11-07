import 'dart:io';

import 'package:equatable/equatable.dart';

import 'incident_category.dart';

/// Form input for creating or editing an incident. Validation happens in the
/// UI/cubit; the repository assumes a valid draft.
class IncidentDraft extends Equatable {
  const IncidentDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.isAnonymous = false,
    this.photo,
    this.removePhoto = false,
  });

  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final bool isAnonymous;

  /// New photo to upload (picked on the device). Null keeps the current one.
  final File? photo;

  /// When editing: true clears the existing photo.
  final bool removePhoto;

  @override
  List<Object?> get props =>
      [title, description, category, location, isAnonymous, photo?.path, removePhoto];
}
