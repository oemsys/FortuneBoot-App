// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillStatistics _$BillStatisticsFromJson(Map<String, dynamic> json) =>
    BillStatistics(
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
      surplus: (json['surplus'] as num).toDouble(),
    );

Map<String, dynamic> _$BillStatisticsToJson(BillStatistics instance) =>
    <String, dynamic>{
      'income': instance.income,
      'expense': instance.expense,
      'surplus': instance.surplus,
    };
