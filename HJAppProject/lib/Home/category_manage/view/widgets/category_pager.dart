import 'package:flutter/material.dart';

class CategoryPager extends StatelessWidget {
  const CategoryPager({
    super.key,
    required this.total,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  final int total;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: hasPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('上一页'),
          ),
          Expanded(
            child: Center(
              child: Text(
                '共 $total 条',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: hasNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('下一页'),
          ),
        ],
      ),
    );
  }
}