import 'package:flutter/material.dart';

/// 用户头部区域组件：显示头像首字母、用户名、“查看个人资料”入口与二维码按钮。
/// 将主页面中的用户信息头部区域解耦为可复用组件，方便在其它页面/场景中复用。
class MineUserHeader extends StatelessWidget {
  /// 显示的用户名
  final String username;

  /// 点击“查看个人资料”的回调
  final VoidCallback onViewProfile;

  /// 点击右侧二维码按钮的回调
  final VoidCallback onShowQRCode;

  const MineUserHeader({
    super.key,
    required this.username,
    required this.onViewProfile,
    required this.onShowQRCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = (username.isNotEmpty ? username.substring(0, 1) : '?').toUpperCase();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: onViewProfile,
                  child: const Row(
                    children: [
                      Text(
                        '查看个人资料',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.white),
            onPressed: onShowQRCode,
            tooltip: '打赏/二维码',
          ),
        ],
      ),
    );
  }
}