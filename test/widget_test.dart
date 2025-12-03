import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personality_test_new/main.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mockito/mockito.dart'; // Mockito 패키지가 pubspec.yaml에 있는지 확인하세요.

// Mock FirebaseRemoteConfig 클래스는 유지 (MyApp 호출에 필요)
class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {
  @override
  bool getBool(String key) => false;
  @override
  String getString(String key) => 'Test App Title';
  @override
  int getInt(String key) => 70;
}

void main() {
  testWidgets('App starts on LoginPage if not authenticated', (WidgetTester tester) async {

    // Mock 인스턴스 생성 및 전달 (MyApp의 필수 매개변수 충족)
    final mockRemoteConfig = MockFirebaseRemoteConfig();
    await tester.pumpWidget(MyApp(remoteConfig: mockRemoteConfig));

    // 💡 [핵심 테스트] 앱이 '로그인' 제목을 가진 화면으로 시작하는지 확인
    // LoginPage의 AppBar title이 '로그인'인지 확인합니다.
    expect(find.text('로그인'), findsOneWidget);

    // '회원가입' 버튼이 보이는지 확인 (LoginPage 요소)
    expect(find.text('회원가입'), findsOneWidget);
  });
}