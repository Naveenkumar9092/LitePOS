import "package:flutter_riverpod/flutter_riverpod.dart";
import "../data/notification_repository.dart";
import "../models/notification_models.dart";

class NotificationState {
  final bool isLoading;
  final bool isDispatching;
  final ShopPreferenceModel? preferences;
  final SystemInfoSummaryModel? systemInfo;
  final List<NotificationAuditLogModel> recentLogs;
  final NotificationResultModel? lastDispatchResult;
  final DatabaseBackupResultModel? lastBackupResult;
  final String? errorMessage;
  final String? successMessage;

  const NotificationState({
    this.isLoading = false,
    this.isDispatching = false,
    this.preferences,
    this.systemInfo,
    this.recentLogs = const [],
    this.lastDispatchResult,
    this.lastBackupResult,
    this.errorMessage,
    this.successMessage,
  });

  NotificationState copyWith({
    bool? isLoading,
    bool? isDispatching,
    ShopPreferenceModel? preferences,
    SystemInfoSummaryModel? systemInfo,
    List<NotificationAuditLogModel>? recentLogs,
    NotificationResultModel? lastDispatchResult,
    DatabaseBackupResultModel? lastBackupResult,
    String? errorMessage,
    String? successMessage,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      isDispatching: isDispatching ?? this.isDispatching,
      preferences: preferences ?? this.preferences,
      systemInfo: systemInfo ?? this.systemInfo,
      recentLogs: recentLogs ?? this.recentLogs,
      lastDispatchResult: lastDispatchResult ?? this.lastDispatchResult,
      lastBackupResult: lastBackupResult ?? this.lastBackupResult,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository);
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;

  NotificationNotifier(this._repository) : super(const NotificationState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.wait([
      loadPreferences(),
      loadSystemInfo(),
      loadLogs(),
    ]);
    state = state.copyWith(isLoading: false);
  }

  Future<void> loadPreferences() async {
    try {
      final res = await _repository.getPreferences();
      if (res.success && res.data != null) {
        state = state.copyWith(preferences: res.data);
      } else {
        state = state.copyWith(
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to load preferences.",
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<bool> updatePreferences(ShopPreferenceModel prefs) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.updatePreferences(prefs);
      if (res.success && res.data != null) {
        state = state.copyWith(
          isLoading: false,
          preferences: res.data,
          successMessage: "Store preferences and notification settings updated.",
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to update preferences.",
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<NotificationResultModel?> sendInvoiceEmail({
    required int invoiceId,
    String? recipientOverride,
  }) async {
    state = state.copyWith(isDispatching: true, errorMessage: null);
    try {
      final req = SendInvoiceNotificationModel(
        invoiceId: invoiceId,
        channel: NotificationChannel.email,
        recipientOverride: recipientOverride,
      );
      final res = await _repository.sendInvoiceEmail(req);
      if (res.success && res.data != null) {
        await loadLogs();
        state = state.copyWith(
          isDispatching: false,
          lastDispatchResult: res.data,
          successMessage: "Tax Invoice emailed successfully to ${res.data!.recipient}.",
        );
        return res.data;
      } else {
        state = state.copyWith(
          isDispatching: false,
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to send invoice email.",
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isDispatching: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<NotificationResultModel?> sendInvoiceWhatsApp({
    required int invoiceId,
    String? recipientOverride,
  }) async {
    state = state.copyWith(isDispatching: true, errorMessage: null);
    try {
      final req = SendInvoiceNotificationModel(
        invoiceId: invoiceId,
        channel: NotificationChannel.whatsApp,
        recipientOverride: recipientOverride,
      );
      final res = await _repository.sendInvoiceWhatsApp(req);
      if (res.success && res.data != null) {
        await loadLogs();
        state = state.copyWith(
          isDispatching: false,
          lastDispatchResult: res.data,
          successMessage: "Invoice sent via WhatsApp to ${res.data!.recipient}.",
        );
        return res.data;
      } else {
        state = state.copyWith(
          isDispatching: false,
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to send WhatsApp invoice.",
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isDispatching: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<DatabaseBackupResultModel?> triggerDatabaseBackup() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.createDatabaseBackup();
      if (res.success && res.data != null) {
        await loadSystemInfo();
        state = state.copyWith(
          isLoading: false,
          lastBackupResult: res.data,
          successMessage: "Database backup completed: ${res.data!.backupFileName}",
        );
        return res.data;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.message.isNotEmpty ? res.message : "Failed to create database backup.",
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<void> loadSystemInfo() async {
    try {
      final res = await _repository.getSystemInfo();
      if (res.success && res.data != null) {
        state = state.copyWith(systemInfo: res.data);
      }
    } catch (_) {}
  }

  Future<void> loadLogs() async {
    try {
      final res = await _repository.getNotificationLogs(page: 1, pageSize: 20);
      if (res.success && res.data != null) {
        state = state.copyWith(recentLogs: res.data!);
      }
    } catch (_) {}
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

