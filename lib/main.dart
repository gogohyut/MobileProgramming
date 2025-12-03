import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personality_test_new/firebase_options.dart';
import 'main/mainlist_page.dart';
import 'main/login_page.dart';
import 'main/account_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MobileAds.instance.initialize();
  final remoteConfig = FirebaseRemoteConfig.instance;
  try {
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await remoteConfig.fetchAndActivate();
  } catch (exception) {
    print('Failed to fetch remote config: $exception');
  }
  runApp(MyApp(remoteConfig: remoteConfig));
}
//MyApp 및 _MyAppState 클래스 재정립
// 1. MyApp: StatefulWidget으로 변경
class MyApp extends StatefulWidget {
  final FirebaseRemoteConfig remoteConfig;
  const MyApp({super.key, required this.remoteConfig});

  @override
  State<MyApp> createState() => _MyAppState();
}
// 2. _MyAppState: State 관리
class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('themeMode');
    if (savedTheme != null) {
      setState(() {
        _themeMode = ThemeMode.values.firstWhere(
              (e) => e.toString() == 'ThemeMode.$savedTheme',
          orElse: () => ThemeMode.system,
        );
      });
    }
  }

  //account_settings_page.dart에서 호출하는 테마 변경 함수
  void setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PersonalityTest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasData) {
            final user = snapshot.data;

            return MainPage(
                remoteConfig: widget.remoteConfig,
                nickname: user?.displayName ?? '사용자',
                email: user?.email ?? '이메일 정보 없음',
            );
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}