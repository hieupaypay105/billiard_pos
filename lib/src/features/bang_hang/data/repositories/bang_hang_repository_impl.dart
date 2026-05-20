import 'package:anholding_app/src/features/bang_hang/data/datasources/bang_hang_remote_source.dart';
import 'package:anholding_app/src/features/bang_hang/data/models/bang_hang_list_response.dart';
import 'package:anholding_app/src/features/bang_hang/domain/entities/bang_hang_filter.dart';
import 'package:anholding_app/src/features/bang_hang/domain/repositories/bang_hang_repository.dart';

class BangHangRepositoryImpl implements BangHangRepository {
  const BangHangRepositoryImpl({required this.dataSource});

  final BangHangRemoteDataSource dataSource;

  @override
  Future<BangHangListResponse> getItems({required BangHangFilter filter}) {
    return dataSource.getItems(filter: filter);
  }

  @override
  Future<List<String>> getFilterOptions({
    required int projectId,
    required String type,
  }) {
    return dataSource.getFilterOptions(projectId: projectId, type: type);
  }

  @override
  Future<Map<String, String>> getColumnConfigs({required int projectId}) {
    return dataSource.getColumnConfigs(projectId: projectId);
  }
}
