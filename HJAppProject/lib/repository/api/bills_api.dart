import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_statistics.dart';

abstract class BillsApi {
  bool hasMore = true;

  bool isLoadingMore = false;

  /// {@macro todos_api}
  BillsApi();

  int? groupId;

  int? bookId;

  /// Provides a [Stream] of all todos.
  Stream<List<BillItem>> getBills();

  /// Saves a [todo].
  ///
  /// If a [todo] with the same id already exists, it will be replaced.
  Future<void> saveBills(BillItem billItem);

  Future<void> deleteBill(int billId);

  Future<void> updateRemoteBill({int? groupId, int? bookId});

  Future<void> nextBillPage();

  /// Closes the client and frees up any resources.
  Future<void> close();

  Future<void> refreshBills(bool clear);

  BillStatistics? billStatistics;
}
