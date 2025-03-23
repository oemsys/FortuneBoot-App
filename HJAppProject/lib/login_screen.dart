import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_login_example/Login/login_model.dart';
import 'package:flutter_login_example/Login/login_request.dart';
import 'package:flutter_login_example/constants.dart';
import 'package:flutter_login_example/custom_route.dart';
import 'package:flutter_login_example/dashboard_screen.dart';
import 'package:flutter_login_example/theme/app_theme.dart';
import 'package:flutter_login_example/users.dart';
import 'package:flutter_login_example/util/base64_img.dart';
import 'package:flutter_login_example/util/rsa_util.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:retrofit/error_logger.dart';
import 'package:encrypt/encrypt.dart';
import 'generated/l10n.dart';
import 'package:dio/dio.dart';
import 'main.dart';
import 'package:flutter/services.dart';
import 'package:pointycastle/pointycastle.dart' as PC;

class LoginScreen extends StatelessWidget {
  static const routeName = '/auth';

  const LoginScreen({super.key, this.roles = const []});

  final List<Map<String, dynamic>> roles;

  Duration get loginTime => Duration(milliseconds: timeDilation.ceil() * 0);

  String formatPublicKey(String rawBase64) {
    final header = '-----BEGIN PUBLIC KEY-----\n';
    final footer = '\n-----END PUBLIC KEY-----';
    final sb = StringBuffer(header);

    // 每64字符换行（RFC规范要求）
    for (var i = 0; i < rawBase64.length; i += 64) {
      final end = (i + 64) > rawBase64.length ? rawBase64.length : i + 64;
      sb.writeln(rawBase64.substring(i, end));
    }
    return sb.toString() + footer;
  }

  Future<String?> _loginUser(LoginData data) async {
    // lxjtodo：注册：1.验证码 2.rsa加密密码 3.login
    final dio = Dio();
    final loginService = LoginService(dio, errorLogger: LoginErrorReport());
    var capImgRes = await loginService.captchaImage();
    /**
     *"data": {
     *  "isCaptchaOn": true,
     *  "captchaCodeKey": "string",
     *  "captchaCodeImg": "string"
     *}
     */
    debugPrint('验证码：$capImgRes');
    Map<String, dynamic> capDic =
        Map<String, dynamic>.from(capImgRes.data as Map);
    bool isCaptchaOn = capDic['isCaptchaOn'] as bool;
    Map? userResDic = {};
    if (isCaptchaOn) {
      userResDic = await showCaptchaDialog(capDic);
      if (userResDic == null) {
        return '验证码错误或未输入验证码';
      }
    }
    debugPrint('userCode $userResDic');
    var rsaKey = await loginService.getRsaPublicKey();
    /**
     * "data": "string"
     */
    debugPrint('rsa公钥 $rsaKey');
    try {
      String userName = data.name;
      String password = data.password;
      String formattedPublicKey = formatPublicKey(rsaKey.data as String);
      debugPrint('公钥: $formattedPublicKey');
      var publicKey =
          RSAKeyParser().parse(formattedPublicKey) as PC.RSAPublicKey;
      final encrypter = Encrypter(RSA(publicKey: publicKey));
      final encrypted = encrypter.encrypt(password).base64;
      debugPrint('加密结果: $encrypted');
      Login loginRequest = Login(
        userName,
        encrypted,
        userResDic['captchaUserInput'] as String? ?? "",
        userResDic['captchaCodeKey'] as String? ?? "",
      );
      return loginService.login(loginRequest).then((value) {
        debugPrint('登录: $value');
        if (value.code == 0) {
          return null;
        }
        return value.msg ?? '注册失败';
      }).catchError((err) {
        debugPrint(err.toString());
        return 'service error: $err';
      });
    } catch (e) {
      debugPrint(e.toString());
      return 'service error: $e';
    }
  }

  void _selectRole(SignupData data, Map<String, dynamic> role) async {
    debugPrint("选择角色: $role");
    var str = await _signupUserWithRole(data, role);
    MyApp.navigatorKey.currentState?.pop(str);
  }

  Future<String?> _signupUserWithRole(SignupData data, Map role) async {
    final dio = Dio();
    final loginService = LoginService(dio, errorLogger: LoginErrorReport());
    String userName = data.name!;
    String nickName = data.additionalSignupData!['nickname']!;
    String email = data.additionalSignupData!['email']!;
    String phoneNumber = data.additionalSignupData!['phone_number']!;
    int sex =
        (data.additionalSignupData!['sex'] ?? S.current.male) == S.current.male
            ? 1
            : 0;
    String password = data.password!;
    final ResisterLogin post = ResisterLogin(
      userName,
      nickName,
      email,
      phoneNumber,
      sex,
      "",
      password,
      0,
      role['roleId'] as int? ?? 0,
      "",
      0,
    );
    debugPrint(post.toString());
    return loginService.loginRegister(post).then((value) {
      if (value.code == 0) {
        return null;
      }
      debugPrint(value.toString());
      return value.msg ?? '注册失败';
    }).catchError((err) {
      return 'service error: $err';
    });
  }

  Future<String?> _signupUser(SignupData data) async {
    print('lxjtodo _signupConfirm');
    try {
      final dio = Dio();
      final loginService = LoginService(dio, errorLogger: LoginErrorReport());
      var registerRoles = await loginService.getAllowRegisterRoles();
      if (registerRoles.data is List<dynamic>) {
        final List<Map<String, dynamic>> roles =
            List<Map<String, dynamic>>.from(
          registerRoles.data as List<dynamic>,
        );
        if (roles.length == 1) {
          return _signupUserWithRole(
              data, roles.first as Map<String, dynamic>? ?? {});
        } else if (roles.length > 1) {
          final List<SimpleDialogOption> simpleDialogs = roles.map((role) {
            return SimpleDialogOption(
              onPressed: () => _selectRole(data, role),
              child: Text(role['roleName'] as String? ?? ''),
            );
          }).toList();
          return showDialog<String?>(
            context: MyApp.navigatorKey.currentContext!,
            builder: (context) => SimpleDialog(
              title: Text("选择角色"),
              children: simpleDialogs,
            ),
          );
        } else {
          return 'service err role err';
        }
      }
    } catch (e) {
      return Future.delayed(loginTime).then((err) {
        return 'service err $err';
      });
    }
  }

  Future<String?> _recoverPassword(String name) {
    return Future.delayed(loginTime).then((_) {
      if (!mockUsers.containsKey(name)) {
        return S.current.user_not_exist;
      }
      return null;
    });
  }

  Future<String?> _signupConfirm(String error, LoginData data) {
    print('lxjtodo _signupConfirm');
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final additionalSignupFields = fetchUserForms(context);
    return FlutterLogin(
      title: S.of(context).main_logo,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      logo: const AssetImage('assets/images/LOGO.png'),
      logoTag: Constants.logoTag,
      titleTag: Constants.titleTag,
      navigateBackAfterRecovery: true,
      onConfirmRecover: _signupConfirm,
      onSwitchToAdditionalFields: (p0) async {
        Dio dio = Dio();
        final loginService = LoginService(dio, errorLogger: LoginErrorReport());
        var response = await loginService.checkRepeat(p0.name ?? '');
        print('lxjtodo: $response');
        if (response.code == 0) {
          if (response.data is bool) {
            bool res = response.data as bool;
            if (res) {
              return S.current.account_valid;
            }
          }
          return null;
        } else {
          return S.current.account_valid;
        }
      },
      loginAfterSignUp: false,
      termsOfService: [
        TermOfService(
          id: 'general-term',
          mandatory: true,
          text: S.of(context).term_of_services,
          linkUrl: 'https://www.baidu.com',
          validationErrorMessage: S.of(context).service_required,
        ),
      ],
      additionalSignupFields: additionalSignupFields,
      messages: LoginMessages(
        userHint: S.of(context).login_account,
        passwordHint: S.of(context).login_pass,
        confirmPasswordHint: S.of(context).login_confirm,
        loginButton: S.of(context).login_button_text,
        signupButton: S.of(context).register,
        forgotPasswordButton: S.of(context).forgot_huh,
        recoverPasswordButton: S.of(context).help_me,
        goBackButton: S.of(context).go_back,
        confirmPasswordError: S.of(context).not_match,
        recoverPasswordIntro: S.of(context).dont_worry_be_happy,
        recoverPasswordDescription: S.of(context).default_comment,
        recoverPasswordSuccess: S.of(context).password_rescued_successfully,
        flushbarTitleError: S.of(context).oh_no,
        flushbarTitleSuccess: S.of(context).succes,
        providersTitleFirst: S.of(context).or_login_with,
        additionalSignUpFormDescription: S.of(context).fill_to_signup,
        additionalSignUpSubmitButton: S.of(context).sign_up_submit,
        signUpSuccess: S.of(context).sign_up_success,
        // providersTitle: 'login with'
      ),
      theme: AppTheme.loginTheme(context),
      userValidator: (value) {
        if (value!.isEmpty) {
          return S.of(context).user_auth_vaild;
        }
        return null;
      },
      passwordValidator: (value) {
        if (value!.isEmpty) {
          return S.of(context).password_is_empty;
        }

        // 使用指定的正则表达式进行密码校验
        final passwordRegExp = RegExp(
            r'^(?![0-9]+$)(?![a-z]+$)(?![A-Z]+$)(?!([^(0-9a-zA-Z)]|[()])+$)(?!^.*[\u4E00-\u9FA5].*$)([^(0-9a-zA-Z)]|[()]|[a-z]|[A-Z]|[0-9]){8,18}$');

        if (!passwordRegExp.hasMatch(value)) {
          return '密码必须包含字母、数字或特殊字符，长度8-18位，不能包含中文';
        }

        return null;
      },
      onLogin: (loginData) {
        debugPrint('Login info');
        debugPrint('Name: ${loginData.name}');
        debugPrint('Password: ${loginData.password}');
        return _loginUser(loginData);
      },
      onSignup: (signupData) {
        debugPrint('Signup info');
        debugPrint('Name: ${signupData.name}');
        debugPrint('Password: ${signupData.password}');

        signupData.additionalSignupData?.forEach((key, value) {
          debugPrint('$key: $value');
        });
        if (signupData.termsOfService.isNotEmpty) {
          debugPrint('Terms of service: ');
          for (final element in signupData.termsOfService) {
            debugPrint(
              ' - ${element.term.id}: ${element.accepted == true ? 'accepted' : 'rejected'}',
            );
          }
        }
        return _signupUser(signupData);
      },
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(
          FadePageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      },
      onRecoverPassword: (name) {
        debugPrint('Recover password info');
        debugPrint('Name: $name');
        return _recoverPassword(name);
        // Show new password dialog
      },
      headerWidget: const IntroWidget(),
    );
  }

  List<UserFormField> fetchUserForms(BuildContext context) {
    return [
      UserFormField(
        keyName: 'nickname',
        displayName: S.of(context).login_nickname,
        icon: const Icon(FontAwesomeIcons.userLarge),
        fieldValidator: (value) {
          if (value!.isEmpty) {
            return S.of(context).user_auth_vaild;
          }
          return null;
        },
      ),
      UserFormField(
        keyName: 'sex',
        displayName: S.of(context).sex,
        icon: const Icon(FontAwesomeIcons.venusMars),
        userType: LoginUserType.text,
      ),
      UserFormField(
        keyName: 'email',
        displayName: S.of(context).login_email,
        userType: LoginUserType.email,
        icon: const Icon(Icons.email),
        fieldValidator: (value) {
          if (value!.isNotEmpty &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return S.of(context).invalid_email;
          }
          return null;
        },
      ),
      UserFormField(
        keyName: 'phone_number',
        displayName: S.of(context).phone_number,
        userType: LoginUserType.phone,
        // 允许手机号为空
        fieldValidator: (value) {
          // 允许手机号为空
          if (value == null || value.isEmpty) {
            return null;
          }

          final phoneRegExp = RegExp(r'^'
              r'(?:' // 国际号码匹配组
              r'\+1[ -]?(?:\(\d{3}\)|\d{3})[ -]?\d{3}[ -]?\d{4}' // 美国
              r'|\+81[ -]?(?:0\d{1,4}[ -]?\d{1,4}[ -]?\d{4}|\d{1,4}[ -]?\d{1,4}[ -]?\d{4})' // 日本
              r'|\+82[ -]?0?1[0-9]{1}[ -]?\d{3,4}[ -]?\d{4}' // 韩国
              r'|\+33[ -]?(?:[1-9]\d{1}[ -]?){3}\d{2}' // 法国
              r'|\+44[ -]?7(?:[0-9][ -]?){9}' // 英国
              r'|\+7[ -]?[3489]\d{2}[ -]?\d{3}[ -]?\d{2}[ -]?\d{2}' // 俄罗斯
              r'|\+91[ -]?[6-9]\d{4}[ -]?\d{5}' // 印度
              r'|\+86[ -]?1[3-9]\d[ -]?\d{4}[ -]?\d{4}' // 中国国际格式
              r')'
              r'|' // 或中国国内简写格式
              r'(?:1[3-9]\d[ -]?\d{4}[ -]?\d{4})' // 中国国内
              r'$');
          if (!phoneRegExp.hasMatch(value)) {
            return S.of(context).valid_phone_number;
          }
          return null;
        },
      ),
    ];
  }
}

class IntroWidget extends StatelessWidget {
  const IntroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: S.of(context).login_message,
              ),
              TextSpan(
                text: S.of(context).login_host,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          textAlign: TextAlign.justify,
        ),
        Row(
          children: <Widget>[
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(S.of(context).authenticate),
            ),
            Expanded(child: Divider()),
          ],
        ),
      ],
    );
  }
}

// 验证码弹窗组件
Future<Map?> showCaptchaDialog(Map captchaDic) async {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  String captchaCode = captchaDic['captchaCodeImg'] as String;
  Map captchaData = captchaDic;
  final Dio dio = Dio();
  final LoginService loginService =
      LoginService(dio, errorLogger: LoginErrorReport());
  return showDialog<Map?>(
    context: MyApp.navigatorKey.currentContext!,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '请输入验证码',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing),
                GestureDetector(
                  onTap: () async {
                    final capImgRes = await loginService.captchaImage();
                    debugPrint('刷新验证码：$capImgRes');
                    final Map<String, dynamic> capDic =
                        Map<String, dynamic>.from(capImgRes.data as Map);
                    final String resKey = capDic['captchaCodeImg'] as String;
                    setState(() {
                      captchaCode = resKey;
                      captchaData = capDic;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.dividerColor),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                    ),
                    child: Base64Image(base64String: captchaCode),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '请输入图片中的数字',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        final capImgRes = await loginService.captchaImage();
                        debugPrint('刷新验证码：$capImgRes');
                        final Map<String, dynamic> capDic =
                            Map<String, dynamic>.from(capImgRes.data as Map);
                        final String resKey =
                            capDic['captchaCodeImg'] as String;
                        setState(() {
                          captchaCode = resKey;
                          captchaData = capDic;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    ElevatedButton(
                      onPressed: () {
                        Map<String, dynamic> userDic = {};
                        userDic['captchaUserInput'] = controller.text;
                        userDic['captchaCodeKey'] =
                            captchaData['captchaCodeKey'];
                        Navigator.pop(context, userDic);
                      },
                      child: const Text('确认'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
