import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/notification_repository.dart';
import '../../models/app_notification.dart';
import '../form_status.dart';

class NotificationsState extends Equatable {
  const NotificationsState({this.status = LoadStatus.loading, this.items = const []});

  final LoadStatus status;
  final List<AppNotification> items;

  int get unread => items.where((n) => !n.read).length;

  @override
  List<Object?> get props => [status, items];
}

/// Live alerts for the signed-in user; drives the Alerts tab and the
/// unread dot on the Home bell.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repo, this._uid) : super(const NotificationsState()) {
    _sub = _repo.watchFor(_uid).listen(
          (items) => emit(NotificationsState(status: LoadStatus.loaded, items: items)),
          onError: (Object _) => emit(NotificationsState(status: LoadStatus.failure, items: state.items)),
        );
  }

  final NotificationRepository _repo;
  final String _uid;
  late final StreamSubscription<List<AppNotification>> _sub;

  Future<void> markRead(String id) => _repo.markRead(_uid, id);
  Future<void> markAllRead() => _repo.markAllRead(_uid);

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
