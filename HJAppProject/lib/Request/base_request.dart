import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_example/Login/model/login_model.dart';
import 'package:retrofit/error_logger.dart';

abstract class BaseService {
  Future<HJResponse> getEnableList(int id, {int? type});
}

class AccountErrorReport extends ParseErrorLogger {
  @override
  void logError(Object error, StackTrace stackTrace, RequestOptions options) {
    debugPrint('LoginErrorReport: $error $stackTrace $options');
  }
}
