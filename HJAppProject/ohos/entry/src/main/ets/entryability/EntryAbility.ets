
import window from '@ohos.window';
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class EntryAbility extends FlutterAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    super.onWindowStageCreate(windowStage);
    // 创建 Flutter 渲染视图并把 viewId 写入全局存储，供 ETS 页面读取
    // createFlutterView 由 FlutterAbility 提供，返回 Promise<string> viewId
    // 防止异常导致白屏，这里加上兜底日志
    this.createFlutterView(windowStage).then((viewId: string) => {
      try {
        // 将 viewId 写入 AppStorage，页面端从 AppStorage 获取
        // AppStorage 是全局级别，可在任意页面读取
        AppStorage.SetOrCreate('viewId', viewId);
      } catch (e: Error | object) {
        console.error('Failed to set viewId to AppStorage:', e);
      }
    }).catch((err: Error | object) => {
      console.error('createFlutterView failed:', err);
    });
  }
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }
}
