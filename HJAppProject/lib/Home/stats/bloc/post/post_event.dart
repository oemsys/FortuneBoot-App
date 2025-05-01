part of 'post_bloc.dart';

sealed class SettingEvent extends Equatable {
  @override
  List<Object> get props => [];
}

final class SettingInitDataLoaded extends SettingEvent {}

final class GroupSettingFetched extends SettingEvent {
  GroupSettingFetched({this.groupId});
  final int? groupId;
  @override
  List<Object> get props => [groupId ?? 0];
}
