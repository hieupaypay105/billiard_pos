import 'package:anholding_app/src/features/du_an/data/datasources/du_an_remote_source.dart';
import 'package:anholding_app/src/features/du_an/data/models/du_an_list_response.dart';
import 'package:anholding_app/src/features/du_an/domain/repositories/du_an_repository.dart';
import 'package:anholding_app/src/features/du_an/presentation/provider/du_an_provider.dart';

class DuAnRepositoryImpl implements DuAnRepository {
  const DuAnRepositoryImpl({required this.dataSource});

  final DuAnRemoteDataSource dataSource;

  @override
  Future<DuAnListResponse> getItems({
    required DuAnFilter filter,
  }) {
    return dataSource.getItems(filter: filter);
  }

  @override
  Future<void> deleteItem({required String id}) {
    return dataSource.deleteItem(id: id);
  }

  @override
  Future<void> createItem({required Map<String, dynamic> data}) {
    return dataSource.createItem(data: data);
  }

  @override
  Future<void> updateItem({required Map<String, dynamic> data}) {
    return dataSource.updateItem(data: data);
  }
}
