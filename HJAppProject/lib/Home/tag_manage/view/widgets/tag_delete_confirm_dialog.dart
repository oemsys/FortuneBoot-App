import 'package:flutter/material.dart';

class TagDeleteConfirmDialog extends StatefulWidget {
  final String tagName;
  final Future<void> Function() onConfirm;

  const TagDeleteConfirmDialog({
    Key? key,
    required this.tagName,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<TagDeleteConfirmDialog> createState() => _TagDeleteConfirmDialogState();
}

class _TagDeleteConfirmDialogState extends State<TagDeleteConfirmDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        color: theme.colorScheme.error,
        size: 32,
      ),
      title: const Text('确认删除'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('您确定要将标签 "${widget.tagName}" 移入回收站吗？'),
          const SizedBox(height: 8),
          Text(
            '此操作可以撤销，您可以在回收站中恢复。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onError,
                  ),
                )
              : const Text('移入回收站'),
        ),
      ],
    );
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    try {
      await widget.onConfirm();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}