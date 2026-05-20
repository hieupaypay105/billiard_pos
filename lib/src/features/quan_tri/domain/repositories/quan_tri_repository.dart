import 'package:anholding_app/src/features/quan_tri/data/models/quan_tri_list_response.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/provider/quan_tri_provider.dart';

abstract class QuanTriRepository {
  Future<QuanTriListResponse> getItems({
    required QuanTriFilter filter,
  });

  Future<void> deleteItem({required String id});

  Future<void> createItem({required Map<String, dynamic> data});

  Future<void> updateItem({required Map<String, dynamic> data});
}
