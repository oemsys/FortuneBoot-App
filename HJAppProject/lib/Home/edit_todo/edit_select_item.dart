import 'package:json_annotation/json_annotation.dart';

part 'edit_select_item.g.dart';

abstract class BaseSelectItem {
  String title;
  int id;
  BaseSelectItem(this.title, this.id);
}

class AccountSelectItem extends BaseSelectItem {
  AccountSelectItem(super.title, super.id);
}

class BookSelectItem extends BaseSelectItem {
  BookSelectItem(super.title, super.id);
}

class TagSelectItem extends BaseSelectItem {
  TagSelectItem(super.title, super.id);
}

class PayeeSelectItem extends BaseSelectItem {
  PayeeSelectItem(super.title, super.id);
}

@JsonSerializable()
class CategorySelectItem {
  List<CategorySelectItem>? children;

  @JsonKey(name: 'categoryName')
  String title;
  @JsonKey(name: 'categoryId')
  int id;
  CategorySelectItem(this.title, this.id, {this.children});

  factory CategorySelectItem.fromJson(Map<String, dynamic> json) =>
      _$CategorySelectItemFromJson(json);
  Map<String, dynamic> toJson() => _$CategorySelectItemToJson(this);

  @override
  String toString() {
    return '$title $id $children';
  }
}
