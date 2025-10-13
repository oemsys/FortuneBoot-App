import 'package:flutter/material.dart';

class TagEmptyState extends StatelessWidget {
  const TagEmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.label_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无标签',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角的 + 按钮添加第一个标签',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              // 这里可以触发添加标签的操作
              // 但由于这个组件是无状态的，我们暂时不实现具体逻辑
            },
            icon: const Icon(Icons.add),
            label: const Text('添加标签'),
          ),
        ],
      ),
    );
  }
}