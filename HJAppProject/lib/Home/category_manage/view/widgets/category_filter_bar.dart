import 'package:flutter/material.dart';

class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  /// 当前选择的类型：1 支出，2 收入
  final int selectedType;

  /// 切换类型的回调，传入 1 或 2
  final ValueChanged<int> onTypeChanged;

  static const int expenseType = 1;
  static const int incomeType = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _typeButton(context, expenseType, '支出分类')),
          const SizedBox(height: 0, width: 8),
          Expanded(child: _typeButton(context, incomeType, '收入分类')),
        ],
      ),
    );
  }

  Widget _typeButton(BuildContext context, int type, String label) {
    final bool selected = selectedType == type;
    final Color color = Theme.of(context).primaryColor;
    return InkWell(
      onTap: () => onTypeChanged(type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}