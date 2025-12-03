import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';
import 'package:flutter/cupertino.dart';
import '../main.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = user?.email ?? '이메일 정보 없음';
    _nicknameController.text = user?.displayName ?? '사용자';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }
  String _encodeEmail(String email) {
    return Uri.encodeComponent(email).replaceAll('.', ',');
  }
  // 1. 이메일 변경
  void _changeEmail() async {
    final newEmail = _emailController.text.trim();
    if (user == null || newEmail.isEmpty) return;

    try {
      await user!.updateEmail(newEmail);
      _showSnackBar('✅ 이메일이 성공적으로 변경되었습니다. (재로그인 필요)');
    } on FirebaseAuthException catch (e) {
      _showSnackBar('❌ 이메일 변경 실패: ${e.message}');
    }
  }
  //2. 비밀번호 변경
  void _changePassword() async {
    final newPassword = _passwordController.text.trim();
    if (user == null || newPassword.length < 6) {
      _showSnackBar('비밀번호는 최소 6자 이상이어야 합니다.');
      return;
    }

    try {
      await user!.updatePassword(newPassword);
      _showSnackBar('✅ 비밀번호가 성공적으로 변경되었습니다.');
      _passwordController.clear();
    } on FirebaseAuthException catch (e) {
      _showSnackBar('❌ 비밀번호 변경 실패: ${e.message}. 최근 로그인 후 너무 시간이 지났다면 다시 로그인해야 합니다.');
    }
  }
  //3. 닉네임 변경
  void _changeNickname() async {
    final newNickname = _nicknameController.text.trim();
    if (user == null || newNickname.isEmpty) return;

    try {
      await user!.updateDisplayName(newNickname);
      _showSnackBar('✅ 닉네임이 성공적으로 변경되었습니다.');
    } on FirebaseAuthException catch (e) {
      _showSnackBar('❌ 닉네임 변경 실패: ${e.message}');
    }
  }
  //4. 회원 탈퇴 (계정 삭제 및 3일 차단 기록)

  void _deleteAccount() async {
    if (user == null || user!.email == null) return;

    final String userEmail = user!.email!;
    final String encodedEmail = _encodeEmail(userEmail);
    final DatabaseReference bannedEmailRef = FirebaseDatabase.instance.ref('bannedEmails/$encodedEmail');

    // 재가입 차단 만료 시간
    final int banDurationDays = 3;
    final int banUntilTimestamp = DateTime.now()
        .add(Duration(days: banDurationDays))
        .millisecondsSinceEpoch;

    try {
      // 1. Firebase Auth 계정 삭제
      await user!.delete();

      // 2. Realtime DB에 해당 이메일의 재가입 금지 정보 기록
      await bannedEmailRef.set({
        'email': userEmail,
        'bannedUntil': banUntilTimestamp,
        'deletedAt': ServerValue.timestamp,
      });

      // 3. 로그아웃 및 UI 전환
      await FirebaseAuth.instance.signOut();
      _showSnackBar('✅ 계정이 삭제되었으며, 해당 이메일은 ${banDurationDays}일간 재가입이 제한됩니다.');

      // 로그인 페이지로 강제 이동 (StreamBuilder 로직을 피하기 위해)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showSnackBar('탈퇴 실패: ${e.message}. 최근 로그인 후 너무 시간이 지났다면 다시 로그인해야 합니다.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('로그인이 필요합니다.'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      );
    }
    // [UI 구현] 계정 설정 화면 UI
    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 설정'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- 현재 사용자 정보 ---
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '현재 로그인: ${user!.email}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- 1. 닉네임 변경 ---
            const Text('닉네임 변경', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      hintText: '새 닉네임',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _changeNickname,
                  child: const Text('변경', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- 2. 이메일 변경 ---
            const Text('이메일 변경', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: '새 이메일 주소',
                      border: UnderlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                TextButton(
                  onPressed: _changeEmail,
                  child: const Text('변경', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- 3. 비밀번호 변경 ---
            const Text('비밀번호 변경', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: '새 비밀번호 (6자 이상)',
                      border: UnderlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ),
                TextButton(
                  onPressed: _changePassword,
                  child: const Text('변경', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 50),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('다크 모드 사용', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (bool newValue) {

                    final myAppState = context.findAncestorStateOfType<State<MyApp>>();
                    if (myAppState != null) {

                      (myAppState as dynamic).setThemeMode(newValue ? ThemeMode.dark : ThemeMode.light);
                    }
                  },
                  activeColor: Colors.deepPurple,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- 4. 회원 탈퇴 버튼 ---
            ElevatedButton(
              onPressed: _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('회원 탈퇴', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}