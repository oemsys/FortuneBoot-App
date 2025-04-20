part of 'post_bloc.dart';

enum SettingStatus { initial, success, failure }

final class SettingState extends Equatable {
  const SettingState({
    this.status = SettingStatus.initial,
    this.settings = const <Setting>[],
  });

  final SettingStatus status;
  final List<Setting> settings;

  SettingState copyWith({
    SettingStatus? status,
    List<Setting>? settings,
  }) {
    return SettingState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
    );
  }

  @override
  String toString() {
    return '''SettingState { status: $status, posts: ${settings.length} }''';
  }

  @override
  List<Object> get props => [status, settings];
}
