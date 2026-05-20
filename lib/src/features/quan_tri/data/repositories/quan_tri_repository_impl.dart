import 'package:anholding_app/src/features/quan_tri/data/datasources/quan_tri_remote_source.dart';
import 'package:anholding_app/src/features/quan_tri/data/models/quan_tri_list_response.dart';
import 'package:anholding_app/src/features/quan_tri/domain/repositories/quan_tri_repository.dart';
import 'package:anholding_app/src/features/quan_tri/presentation/provider/quan_tri_provider.dart';

class QuanTriRepositoryImpl implements QuanTriRepository {
  const QuanTriRepositoryImpl({required this.dataSource});

  final QuanTriRemoteDataSource dataSource;

  @override
  Future<QuanTriListResponse> getItems({
    required QuanTriFilter filter,
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
