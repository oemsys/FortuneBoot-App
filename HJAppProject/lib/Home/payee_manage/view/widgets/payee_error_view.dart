import 'package:flutter/material.dart';
import 'package:hjproject/Home/category_manage/view/widgets/category_error_view.dart';

/// 交易对象错误态：复用分类管理的错误视图与交互
class PayeeErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const PayeeErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryErrorView(message: message, onRetry: onRetry);
  }
}