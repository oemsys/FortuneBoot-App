import 'package:flutter/material.dart';

/// 语言选择底部弹窗组件
class LanguageSelectionSheet extends StatelessWidget {
  final List<String> languages;
  final String? current;
  final ValueChanged<String> onSelected;

  const LanguageSelectionSheet({
    super.key,
    required this.languages,
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
              '选择语言',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final item = languages[index];
                final selected = (current != null && current == item) || (current == null && item.contains('简体中文'));
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