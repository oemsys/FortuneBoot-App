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
    final cs = Theme.of(context).colorScheme;

    double hPadding() {
      final w = MediaQuery.of(context).size.width;
      if (w < 600) return 16;
      if (w < 1024) return 20;
      return 24;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(hPadding(), 12, hPadding(), 0),
      child: Card(
        elevation: 1,
        color: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: _typeButton(
                  context: context,
                  type: expenseType,
                  label: '支出分类',
                  selected: selectedType == expenseType,
                  icon: Icons.remove_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _typeButton(
                  context: context,
                  type: incomeType,
                  label: '收入分类',
                  selected: selectedType == incomeType,
                  icon: Icons.add_circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeButton({
    required BuildContext context,
    required int type,
    required String label,
    required bool selected,
    required IconData icon,
  }) {
    final tt = Theme.of(context).textTheme;

    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: tt.labelLarge,
          ),
        ),
      ],
    );

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

    final ButtonStyle baseStyle = ButtonStyle(
      shape: MaterialStatePropertyAll(shape),
      minimumSize: const MaterialStatePropertyAll(Size.fromHeight(44)),
      padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
      visualDensity: VisualDensity.standard,
    );

    final Widget button = selected
        ? FilledButton.tonal(
            onPressed: () => onTypeChanged(type),
            style: baseStyle,
            child: child,
          )
        : OutlinedButton(
            onPressed: () => onTypeChanged(type),
            style: baseStyle,
            child: child,
          );

    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 400),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        onTapHint: '切换$type',
        child: FocusTraversalGroup(child: button),
      ),
    );
  }
}