import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_example/Home/stats/bloc/viewModels/include_request.dart';
import 'package:flutter_login_example/Home/stats/models/mine_setting.dart';
import 'package:flutter_login_example/Login/model/login_constants.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:flutter_login_example/Login/model/users.dart';
import 'package:flutter_login_example/Login/viewmodel/login_request.dart';
import 'package:http/http.dart' as http;
import 'package:stream_transform/stream_transform.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

part 'post_event.dart';
part 'post_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class SettingBloc extends Bloc<SettingEvent, SettingState> {
  LoginService _loginService = LoginService();
  IncludeService _accountService = IncludeService();
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
    var elements = await _fetchStaticSettings();
    elements.add(Setting('API版本',
        content: '99.99', leadingWidget: Icon(Icons.cloud_queue))); // todo：调接口
    elements.add(Setting('账户概览',
        detail: '资产：0.00，负债：0.00，净资产：0.00',
        leadingWidget: Icon(Icons.paid))); // todo：接口
    emit(
      state.copyWith(status: SettingStatus.initial, settings: elements),
    );
    var settings = await _fetchStaticSettings();
    var remoteSetting = await _fetchSettings();
    settings.addAll(remoteSetting);
    emit(
      state.copyWith(status: SettingStatus.success, settings: settings),
    );
  }

  Future<List<Setting>> _fetchStaticSettings() async {
    var user = UserDataSingleton();
    List<Setting> elements = [];
    var curUser = user.get(UserDataSingleton.userInfo);
    var userInfo = Map<String, dynamic>.from(curUser['userInfo'] as Map? ?? {});
    var nickName = userInfo['nickname'] as String? ?? '';
    elements.add(Setting('用户名',
        content: nickName, leadingWidget: Icon(Icons.face_retouching_natural)));
    elements.add(Setting('当前主题',
        content: '跟随系统', leadingWidget: Icon(Icons.dark_mode))); // todo：主题
    String currentLocale =
        (Intl.defaultLocale ?? 'en') == 'en' ? '🇺🇸 English' : '🇨🇳 简体中文';
    elements.add(Setting('当前语言',
        content: currentLocale, leadingWidget: Icon(Icons.translate)));
    elements.add(Setting('API',
        content: LoginConstants.baseUrl, leadingWidget: Icon(Icons.edit_note)));
    elements.add(Setting('当前版本',
        content: '99.99', leadingWidget: Icon(Icons.abc))); // todo：当前版本号
    return elements;
  }

  Future<void> _onFetched(
    SettingFetched event,
    Emitter<SettingState> emit,
  ) async {
    var settings = await _fetchStaticSettings();
    var remoteSetting = await _fetchSettings();
    settings.addAll(remoteSetting);
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
    HJResponse apiResponse = await _loginService.apiVersion();
    HJResponse accountResponse =
        await _accountService.getFortuneAssetsLiabilities(1);
    var settings = <Setting>[];
    if (apiResponse.code == 0) {
      String apiVersion = apiResponse.data as String? ?? '';
      settings.add(Setting('API版本',
          content: apiVersion, leadingWidget: const Icon(Icons.cloud_queue)));
    }
    if (accountResponse.code == 0) {
      Map<String, dynamic> accountData =
          Map<String, dynamic>.from(accountResponse.data as Map? ?? {});
      double totalAssets = accountData['totalAssets'] as double? ?? 0.0;
      double totalLiabilities = accountData['totalLiabilities'] as double? ?? 0.0;
      double netAssets = accountData['netAssets'] as double? ?? 0.0;
      settings.add(Setting('账户概览',
          detail: '资产：$totalAssets，负债：$totalLiabilities，净资产：$netAssets', leadingWidget: const Icon(Icons.paid)));
    }
    return settings;
  }
}
