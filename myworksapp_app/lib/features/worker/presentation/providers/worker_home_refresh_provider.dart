import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 0 = Pendientes, 1 = En curso, 2 = Finalizados
class WorkerHomeRefreshState {
  const WorkerHomeRefreshState({
    required this.token,
    this.openTabIndex,
  });

  final int token;
  final int? openTabIndex;

  WorkerHomeRefreshState copyWith({
    int? token,
    int? openTabIndex,
    bool clearOpenTabIndex = false,
  }) {
    return WorkerHomeRefreshState(
      token: token ?? this.token,
      openTabIndex: clearOpenTabIndex ? null : (openTabIndex ?? this.openTabIndex),
    );
  }
}

/// Incrementar [token] fuerza recarga del panel del trabajador.
final workerHomeRefreshProvider =
    StateProvider<WorkerHomeRefreshState>((ref) => const WorkerHomeRefreshState(token: 0));

void requestWorkerHomeRefresh(
  WidgetRef ref, {
  int? openTabIndex,
}) {
  ref.read(workerHomeRefreshProvider.notifier).update(
        (state) => WorkerHomeRefreshState(
          token: state.token + 1,
          openTabIndex: openTabIndex,
        ),
      );
}

void clearWorkerHomeOpenTab(WidgetRef ref) {
  ref.read(workerHomeRefreshProvider.notifier).update(
        (state) => state.copyWith(clearOpenTabIndex: true),
      );
}
