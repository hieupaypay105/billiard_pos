import 'package:anholding_app/src/features/du_an/data/models/du_an_list_response.dart';
import 'package:anholding_app/src/features/du_an/presentation/provider/du_an_provider.dart';

abstract class DuAnRepository {
  Future<DuAnListResponse> getItems({
    required DuAnFilter filter,
  });

  Future<void> deleteItem({required String id});

  Future<void> createItem({required Map<String, dynamic> data});

  Future<void> updateItem({required Map<String, dynamic> data});
}
