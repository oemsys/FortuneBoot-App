// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_file_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillFileItem _$BillFileItemFromJson(Map<String, dynamic> json) => BillFileItem(
      fileId: json['fileId'] as int?,
      contentType: json['contentType'] as String?,
      fileData: json['fileData'] as String?,
      size: json['size'] as int?,
      originalName: json['originalName'] as String?,
      billId: json['billId'] as int?,
    );

Map<String, dynamic> _$BillFileItemToJson(BillFileItem instance) =>
    <String, dynamic>{
      'fileId': instance.fileId,
      'contentType': instance.contentType,
      'fileData': instance.fileData,
      'size': instance.size,
      'originalName': instance.originalName,
      'billId': instance.billId,
    };
