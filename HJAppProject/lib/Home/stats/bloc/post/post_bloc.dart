import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_example/Home/stats/models/mine_setting.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:flutter_login_example/Login/model/users.dart';
import 'package:flutter_login_example/Request/book_request.dart';
import 'package:flutter_login_example/Request/group_request.dart';
import 'package:flutter_login_example/Request/include_request.dart';
import 'package:flutter_login_example/Request/login_request.dart';
import 'package:flutter_login_example/repository/repository/bills_repository.dart';
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

  SettingBloc({
    required BillsRepository billsRepository,
  })  : _billsRepository = billsRepository,
        super(const SettingState()) {
    on<SettingInitDataLoaded>(
      _onInitData,
      transformer: throttleDroppable(throttleDuration),
    );
    on<GroupSettingFetched>(
      _onFetchedGroup,
      transformer: throttleDroppable(throttleDuration),
    );
    on<BookIdChanged>(
      _onChangedBookId,
      transformer: throttleDroppable(throttleDuration),
    );
  }

  final BillsRepository _billsRepository;

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
    elements.add(Setting(SettingType.currentVersion,
        content: _billsRepository.version, leadingWidget: Icon(Icons.abc)));
    return elements;
  }

  Future<void> _onFetchedGroup(
    GroupSettingFetched event,
    Emitter<SettingState> emit,
  ) async {
    // 这里更新分组ID，
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
          detail: '资产：$totalAssets\r\n负债：$totalLiabilities\r\n净资产：$netAssets',
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
      // 查询bills,更新repository
      _billsRepository.updateRemoteBill(
          groupId: findGroupId, bookId: data['defaultBookId'] as int? ?? 1);
    }
    return settings;
  }

  FutureOr<void> _onChangedBookId(
      BookIdChanged event, Emitter<SettingState> emit) async {
    var newGroup = <Setting>[];
    Setting? groupSetting;
    Setting? bookSetting;
    state.groupSettings.forEach((element) {
      if (element.type == SettingType.currentGroup) {
        groupSetting = element;
      } else if (element.type == SettingType.currentBook) {
        bookSetting = Setting(SettingType.currentBook,
            content: event.bookName,
            leadingWidget: const Icon(Icons.book_online_outlined),
            data: {
              "groupId": _billsRepository.groupId(),
              "bookId": event.bookId,
            });
      }
    });
    _billsRepository.updateRemoteBill(bookId: event.bookId);
    if (groupSetting != null) {
      newGroup.add(groupSetting!);
    }
    if (bookSetting != null) {
      newGroup.add(bookSetting!);
    }
    emit(
      state.copyWith(status: SettingStatus.failure, groupSettings: newGroup),
    );
  }
}
