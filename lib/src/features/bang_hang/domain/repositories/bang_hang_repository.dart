import 'package:anholding_app/src/features/bang_hang/data/models/bang_hang_list_response.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_filter.dart';

abstract class BangHangRepository {
  Future<BangHangListResponse> getItems({required BangHangFilter filter});

  /// Fetches available option values for a filter [type] within a project.
  ///
  /// [type]: 'area' | 'type' | 'direction' | 'handover_status'
  Future<List<String>> getFilterOptions({
    required int projectId,
    required String type,
  });

  /// Fetches column configuration (key: label) for a project.
  Future<Map<String, String>> getColumnConfigs({required int projectId});
}
