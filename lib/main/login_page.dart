import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:personality_test_new/main/reset_password_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mainlist_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLogin = true;

  //자동 로그인 및 이메일 기억 상태 변수
  bool _rememberMe = false;
  static const String _rememberEmailKey = 'remember_email_key';

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  //로컬 저장소 로드/저장 함수
  void _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_rememberEmailKey);
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  void _saveRememberedEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      prefs.setString(_rememberEmailKey, email);
    } else {
      prefs.remove(_rememberEmailKey);
    }
  }

  //DB 키 생성을 위한 인코딩 함수
  String _encodeEmail(String email) {
    return Uri.encodeComponent(email).replaceAll('.', ',');
  }

  //차단 상태 확인 함수
  Future<bool> _checkBanStatus(String email) async {
    final DatabaseReference bannedEmailRef = FirebaseDatabase.instance.ref('bannedEmails');
    final String encodedEmail = _encodeEmail(email);
    final snapshot = await bannedEmailRef.child(encodedEmail).get();

    if (snapshot.exists) {
      final banData = snapshot.value as Map;
      final int banUntil = banData['bannedUntil'] as int? ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;

      if (banUntil > now) {
        final remainingDays = (Duration(milliseconds: banUntil - now).inHours / 24).ceil();
        _showSnackBar('❌ 이 이메일은 회원 탈퇴로 인해 ${remainingDays}일 후 재가입이 가능합니다.');
        return true;
      } else {
        await bannedEmailRef.child(encodedEmail).remove();
      }
    }
    return false;
  }


  void _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && nickname.isEmpty)) {
      _showSnackBar('모든 필수 정보를 입력해주세요.');
      return;
    }

    try {
      if (!_isLogin) {
        if (await _checkBanStatus(email)) {
          return;
        }
      }

      UserCredential? userCredential;

      if (_isLogin) {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null && nickname.isNotEmpty) {
          await userCredential.user!.updateDisplayName(nickname);
        }
      }

      if (userCredential != null) {
        _saveRememberedEmail(email);
      }

    } on FirebaseAuthException catch (e) {
      String message = '❌인증에 실패했습니다. (${e.code})';

      final bool isBanned = await _checkBanStatus(email);

      if (isBanned) {
        return;
      }

      if (_isLogin && e.code == 'user-not-found') {
        message = '❌ 해당 이메일로 가입된 계정이 없거나 탈퇴된 계정입니다.';
      } else if (e.code == 'wrong-password') {
        message = '❌ 비밀번호가 잘못되었습니다.';
      } else if (e.code == 'email-already-in-use') {
        message = '❌ 이미 사용 중인 이메일입니다.';
      }

      _showSnackBar(message);
    } catch (e) {
      _showSnackBar('❌ 오류가 발생했습니다: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        toolbarHeight: 120,
        flexibleSpace: SafeArea(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '심리 테스트 앱',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isLogin ? '로그인' : '회원가입',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 닉네임 입력 필드 (회원가입 시에만)
              if (!_isLogin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(labelText: '닉네임 (필수)'),
                  ),
                ),

              // 이메일 입력 필드
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  prefixIcon: const Icon(Icons.email, color: Colors.deepPurple),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),

              // 비밀번호 입력 필드
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
                ),
                  obscureText: true,
              ),

              //자동 로그인 및 이메일 기억 체크박스 UI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. 이메일 기억 체크박스
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _rememberMe = newValue!;
                          });
                        },
                      ),
                      const Text('이메일 기억 및 자동 로그인 유지'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 로그인/회원가입 버튼
              ElevatedButton(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_isLogin ? '로그인' : '회원가입'),
              ),
              const SizedBox(height: 20),

              // 상태 전환 버튼
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin ? '계정이 없으신가요? 회원가입' : '이미 계정이 있으신가요? 로그인',
                  style: const TextStyle(color: Colors.deepPurple),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
                  );
                },
                child: const Text(
                  '비밀번호를 잊으셨나요?',
                  style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}