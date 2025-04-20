import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

final class Setting extends Equatable {
  const Setting(this.title, {this.detail, this.content, this.leadingWidget});

  final String title;
  final String? detail;
  final String? content;
  final Widget? leadingWidget;

  @override
  List<Object> get props => [title, detail ?? '', content ?? '', leadingWidget.hashCode];
}
