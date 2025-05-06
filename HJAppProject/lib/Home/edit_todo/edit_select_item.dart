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
class CategorySelectItem extends BaseSelectItem {
  CategorySelectItem(super.title, super.id);
}
