// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_stats_classification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillStatsClassification _$BillStatsClassificationFromJson(
        Map<String, dynamic> json) =>
    BillStatsClassification(
      name: json['name'] as String?,
      value: (json['value'] as num?)?.toDouble(),
      percent: (json['percent'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BillStatsClassificationToJson(
        BillStatsClassification instance) =>
    <String, dynamic>{
      'name': instance.name,
      'value': instance.value,
      'percent': instance.percent,
    };
