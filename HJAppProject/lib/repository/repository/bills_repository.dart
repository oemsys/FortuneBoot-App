import 'package:flutter_login_example/home/todos_overview/models/bill_item.dart';
import 'package:flutter_login_example/home/todos_overview/models/bill_statistics.dart';
import 'package:flutter_login_example/repository/api/bills_api.dart';

class BillsRepository {
  BillsRepository({
    required BillsApi billsApi,
  }) : _billsApi = billsApi;

  String version = '1.0.0';

  final BillsApi _billsApi;

  int? groupId() => _billsApi.groupId;

  int? bookId() => _billsApi.bookId;

  bool hasMore() => _billsApi.hasMore;

  bool isLoadingMore() => _billsApi.isLoadingMore;

  /// Provides a [Stream] of all todos.
  Stream<List<BillItem>> getBills() => _billsApi.getBills();

  Future<void> saveBills(BillItem billItem) => _billsApi.saveBills(billItem);

  Future<void> updateRemoteBill({int? groupId, int? bookId}) =>
      _billsApi.updateRemoteBill(groupId: groupId, bookId: bookId);

  Future<void> nextBillPage() => _billsApi.nextBillPage();

  /// Disposes any resources managed by the repository.
  void dispose() => _billsApi.close();

  void refreshBills({bool clear = true}) => _billsApi.refreshBills(clear);

  void deleteBill(int billId) => _billsApi.deleteBill(billId);

  BillStatistics? getStatistics() => _billsApi.billStatistics;
}
