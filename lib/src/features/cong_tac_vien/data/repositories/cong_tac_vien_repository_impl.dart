import 'package:anholding_app/src/features/cong_tac_vien/data/datasources/cong_tac_vien_remote_source.dart';
import 'package:anholding_app/src/features/cong_tac_vien/data/models/cong_tac_vien_list_response.dart';
import 'package:anholding_app/src/features/cong_tac_vien/data/models/cong_tac_vien_option_response.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_filter.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/repositories/cong_tac_vien_repository.dart';

class CongTacVienRepositoryImpl implements CongTacVienRepository {
  const CongTacVienRepositoryImpl({required this.dataSource});

  final CongTacVienRemoteDataSource dataSource;

  @override
  Future<CongTacVienListResponse> getItems({
    required CongTacVienFilter filter,
  }) {
    return dataSource.getItems(filter: filter);
  }

  @override
  Future<CongTacVienOptionResponse> getOptions() {
    return dataSource.getOptions();
  }

  @override
  Future<void> deleteItem({required String id}) {
    return dataSource.deleteItem(id: id);
  }

  @override
  Future<String> genCode() {
    return dataSource.genCode();
  }

  @override
  Future<void> createPartner({required Map<String, dynamic> data}) {
    return dataSource.createPartner(data: data);
  }

  @override
  Future<void> updatePartner({required Map<String, dynamic> data}) {
    return dataSource.updatePartner(data: data);
  }
}
