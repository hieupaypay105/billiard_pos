import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/api_client.dart';
import '../../core/providers/providers.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class ShiftModel {
  final String id;
  final String userId;
  final DateTime openedAt;
  final double initialCash;
  final String? note;
  final DateTime? closedAt;
  final double? actualCash;

  const ShiftModel({
    required this.id,
    required this.userId,
    required this.openedAt,
    required this.initialCash,
    this.note,
    this.closedAt,
    this.actualCash,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'opened_at': openedAt.toIso8601String(),
        'initial_cash': initialCash,
        if (note != null) 'note': note,
        if (closedAt != null) 'closed_at': closedAt!.toIso8601String(),
        if (actualCash != null) 'actual_cash': actualCash,
      };

  factory ShiftModel.fromJson(Map<String, dynamic> json) => ShiftModel(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        openedAt: DateTime.tryParse(json['opened_at']?.toString() ?? '') ??
            DateTime.now(),
        initialCash: double.tryParse(json['initial_cash']?.toString() ?? '') ?? 0.0,
        note: json['note']?.toString(),
        closedAt: json['closed_at'] != null ? DateTime.tryParse(json['closed_at']?.toString() ?? '') : null,
        actualCash: json['actual_cash'] != null ? double.tryParse(json['actual_cash']?.toString() ?? '') : null,
      );
}

// ─── State ────────────────────────────────────────────────────────────────────

class ShiftState {
  final ShiftModel? activeShift;
  final bool isLoading;

  const ShiftState({this.activeShift, this.isLoading = false});

  bool get hasActiveShift => activeShift != null;
  String? get currentShiftId => activeShift?.id;

  ShiftState copyWith({ShiftModel? activeShift, bool? isLoading, bool clearShift = false}) {
    return ShiftState(
      activeShift: clearShift ? null : (activeShift ?? this.activeShift),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ShiftNotifier extends StateNotifier<ShiftState> {
  final LocalDbService _localDb;
  final ApiClient? _apiClient;

  ShiftNotifier(this._localDb, [this._apiClient]) : super(const ShiftState()) {
    _loadFromLocal();
  }

  /// Khôi phục ca đang mở từ local DB khi khởi động app.
  Future<void> _loadFromLocal() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _localDb.getActiveShift();
      if (data != null) {
        state = ShiftState(activeShift: ShiftModel.fromJson(data));
      } else {
        state = const ShiftState();
      }
    } catch (e) {
      state = const ShiftState();
    }
  }

  /// Mở ca mới — cố gắng gọi API, nếu offline thì lưu local.
  Future<bool> openShift({
    required String userId,
    required double initialCash,
    String? note,
  }) async {
    state = state.copyWith(isLoading: true);
    final now = DateTime.now();
    String shiftId = 'shift-${now.millisecondsSinceEpoch}';

    if (_apiClient != null) {
      try {
        final res = await _apiClient!.openShift({
          'initial_cash': initialCash,
          if (note != null && note.isNotEmpty) 'note': note,
        });
        final status = res['status'];
        if (status == 1 || status == '1') {
          final data = res['data'] as Map<String, dynamic>?;
          final backendId = data?['id']?.toString();
          if (backendId != null && backendId.isNotEmpty) {
            shiftId = backendId;
          }
        }
      } on Exception {
        // API đã throw (status != 1) → re-throw để UI hiện thông báo
        state = state.copyWith(isLoading: false);
        rethrow;
      } catch (e) {
        // Lỗi network/timeout → offline mode, tiếp tục với local ID
        print('Lỗi mở ca trên backend (offline?): $e');
      }
    }

    final shift = ShiftModel(
      id: shiftId,
      userId: userId,
      openedAt: now,
      initialCash: initialCash,
      note: note,
    );

    try {
      await _localDb.saveActiveShift(
        id: shiftId,
        userId: userId,
        openedAt: now,
        data: shift.toJson(),
      );
      state = ShiftState(activeShift: shift);
      return true;
    } catch (e) {
      print('Lỗi lưu ca làm việc local: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Đóng ca — gọi API đóng ca (nếu online), xóa local.
  Future<bool> closeShift({
    required double actualCash,
    String? note,
  }) async {
    final currentShift = state.activeShift;
    if (currentShift == null) return false;

    state = state.copyWith(isLoading: true);

    if (_apiClient != null) {
      try {
        await _apiClient!.closeShift(currentShift.id, {
          'actual_cash': actualCash,
          if (note != null && note.isNotEmpty) 'note': note,
        });
      } on Exception {
        // API đã throw (status != 1) → re-throw để UI hiện thông báo
        state = state.copyWith(isLoading: false);
        rethrow;
      } catch (e) {
        // Lỗi network/timeout → offline mode, vẫn xóa local
        print('Lỗi đóng ca trên backend (offline?): $e');
      }
    }

    try {
      await _localDb.clearActiveShift();
      state = state.copyWith(clearShift: true);
      return true;
    } catch (e) {
      print('Lỗi xóa ca làm việc local: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  final localDb = ref.watch(localDbServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return ShiftNotifier(localDb, apiClient);
});

/// Trả về shift ID hiện tại (nullable). Null = chưa mở ca.
final currentShiftIdProvider = Provider<String?>((ref) {
  return ref.watch(shiftProvider).currentShiftId;
});

/// Trả về true nếu đang có ca làm việc.
final hasActiveShiftProvider = Provider<bool>((ref) {
  return ref.watch(shiftProvider).hasActiveShift;
});
