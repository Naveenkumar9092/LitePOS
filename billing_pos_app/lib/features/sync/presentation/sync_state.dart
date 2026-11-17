import "package:flutter_riverpod/flutter_riverpod.dart";
import "../data/sync_repository.dart";
import "../models/sync_models.dart";

class SyncState {
  final bool isSyncing;
  final DeviceStatusModel? deviceStatus;
  final int pendingOutboxCount;
  final DateTime? lastSyncTime;
  final List<SyncAuditLogModel> history;
  final String? errorMessage;
  final String? successMessage;
  final bool isOnline;

  const SyncState({
    this.isSyncing = false,
    this.deviceStatus,
    this.pendingOutboxCount = 0,
    this.lastSyncTime,
    this.history = const [],
    this.errorMessage,
    this.successMessage,
    this.isOnline = true,
  });

  SyncState copyWith({
    bool? isSyncing,
    DeviceStatusModel? deviceStatus,
    int? pendingOutboxCount,
    DateTime? lastSyncTime,
    List<SyncAuditLogModel>? history,
    String? errorMessage,
    String? successMessage,
    bool? isOnline,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      pendingOutboxCount: pendingOutboxCount ?? this.pendingOutboxCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      history: history ?? this.history,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final repository = ref.watch(syncRepositoryProvider);
  return SyncNotifier(repository);
});

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncRepository _repository;
  final String _currentDeviceId = "POS-TERM-01";

  SyncNotifier(this._repository) : super(const SyncState()) {
    init();
  }

  Future<void> init() async {
    await registerOrGetDevice();
    await checkPending();
    await loadHistory();
  }

  Future<void> registerOrGetDevice() async {
    final res = await _repository.registerDevice(
      deviceId: _currentDeviceId,
      deviceName: "Counter 1 Terminal",
      appVersion: "1.0.0",
      isOnline: true,
    );

    if (res.success && res.data != null) {
      state = state.copyWith(
        deviceStatus: res.data,
        lastSyncTime: res.data!.lastSyncTimeUtc,
        isOnline: res.data!.isOnline,
      );
    }
  }

  Future<void> checkPending() async {
    final count = await _repository.getPendingOutboxCount();
    state = state.copyWith(pendingOutboxCount: count);
  }

  Future<void> loadHistory() async {
    final res = await _repository.getSyncHistory(deviceId: _currentDeviceId, limit: 15);
    if (res.success && res.data != null) {
      state = state.copyWith(history: res.data!);
    }
  }

  Future<void> syncNow() async {
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, errorMessage: null, successMessage: null);

    try {
      // 1. Push all offline records (categories, products, invoices, customers)
      await _repository.syncAllPendingOutbox(
        deviceId: _currentDeviceId,
        appVersion: "1.0.0",
      );

      // 2. Pull latest server catalog
      final pullRes = await _repository.pullCatalog(
        deviceId: _currentDeviceId,
        lastSyncUtc: state.lastSyncTime,
      );

      if (pullRes.success) {
        final now = DateTime.now().toUtc();
        state = state.copyWith(
          isSyncing: false,
          lastSyncTime: now,
          successMessage: "Sync completed successfully. ${pullRes.data ?? 0} master records refreshed.",
          isOnline: true,
        );
      } else {
        state = state.copyWith(
          isSyncing: false,
          errorMessage: pullRes.message.isNotEmpty ? pullRes.message : "Sync encountered issues.",
        );
      }

      await checkPending();
      await loadHistory();
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
        isOnline: false,
      );
    }
  }
}
