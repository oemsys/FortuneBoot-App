import 'package:flutter/foundation.dart';

/// 交易对象模型与分页数据
class Payee {
  final int payeeId;
  final int bookId;
  final String payeeName;
  final int sort;
  final bool canExpense;
  final bool canIncome;
  final bool enable;
  final String? remark;

  const Payee({
    required this.payeeId,
    required this.bookId,
    required this.payeeName,
    required this.sort,
    required this.canExpense,
    required this.canIncome,
    required this.enable,
    this.remark,
  });

  factory Payee.fromJson(Map<String, dynamic> json) {
    return Payee(
      payeeId: json['payeeId'] is String ? int.tryParse(json['payeeId']) ?? 0 : (json['payeeId'] ?? 0) as int,
      bookId: json['bookId'] is String ? int.tryParse(json['bookId']) ?? 0 : (json['bookId'] ?? 0) as int,
      payeeName: (json['payeeName'] ?? '').toString(),
      sort: json['sort'] is String ? int.tryParse(json['sort']) ?? 0 : (json['sort'] ?? 0) as int,
      canExpense: (json['canExpense'] as bool?) ?? false,
      canIncome: (json['canIncome'] as bool?) ?? false,
      enable: (json['enable'] as bool?) ?? false,
      remark: json['remark']?.toString(),
    );
  }

  @override
  String toString() {
   return 'Payee(payeeId: $payeeId, name: $payeeName, sort: $sort, canExpense: $canExpense, canIncome: $canIncome, enable: $enable)';
  }
}

class PayeePageData {
  final int total;
  final List<Payee> rows;

  const PayeePageData({
    required this.total,
    required this.rows,
  });

  factory PayeePageData.fromJson(Map<String, dynamic> json) {
    final total = json['total'] is String ? int.tryParse(json['total']) ?? 0 : (json['total'] ?? 0) as int;
    final list = json['rows'];
    final rows = (list is List ? list : const <dynamic>[])
        .map((e) => Payee.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return PayeePageData(total: total, rows: rows);
  }
}