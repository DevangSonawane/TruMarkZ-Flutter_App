import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/verification_models.dart';
import '../../../core/network/api_client.dart';
import '../data/verification_repository.dart';

class VerificationListState {
  const VerificationListState({
    required this.data,
    required this.statusFilter,
    required this.offset,
  });

  final AsyncValue<VerificationListResponse> data;
  final String? statusFilter; // null = all
  final int offset;

  VerificationListState copyWith({
    AsyncValue<VerificationListResponse>? data,
    String? statusFilter,
    int? offset,
    bool clearStatusFilter = false,
  }) {
    return VerificationListState(
      data: data ?? this.data,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      offset: offset ?? this.offset,
    );
  }
}

final verificationListNotifierProvider =
    StateNotifierProvider<VerificationListNotifier, VerificationListState>((
      ref,
    ) {
      return VerificationListNotifier(ref.read(verificationRepositoryProvider));
    });

class VerificationListNotifier extends StateNotifier<VerificationListState> {
  VerificationListNotifier(this._repo)
    : super(
        const VerificationListState(
          data: AsyncLoading(),
          statusFilter: null,
          offset: 0,
        ),
      );

  final VerificationRepository _repo;

  Future<void> load({int limit = 200}) async {
    state = state.copyWith(data: const AsyncLoading());
    try {
      final VerificationListResponse res = await _repo.getAllVerifications(
        status: state.statusFilter,
        offset: state.offset,
        limit: limit,
      );
      state = state.copyWith(data: AsyncData(res));
    } on ApiException catch (e, st) {
      state = state.copyWith(data: AsyncError(e, st));
    } catch (e, st) {
      state = state.copyWith(data: AsyncError(e, st));
    }
  }

  Future<void> setFilter(String? status) async {
    state = state.copyWith(
      statusFilter: status?.trim().isEmpty ?? true ? null : status?.trim(),
      offset: 0,
    );
    await load();
  }
}
