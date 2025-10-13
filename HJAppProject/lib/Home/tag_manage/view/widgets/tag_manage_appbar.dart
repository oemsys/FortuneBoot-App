import 'package:flutter/material.dart';

class TagManageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onAddPressed;

  const TagManageAppBar({
    Key? key,
    required this.onAddPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('标签管理'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: onAddPressed,
          tooltip: '添加标签',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}