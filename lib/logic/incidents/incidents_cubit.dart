import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/incident_repository.dart';
import '../../models/incident.dart';
import '../../models/incident_category.dart';
import '../../models/incident_status.dart';
import '../form_status.dart';

enum IncidentScope { all, mine }

enum IncidentSort { newest, oldest }

class IncidentsState extends Equatable {
  const IncidentsState({
    this.status = LoadStatus.loading,
    this.all = const [],
    this.query = '',
    this.statusFilter,
    this.categoryFilter,
    this.scope = IncidentScope.all,
    this.sort = IncidentSort.newest,
    this.error,
  });

  final LoadStatus status;
  final List<Incident> all;
  final String query;

  /// Null means every status.
  final IncidentStatus? statusFilter;

  /// Null means every category.
  final IncidentCategory? categoryFilter;
  final IncidentScope scope;
  final IncidentSort sort;
  final String? error;

  bool get hasFilters => query.isNotEmpty || statusFilter != null || categoryFilter != null;

  /// [all] after search, filters, scope and sort. [viewerId] decides "mine".
  List<Incident> visible(String viewerId) {
    final q = query.trim().toLowerCase();
    final list = all.where((i) {
      if (scope == IncidentScope.mine && i.reporterId != viewerId) return false;
      if (statusFilter != null && i.status != statusFilter) return false;
      if (categoryFilter != null && i.category != categoryFilter) return false;
      if (q.isNotEmpty &&
          !i.title.toLowerCase().contains(q) &&
          !i.location.toLowerCase().contains(q) &&
          !i.description.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
    list.sort((a, b) => sort == IncidentSort.newest
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return list;
  }

  int countWhere(IncidentStatus s) => all.where((i) => i.status == s).length;

  IncidentsState copyWith({
    LoadStatus? status,
    List<Incident>? all,
    String? query,
    IncidentStatus? Function()? statusFilter,
    IncidentCategory? Function()? categoryFilter,
    IncidentScope? scope,
    IncidentSort? sort,
    String? Function()? error,
  }) =>
      IncidentsState(
        status: status ?? this.status,
        all: all ?? this.all,
        query: query ?? this.query,
        statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
        categoryFilter: categoryFilter != null ? categoryFilter() : this.categoryFilter,
        scope: scope ?? this.scope,
        sort: sort ?? this.sort,
        error: error != null ? error() : this.error,
      );

  @override
  List<Object?> get props => [status, all, query, statusFilter, categoryFilter, scope, sort, error];
}

/// Live list of every incident plus the browse filters. Shared by the
/// student Reports screen and the staff Queue, so a status change made by
/// staff shows up everywhere immediately.
class IncidentsCubit extends Cubit<IncidentsState> {
  IncidentsCubit(this._repo, {IncidentSort sort = IncidentSort.newest})
      : super(IncidentsState(sort: sort)) {
    _subscribe();
  }

  final IncidentRepository _repo;
  StreamSubscription<List<Incident>>? _sub;

  void _subscribe() {
    _sub?.cancel();
    _sub = _repo.watchAll().listen(
          (items) => emit(state.copyWith(status: LoadStatus.loaded, all: items, error: () => null)),
          onError: (Object e) => emit(state.copyWith(
              status: LoadStatus.failure, error: () => 'Could not load reports. Pull to retry.')),
        );
  }

  void retry() {
    emit(state.copyWith(status: LoadStatus.loading));
    _subscribe();
  }

  void search(String query) => emit(state.copyWith(query: query));
  void filterStatus(IncidentStatus? s) => emit(state.copyWith(statusFilter: () => s));
  void filterCategory(IncidentCategory? c) => emit(state.copyWith(categoryFilter: () => c));
  void setScope(IncidentScope scope) => emit(state.copyWith(scope: scope));
  void toggleSort() => emit(state.copyWith(
      sort: state.sort == IncidentSort.newest ? IncidentSort.oldest : IncidentSort.newest));
  void clearFilters() => emit(state.copyWith(query: '', statusFilter: () => null, categoryFilter: () => null));

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
