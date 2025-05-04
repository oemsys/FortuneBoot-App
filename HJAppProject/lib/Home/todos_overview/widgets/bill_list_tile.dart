import 'package:flutter/material.dart';
import 'package:flutter_login_example/Home/theme/theme.dart';
import 'package:flutter_login_example/Home/todos_overview/models/bill_item.dart';
import 'package:todos_repository/todos_repository.dart';
import 'package:intl/intl.dart';

class BillListTile extends StatelessWidget {
  const BillListTile({
    required this.bill,
    super.key,
    this.onToggleCompleted,
    this.onDismissed,
    this.onTap,
  });

  final BillItem bill;
  final ValueChanged<bool>? onToggleCompleted;
  final DismissDirectionCallback? onDismissed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final captionColor = theme.textTheme.bodySmall?.color;
    String title = '';
    bill.categoryAmountPair?.forEach((value) {
      title += value.categoryName ?? ',';
    });
    if (title.length > 0) {
      title.substring(0, title.length - 1);
      title += ' - ';
    }
    title += bill.title ?? '';
    String subtitle = '';
    subtitle += bill.billType?.title ?? '';
    subtitle = subtitle.isNotEmpty ? '$subtitle ' : '';
    DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');
    String formattedDate = formatter.format(bill.tradeTime ?? DateTime.now());
    subtitle += formattedDate;
    Color? billColor;
    switch (bill.billType) {
      case BillType.expenditure:
        billColor =
            Theme.of(context).extension<CustomColors>()!.expenseTextColor;
        break;
      case BillType.income:
        billColor =
            Theme.of(context).extension<CustomColors>()!.incomeTextColor;
        break;
      case BillType.transfer:
        billColor =
            Theme.of(context).extension<CustomColors>()!.transferTextColor;
        break;
      case BillType.adjust:
        billColor =
            Theme.of(context).extension<CustomColors>()!.adjustTextColor;
        break;
      case null:
        // TODO: Handle this case.
        break;
    }
    return Dismissible(
      key: Key('todoListTile_dismissible_${bill.billId}'),
      onDismissed: onDismissed,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: theme.colorScheme.error,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(
          Icons.delete,
          color: Color(0xAAFFFFFF),
        ),
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
        elevation: 8.0,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: ListTile(
          onTap: onTap,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            // style: TextStyle(
            //   color: captionColor,
            //   decoration: TextDecoration.lineThrough,
            // ),
          ),
          subtitle: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: bill.billType?.title, // 前3个字符
                  style:
                      TextStyle(color: billColor, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' $formattedDate', // 剩余字符
                ),
              ],
            ),
          ),
// Text(
//             subtitle,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
          // leading: Checkbox(
          //   shape: const ContinuousRectangleBorder(
          //     borderRadius: BorderRadius.all(Radius.circular(8)),
          //   ),
          //   value: todo.isCompleted,
          //   onChanged: onToggleCompleted == null
          //       ? null
          //       : (value) => onToggleCompleted!(value!),
          // ),
          trailing: Text(
            bill.convertedAmount.toString(),
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: billColor, fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
