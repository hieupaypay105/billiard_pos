import 'package:anholding_app/src/features/khach_hang/data/datasources/khach_hang_remote_source.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_list_response.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_option_response.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/contact_item.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_filter.dart';
import 'package:anholding_app/src/features/khach_hang/domain/repositories/khach_hang_repository.dart';

class KhachHangRepositoryImpl implements KhachHangRepository {
  const KhachHangRepositoryImpl({required this.dataSource});

  final KhachHangRemoteDataSource dataSource;

  @override
  Future<KhachHangListResponse> getItems({
    required KhachHangFilter filter,
  }) {
    return dataSource.getItems(filter: filter);
  }

  @override
  Future<KhachHangOptionResponse> getOptions() {
    return dataSource.getOptions();
  }

  @override
  Future<void> deleteItem({required String id}) {
    return dataSource.deleteItem(id: id);
  }

  @override
  Future<void> createCustomer({required Map<String, dynamic> data}) {
    return dataSource.createCustomer(data: data);
  }

  @override
  Future<void> updateCustomer({required Map<String, dynamic> data}) {
    return dataSource.updateCustomer(data: data);
  }

  @override
  Future<List<String>> getFilterOptions({
    required int projectId,
    required String type,
  }) {
    return dataSource.getFilterOptions(projectId: projectId, type: type);
  }

  @override
  Future<List<ContactItem>> getListContact({required String customerId}) {
    return dataSource.getListContact(customerId: customerId);
  }

  @override
  Future<void> createContact({
    required String customerId,
    required String comment,
  }) {
    return dataSource.createContact(customerId: customerId, comment: comment);
  }

  @override
  Future<String> deleteContact({required String contactId}) {
    return dataSource.deleteContact(contactId: contactId);
  }

  @override
  Future<void> saveFilter({
    required String name,
    required Map<String, dynamic> data,
  }) {
    return dataSource.saveFilter(name: name, data: data);
  }

  @override
  Future<void> setDefaultFilter({
    required String id,
    required int isDefault,
  }) {
    return dataSource.setDefaultFilter(id: id, isDefault: isDefault);
  }

  @override
  Future<void> deleteFilter({required String id}) {
    return dataSource.deleteFilter(id: id);
  }
}
