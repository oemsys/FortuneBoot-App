import 'package:flutter/material.dart';

class CategoryManageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CategoryManageAppBar({super.key, required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('分类管理'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: '新增分类',
          onPressed: onAddPressed,
        ),
      ],
    );
  }
}