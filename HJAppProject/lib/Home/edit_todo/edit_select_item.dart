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

class PayeeSelectItem extends BaseSelectItem {
  PayeeSelectItem(super.title, super.id);
}

abstract class BaseTreeSelectItem<T extends BaseTreeSelectItem<T>> {
  List<T>? children;
  String title;
  int id;

  BaseTreeSelectItem(this.title, this.id, {this.children});

  @override
  String toString() => '$title $id $children';
}

@JsonSerializable()
class CategorySelectItem extends BaseTreeSelectItem<CategorySelectItem> {
  List<CategorySelectItem>? children;

  @JsonKey(name: 'categoryName')
  String title;
  @JsonKey(name: 'categoryId')
  int id;
  CategorySelectItem(this.title, this.id, {this.children}) : super(title, id);

  factory CategorySelectItem.fromJson(Map<String, dynamic> json) =>
      _$CategorySelectItemFromJson(json);
  Map<String, dynamic> toJson() => _$CategorySelectItemToJson(this);

  @override
  String toString() {
    return '$title $id $children';
  }
}

@JsonSerializable()
class TagSelectItem extends BaseTreeSelectItem<TagSelectItem> {
  List<TagSelectItem>? children;

  @JsonKey(name: 'tagName')
  String title;
  @JsonKey(name: 'tagId')
  int id;
  TagSelectItem(this.title, this.id, {this.children}) : super(title, id);

  factory TagSelectItem.fromJson(Map<String, dynamic> json) =>
      _$TagSelectItemFromJson(json);
  Map<String, dynamic> toJson() => _$TagSelectItemToJson(this);

  @override
  String toString() {
    return '$title $id $children';
  }
}
