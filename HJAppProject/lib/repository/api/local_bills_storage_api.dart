import 'dart:async';
import 'dart:convert';

import 'package:hjproject/home/todos_overview/models/bill_item.dart';
import 'package:hjproject/home/todos_overview/models/bill_statistics.dart';
import 'package:hjproject/request/bill_request.dart';
import 'package:hjproject/repository/api/bills_api.dart';
import 'package:hjproject/request/include_request.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  final BillService _billService = BillService();
  final IncludeService _includeService = IncludeService();
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

  Future<void> _setValue(String key, String value) =>
      _plugin.setString(key, value);

  DateTime addOneMonth(DateTime date) {
    int newYear = date.year;
    int newMonth = date.month + 1; // 月份加1

    // 处理跨年（如12月加1个月变为下一年1月）
    if (newMonth > 12) {
      newYear += 1;
      newMonth = 1;
    }

    // 处理目标月份天数不足（如1月31日加1个月到2月需调整为28/29日）
    int newDay = date.day;
    int daysInTargetMonth =
        DateTime(newYear, newMonth + 1, 0).day; // 目标月最大天数[1,3](@ref)
    if (newDay > daysInTargetMonth) {
      newDay = daysInTargetMonth; // 调整为最后一天
    }

    return DateTime(newYear, newMonth, newDay);
  }

  DateTime subtractMonth(DateTime date) {
    int newYear = date.year;
    int newMonth = date.month - 1; // 月份减1

    // 处理跨年（如1月减1个月变为去年12月）
    if (newMonth < 1) {
      newYear -= 1;
      newMonth = 12; // 设为12月
    }

    // 处理目标月份天数不足（如3月31日减1个月到2月可能无效）
    int newDay = date.day;
    int daysInTargetMonth = DateTime(newYear, newMonth + 1, 0).day; // 目标月最大天数
    if (newDay > daysInTargetMonth) {
      newDay = daysInTargetMonth; // 调整为最后一天（如2月28/29日）
    }

    return DateTime(newYear, newMonth, newDay);
  }

  bool refreshCaculatorStatisticsDuration(DateTime time,
      {bool forceRefresh = false}) {
    caculatorTime = time;
    DateTime newEndTime;
    DateTime newStartTime;
    final nextMonth = addOneMonth(time);
    final lastMonth = subtractMonth(time);
    bool needRefresh = false;
    if (time.day > billStatisticsDay) {
      newStartTime = DateTime(time.year, time.month, billStatisticsDay);
      newEndTime = DateTime(nextMonth.year, nextMonth.month, billStatisticsDay);
    } else {
      newStartTime =
          DateTime(lastMonth.year, lastMonth.month, billStatisticsDay);
      newEndTime = DateTime(time.year, time.month, billStatisticsDay);
    }
    if (forceRefresh) {
      endTime = newEndTime;
      startTime = newStartTime;
      return true;
    }
    if (newEndTime != endTime || newStartTime != startTime) {
      endTime = newEndTime;
      startTime = newStartTime;
      needRefresh = true;
    }
    print(
        'lxjtodo: refreshCaculatorStatisticsDuration $endTime $startTime $needRefresh');
    return needRefresh;
  }

  void _init() {
    billStatisticsDay = _plugin.getInt("billStatisticsDay") ?? 1;
    refreshCaculatorStatisticsDuration(DateTime.now(), forceRefresh: true);
  }

  @override
  Future<void> refreshStatistics(DateTime time) async {
    if (refreshCaculatorStatisticsDuration(time)) {
      await refreshStatic(startTime, endTime);
    }
    return;
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
    await refreshStatic(startTime, endTime);
    if (billIndex == -1) {
    } else {
      bills.removeAt(billIndex);
      _billStreamController.add(bills);
      // 统计
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
    await refreshStatic(startTime, endTime);
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

  Future<void> refreshStatic(DateTime startTime, DateTime endTime) async {
    var billStatisticsResponse = await _includeService.getBillStatistics(
      bookId ?? 0,
      DateFormat('yyyy-MM-dd').format(startTime),
      DateFormat('yyyy-MM-dd').format(endTime),
    );
    if (billStatisticsResponse.code == 0) {
      if (billStatisticsResponse.data == null) {
        billStatistics = BillStatistics(
            income: 0, expense: 0, surplus: 0, staticTime: startTime);
      } else {
        BillStatistics statistics = BillStatistics.fromJson(
            Map<String, dynamic>.from(
                billStatisticsResponse.data as Map? ?? {}));
        statistics.staticTime = startTime;
        print('lxjtodo: $statistics startTime:$startTime, endTime:$endTime');
        billStatistics = statistics;
      }
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

  @override
  Future<void> statisticsDayChanged(int day) async {
    billStatisticsDay = day;
    _plugin.setInt("billStatisticsDay", day);
    refreshCaculatorStatisticsDuration(caculatorTime);
    await refreshStatic(startTime, endTime);
    return;
  }
}
