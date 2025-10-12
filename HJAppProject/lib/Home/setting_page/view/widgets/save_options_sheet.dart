import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// 通用“保存/下载”底部操作面板组件：
/// - Web: 显示“下载图片”
/// - 非Web: 显示“保存到相册”和简要说明
/// - 通用: 显示“复制资源路径”和“取消”
class SaveOptionsSheet extends StatelessWidget {
  final String assetPath;
  final String suggestedName;
  final Future<void> Function() onDownloadOrSave; // 统一保存/下载动作
  final VoidCallback? onClose;

  const SaveOptionsSheet({
    super.key,
    required this.assetPath,
    required this.suggestedName,
    required this.onDownloadOrSave,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text(
            '操作',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 1),
          if (kIsWeb)
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('下载图片'),
              onTap: () async {
                Navigator.pop(context);
                await onDownloadOrSave();
              },
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('保存到相册'),
              onTap: () async {
                Navigator.pop(context);
                await onDownloadOrSave();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('说明'),
              subtitle: const Text('如保存失败，请尝试截图或检查系统权限设置'),
              onTap: () => Navigator.pop(context),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('复制资源路径'),
            subtitle: Text(assetPath),
            onTap: () {
              Clipboard.setData(ClipboardData(text: assetPath));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制资源路径')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('取消'),
            onTap: () {
              Navigator.pop(context);
              onClose?.call();
            },
          ),
        ],
      ),
    );
  }
}