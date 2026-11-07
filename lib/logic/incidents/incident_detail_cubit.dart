import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/incident_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../models/incident_status.dart';
import '../form_status.dart';

class IncidentDetailState extends Equatable {
  const IncidentDetailState({
    this.status = LoadStatus.loading,
    this.incident,
    this.action = FormStatus.idle,
    this.actionMessage,
    this.deleted = false,
  });

  final LoadStatus status;
  final Incident? incident;

  /// Status of the last delete / status-update action.
  final FormStatus action;
  final String? actionMessage;
  final bool deleted;

  IncidentDetailState copyWith({
    LoadStatus? status,
    Incident? incident,
    FormStatus? action,
    String? Function()? actionMessage,
    bool? deleted,
  }) =>
      IncidentDetailState(
        status: status ?? this.status,
        incident: incident ?? this.incident,
        action: action ?? this.action,
        actionMessage: actionMessage != null ? actionMessage() : this.actionMessage,
        deleted: deleted ?? this.deleted,
      );

  @override
  List<Object?> get props => [status, incident, action, actionMessage, deleted];
}

/// One incident, live. Students can delete their own submitted report;
/// staff can change the status.
class IncidentDetailCubit extends Cubit<IncidentDetailState> {
  IncidentDetailCubit(this._repo, this.incidentId) : super(const IncidentDetailState()) {
    _sub = _repo.watchOne(incidentId).listen(
      (i) {
        if (i == null) {
          emit(state.copyWith(status: LoadStatus.failure, deleted: true));
        } else {
          emit(state.copyWith(status: LoadStatus.loaded, incident: i));
        }
      },
      onError: (Object _) => emit(state.copyWith(status: LoadStatus.failure)),
    );
  }

  final IncidentRepository _repo;
  final String incidentId;
  late final StreamSubscription<Incident?> _sub;

  Future<void> updateStatus(IncidentStatus status, {required AppUser staff, String? note}) =>
      _run(() => _repo.updateStatus(incidentId, status: status, staff: staff, note: note),
          success: 'Status updated to ${status.label}. The reporter has been notified.');

  Future<void> delete() => _run(() => _repo.delete(incidentId), success: 'Report deleted.');

  Future<void> _run(Future<void> Function() action, {required String success}) async {
    if (state.action == FormStatus.submitting) return;
    emit(state.copyWith(action: FormStatus.submitting, actionMessage: () => null));
    try {
      await action();
      emit(state.copyWith(action: FormStatus.success, actionMessage: () => success));
    } on RepositoryException catch (e) {
      emit(state.copyWith(action: FormStatus.failure, actionMessage: () => e.message));
    } catch (_) {
      emit(state.copyWith(action: FormStatus.failure, actionMessage: () => 'Something went wrong. Try again.'));
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
