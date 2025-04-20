import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_example/Home/stats/models/mine_setting.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:flutter_login_example/Login/model/users.dart';
import 'package:flutter_login_example/Request/include_request.dart';
import 'package:flutter_login_example/Request/login_request.dart';
import 'package:flutter_login_example/util/dio_client.dart';
import 'package:intl/intl.dart';
import 'package:stream_transform/stream_transform.dart';

part 'post_event.dart';
part 'post_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class SettingBloc extends Bloc<SettingEvent, SettingState> {
  final LoginService _loginService = LoginService();
  final IncludeService _accountService = IncludeService();

  SettingBloc() : super(const SettingState()) {
    on<SettingFetched>(
      _onFetched,
      transformer: throttleDroppable(throttleDuration),
    );
    on<SettingInitDataLoaded>(
      _onInitData,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  void sortList(List<Setting> settings) {
    final Map<String, int> curSortList = {
      "用户名": 0,
      "账户概览": 1,
      "当前分组": 2,
      "当前账本": 3,
      "当前主题": 4,
      "当前语言": 5,
      "API": 6,
      "当前版本": 7,
      "API版本": 8,
    };
    settings.sort((a, b) {
      final int indexA = curSortList[a.title] ?? 0;
      final int indexB = curSortList[b.title] ?? 0;
      return indexA - indexB;
    });
  }

  static int curId = 0;

  Future<void> _onInitData(
    SettingInitDataLoaded event,
    Emitter<SettingState> emit,
  ) async {
    // nickname
    // 用户名
    // 账户概览
    // 当前账本
    // 当前主题
    // 当前语言
    // API：
    // 当前版本
    // API版本
    // 退出登录
    final elements = await _fetchStaticSettings();
    elements.add(const Setting('API版本',
        content: '99.99', leadingWidget: Icon(Icons.cloud_queue))); // todo：调接口
    elements.add(const Setting('账户概览',
        detail: '资产：0.00，负债：0.00，净资产：0.00',
        leadingWidget: Icon(Icons.paid))); // todo：接口
    emit(
      state.copyWith(status: SettingStatus.initial, settings: elements),
    );
    var settings = await _fetchStaticSettings();
    var remoteSetting = await _fetchSettings();
    settings.addAll(remoteSetting);
    sortList(settings);
    emit(
      state.copyWith(status: SettingStatus.success, settings: settings),
    );
  }

  Future<List<Setting>> _fetchStaticSettings() async {
    final user = UserDataSingleton();
    final List<Setting> elements = [];
    final curUser = user.get(UserDataSingleton.userInfo);
    final userInfo =
        Map<String, dynamic>.from(curUser['userInfo'] as Map? ?? {});
    final nickName = userInfo['nickname'] as String? ?? '';
    elements.add(Setting('用户名',
        content: nickName,
        leadingWidget: const Icon(Icons.face_retouching_natural)));
    elements.add(const Setting('当前主题',
        content: '跟随系统', leadingWidget: Icon(Icons.dark_mode))); // todo：主题
    final String currentLocale =
        (Intl.defaultLocale ?? 'en') == 'en' ? '🇺🇸 English' : '🇨🇳 简体中文';
    elements.add(Setting('当前语言',
        content: currentLocale, leadingWidget: Icon(Icons.translate)));
    elements.add(Setting('API',
        detail: DioClient().dio.options.baseUrl,
        leadingWidget: const Icon(Icons.edit_note)));
    elements.add(const Setting('当前版本',
        content: '99.99', leadingWidget: Icon(Icons.abc))); // todo：当前版本号
    return elements;
  }

  Future<void> _onFetched(
    SettingFetched event,
    Emitter<SettingState> emit,
  ) async {
    final settings = await _fetchStaticSettings();
    final remoteSetting = await _fetchSettings();
    settings.addAll(remoteSetting);
    sortList(settings);
    try {
      emit(
        state.copyWith(status: SettingStatus.success, settings: settings),
      );
    } catch (_) {
      emit(
        state.copyWith(status: SettingStatus.failure, settings: settings),
      );
    }
  }

  Future<List<Setting>> _fetchSettings() async {
    final HJResponse apiResponse = await _loginService.apiVersion();
    final HJResponse accountResponse =
        await _accountService.getFortuneAssetsLiabilities(1);
    var settings = <Setting>[];
    if (apiResponse.code == 0) {
      final String apiVersion = apiResponse.data as String? ?? '';
      settings.add(
        Setting(
          'API版本',
          content: apiVersion,
          leadingWidget: const Icon(Icons.cloud_queue),
        ),
      );
    }
    if (accountResponse.code == 0) {
      final Map<String, dynamic> accountData =
          Map<String, dynamic>.from(accountResponse.data as Map? ?? {});
      final double totalAssets = accountData['totalAssets'] as double? ?? 0.0;
      final double totalLiabilities =
          accountData['totalLiabilities'] as double? ?? 0.0;
      final double netAssets = accountData['netAssets'] as double? ?? 0.0;
      settings.add(
        Setting(
          '账户概览',
          detail: '资产：$totalAssets，负债：$totalLiabilities，净资产：$netAssets',
          leadingWidget: const Icon(Icons.paid),
        ),
      );
    }
    return settings;
  }
}
