import 'package:flutter/material.dart';

class AccountMoveToRecycleDialog extends StatefulWidget {
  final String accountName;
  final Future<void> Function() onConfirm;

  const AccountMoveToRecycleDialog({
    Key? key,
    required this.accountName,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<AccountMoveToRecycleDialog> createState() => _AccountMoveToRecycleDialogState();
}

class _AccountMoveToRecycleDialogState extends State<AccountMoveToRecycleDialog> {
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
      title: const Text('确认移入回收站'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('确认将该账户 "${widget.accountName}" 移入回收站？'),
          const SizedBox(height: 8),
          Text(
            '该操作不会删除数据，可在回收站恢复。',
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
            content: Text('操作失败: ${e.toString()}'),
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