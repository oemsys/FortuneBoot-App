import 'package:flutter/material.dart';

/// 主题选择底部弹窗组件
class ThemeSelectionSheet extends StatelessWidget {
  final List<String> themes;
  final String? current;
  final ValueChanged<String> onSelected;

  const ThemeSelectionSheet({
    super.key,
    required this.themes,
    required this.onSelected,
    this.current,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '选择主题',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final item = themes[index];
                final selected = (current != null && current == item) || (current == null && item == '跟随系统');
                return ListTile(
                  title: Text(item),
                  trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
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