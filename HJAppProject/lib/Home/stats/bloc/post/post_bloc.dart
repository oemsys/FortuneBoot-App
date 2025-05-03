import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dropdown_flutter/custom_dropdown.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_example/Home/stats/models/mine_setting.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:flutter_login_example/Login/model/users.dart';
import 'package:flutter_login_example/Request/book_request.dart';
import 'package:flutter_login_example/Request/group_request.dart';
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
  final GroupService _groupService = GroupService();
  final BookService _bookService = BookService();

  SettingBloc() : super(const SettingState()) {
    on<SettingInitDataLoaded>(
      _onInitData,
      transformer: throttleDroppable(throttleDuration),
    );
    on<GroupSettingFetched>(
      _onFetchedGroup,
      transformer: throttleDroppable(throttleDuration),
    );
    on<GroupSettingChanged>(
      _onChangedGroup,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  static int curId = 0;

  Future<void> _onInitData(
    SettingInitDataLoaded event,
    Emitter<SettingState> emit,
  ) async {
    print('lxjtodo _onInitData');
    final elements = await _fetchStaticSettings();
    emit(
      state.copyWith(status: SettingStatus.initial, settings: elements),
    );
    var settings = await _fetchStaticSettings();
    var remoteSetting = await _fetchSettings();
    emit(
      state.copyWith(
          status: SettingStatus.success,
          settings: settings,
          remoteSettings: remoteSetting),
    );
  }

  Future<List<Setting>> _fetchStaticSettings() async {
    final user = UserDataSingleton();
    final List<Setting> elements = [];
    final curUser = user.get(UserDataSingleton.userInfo);
    final userInfo =
        Map<String, dynamic>.from(curUser['userInfo'] as Map? ?? {});
    final nickName = userInfo['nickname'] as String? ?? '';
    elements.add(Setting(SettingType.username,
        content: nickName,
        leadingWidget: const Icon(Icons.face_retouching_natural)));
    elements.add(const Setting(SettingType.currentTheme,
        content: '跟随系统', leadingWidget: Icon(Icons.dark_mode))); // todo：主题
    final String currentLocale =
        (Intl.defaultLocale ?? 'en') == 'en' ? '🇺🇸 English' : '🇨🇳 简体中文';
    elements.add(Setting(SettingType.currentLanguage,
        content: currentLocale, leadingWidget: Icon(Icons.translate)));
    elements.add(Setting(SettingType.api,
        detail: DioClient().dio.options.baseUrl,
        leadingWidget: const Icon(Icons.edit_note)));
    elements.add(const Setting(SettingType.currentVersion,
        content: '99.99', leadingWidget: Icon(Icons.abc))); // todo：当前版本号
    return elements;
  }

  Future<void> _onFetchedGroup(
    GroupSettingFetched event,
    Emitter<SettingState> emit,
  ) async {
    print('lxjtodo _onFetchedGroup');
    var curSetting = state.settings;
    try {
      final groupSettings = await _fetchGroupSettings(event.groupId);
      emit(
        state.copyWith(
            status: SettingStatus.success,
            settings: curSetting,
            groupSettings: groupSettings),
      );
    } catch (_) {
      emit(
        state.copyWith(status: SettingStatus.failure, settings: curSetting),
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
          SettingType.apiVersion,
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
          SettingType.accountOverview,
          detail: '资产：$totalAssets，负债：$totalLiabilities，净资产：$netAssets',
          leadingWidget: const Icon(Icons.paid),
        ),
      );
    }
    return settings;
  }

  // 查询分组 & 账本设置
  Future<List<Setting>> _fetchGroupSettings(int? groupId) async {
    // todo：groupId是空的话，本地有的话返回
    // groupId不为空，查询分组 & 账本设置否则查询默认分组
    var settings = <Setting>[];
    int? findGroupId = groupId;
    if (findGroupId == null) {
      // 查询默认分组 & 账本设置，本地如果有groupId的话，用本地的去查
      final HJResponse defaultGroupIdResponse =
          await _groupService.getDefaultGroupId();
      if (defaultGroupIdResponse.code == 0) {
        findGroupId = defaultGroupIdResponse.data as int? ?? 0;
      }
    }
    if (findGroupId == null) {
      return settings;
    }
    final HJResponse accountInfo =
        await _groupService.getByGroupId(findGroupId);
    if (accountInfo.code == 0) {
      var data = accountInfo.data as Map? ?? {}; // todo：data存本地
      var groupName = data['groupName'] as String? ?? '';
      var defaultBookName = data['defaultBookName'] as String? ?? '默认账本';
      // var bookListResponse = await _bookService.getByGroupId();
      settings.add(Setting(SettingType.currentGroup,
          content: groupName,
          leadingWidget: const Icon(Icons.group),
          data: {"groupId": data['groupId'], "bookId": data['defaultBookId']}));
      settings.add(Setting(SettingType.currentBook,
          content: defaultBookName,
          leadingWidget: const Icon(Icons.book_online_outlined),
          data: {"groupId": data['groupId'], "bookId": data['defaultBookId']}));
    }
    return settings;
  }

  FutureOr<void> _onChangedGroup(
      GroupSettingChanged event, Emitter<SettingState> emit) async {
    var response = await _bookService.getByGroupId(event.groupId);
    if (response.code == 0) {}
  }
}
