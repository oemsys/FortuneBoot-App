import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bill_statistics.g.dart';

@immutable
@JsonSerializable()
class BillStatistics {
  double income;
  double expense;
  double surplus;
  factory BillStatistics.fromJson(Map<String, dynamic> json) =>
      _$BillStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$BillStatisticsToJson(this);

  BillStatistics(
      {required this.income, required this.expense, required this.surplus});
}
