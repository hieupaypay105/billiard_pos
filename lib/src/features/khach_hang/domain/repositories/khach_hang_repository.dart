import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_list_response.dart';
import 'package:anholding_app/src/features/khach_hang/data/models/khach_hang_option_response.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/contact_item.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_filter.dart';

abstract class KhachHangRepository {
  Future<KhachHangListResponse> getItems({
    required KhachHangFilter filter,
  });

  Future<KhachHangOptionResponse> getOptions();

  Future<void> deleteItem({required String id});

  Future<void> createCustomer({required Map<String, dynamic> data});

  Future<void> updateCustomer({required Map<String, dynamic> data});

  Future<List<String>> getFilterOptions({
    required int projectId,
    required String type,
  });

  Future<List<ContactItem>> getListContact({required String customerId});

  Future<void> createContact({
    required String customerId,
    required String comment,
  });

  Future<String> deleteContact({required String contactId});

  Future<void> saveFilter({
    required String name,
    required Map<String, dynamic> data,
  });

  Future<void> setDefaultFilter({required String id, required int isDefault});

  Future<void> deleteFilter({required String id});
}
