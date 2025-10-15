import 'package:flutter/material.dart';
import 'package:hjproject/Home/payee_manage/view/payee_manage_page.dart';
import 'package:hjproject/home/category_manage/view/category_manage_page.dart';
import 'package:hjproject/Home/tag_manage/view/tag_manage_page.dart';
import 'package:hjproject/Home/account_manage/view/account_manage_page.dart';

/// 账本配置分组组件：包含“分类管理”入口
/// 从主页面拆分，保障样式与交互行为一致。
class BookConfigGroup extends StatelessWidget {
  const BookConfigGroup({super.key});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              '账本配置',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.category, color: theme.primaryColor),
            title: const Text('分类管理'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CategoryManagePage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.label, color: theme.primaryColor),
            title: const Text('标签管理'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TagManagePage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.people_alt, color: theme.primaryColor),
            title: const Text('交易对象'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PayeeManagePage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.account_balance, color: theme.primaryColor),
            title: const Text('账户管理'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AccountManagePage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}