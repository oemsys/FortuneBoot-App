import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_login_example/Login/login_model.dart';
import 'package:flutter_login_example/Login/login_request.dart';
import 'package:flutter_login_example/constants.dart';
import 'package:flutter_login_example/custom_route.dart';
import 'package:flutter_login_example/dashboard_screen.dart';
import 'package:flutter_login_example/users.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'generated/l10n.dart';
import 'package:dio/dio.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/auth';

  const LoginScreen({super.key});

  Duration get loginTime => Duration(milliseconds: timeDilation.ceil() * 0);

  Future<String?> _loginUser(LoginData data) {
    return Future.delayed(loginTime).then((_) {
      if (!mockUsers.containsKey(data.name)) {
        return S.current.user_not_exist;
      }
      if (mockUsers[data.name] != data.password) {
        return 'Password does not match';
      }
      return null;
    });
  }

  Future<String?> _signupUser(SignupData data) {
    // lxjtodo 注册
    try {
      final dio = Dio();
      final loginService = LoginService(dio);
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
        0,
        "",
        0,
      );
      debugPrint(post.toString());
      return loginService.loginRegister(post).then((value) {
        debugPrint(value.toString());
        return 'no';
      });
    } catch (e) {
      return Future.delayed(loginTime).then((_) {
        return 'service err';
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
    return Future.delayed(loginTime).then((_) {
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: S.of(context).main_logo,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      logo: const AssetImage('assets/images/LOGO.png'),
      logoTag: Constants.logoTag,
      titleTag: Constants.titleTag,
      navigateBackAfterRecovery: true,
      onConfirmRecover: _signupConfirm,
      // onConfirmSignup: _signupConfirm,
      loginAfterSignUp: false,
      // loginProviders: [
      //   LoginProvider(
      //     button: Buttons.linkedIn,
      //     label: 'Sign in with LinkedIn',
      //     callback: () async {
      //       return null;
      //     },
      //     providerNeedsSignUpCallback: () {
      //       // put here your logic to conditionally show the additional fields
      //       return Future.value(true);
      //     },
      //   ),
      //   LoginProvider(
      //     icon: FontAwesomeIcons.google,
      //     label: 'Google',
      //     callback: () async {
      //       return null;
      //     },
      //   ),
      //   LoginProvider(
      //     icon: FontAwesomeIcons.githubAlt,
      //     callback: () async {
      //       debugPrint('start github sign in');
      //       await Future.delayed(loginTime);
      //       debugPrint('stop github sign in');
      //       return null;
      //     },
      //   ),
      // ],
      termsOfService: [
        // TermOfService(
        //   id: 'newsletter',
        //   mandatory: false,
        //   text: 'Newsletter subscription',
        // ),
        TermOfService(
          id: 'general-term',
          mandatory: true,
          text: S.of(context).term_of_services,
          linkUrl: 'https://www.baidu.com',
          validationErrorMessage: S.of(context).service_required,
        ),
      ],
      additionalSignupFields: [
        UserFormField(
          // username
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
          // username
          keyName: 'sex',
          displayName: S.of(context).sex,
          icon: const Icon(FontAwesomeIcons.userLarge),
          fieldValidator: (value) {
            if (value!.isEmpty ||
                value == S.of(context).male ||
                value == S.of(context).female) {
              return null;
            }
            return S.of(context).sex_valid;
          },
        ),
        UserFormField(
          // username
          keyName: 'email',
          displayName: S.of(context).login_email,
          userType: LoginUserType.email,
          icon: const Icon(Icons.email),
          fieldValidator: (value) {
            if (!value!.contains('@') || !value.endsWith('.com')) {
              return S.of(context).email_auth;
            }
            return null;
          },
        ),
        UserFormField(
          // phone
          keyName: 'phone_number',
          displayName: S.of(context).phone_number,
          userType: LoginUserType.phone,
          fieldValidator: (value) {
            final phoneRegExp = RegExp(
              '^(\\+\\d{1,2}\\s)?\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4}\$',
            );
            if (value != null &&
                value.length < 7 &&
                !phoneRegExp.hasMatch(value)) {
              return S.of(context).valid_phone_number;
            }
            return null;
          },
        ),
      ],
      // scrollable: true,
      // hideProvidersTitle: false,
      // loginAfterSignUp: false,
      // hideForgotPasswordButton: true,
      // hideSignUpButton: true,
      // disableCustomPageTransformer: true,
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
      theme: LoginTheme(
        primaryColor: Colors.teal,
        accentColor: Theme.of(context).colorScheme.secondary,
        errorColor: Colors.deepOrange,
        pageColorLight: Colors.indigo.shade300,
        pageColorDark: Colors.indigo.shade500,
        logoWidth: 0.80,
        titleStyle: TextStyle(
          color: Colors.greenAccent,
          fontFamily: 'Quicksand',
          letterSpacing: 4,
        ),
      ),
      //   // beforeHeroFontSize: 50,
      //   // afterHeroFontSize: 20,
      //   bodyStyle: TextStyle(
      //     fontStyle: FontStyle.italic,
      //     decoration: TextDecoration.underline,
      //   ),
      //   textFieldStyle: TextStyle(
      //     color: Colors.orange,
      //     shadows: [Shadow(color: Colors.yellow, blurRadius: 2)],
      //   ),
      //   buttonStyle: TextStyle(
      //     fontWeight: FontWeight.w800,
      //     color: Colors.yellow,
      //   ),
      //   cardTheme: CardTheme(
      //     color: Colors.yellow.shade100,
      //     elevation: 5,
      //     margin: EdgeInsets.only(top: 15),
      //     shape: ContinuousRectangleBorder(
      //         borderRadius: BorderRadius.circular(100.0)),
      //   ),
      //   inputTheme: InputDecorationTheme(
      //     filled: true,
      //     fillColor: Colors.purple.withOpacity(.1),
      //     contentPadding: EdgeInsets.zero,
      //     errorStyle: TextStyle(
      //       backgroundColor: Colors.orange,
      //       color: Colors.white,
      //     ),
      //     labelStyle: TextStyle(fontSize: 12),
      //     enabledBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.blue.shade700, width: 4),
      //       borderRadius: inputBorder,
      //     ),
      //     focusedBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.blue.shade400, width: 5),
      //       borderRadius: inputBorder,
      //     ),
      //     errorBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.red.shade700, width: 7),
      //       borderRadius: inputBorder,
      //     ),
      //     focusedErrorBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.red.shade400, width: 8),
      //       borderRadius: inputBorder,
      //     ),
      //     disabledBorder: UnderlineInputBorder(
      //       borderSide: BorderSide(color: Colors.grey, width: 5),
      //       borderRadius: inputBorder,
      //     ),
      //   ),
      //   buttonTheme: LoginButtonTheme(
      //     splashColor: Colors.purple,
      //     backgroundColor: Colors.pinkAccent,
      //     highlightColor: Colors.lightGreen,
      //     elevation: 9.0,
      //     highlightElevation: 6.0,
      //     shape: BeveledRectangleBorder(
      //       borderRadius: BorderRadius.circular(10),
      //     ),
      //     // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      //     // shape: CircleBorder(side: BorderSide(color: Colors.green)),
      //     // shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(55.0)),
      //   ),
      // ),
      userValidator: (value) {
        // if (!value!.contains('@') || !value.endsWith('.com')) {
        //   return S.of(context).email_auth;
        // }
        if (value!.isEmpty) {
          return S.of(context).user_auth_vaild;
        }
        return null;
      },
      passwordValidator: (value) {
        if (value!.isEmpty) {
          return S.of(context).password_is_empty;
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
