import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ExpandableDropdown extends StatefulWidget {
  @override
  _ExpandableDropdownState createState() => _ExpandableDropdownState();
}

class _ExpandableDropdownState extends State<ExpandableDropdown> {
  bool _isExpanded = false; // 展开状态
  final double _collapsedWidth = 120; // 收起时宽度
  final double _expandedWidth = 240; // 展开时宽度

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300), // 动画时长
        curve: Curves.easeInOut, // 动画曲线
        width: _isExpanded ? _expandedWidth : _collapsedWidth,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _buildContent(), // 自定义下拉内容
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        // 默认显示项
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [Text('选择项'), Spacer(), Icon(Icons.arrow_drop_down)],
          ),
        ),
        // 展开时的选项列表
        if (_isExpanded)
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.only(top: 40),
              children: ['选项1', '选项2', '选项3']
                  .map((e) => ListTile(title: Text(e), onTap: () => _selectItem(e)))
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _selectItem(String value) {
    setState(() {
      _isExpanded = false; // 选中后收起
      // 更新选中状态逻辑...
    });
  }
}