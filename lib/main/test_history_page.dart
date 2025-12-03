import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:personality_test_new/test_model.dart';
import '../test_model.dart';

class TestHistoryPage extends StatefulWidget {
  final TestResult result;
  const TestHistoryPage({super.key, required this.result});

  @override
  State<TestHistoryPage> createState() => _TestHistoryPageState();
}

class _TestHistoryPageState extends State<TestHistoryPage> {
  //광고 관련 변수
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final adUnitId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  //광고 로드 함수
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() { _isAdLoaded = true; });
        },
        onAdFailedToLoad: (ad, err) {
          _isAdLoaded = false;
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  //공유 기능 함수
  void _shareResult() async {
    String shareText =
        "[기록된 테스트 결과 공유]\n\n"
        "테스트: ${widget.result.title}\n"
        "결과: ${widget.result.result}\n"
        "날짜: ${widget.result.date}";

    await Share.share(shareText);
  }
  void shareResult(TestResult result) async {
    String shareText =
        "[나의 기록 공유]\n\n"
        "테스트: ${result.title}\n"
        "결과: ${result.result}\n"
        "날짜: ${result.date}";

    await Share.share(shareText);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공유 창이 열렸습니다. 공유가 완료되었습니다!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.result.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. 상세 결과 본문
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('테스트 결과 상세 기록', style: TextStyle(fontSize: 18, color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text('기록 날짜: ${widget.result.date}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Text(
                        widget.result.result,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2.광고 배너
          if (_isAdLoaded && _bannerAd != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0), // 공유 버튼과 분리
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),

          // 3. 공유하기 버튼 (맨 아래)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: ElevatedButton.icon(
              onPressed: _shareResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE500),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.share),
              label: const Text(
                '다른 사람에게 공유하기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}