import 'package:accordion/accordion.dart';
import 'package:accordion/controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_example/Home/edit_todo/edit_select_item.dart';
import 'package:flutter_login_example/Home/edit_todo/view/tree_accordion.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:flutter_login_example/Request/category_request.dart';
import 'package:flutter_login_example/Request/tag_request.dart';
import 'package:flutter_login_example/repository/repository/bills_repository.dart';

class TagSelectField extends StatefulWidget {
  TagSelectField({super.key, required this.billType});
  BillType billType;

  @override
  State<TagSelectField> createState() => _TagSelectFieldState();
}

class _TagSelectFieldState extends State<TagSelectField> {
  @override
  Widget build(BuildContext context) {
    Future<List<TagSelectItem>> futureTagItems =
        tagFutureItems(context, widget.billType);
    return FutureBuilder<List<TagSelectItem>>(
      future: futureTagItems,
      builder: (context, snapshot) {
        // 处理不同状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No data found');
        }

        // 数据加载成功，构建UI
        final items = snapshot.data!;
        return Accordion(
          headerBorderColor: Colors.blueGrey,
          headerBorderColorOpened: Colors.transparent,
          headerBorderWidth: 1,
          disableScrolling: true,
          headerBackgroundColorOpened: Colors.green,
          contentBackgroundColor: Colors.white,
          contentBorderColor: Colors.green,
          contentBorderWidth: 3,
          contentHorizontalPadding: 20,
          scaleWhenAnimating: true,
          openAndCloseAnimation: true,
          headerPadding:
              const EdgeInsets.symmetric(vertical: 7, horizontal: 15),
          sectionOpeningHapticFeedback: SectionHapticFeedback.heavy,
          sectionClosingHapticFeedback: SectionHapticFeedback.light,
          children: [
            AccordionSection(
              // isOpen: true,
              leftIcon:
                  const Icon(Icons.category_outlined, color: Colors.white),
              header: const Text('分类',
                  style: TextStyle(
                      color: Color(0xffffffff),
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              content: TreeAccordion(children: items),
            ),
          ],
        );
      },
    );
  }
}

Future<List<TagSelectItem>> tagFutureItems(
    BuildContext context, BillType billType) async {
  TagService categoryService = TagService();
  var response = await categoryService.getEnableList(
      context.read<BillsRepository>().bookId() ?? 1,
      type: billType.value);
  List<TagSelectItem> categroyItems = [];
  if (response.code == 0) {
    var list = response.data as List? ?? [];
    for (final item in list) {
      categroyItems.add(TagSelectItem.fromJson(
          Map<String, dynamic>.from(item as Map? ?? {})));
    }
  }
  return categroyItems;
}
