import 'package:flutter/material.dart';

class CategoryEmptyState extends StatelessWidget {
  const CategoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('暂无分类'),
    );
  }
}