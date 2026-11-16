import "package:flutter_riverpod/flutter_riverpod.dart";
import "../data/gst_repository.dart";
import "../models/gst_models.dart";

final gstNotifierProvider = StateNotifierProvider<GstNotifier, GstState>((ref) {
  final repo = ref.watch(gstRepositoryProvider);
  return GstNotifier(repo);
});

class GstState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final List<TaxModel> taxes;
  final List<HsnSacModel> hsnSacs;
  final GstConfigurationModel? gstConfig;
  final List<CreditNoteModel> creditNotes;
  final GstSummaryModel? gstSummary;
  final DateTime summaryFrom;
  final DateTime summaryTo;

  GstState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.taxes = const [],
    this.hsnSacs = const [],
    this.gstConfig,
    this.creditNotes = const [],
    this.gstSummary,
    DateTime? summaryFrom,
    DateTime? summaryTo,
  })  : summaryFrom = summaryFrom ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
        summaryTo = summaryTo ?? DateTime.now();

  GstState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    List<TaxModel>? taxes,
    List<HsnSacModel>? hsnSacs,
    GstConfigurationModel? gstConfig,
    List<CreditNoteModel>? creditNotes,
    GstSummaryModel? gstSummary,
    DateTime? summaryFrom,
    DateTime? summaryTo,
  }) {
    return GstState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      taxes: taxes ?? this.taxes,
      hsnSacs: hsnSacs ?? this.hsnSacs,
      gstConfig: gstConfig ?? this.gstConfig,
      creditNotes: creditNotes ?? this.creditNotes,
      gstSummary: gstSummary ?? this.gstSummary,
      summaryFrom: summaryFrom ?? this.summaryFrom,
      summaryTo: summaryTo ?? this.summaryTo,
    );
  }
}

class GstNotifier extends StateNotifier<GstState> {
  final GstRepository _repository;

  GstNotifier(this._repository) : super(GstState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final taxRes = await _repository.getTaxes();
    final hsnRes = await _repository.getHsnSacs();
    final configRes = await _repository.getGstConfig();

    state = state.copyWith(
      isLoading: false,
      taxes: taxRes.data ?? [],
      hsnSacs: hsnRes.data ?? [],
      gstConfig: configRes.data,
      errorMessage: !taxRes.success ? taxRes.message : null,
    );
  }

  Future<void> loadSummary({DateTime? from, DateTime? to}) async {
    final f = from ?? state.summaryFrom;
    final t = to ?? state.summaryTo;
    state = state.copyWith(isLoading: true, summaryFrom: f, summaryTo: t);

    final res = await _repository.getGstSummary(fromUtc: f, toUtc: t);
    state = state.copyWith(
      isLoading: false,
      gstSummary: res.data,
      errorMessage: !res.success ? res.message : null,
    );
  }

  Future<void> loadCreditNotes({int? invoiceId, String? noteType}) async {
    state = state.copyWith(isLoading: true);
    final res = await _repository.getCreditNotes(invoiceId: invoiceId, noteType: noteType);
    state = state.copyWith(
      isLoading: false,
      creditNotes: res.data ?? [],
      errorMessage: !res.success ? res.message : null,
    );
  }

  Future<bool> saveTax(CreateTaxRequest request, {int? id, bool isActive = true}) async {
    state = state.copyWith(isLoading: true);
    if (id != null) {
      final res = await _repository.updateTax(id, request, isActive: isActive);
      if (res.success) {
        await loadAll();
        state = state.copyWith(successMessage: "Tax slab updated successfully.");
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: res.message);
      return false;
    } else {
      final res = await _repository.createTax(request);
      if (res.success) {
        await loadAll();
        state = state.copyWith(successMessage: "Tax slab created successfully.");
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: res.message);
      return false;
    }
  }

  Future<bool> saveHsn(CreateHsnRequest request) async {
    state = state.copyWith(isLoading: true);
    final res = await _repository.createOrUpdateHsn(request);
    if (res.success) {
      await loadAll();
      state = state.copyWith(successMessage: "HSN code saved successfully.");
      return true;
    }
    state = state.copyWith(isLoading: false, errorMessage: res.message);
    return false;
  }

  Future<bool> saveConfig(UpdateGstConfigRequest request) async {
    state = state.copyWith(isLoading: true);
    final res = await _repository.updateGstConfig(request);
    if (res.success) {
      await loadAll();
      state = state.copyWith(successMessage: "GST configuration updated successfully.");
      return true;
    }
    state = state.copyWith(isLoading: false, errorMessage: res.message);
    return false;
  }

  Future<bool> issueCreditNote(CreateCreditNoteRequest request) async {
    state = state.copyWith(isLoading: true);
    final res = await _repository.createCreditNote(request);
    if (res.success) {
      await loadCreditNotes();
      state = state.copyWith(successMessage: "${res.data?.noteType ?? "Note"} issued successfully.");
      return true;
    }
    state = state.copyWith(isLoading: false, errorMessage: res.message);
    return false;
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

