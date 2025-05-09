import 'dart:async';
import 'dart:convert';

import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:flutter_login_example/Request/bill_request.dart';
import 'package:flutter_login_example/Request/book_request.dart';
import 'package:flutter_login_example/repository/api/bills_api.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todos_api/todos_api.dart';

/// {@template local_storage_todos_api}
/// A Flutter implementation of the [TodosApi] that uses local storage.
/// {@endtemplate}
class LocalStorageBillsApi extends BillsApi {
  /// {@macro local_storage_todos_api}
  LocalStorageBillsApi({
    required SharedPreferences plugin,
  }) : _plugin = plugin {
    _init();
  }

  final SharedPreferences _plugin;
  final BookService _bookService = BookService();
  final BillService _billService = BillService();
  int pageNum = 1;
  int pageSize = 20;
  late final _billStreamController = BehaviorSubject<List<BillItem>>.seeded(
    const [],
  );

  /// The key used for storing the todos locally.
  ///
  /// This is only exposed for testing and shouldn't be used by consumers of
  /// this library.
  @visibleForTesting
  static const kBillsCollectionKey = '__bills_collection_key__';

  String? _getValue(String key) => _plugin.getString(key);
  Future<void> _setValue(String key, String value) =>
      _plugin.setString(key, value);

  void _init() {
    // final billsJson = _getValue(kBillsCollectionKey);
    // if (billsJson != null) {
    //   final bills = List<Map<dynamic, dynamic>>.from(
    //     json.decode(billsJson) as List,
    //   )
    //       .map((jsonMap) =>
    //           BillItem.fromJson(Map<String, dynamic>.from(jsonMap)))
    //       .toList();
    //   _billStreamController.add(bills);
    // } else {
    // _billStreamController.add(const []);
    // }
  }

  @override
  Stream<List<BillItem>> getBills() =>
      _billStreamController.asBroadcastStream();

  @override
  Future<void> saveBills(BillItem billItem) {
    final bills = [..._billStreamController.value];
    final billIndex = bills.indexWhere((t) => t.billId == billItem.billId);
    if (billIndex >= 0) {
      bills[billIndex] = billItem;
    } else {
      bills.add(billItem);
    }

    _billStreamController.add(bills);
    return _setValue(kBillsCollectionKey, json.encode(bills));
  }

  @override
  Future<void> deleteBill(int billId) async {
    final bills = [..._billStreamController.value];
    final billIndex = bills.indexWhere((t) => t.billId == billId);
    if (billIndex == -1) {
      throw TodoNotFoundException();
    } else {
      bills.removeAt(billIndex);
      _billStreamController.add(bills);
      return _setValue(kBillsCollectionKey, json.encode(bills));
    }
  }

  @override
  Future<void> close() {
    return _billStreamController.close();
  }

  @override
  Future<void> nextBillPage() async {
    pageNum++;
    queryNewBills();
  }

  Future<void> queryNewBills({bool clear = true}) async {
    isLoadingMore = true;
    List<BillItem> items = [..._billStreamController.value];
    var billResponse = await _billService.getPage(
      pageNum: pageNum,
      pageSize: pageSize,
      bookId: '$bookId',
    );
    if (billResponse.code == 0) {
      var billList = billResponse.data['rows'] as List? ?? [];
      List<BillItem> remoteItems = billList.map((ele) {
        return BillItem.fromJson(Map<String, dynamic>.from(ele as Map? ?? {}));
      }).toList();
      if (clear) {
        items.addAll(remoteItems);
      } else {
        items = remoteItems;
      }
      final allBillsCount = billResponse.data['total'] as int? ?? 20;
      hasMore = items.length < allBillsCount;
      isLoadingMore = false;
      print('lxjbill $items');
      _billStreamController.add(items);
      // _setValue(kBillsCollectionKey, json.encode(items));
    }
    isLoadingMore = false;
  }

  @override
  Future<void> updateRemoteBill({int? groupId, int? bookId}) async {
    print('lxjtodo change bookId $bookId $groupId ');
    if ((groupId != null && groupId != this.groupId) ||
        (bookId != null && bookId != this.bookId)) {
      this.groupId = groupId ?? this.groupId;
      this.bookId = bookId ?? this.bookId;
      pageNum = 1;
      _billStreamController.add([]);
      // await _setValue(kBillsCollectionKey, json.encode([]));
      queryNewBills();
    }
  }

  @override
  Future<void> refreshBills(bool clear) async {
    pageNum = 1;
    if (clear) {
      _billStreamController.add([]);
    }
    queryNewBills(clear: clear);
  }
}
