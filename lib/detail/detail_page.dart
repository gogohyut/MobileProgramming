import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';

class DetailPage extends StatefulWidget {
  final String answer;
  final String question;

  const DetailPage({super.key, required this.answer, required this.question});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isSaving = false;
  bool _isSaved = false;


  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  void _shareResult() async {
    String shareText =
        "[심리 테스트 결과 공유]\n\n"
        "테스트: ${widget.question}\n"
        "내 결과: ${widget.answer}\n\n"
        "나의 심리 테스트 결과를 확인해보세요!";
    await Share.share(shareText);
    _showSnackBar('✅ 공유가 완료되었어요');
  }

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  // 💡 배너 광고 로드 함수
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7697043383568470/1126294694',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  void _saveResult() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('로그인 후 결과를 저장할 수 있어요.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final DatabaseReference userHistoryRef = FirebaseDatabase.instance.ref('users/${user.uid}/results');

      await userHistoryRef.push().set({
        'testTitle': widget.question,
        'result': widget.answer,
        'timestamp': ServerValue.timestamp,
      });

      setState(() {
        _isSaved = true;
      });
      _showSnackBar('✅ 결과가 성공적으로 저장되었어요!');

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      _showSnackBar('❌ 결과 저장에 실패했어요: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
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
        title: const Text('테스트 결과'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. 질문 재확인 및 결과 제목
              Text(
                '질문: ${widget.question}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              const Text(
                '당신의 심리 테스트 결과는?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 30),

              // 2. 최종 결과 Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Text(
                    widget.answer,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // 3. 광고 배너 표시
              if (_isAdLoaded && _bannerAd != null)
                Container(
                  alignment: Alignment.center,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              const SizedBox(height: 10),

              // 4. 결과 저장 버튼
              ElevatedButton(
                onPressed: _isSaved || _isSaving ? null : _saveResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaved ? Colors.green : Colors.deepPurpleAccent.shade100,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isSaved ? '✅ 결과 저장을 완료했어요' : '내 결과 기록하기', style: const TextStyle(fontSize: 18)),
              ),

              ElevatedButton.icon(
                onPressed: _shareResult, // 기존 공유 함수 재사용
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500), // 카카오톡 공식 노란색
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                // 카카오톡 아이콘 대신 일반 공유 아이콘 사용 (카카오톡 아이콘은 외부 라이브러리 필요)
                icon: const Icon(Icons.chat_bubble),
                label: const Text(
                  '다른 사람에게 공유하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 10),

              // 5. 돌아가기 버튼
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('돌아가기', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}