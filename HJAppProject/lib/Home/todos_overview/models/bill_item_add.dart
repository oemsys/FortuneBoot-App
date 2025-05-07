import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bill_item_add.g.dart';

@immutable
@JsonSerializable()
class BillItemAdd {
  Data? data;
  List<String>? files;

  BillItemAdd({this.data, this.files});
  factory BillItemAdd.fromJson(Map<String, dynamic> json) =>
      _$BillItemAddFromJson(json);
  Map<String, dynamic> toJson() => _$BillItemAddToJson(this);

  @override
  String toString() {
    return 'BillItemAdd{data: $data, files: $files}';
  }
}

@JsonSerializable()
class Data {
  int? bookId;
  String? title;
  String? tradeTime;
  int? accountId;
  int? accountToId;
  List<CategoryAmountPair>? categoryAmountPair;
  int? amount;
  int? convertedAmount;
  int? payeeId;
  int? billType;
  int? toAccountId;
  bool? confirm;
  bool? include;
  String? remark;
  List<int>? tagIdList;
  List<String>? fileList;

  Data(
      {this.bookId,
      this.title,
      this.tradeTime,
      this.accountId,
      this.accountToId,
      this.categoryAmountPair,
      this.amount,
      this.convertedAmount,
      this.payeeId,
      this.billType,
      this.toAccountId,
      this.confirm,
      this.include,
      this.remark,
      this.tagIdList,
      this.fileList});

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
  Map<String, dynamic> toJson() => _$DataToJson(this);

  @override
  String toString() {
    return 'Data{bookId: $bookId, title: $title, tradeTime: $tradeTime, accountId: $accountId, accountToId: $accountToId, categoryAmountPair: $categoryAmountPair, amount: $amount, convertedAmount: $convertedAmount, payeeId: $payeeId, billType: $billType, toAccountId: $toAccountId, confirm: $confirm, include: $include, remark: $remark, tagIdList: $tagIdList, fileList: $fileList}';
  }
}

@JsonSerializable()
class CategoryAmountPair {
  int? key;
  int? value;

  CategoryAmountPair({this.key, this.value});

  factory CategoryAmountPair.fromJson(Map<String, dynamic> json) => _$CategoryAmountPairFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryAmountPairToJson(this);

  @override
  String toString() {
    return 'CategoryAmountPair{key: $key, value: $value}';
  }

}
