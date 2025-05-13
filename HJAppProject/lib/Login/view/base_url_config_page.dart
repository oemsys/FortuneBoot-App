import 'dart:math';

import 'package:hjproject/repository/repository/bills_repository.dart';
import 'package:hjproject/request/login_request.dart';
import 'package:flutter/material.dart';
import 'package:hjproject/home/home/view/home_page.dart';
import 'package:hjproject/login/model/users.dart';
import 'package:hjproject/login/view/login_screen.dart';
import 'package:hjproject/generated/l10n.dart';
import 'package:hjproject/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:hjproject/util/dio_client.dart';
import 'package:permission_handler/permission_handler.dart';

enum AuthMode {
  loading,
  signIn,
}

class BaseUrlConfigPage extends StatefulWidget {
  static const routeName = '/base_url_config';

  const BaseUrlConfigPage({Key? key}) : super(key: key);

  @override
  _BaseUrlConfigPageState createState() => _BaseUrlConfigPageState();
}

class _BaseUrlConfigPageState extends State<BaseUrlConfigPage> {
  final _formKey = GlobalKey<FormState>();
  ValueNotifier<AuthMode> _authMode = ValueNotifier<AuthMode>(AuthMode.loading);
  String _protocol = 'https';
  final TextEditingController _domainController =
      TextEditingController(text: 'fortuneboot.com');
  final TextEditingController _portController =
      TextEditingController(text: '443');

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTokenValid();
    });
    super.initState();
  }

  Future<void> _checkTokenValid() async {
    var baseUrlDomain =
        await UserDataSingleton().getStr(UserDataSingleton.baseUrlDomain);
    var baseUrlPort =
        await UserDataSingleton().getStr(UserDataSingleton.baseUrlPort);
    var baseProtocol =
        await UserDataSingleton().getStr(UserDataSingleton.baseUrlProtocol);
    if (baseUrlDomain?.isNotEmpty == true &&
        baseUrlPort?.isNotEmpty == true &&
        baseProtocol?.isNotEmpty == true) {
      _domainController.text = baseUrlDomain!;
      _portController.text = baseUrlPort!;
      _protocol = baseProtocol!;
    }
    var userInfo = await UserDataSingleton().getMap(UserDataSingleton.userInfo);
    var userToken =
        await UserDataSingleton().getMap(UserDataSingleton.userToken);
    if ((userInfo?.isNotEmpty == true) &&
        (userToken?.isNotEmpty == true) &&
        (baseUrlDomain?.isNotEmpty == true) &&
        (baseUrlPort?.isNotEmpty == true) &&
        (baseProtocol?.isNotEmpty == true)) {
      // 跳登录页
      final baseUrl = '$baseProtocol://$baseUrlDomain:$baseUrlPort';
      DioClient().updateBaseUrl('$baseUrl/prod-api');
      if (!(await checkApiVersion())) {
        _showErrorDialog(S.current.serverConnectionFailed);
        _authMode.value = AuthMode.signIn;
        return;
      }
      DioClient().refreshToken(userToken!);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
        (route) => false,
      );
    } else {
      _authMode.value = AuthMode.signIn;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _authMode,
        builder: (a, v, b) {
          return Scaffold(
            appBar: AppBar(
              title: Text(S.of(context).baseUrlConfig),
            ),
            body: v == AuthMode.loading
                ? Container()
                : Form(
                    key: _formKey,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacing),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppTheme.cardBorderRadius),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacing),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  S.of(context).baseUrlConfig,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppTheme.spacingLarge),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: DropdownButtonFormField<String>(
                                        value: _protocol,
                                        items: ['https', 'http']
                                            .map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _protocol = newValue!;
                                          });
                                        },
                                        decoration: InputDecoration(
                                            labelText: S.of(context).protocol),
                                      ),
                                    ),
                                    const SizedBox(
                                        width: AppTheme.spacingSmall),
                                    Expanded(
                                      flex: 4,
                                      child: TextFormField(
                                        controller: _domainController,
                                        decoration: InputDecoration(
                                            labelText: S.of(context).domain),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return S
                                                .of(context)
                                                .pleaseEnterDomain; // 可为空
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                        width: AppTheme.spacingSmall),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _portController,
                                        decoration: InputDecoration(
                                            labelText: S.of(context).port),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingLarge),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _submitForm,
                                    child: Text(S.of(context).confirm),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          );
        });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      var baseUrl = '$_protocol://${_domainController.text}';
      if (_portController.text.isNotEmpty) {
        baseUrl += ':${_portController.text}';
      }
      DioClient().updateBaseUrl('$baseUrl/prod-api');
      try {
        if (await checkApiVersion()) {
          UserDataSingleton()
              .setStr(UserDataSingleton.baseUrlDomain, _domainController.text);
          UserDataSingleton()
              .setStr(UserDataSingleton.baseUrlPort, _portController.text);
          UserDataSingleton()
              .setStr(UserDataSingleton.baseUrlProtocol, _protocol);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LoginScreen(),
            ),
          );
        } else {
          _showErrorDialog(S.current.serverConnectionFailed);
        }
      } catch (e) {
        _showErrorDialog(S.current.serverConnectionFailed);
      }
    }
  }

  Future<bool> checkApiVersion() async {
    LoginService loginService = LoginService();
    try {
      final apiResponse = await loginService.apiVersion();
      if (apiResponse.code == 0) {
        final curVersionString = apiResponse.data as String? ?? '';
        if (curVersionString.isNotEmpty) {
          final int maxRes =
              compareVersion(curVersionString, BillsRepository.maxApiVersion);
          final int minRes =
              compareVersion(curVersionString, BillsRepository.minApiVersion);
          // 左闭右开
          print('lxjtodo: $maxRes $minRes');
          return maxRes < 0 && minRes >= 0;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      _showErrorDialog(e.toString());
      return false;
    }
  }

  int compareVersion(String version1, String version2) {
    List<String> v1 = version1.split('.');
    List<String> v2 = version2.split('.');

    int maxLength = max(v1.length, v2.length);
    for (int i = 0; i < maxLength; i++) {
      int num1 = (i < v1.length) ? int.parse(v1[i]) : 0;
      int num2 = (i < v2.length) ? int.parse(v2[i]) : 0;

      if (num1 < num2)
        return -1;
      else if (num1 > num2) return 1;
    }
    return 0;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.of(context).ok),
          ),
        ],
      ),
    );
  }
}
