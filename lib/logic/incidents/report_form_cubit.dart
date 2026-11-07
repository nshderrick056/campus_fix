import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/incident_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../models/incident_category.dart';
import '../../models/incident_draft.dart';
import '../form_status.dart';

class ReportFormState extends Equatable {
  const ReportFormState({
    this.category,
    this.photo,
    this.existingPhotoUrl,
    this.isAnonymous = false,
    this.showCategoryError = false,
    this.status = FormStatus.idle,
    this.error,
    this.createdId,
  });

  final IncidentCategory? category;

  /// Newly picked photo (not yet uploaded).
  final File? photo;

  /// When editing, the photo already stored on the report.
  final String? existingPhotoUrl;
  final bool isAnonymous;
  final bool showCategoryError;
  final FormStatus status;
  final String? error;

  /// Id of the created/edited report, set on success.
  final String? createdId;

  bool get isSubmitting => status == FormStatus.submitting;

  ReportFormState copyWith({
    IncidentCategory? category,
    File? Function()? photo,
    String? Function()? existingPhotoUrl,
    bool? isAnonymous,
    bool? showCategoryError,
    FormStatus? status,
    String? Function()? error,
    String? createdId,
  }) =>
      ReportFormState(
        category: category ?? this.category,
        photo: photo != null ? photo() : this.photo,
        existingPhotoUrl: existingPhotoUrl != null ? existingPhotoUrl() : this.existingPhotoUrl,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        showCategoryError: showCategoryError ?? this.showCategoryError,
        status: status ?? this.status,
        error: error != null ? error() : this.error,
        createdId: createdId ?? this.createdId,
      );

  @override
  List<Object?> get props =>
      [category, photo?.path, existingPhotoUrl, isAnonymous, showCategoryError, status, error, createdId];
}

/// Create or edit a report. Text fields live in the form widget (validated
/// with `Validators`); this cubit owns category, photo, anonymity and the
/// submit lifecycle (upload + Firestore write, loading, errors).
class ReportFormCubit extends Cubit<ReportFormState> {
  ReportFormCubit(this._repo, {required this.reporter, this.editing})
      : super(ReportFormState(
          category: editing?.category,
          isAnonymous: editing?.isAnonymous ?? false,
          existingPhotoUrl: editing?.photoUrl,
        ));

  final IncidentRepository _repo;
  final AppUser reporter;

  /// The report being edited, or null when creating.
  final Incident? editing;

  bool get isEditing => editing != null;

  void selectCategory(IncidentCategory c) => emit(state.copyWith(category: c, showCategoryError: false));
  void setPhoto(File file) => emit(state.copyWith(photo: () => file));
  void removePhoto() => emit(state.copyWith(photo: () => null, existingPhotoUrl: () => null));
  void setAnonymous(bool value) => emit(state.copyWith(isAnonymous: value));

  /// [formValid] is the result of the text fields' validation.
  Future<void> submit({
    required bool formValid,
    required String title,
    required String description,
    required String location,
  }) async {
    if (state.isSubmitting) return;
    if (state.category == null || !formValid) {
      emit(state.copyWith(showCategoryError: state.category == null, error: () => null));
      return;
    }
    emit(state.copyWith(status: FormStatus.submitting, error: () => null));
    final draft = IncidentDraft(
      title: title,
      description: description,
      category: state.category!,
      location: location,
      isAnonymous: state.isAnonymous,
      photo: state.photo,
      removePhoto: isEditing && editing!.hasPhoto && state.photo == null && state.existingPhotoUrl == null,
    );
    try {
      final id = isEditing
          ? await _repo.update(editing!.id, draft).then((_) => editing!.id)
          : await _repo.create(draft, reporter: reporter);
      emit(state.copyWith(status: FormStatus.success, createdId: id));
    } on RepositoryException catch (e) {
      emit(state.copyWith(status: FormStatus.failure, error: () => e.message));
    } catch (_) {
      emit(state.copyWith(
          status: FormStatus.failure, error: () => 'Could not submit the report. Check your connection and try again.'));
    }
  }
}
