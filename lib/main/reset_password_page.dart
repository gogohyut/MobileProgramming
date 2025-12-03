import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('이메일 주소를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase 비밀번호 재설정 이메일 전송 요청
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // 성공 메시지 후 로그인 화면으로 돌아가기
      _showSnackBar('비밀번호 재설정 링크가 이메일로 전송되었습니다. 이메일함을 확인해주세요.');

      if (mounted) {
        // 현재 화면을 닫고 이전 화면(로그인 화면)으로 돌아감
        Navigator.of(context).pop();
      }

    } on FirebaseAuthException catch (e) {
      String message = '비밀번호 재설정 요청에 실패했습니다.';
      if (e.code == 'invalid-email') {
        message = '유효하지 않은 이메일 주소입니다.';
      } else {
        message = '오류가 발생했습니다: ${e.message}';
      }
      _showSnackBar(message);

    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 찾기'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              '비밀번호를 재설정할 이메일 주소를 입력해주세요.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // 이메일 입력 필드
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '이메일 주소',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 30),

            // 전송 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _sendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('비밀번호 재설정 링크 전송'),
            ),
          ],
        ),
      ),
    );
  }
}