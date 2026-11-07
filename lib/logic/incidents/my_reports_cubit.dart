import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/incident_repository.dart';
import '../../models/incident.dart';
import '../../models/incident_status.dart';
import '../form_status.dart';

class MyReportsState extends Equatable {
  const MyReportsState({this.status = LoadStatus.loading, this.items = const [], this.error});

  final LoadStatus status;

  /// Newest first.
  final List<Incident> items;
  final String? error;

  int get total => items.length;
  int count(IncidentStatus s) => items.where((i) => i.status == s).length;

  @override
  List<Object?> get props => [status, items, error];
}

/// The signed-in student's own reports and their summary counts
/// (Home dashboard and Profile).
class MyReportsCubit extends Cubit<MyReportsState> {
  MyReportsCubit(this._repo, this._uid) : super(const MyReportsState()) {
    _sub = _repo.watchByReporter(_uid).listen(
          (items) => emit(MyReportsState(status: LoadStatus.loaded, items: items)),
          onError: (Object _) => emit(MyReportsState(
              status: LoadStatus.failure, items: state.items, error: 'Could not load your reports.')),
        );
  }

  final IncidentRepository _repo;
  final String _uid;
  late final StreamSubscription<List<Incident>> _sub;

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
