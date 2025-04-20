part of 'post_bloc.dart';

sealed class SettingEvent extends Equatable {
  @override
  List<Object> get props => [];
}

final class SettingInitDataLoaded extends SettingEvent {}

final class SettingFetched extends SettingEvent {}
