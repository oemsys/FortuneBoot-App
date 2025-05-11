import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hjproject/home/edit_bill/models/edit_select_item.dart';
import 'package:hjproject/home/todos_overview/models/bill_item.dart';
import 'package:hjproject/request/tag_request.dart';
import 'package:hjproject/repository/repository/bills_repository.dart';

class TagTreeSelection extends StatefulWidget {
  TagTreeSelection(
      {super.key,
      required this.tags,
      this.onTagSelected,
      required this.selectedTagIds});
  List<TagSelectItem> tags;
  Function(List<int>)? onTagSelected;
  List<int> selectedTagIds;

  @override
  State<TagTreeSelection> createState() => _TagTreeSelectionState();
}

class _TagTreeSelectionState extends State<TagTreeSelection> {
  // 展开的二级标签ID列表（用于控制UI展开/折叠）
  List<int> _expandedSecondLevelIds = [];

  @override
  Widget build(BuildContext context) {
    widget.onTagSelected?.call(widget.selectedTagIds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 已选择的标签
        if (widget.selectedTagIds.isNotEmpty) _buildSelectedTags(widget.tags),

        // 标签选择器
        _buildTagSelector(widget.tags),
      ],
    );
  }

  // 已选择的标签
  Widget _buildSelectedTags(List<TagSelectItem> allTags) {
    // 从所有标签中找出已选择的标签
    List<String> selectedTagNames = [];

    for (int tagId in widget.selectedTagIds) {
      // 获取标签的完整路径
      String tagPath = TagSelectItem.getFullPathById(allTags, tagId);
      selectedTagNames.add(tagPath);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '已选择的标签',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(widget.selectedTagIds.length, (index) {
              final tagId = widget.selectedTagIds[index];
              final tagName = selectedTagNames[index];

              return Chip(
                label: Text(tagName),
                deleteIcon: Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    widget.selectedTagIds.remove(tagId);
                  });
                },
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              );
            }),
          ),
          SizedBox(height: 16),
          Divider(),
        ],
      ),
    );
  }

  // 标签选择器
  Widget _buildTagSelector(List<TagSelectItem> tags) {
    // 将标签分组显示
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tags.map((tag) {
          return Card(
            margin: EdgeInsets.only(bottom: 16.0),
            elevation: 0,
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 一级标签（主标签）
                ListTile(
                  leading: Icon(Icons.label,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(
                    tag.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 选择一级标签
                      FilterChip(
                        label: Text('选择'),
                        selected: widget.selectedTagIds.contains(tag.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              if (!widget.selectedTagIds.contains(tag.id)) {
                                widget.selectedTagIds.add(tag.id);
                              }
                            } else {
                              widget.selectedTagIds.remove(tag.id);
                            }
                          });
                        },
                        backgroundColor: Colors.transparent,
                        selectedColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        checkmarkColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),

                // 二级标签
                if (tag.children != null && tag.children!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: tag.children!.map((secondLevelTag) {
                        bool isExpanded =
                            _expandedSecondLevelIds.contains(secondLevelTag.id);
                        bool hasThirdLevel = secondLevelTag.children != null &&
                            secondLevelTag.children!.isNotEmpty;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 二级标签标题行
                            InkWell(
                              onTap: hasThirdLevel
                                  ? () {
                                      setState(() {
                                        if (isExpanded) {
                                          _expandedSecondLevelIds
                                              .remove(secondLevelTag.id);
                                        } else {
                                          _expandedSecondLevelIds
                                              .add(secondLevelTag.id);
                                        }
                                      });
                                    }
                                  : null,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.label_outline,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        secondLevelTag.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (hasThirdLevel)
                                      Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: 18,
                                      ),
                                    SizedBox(width: 8),
                                    FilterChip(
                                      label: Text('选择'),
                                      labelStyle: TextStyle(fontSize: 12),
                                      selected: widget.selectedTagIds
                                          .contains(secondLevelTag.id),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            if (!widget.selectedTagIds
                                                .contains(secondLevelTag.id)) {
                                              widget.selectedTagIds
                                                  .add(secondLevelTag.id);
                                            }
                                          } else {
                                            widget.selectedTagIds
                                                .remove(secondLevelTag.id);
                                          }
                                        });
                                      },
                                      backgroundColor: Colors.transparent,
                                      selectedColor: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      checkmarkColor: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 三级标签（如果有且已展开）
                            if (hasThirdLevel && isExpanded)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 24.0, bottom: 8.0),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: secondLevelTag.children!
                                      .map((thirdLevelTag) {
                                    return FilterChip(
                                      label: Text(thirdLevelTag.title),
                                      selected: widget.selectedTagIds
                                          .contains(thirdLevelTag.id),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            if (!widget.selectedTagIds
                                                .contains(thirdLevelTag.id)) {
                                              widget.selectedTagIds
                                                  .add(thirdLevelTag.id);
                                            }
                                          } else {
                                            widget.selectedTagIds
                                                .remove(thirdLevelTag.id);
                                          }
                                        });
                                      },
                                      backgroundColor: Colors.transparent,
                                      selectedColor: Theme.of(context)
                                          .colorScheme
                                          .tertiaryContainer,
                                      checkmarkColor: Theme.of(context)
                                          .colorScheme
                                          .onTertiaryContainer,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 0),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    );
                                  }).toList(),
                                ),
                              ),

                            Divider(height: 1, indent: 16),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                SizedBox(height: 8),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
