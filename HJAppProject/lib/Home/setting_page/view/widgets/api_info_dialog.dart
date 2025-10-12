import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// API 信息展示对话框：展示 API 详情，并支持一键复制
class ApiInfoDialog extends StatelessWidget {
  final String? apiDetail;

  const ApiInfoDialog({
    super.key,
    required this.apiDetail,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('API'),
      content: Text(apiDetail ?? ''),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: apiDetail ?? ''));
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板')),
              );
            }
          },
          child: const Text('复制'),
        ),
      ],
    );
  }
}