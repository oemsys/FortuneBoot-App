import 'package:flutter/material.dart';

class CategoryDeleteConfirmDialog extends StatelessWidget {
  const CategoryDeleteConfirmDialog({
    super.key,
    required this.categoryName,
    required this.onConfirm,
  });

  final String categoryName;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('移入回收站'),
      content: Text('将分类“$categoryName”移入回收站？其子分类也将一并处理。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            await onConfirm();
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context, true);
            }
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}