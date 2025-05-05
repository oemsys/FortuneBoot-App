import 'package:accordion/accordion.dart';
import 'package:accordion/accordion_section.dart';
import 'package:accordion/controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/edit_todo/view/accound_page.dart';
import 'package:flutter_login_example/Home/stats/models/mine_setting.dart';
import 'package:flutter_login_example/Home/stats/models/setting_select_item.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:flutter_login_example/Request/book_request.dart';
import 'package:flutter_login_example/Request/group_request.dart';
import 'package:flutter_login_example/generated/l10n.dart';
import 'package:flutter_login_example/repository/repository/bills_repository.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

// 所属账本
// 标题
// 时间
// 账户
// 分类
// 交易对象
// 标签
// 是否确认
// 是否统计
// 备注
enum EditFieldType {
  billType,
  book,
  title,
  time,
  account,
  category,
  target,
  tag,
  confirm,
  statistics,
  remark
}

class EditFieldCell extends StatefulWidget {
  EditFieldCell({required this.type, super.key});
  EditFieldType type;

  @override
  State<EditFieldCell> createState() => _EditFieldCellState();
}

class _EditFieldCellState extends State<EditFieldCell> {
  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case EditFieldType.billType:
        return EditBaseFieldCell<BillType>.future(
          future: () async {
            return BillType.values
                .map((e) => DropdownItem(label: e.title, value: e))
                .toList();
          },
          type: EditFieldBaseType.dropdown,
          title: '类型',
          needed: true,
        );
      case EditFieldType.book:
        return EditBaseFieldCell<SettingSelectItem>.future(
          future: () async {
            List<DropdownItem<SettingSelectItem>> items = [];
            BookService bookService = BookService();
            var remoteBookResponse = await bookService
                .getByGroupId(context.read<BillsRepository>().groupId() ?? 0);
            if (remoteBookResponse.code == 0) {
              var remoteBookList = remoteBookResponse.data as List? ?? [];
              for (final remoteBookItem in remoteBookList) {
                var remoteBookId = remoteBookItem['bookId'] as String? ?? '';
                var remoteBookName =
                    remoteBookItem['bookName'] as String? ?? '';
                bool selected = false;
                if (remoteBookId == context.read<BillsRepository>().bookId()) {
                  selected = true;
                }
                items.add(
                  DropdownItem(
                      label: remoteBookName,
                      value: SettingSelectItem(remoteBookName,
                          remoteBookItem['bookId'] as int? ?? 0),
                      selected: selected),
                );
              }
            }

            return items;
          },
          type: EditFieldBaseType.dropdown,
          title: '账本',
          needed: true,
        );
      case EditFieldType.title:
        return EditBaseFieldCell(type: EditFieldBaseType.text, title: '标题');
      case EditFieldType.time:
        return EditBaseFieldCell(
            type: EditFieldBaseType.time, title: '时间', needed: true);
      case EditFieldType.account:
        return EditBaseFieldCell<String>.future(
            future: () async {
              return [];
            },
            type: EditFieldBaseType.dropdown,
            title: '账户');
      case EditFieldType.category:
        return EditBaseFieldCell(
            type: EditFieldBaseType.category, title: '分类', needed: true);
      case EditFieldType.target:
        return EditBaseFieldCell<String>.future(
            future: () async {
              return [];
            },
            type: EditFieldBaseType.dropdown,
            title: '交易对象');
      case EditFieldType.tag:
        return EditBaseFieldCell<String>.future(
            future: () async {
              return [];
            },
            type: EditFieldBaseType.dropdown,
            title: '标签');
      case EditFieldType.confirm:
        return EditBaseFieldCell(
            type: EditFieldBaseType.selector, title: '是否确认', needed: true);
      case EditFieldType.statistics:
        return EditBaseFieldCell(
            type: EditFieldBaseType.selector, title: '是否统计', needed: true);
      case EditFieldType.remark:
        return EditBaseFieldCell(
            type: EditFieldBaseType.text, title: '备注', needed: true);
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
      {required this.type, required this.title, this.needed = false, super.key})
      : future = null;

  EditBaseFieldCell.future(
      {required this.type,
      required this.title,
      required this.future,
      this.needed = false,
      super.key});
  String title; //标题
  bool needed; // 是否必填
  EditFieldBaseType type;
  FutureRequest<T>? future;

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
        child = textField();
      case EditFieldBaseType.selector:
        child = textField();
      case EditFieldBaseType.category:
        child = categoryField();
    }
    return child;
  }

  Widget textField() {
    return TextFormField(
      key: const Key('editTodoView_title_textFormField'),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.title}:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Expanded(
          child: MultiDropdown<T>.future(
            onSelectionChange: (selectedItems) {},
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
            searchEnabled: true,
            singleSelect: true,
            // items: items,
          ),
        ),
      ],
    );
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
