import 'package:flutter/material.dart';

class CategoryLoadingIndicator extends StatelessWidget {
  const CategoryLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}