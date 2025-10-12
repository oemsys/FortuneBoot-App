import 'package:flutter/material.dart';

/// 更多操作分组组件：打赏、反馈、评分、退出登录
/// 从主设置页拆分，保持UI一致，通过回调注入交互行为。
class AdditionalOptionsGroup extends StatelessWidget {
  final VoidCallback onDonate;
  final VoidCallback onFeedback;
  final VoidCallback onRate;
  final VoidCallback onLogout;

  const AdditionalOptionsGroup({
    super.key,
    required this.onDonate,
    required this.onFeedback,
    required this.onRate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.favorite, color: theme.primaryColor),
            title: const Text('打赏作者'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onDonate,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.feedback, color: theme.primaryColor),
            title: const Text('意见反馈'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onFeedback,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.star, color: theme.primaryColor),
            title: const Text('给应用评分'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onRate,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}