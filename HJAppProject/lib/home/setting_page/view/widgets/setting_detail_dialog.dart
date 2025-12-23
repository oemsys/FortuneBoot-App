import 'package:flutter/material.dart';

/// 通用设置详情对话框组件：展示标题、内容与详细信息
class SettingDetailDialog extends StatelessWidget {
  final String title;
  final String? contentText;
  final String? detailText;

  const SettingDetailDialog({
    super.key,
    required this.title,
    this.contentText,
    this.detailText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contentText != null) Text('内容: $contentText'),
          if (detailText != null) ...[
            const SizedBox(height: 8),
            Text('$detailText'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('确定'),
        ),
      ],
    );
  }
}