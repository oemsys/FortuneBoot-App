import 'package:flutter/material.dart';

/// 通用选择列表底部弹窗组件，支持外部传入列表项与选中状态，点击回传所选项。
/// 适用于：分组选择、账本选择、通用简单选项选择等。
class SelectionOption<T> {
  final String label;
  final T value;
  final bool selected;

  const SelectionOption({
    required this.label,
    required this.value,
    this.selected = false,
  });

  SelectionOption<T> copyWith({String? label, T? value, bool? selected}) {
    return SelectionOption<T>(
      label: label ?? this.label,
      value: value ?? this.value,
      selected: selected ?? this.selected,
    );
    }
}

class SelectionBottomSheet<T> extends StatelessWidget {
  final String title;
  final List<SelectionOption<T>> options;
  final ValueChanged<SelectionOption<T>> onSelected;

  const SelectionBottomSheet({
    super.key,
    required this.title,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final item = options[index];
                return ListTile(
                  title: Text(item.label),
                  trailing: item.selected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}