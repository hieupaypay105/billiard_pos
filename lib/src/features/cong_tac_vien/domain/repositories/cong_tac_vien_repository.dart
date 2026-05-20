import 'package:anholding_app/src/features/cong_tac_vien/data/models/cong_tac_vien_list_response.dart';
import 'package:anholding_app/src/features/cong_tac_vien/data/models/cong_tac_vien_option_response.dart';
import 'package:anholding_app/src/features/cong_tac_vien/domain/entities/cong_tac_vien_filter.dart';

abstract class CongTacVienRepository {
  Future<CongTacVienListResponse> getItems({
    required CongTacVienFilter filter,
  });

  Future<CongTacVienOptionResponse> getOptions();

  Future<void> deleteItem({required String id});

  Future<String> genCode();

  Future<void> createPartner({required Map<String, dynamic> data});

  Future<void> updatePartner({required Map<String, dynamic> data});
}
