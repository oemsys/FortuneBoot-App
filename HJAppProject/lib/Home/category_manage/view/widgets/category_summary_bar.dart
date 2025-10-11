import 'package:flutter/material.dart';

class CategorySummaryBar extends StatelessWidget {
  const CategorySummaryBar({
    super.key,
    required this.typeText,
    required this.total,
    required this.currentPage,
  });

  /// “支出”或“收入”
  final String typeText;

  /// 总条目数
  final int total;

  /// 当前页码
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  typeText == '支出' ? Icons.remove_circle : Icons.add_circle,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$typeText分类 共$total项',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text('第 $currentPage 页', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}