import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// 通用选择列表底部弹窗组件，支持外部传入列表项与选中状态，点击回传所选项。
/// 适用于：分组选择、账本选择、通用简单选项选择等。
class SelectionOption<T> {
  final String label;
  final T value;
  final bool selected;

  const SelectionOption({
    required this.label,
    required this.value,
    this.selected = false,
  });

  SelectionOption<T> copyWith({String? label, T? value, bool? selected}) {
    return SelectionOption<T>(
      label: label ?? this.label,
      value: value ?? this.value,
      selected: selected ?? this.selected,
    );
    }
}

class SelectionBottomSheet<T> extends StatelessWidget {
  final String title;
  final List<SelectionOption<T>> options;
  final ValueChanged<SelectionOption<T>> onSelected;

  const SelectionBottomSheet({
    super.key,
    required this.title,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final item = options[index];
                return ListTile(
                  title: Text(item.label),
                  trailing: item.selected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () async {
                    developer.log('🎯 SelectionBottomSheet: 用户点击了选项 - ${item.label}', name: 'SelectionBottomSheet');
                    
                    try {
                      // 先调用onSelected回调，让上层处理业务逻辑
                      developer.log('🔄 SelectionBottomSheet: 触发onSelected回调', name: 'SelectionBottomSheet');
                      onSelected(item);
                      
                      // 添加短暂延迟，确保BLoC事件被处理
                      await Future.delayed(const Duration(milliseconds: 50));
                      
                      // 最后关闭弹窗
                      if (context.mounted) {
                        developer.log('✅ SelectionBottomSheet: 关闭弹窗', name: 'SelectionBottomSheet');
                        Navigator.pop(context);
                      } else {
                        developer.log('⚠️ SelectionBottomSheet: Context已失效，跳过Navigator.pop', name: 'SelectionBottomSheet');
                      }
                    } catch (error, stackTrace) {
                      developer.log('❌ SelectionBottomSheet: 处理选择时发生错误', error: error, stackTrace: stackTrace, name: 'SelectionBottomSheet');
                      // 即使出错也要尝试关闭弹窗
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}