import 'package:flutter/material.dart';

/// 帮助中心对话框组件，复刻原 UI 与文案，便于在多个页面复用。
class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('帮助中心'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1. 如何切换账本?', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('点击"当前账本"选项，在弹出的列表中选择需要的账本。'),
          SizedBox(height: 12),
          Text('2. 如何修改个人资料?', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('点击"查看个人资料"进入个人资料页面进行修改。'),
          SizedBox(height: 12),
          Text('3. 遇到问题怎么办?', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('加QQ群：1009576058，在群中反馈问题，我们会尽快处理。'),
          // Text('可以通过"意见反馈"功能向我们反馈问题，我们会尽快处理。'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('我知道了'),
        ),
      ],
    );
  }
}