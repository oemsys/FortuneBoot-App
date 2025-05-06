import 'package:accordion/accordion.dart';
import 'package:accordion/accordion_section.dart';
import 'package:accordion/controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/edit_todo/edit_select_item.dart';
import 'package:flutter_login_example/Home/edit_todo/view/accound_page.dart';
import 'package:flutter_login_example/Home/edit_todo/viewmodel/edit_field_cell_viewmodel.dart';
import 'package:flutter_login_example/Home/stats/models/mine_setting.dart';
import 'package:flutter_login_example/Home/stats/models/setting_select_item.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:flutter_login_example/Request/account_request.dart';
import 'package:flutter_login_example/Request/book_request.dart';
import 'package:flutter_login_example/Request/group_request.dart';
import 'package:flutter_login_example/Request/payee_request.dart';
import 'package:flutter_login_example/Request/tag_request.dart';
import 'package:flutter_login_example/generated/l10n.dart';
import 'package:flutter_login_example/repository/repository/bills_repository.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:intl/intl.dart';

enum EditFieldType {
  billType, // 类型
  book, // 所属账本
  title, // 标题
  time, // 时间
  account, // 账户
  category, // 分类
  target, // 交易对象
  tag, // 标签
  confirm, // 是否确认
  statistics, // 是否统计
  remark, // 备注
  transferOutAccount, // 转出账户
  transferInAccount, // 转入账户
  transferAmount // 金额
}

class EditFieldCell extends StatefulWidget {
  EditFieldCell(
      {required this.type,
      required this.billType,
      super.key,
      this.onTypeChange});
  EditFieldType type;
  BillType billType;
  Function(BillType type)? onTypeChange;

  @override
  State<EditFieldCell> createState() => _EditFieldCellState();
}

class _EditFieldCellState extends State<EditFieldCell> {
  //
  @override
  Widget build(BuildContext context) {
    int bookId = context.read<BillsRepository>().bookId() ?? 1;
    int groupId = context.read<BillsRepository>().groupId() ?? 1;
    switch (widget.type) {
      case EditFieldType.billType:
        return EditBaseFieldCell<BillType>.futureDropDown(
          billType: widget.billType,
          future: () async {
            return BillType.values
                .map((e) => DropdownItem(
                    label: e.title, value: e, selected: e == widget.billType))
                .toList()
                .sublist(0, 3);
          },
          onSelectionChange: (selectedItems) {
            widget.billType = BillType.fromValue(selectedItems.first.value) ??
                widget.billType;
            widget.onTypeChange?.call(widget.billType);
          },
          title: '类型',
          needed: true,
        );
      case EditFieldType.book:
        return EditBaseFieldCell<BookSelectItem>.futureDropDown(
          billType: widget.billType,
          future: () async {
            return bookItems(BookService(),
                id: groupId, type: widget.billType.value);
          },
          title: '账本',
          needed: true,
        );
      case EditFieldType.title:
        return EditBaseFieldCell(
            type: EditFieldBaseType.text,
            billType: widget.billType,
            title: '标题');
      case EditFieldType.time:
        return EditBaseFieldCell(
            billType: widget.billType,
            type: EditFieldBaseType.time,
            title: '时间',
            needed: true);
      case EditFieldType.account:
        return EditBaseFieldCell<AccountSelectItem>.futureDropDown(
            billType: widget.billType,
            future: () async {
              return accountItems(AccountService(),
                  id: groupId, type: widget.billType.value);
            },
            title: '账户');
      case EditFieldType.category:
        return EditBaseFieldCell(
            billType: widget.billType,
            type: EditFieldBaseType.category,
            title: '分类',
            needed: true);
      case EditFieldType.target:
        return EditBaseFieldCell<PayeeSelectItem>.futureDropDown(
            billType: widget.billType,
            future: () async {
              return payeeItems(PayeeService(),
                  id: bookId, type: widget.billType.value);
            },
            title: '交易对象');
      case EditFieldType.tag:
        return EditBaseFieldCell<String>.futureDropDown(
            billType: widget.billType,
            future: () async {
              return [];
            },
            title: '标签');
      case EditFieldType.confirm:
        return EditBaseFieldCell(
            billType: widget.billType,
            type: EditFieldBaseType.selector,
            title: '是否确认',
            needed: true);
      case EditFieldType.statistics:
        return EditBaseFieldCell(
            billType: widget.billType,
            type: EditFieldBaseType.selector,
            title: '是否统计',
            needed: true);
      case EditFieldType.remark:
        return EditBaseFieldCell(
            billType: widget.billType,
            type: EditFieldBaseType.text,
            title: '备注',
            needed: true);
      case EditFieldType.transferOutAccount:
        return EditBaseFieldCell<AccountSelectItem>.futureDropDown(
            future: () {
              return accountItems(AccountService(),
                  id: groupId, type: widget.billType.value);
            },
            billType: widget.billType,
            title: '转出账户',
            needed: true);
      case EditFieldType.transferInAccount:
        return EditBaseFieldCell<AccountSelectItem>.futureDropDown(
            future: () {
              return accountItems(AccountService(),
                  id: groupId, type: widget.billType.value);
            },
            billType: widget.billType,
            title: '转入账户',
            needed: true);
      case EditFieldType.transferAmount:
        return EditBaseFieldCell(
            billType: widget.billType,
            type: EditFieldBaseType.text,
            title: '转入账户',
            needed: true);
    }
  }
}

// 下拉选择框
// 文本输入框
// 时间选择器
enum EditFieldBaseType {
  dropdown,
  text,
  time,
  selector,
  category,
}

class EditBaseFieldCell<T extends Object> extends StatefulWidget {
  EditBaseFieldCell(
      {required this.type,
      required this.billType,
      required this.title,
      this.needed = false,
      this.onSelectionChange,
      super.key})
      : future = null;

  EditBaseFieldCell.futureDropDown(
      {required this.billType,
      required this.title,
      required this.future,
      this.onSelectionChange,
      this.needed = false,
      super.key})
      : type = EditFieldBaseType.dropdown;
  String title; //标题
  bool needed; // 是否必填
  EditFieldBaseType type;
  FutureRequest<T>? future;
  BillType billType;
  OnSelectionChanged<T>? onSelectionChange;

  @override
  State<EditBaseFieldCell> createState() => _EditBaseFieldCellState<T>();
}

class _EditBaseFieldCellState<T extends Object>
    extends State<EditBaseFieldCell<T>> {
  @override
  Widget build(BuildContext context) {
    Widget child = Container();
    switch (widget.type) {
      case EditFieldBaseType.dropdown:
        child = dropdownField(context);
      case EditFieldBaseType.text:
        child = textField();
      case EditFieldBaseType.time:
        child = timeField();
      case EditFieldBaseType.selector:
        child = selectorField();
      case EditFieldBaseType.category:
        child = categoryField();
    }
    return child;
  }

  Widget textField() {
    return TextFormField(
      // key: const Key('editTodoView_title_textFormField'),
      // initialValue: '输入标题',
      decoration: InputDecoration(
        labelText: widget.title,
        hintText: widget.title,
      ),
      maxLength: 50,
      inputFormatters: [
        LengthLimitingTextInputFormatter(50),
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
      ],
      onChanged: (value) {
        // context.read<EditTodoBloc>().add(EditTodoTitleChanged(value));
        // 提交
      },
    );
  }

  Widget categoryField() {
    return Accordion(
      headerBorderColor: Colors.blueGrey,
      headerBorderColorOpened: Colors.transparent,
      // headerBorderWidth: 1,
      disableScrolling: true,
      headerBackgroundColorOpened: Colors.green,
      contentBackgroundColor: Colors.white,
      contentBorderColor: Colors.green,
      contentBorderWidth: 3,
      contentHorizontalPadding: 20,
      scaleWhenAnimating: true,
      openAndCloseAnimation: true,
      headerPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
      sectionOpeningHapticFeedback: SectionHapticFeedback.heavy,
      sectionClosingHapticFeedback: SectionHapticFeedback.light,
      children: [
        AccordionSection(
          isOpen: true,
          leftIcon: const Icon(Icons.child_care_rounded, color: Colors.white),
          header: const Text('Nested Accordion',
              style: TextStyle(
                  color: Color(0xffffffff),
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          content: const MyNestedAccordion(),
        ),
      ],
    );
  }

  Widget dropdownField(BuildContext context) {
    String key = 'dropdown_${widget.title}_${widget.billType}';
    print('lxjtodo: dropdownField rebuild key: $key');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.title}:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Expanded(
          child: MultiDropdown<T>.future(
            key: Key(key),
            onSelectionChange: (selectedItems) {
              print('lxjtodo: selectedItems $selectedItems');
              widget.onSelectionChange?.call(selectedItems);
            },
            future: widget.future,
            dropdownItemDecoration: DropdownItemDecoration(
                selectedBackgroundColor: Theme.of(context).focusColor),
            fieldDecoration: FieldDecoration(
              hintText: widget.title,
              hintStyle: const TextStyle(fontSize: 14),
              // prefixIcon: element.leadingWidget,
              showClearIcon: false,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
            ),
            // focusNode: element.type == SettingType.currentGroup ? _focusNode : null,
            dropdownDecoration: DropdownDecoration(
              backgroundColor: Theme.of(context).cardColor,
              marginTop: 2,
              maxHeight: 500,
              header: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a country';
              }
              return null;
            },
            // searchEnabled: true,
            singleSelect: true,
            // items: items,
          ),
        ),
      ],
    );
  }

  Widget timeField() {
    // 当前时间
    final DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');
    String formattedDate = formatter.format(now);
    return Row(
      children: [
        ElevatedButton(
          onPressed: () async {
            final DateTime? dateTime =
                await showOmniDateTimePicker(context: context);
            // Use dateTime here
            debugPrint('dateTime: $dateTime');
          },
          child: Text('时间: $formattedDate'),
        )
      ],
    );
  }

  Widget selectorField() {
    return Container();
  }
}

class MyNestedAccordion extends StatelessWidget {
  const MyNestedAccordion({super.key});

  @override
  Widget build(context) //
  {
    return Accordion(
      paddingListTop: 0,
      paddingListBottom: 0,
      maxOpenSections: 1,
      headerBackgroundColorOpened: Colors.black54,
      headerPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
      children: [
        AccordionSection(
          isOpen: true,
          leftIcon: const Icon(Icons.insights_rounded, color: Colors.white),
          headerBackgroundColor: Colors.black38,
          headerBackgroundColorOpened: Colors.black54,
          header:
              const Text('Nested Section #1', style: AccordionPage.headerStyle),
          content: const Text(AccordionPage.loremIpsum,
              style: AccordionPage.contentStyle),
          contentHorizontalPadding: 20,
          contentBorderColor: Colors.black54,
        ),
        AccordionSection(
          isOpen: true,
          leftIcon: const Icon(Icons.compare_rounded, color: Colors.white),
          header:
              const Text('Nested Section #2', style: AccordionPage.headerStyle),
          headerBackgroundColor: Colors.black38,
          headerBackgroundColorOpened: Colors.black54,
          contentBorderColor: Colors.black54,
          content: const Row(
            children: [
              Icon(Icons.compare_rounded,
                  size: 120, color: Colors.orangeAccent),
              Flexible(
                  flex: 1,
                  child: Text(AccordionPage.loremIpsum,
                      style: AccordionPage.contentStyle)),
            ],
          ),
        ),
      ],
    );
  }
}
