import 'package:flutter/material.dart';

/// 退出登录确认对话框组件
/// onConfirm 由外部注入，执行实际的退出逻辑（清理数据、跳转等）
class LogoutConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const LogoutConfirmDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('退出登录'),
      content: const Text('确定要退出登录吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('退出'),
        ),
      ],
    );
  }
}