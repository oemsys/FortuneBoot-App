import 'package:flutter/material.dart';
import 'package:flutter_login_example/Home/home/view/home_page.dart';
import 'package:flutter_login_example/Login/model/users.dart';
import 'package:flutter_login_example/Login/view/login_screen.dart';
import 'package:flutter_login_example/generated/l10n.dart';
import 'package:flutter_login_example/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter_login_example/util/custom_route.dart';
import 'package:flutter_login_example/util/dio_client.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (baseUrlDomain?.isNotEmpty == true && baseUrlPort?.isNotEmpty == true) {
      _domainController.text = baseUrlDomain!;
      _portController.text = baseUrlPort!;
    }
    var userInfo = await UserDataSingleton().getMap(UserDataSingleton.userInfo);
    var userToken =
        await UserDataSingleton().getMap(UserDataSingleton.userToken);
    if ((userInfo?.isNotEmpty == true) &&
        (userToken?.isNotEmpty == true) &&
        (baseUrlDomain?.isNotEmpty == true) &&
        (baseUrlPort?.isNotEmpty == true)) {
      DioClient().refreshToken(userToken!);
      // 跳登录页
      var baseUrl = '$_protocol://${_domainController.text}';
      if (_portController.text.isNotEmpty) {
        baseUrl += ':${_portController.text}';
      }
      DioClient().updateBaseUrl('$baseUrl/prod-api');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _authMode,
        builder: (a, v, b) {
          // if (v == AuthMode.loading) {
          //   return Container(
          //     // color: Theme.of(context).scaffoldBackgroundColor,
          //     child: LoadingIndicator(
          //         indicatorType: Indicator.ballPulse,

          //         /// Required, The loading type of the widget
          //         colors: const [Colors.white],

          //         /// Optional, The color collections
          //         strokeWidth: 2,

          //         /// Optional, The stroke of the line, only applicable to widget which contains line
          //         backgroundColor: Colors.black,

          //         /// Optional, Background of the widget
          //         pathBackgroundColor: Colors.black

          //         /// Optional, the stroke backgroundColor
          //         ),
          //   );
          // }
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
                                          // // IPv4, IPv6, 或域名的简单验证
                                          // final ipv4Regex =
                                          //     RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                                          // final ipv6Regex = RegExp(
                                          //     r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$');
                                          // final domainRegex =
                                          //     RegExp(r'^[a-zA-Z0-9.-]+(\.[a-zA-Z]{2,})?$');
                                          // if (value != 'localhost' &&
                                          //     !ipv4Regex.hasMatch(value) &&
                                          //     !ipv6Regex.hasMatch(value) &&
                                          //     !domainRegex.hasMatch(value)) {
                                          //   return S.of(context).invalidDomain;
                                          // }
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      var baseUrl = '$_protocol://${_domainController.text}';
      if (_portController.text.isNotEmpty) {
        baseUrl += ':${_portController.text}';
      }
      DioClient().updateBaseUrl('$baseUrl/prod-api');
      try {
        final dio = Dio();
        final response = await dio.get('$baseUrl/prod-api/getApiVersion');
        if (response.statusCode == 200) {
          final responseData = response.data;
          if (responseData is Map<String, dynamic> &&
              responseData['code'] == 0) {
            final apiVersion = responseData['data'] as String;
            UserDataSingleton().setStr(
                UserDataSingleton.baseUrlDomain, _domainController.text);
            UserDataSingleton()
                .setStr(UserDataSingleton.baseUrlPort, _portController.text);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LoginScreen(),
              ),
            );
          } else {
            _showErrorDialog(S.of(context).serverConnectionFailed);
          }
        } else {
          _showErrorDialog(S.of(context).serverConnectionFailed);
        }
      } catch (e) {
        _showErrorDialog(S.of(context).serverConnectionFailed);
      }
    }
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
