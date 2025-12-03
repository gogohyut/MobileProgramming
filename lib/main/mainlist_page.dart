import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../sub/question_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:personality_test_new/test_model.dart';
import 'my_history_page.dart';
import 'account_settings_page.dart';
import '../test_model.dart';



class MainPage extends StatefulWidget {
  final FirebaseRemoteConfig remoteConfig;
  final String nickname;
  final String email;

  const MainPage({
    super.key,
    required this.remoteConfig,
    required this.nickname,
    required this.email
  });

  @override
  State<MainPage> createState() {
    return _MainPage();
  }
}

class _MainPage extends State<MainPage> {
  // Firebase Remote Config 및 Database 인스턴스
  final FirebaseDatabase database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: "https://firstapp-368d1-default-rtdb.firebaseio.com"

  );
  late DatabaseReference _testRef;
  late DatabaseReference _userRef;

  // Remote Config 값 및 기타 변수
  String welcomeTitle = '';
  bool bannerUse = false;
  Future<List<String>>? _dataFuture;
  List<String> testList = List.empty(growable: true);
  List<TestResult> recentResults = [];
  User? currentUser;

  // 배너 광고 객체 및 로드 상태
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final adUnitId = 'ca-app-pub-7697043383568470/1126294694';

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _testRef = database.ref('test');
    _userRef = database.ref('users').child(currentUser?.uid ?? 'guest');

    welcomeTitle = widget.remoteConfig.getString('welcome');
    bannerUse = widget.remoteConfig.getBool('banner');

    _dataFuture = _ensureTestDataExists();

    //_dataFuture = loadAsset();
    //_loadRecentResults();
    _loadBannerAd();
  }

  // Advertising (광고) 로직
  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(adUnitId: adUnitId, request: const AdRequest(), size: AdSize.banner, listener: BannerAdListener(onAdLoaded: (_) {setState(() {_isAdLoaded = true;});}, onAdFailedToLoad: (ad, err) {print('Ad load failed (Code : ${err.code}): ${err.message}');_isAdLoaded = false;ad.dispose();},),);
    _bannerAd!.load();
  }

  // 데이터 자동 등록 함수
  Future<List<String>> _ensureTestDataExists() async {
    DatabaseReference _testRef = database.ref('test');
    final snapshot = await _testRef.get();
    if (snapshot.exists && snapshot.value is Map) {
        final data = await loadAsset();
        _loadRecentResults();
        return data;
      }

    await _testRef.remove();
    _testRef.push().set({
      //1. mbti
      "title": "MBTI 성격 유형 테스트",
      "type": "sequential",
      "questions": [
        {
          "id": "E/I",
          "question": "주말 저녁, 당신의 선택은?",
          "selects": ["새로운 사람들과 파티에서 신나게 논다", "집에서 좋아하는 영화를 보며 휴식한다"]
        },
        {
          "id": "S/N",
          "question": "친구에게 설명할 때 당신의 스타일은?",
          "selects": [
            "단계별로 구체적인 사실과 경험을 말한다",
            "전체적인 개념과 아이디어를 위주로 설명한다"
          ]
        },
        {
          "id": "T/F",
          "question": "친구가 고민을 털어놓을 때, 당신의 반응은?",
          "selects": [
            "문제의 핵심을 파악하고 해결책을 제시한다",
            "친구가 얼마나 힘든지 공감하며 위로해준다"
          ]
        },
        {
          "id": "J/P",
          "question": "여행 계획을 짤 때, 당신은?",
          "selects": [
            "미리 일정표를 만들고 숙소와 동선을 확정한다",
            "일단 떠나서 그때그때 재미있는 곳을 찾아간다"
          ]
        }
      ],
      "answer_result": "이 테스트는 MBTI 유형을 합산하여 결과를 보여줍니다."
    }
    );
    // 2.  당신의 이상적인 연애 성향 심화(4단계 질문)
    _testRef.push().set({
      "title": "당신은 어떤 사랑을 하고 싶나요?",
      "type": "sequential_final",
      "questions": [
        {
          "id": "Q1",
          "question": "파트너와 휴가를 보낸다면 당신의 계획은?",
          "selects": ["계획적인 여행", "자유로운 휴식"]
        },
        {
          "id": "Q2",
          "question": "선물을 할 때 당신의 행동은?",
          "selects": ["완벽한 준비", "필요할 때 바로 제공"]
        },
        {
          "id": "Q3",
          "question": "연락 빈도에 대한 당신의 생각은?",
          "selects": ["하루 종일 연락 유지", "필요할 때만 연락"]
        },
        {
          "id": "Q4",
          "question": "갈등 발생 시 당신의 대처는?",
          "selects": ["즉시 대화로 해결", "혼자 생각할 시간 요청"]
        },
      ],
      "answers": {
        "0-0-0-0": "당신은'완벽주의자 애인': 모든 것을 계획하고 준비하며, 하루 종일 소통하며 즉시 갈등을 해결해야 만족합니다.",
        "0-0-0-1": "당신은'계획형 관찰자': 계획적인 연애를 선호하지만, 갈등 시에는 혼자 생각할 시간을 가져야만 정리됩니다.",
        "0-0-1-0": "당신은'신중한 독립가': 계획적이고 선물을 신중히 준비하지만, 연락은 필요한 순간에만 하고 갈등은 즉시 해결합니다.",
        "0-0-1-1": "당신은'차분한 완벽주의자': 신중한 계획을 세우지만, 갈등이 생기면 연락을 줄이고 혼자 해결하는 방식을 선호합니다.",
        "1-0-0-0": "당신은'즉흥적인 로맨티스트': 자유로운 데이트를 선호하며, 감정적으로 깊이 연결되어 갈등을 즉시 해소합니다.",
        "1-0-0-1": "당신은'감정적 회피형': 감정에 솔직하고 연락 빈도는 높지만, 갈등 시에는 혼자만의 공간으로 잠시 숨는 타입입니다.",
        "1-0-1-0": "당신은'자유로운 사교가': 즉흥적인 것을 즐기며, 연락은 꼭 필요할 때만 하고 갈등은 직접 맞서 해결합니다.",
        "1-0-1-1": "당신은'느긋한 독립 선언형': 자유롭고 느슨한 관계를 선호하며, 갈등 시에도 파트너에게 생각할 시간을 주는 타입입니다.",
        "0-1-0-0": "당신은'헌신적인 돌보미': 계획적인 연애를 추구하며, 상대가 원할 때 바로 선물을 주고 갈등을 즉시 해소하는 헌신적인 타입입니다.",
        "0-1-0-1": "당신은'감정적 안정 추구형': 계획적이고 즉각적인 감정 표현을 원하지만, 갈등 시에는 혼자만의 안정된 시간을 가져야 합니다.",
        "0-1-1-0": "당신은'독립적인 협상가': 계획을 중시하고 연락은 적지만, 갈등 해결에 있어서는 대화를 통해 즉시 종결짓는 것을 선호합니다.",
        "0-1-1-1": "당신은'개인 공간 존중형': 연애 중에도 개인 시간을 중시하며, 갈등 시 대화 대신 서로의 공간을 존중하는 타입입니다.",
        "1-1-0-0": "당신은'열정적인 리더': 연애를 주도하며 즉흥적인 데이트를 즐기고, 문제 발생 시 즉시 해결하여 관계를 이끌어갑니다.",
        "1-1-0-1": "당신은'쿨한 감정형': 즉흥적인 관계를 좋아하며, 갈등 상황에서는 잠시 떨어져 감정을 정리할 시간을 요구합니다.",
        "1-1-1-0": "당신은'현실적인 모험가': 연락은 최소화하고 자유를 추구하며, 갈등은 대화로 빠르게 종결짓는 현실적인 타입입니다.",
        "1-1-1-1": "당신은'궁극의 자유주의자': 연애에서 가장 중요한 것은 개인의 자유이며, 모든 갈등과 연락은 필요할 때만 최소한으로 하는 독립적인 성향입니다.",
      }
    }
    );
    // 3.  당신의 숨겨진 애완동물 성향 심화(4단계 질문)
    _testRef.push().set({
      "title": "내면의 숨겨진 동물 성향 찾기 테스트",
      "type": "sequential_final",
      "questions": [
        {
          "id": "Q1",
          "question": "새로운 환경에 놓였을 때 당신은?",
          "selects": ["바로 적응하고 돌아다닌다", "숨어서 상황을 관찰한다"]
        },
        {
          "id": "Q2",
          "question": "친한 친구가 당신을 부를 때 당신의 반응은?",
          "selects": ["바로 달려간다", "일단 쳐다보고 반응한다"]
        },
        {
          "id": "Q3",
          "question": "관심을 받고 싶을 때 당신의 행동은?",
          "selects": ["애교를 부린다", "침묵하며 기다린다"]
        },
        {
          "id": "Q4",
          "question": "가장 편안함을 느끼는 장소는?",
          "selects": ["집 안의 특정 구석", "햇볕이 잘 드는 넓은 공간"]
        },
      ],
      "answers": {
        "0-0-0-0": "사교적인 강아지: 매우 활발하고, 즉시 반응하며, 애교가 넘치는 친화력 만렙의 강아지형입니다.",
        "0-0-0-1": "에너지 넘치는 강아지: 활동적이며, 즉시 반응하지만, 자유로운 공간을 선호하는 에너자이저 강아지형입니다.",
        "0-0-1-0": "온순한 강아지: 활발하지만, 관심 표현은 꾹 참고 기다리는 인내심 있는 강아지형입니다.",
        "0-0-1-1": "자유로운 강아지: 활동적이고 빠르며, 넓은 공간을 선호하는 독립적인 강아지형입니다.",
        "0-1-0-0": "호기심 많은 햄스터: 즉시 달려가진 않지만, 돌아다니며 애교를 부리는 호기심 많은 작은 설치류형입니다.",
        "0-1-0-1": "대담한 앵무새: 활동적이고 넓은 공간을 좋아하며, 즉각적인 관심 대신 지켜보는 것을 즐기는 새형입니다.",
        "0-1-1-0": "침묵의 고양이: 행동은 빠르지만, 관심이 필요할 때는 조용히 기다리며 특정 구석을 선호하는 고양이형입니다.",
        "0-1-1-1": "독립적인 고양이: 활동적이고 개방적이지만, 혼자만의 시간을 가지는 것을 선호하는 독립심 강한 고양이형입니다.",
        "1-0-0-0": "소심한 강아지: 새로운 환경에서는 관찰하지만, 익숙한 사람에게는 즉시 반응하고 애교를 부리는 소심한 강아지형입니다.",
        "1-0-0-1": "경계심 강한 새: 관찰 후 넓은 공간을 선호하며, 즉시 반응하는 경계심 강한 새형입니다.",
        "1-0-1-0": "조용한 토끼: 관찰력이 뛰어나고, 관심이 필요할 때 침묵하며, 조용한 구석을 선호하는 토끼형입니다.",
        "1-0-1-1": "예민한 토끼: 조용히 관찰하며, 넓고 밝은 곳에서 휴식하는 것을 좋아하는 예민한 토끼형입니다.",
        "1-1-0-0": "경계하는 고양이: 상황을 관찰하고 느리게 움직이며, 애교를 부리지만 곧 자기만의 공간으로 숨는 고양이형입니다.",
        "1-1-0-1": "느긋한 고양이: 모든 것을 지켜본 후 천천히 행동하며, 햇볕이 잘 드는 곳에서 느긋하게 쉬는 것을 좋아하는 고양이형입니다.",
        "1-1-1-0": "은둔자 고양이: 모든 것에 경계심을 갖고, 침묵하며, 오로지 집 안의 특정 구석에서만 편안함을 느끼는 은둔자형 고양이입니다.",
        "1-1-1-1": "완벽주의자 새: 모든 것을 관찰하고, 천천히 움직이며, 개방된 공간에서 완벽한 휴식을 취하는 완벽주의자형입니다.",
      }
    }
    );
    // 4. 당신의 스트레스 관리 스타일 분석(4단계 질문)
    _testRef.push().set({
      "title": "당신의 스트레스 관리 스타일 분석 테스트",
      "type": "sequential_final",
      "questions": [
        {
          "id": "Q1",
          "question": "스트레스 받을 때 당신은 주로?",
          "selects": ["잠을 잔다", "무언가 먹는다"]
        },
        {
          "id": "Q2",
          "question": "해소 활동 후 당신은?",
          "selects": ["바로 일상으로 복귀", "며칠 더 쉬어야 함"]
        },
        {
          "id": "Q3",
          "question": "스트레스 요인을 주변에 공유하는가?",
          "selects": ["적극적으로 공유", "혼자 해결하려고 노력"]
        },
        {
          "id": "Q4",
          "question": "스트레스 해소에 가장 중요한 것은?",
          "selects": ["새로운 자극(여행, 취미)", "안정된 루틴(운동, 명상)"]
        },
      ],
      "answers": {
        "0-0-0-0": "수면 후 즉시 복귀하는'능동적 회피형'입니다. 스트레스 해결에 리더십이 강합니다.",
        "0-0-0-1": "수면 후 안정된 루틴을 찾는'조직적 휴식형'입니다. 계획적인 휴식이 필수입니다.",
        "0-0-1-0": "잠으로 회피 후 공유하는'의존적 수면형'입니다. 문제를 남에게 털어놓아야 해소됩니다.",
        "0-0-1-1": "수면 후 혼자 루틴을 유지하는'자발적 은둔형'입니다. 조용히 혼자 해결하려 합니다.",
        "0-1-0-0": "잠을 잔 후에도 충분히 쉬어야 하는'회피형 회복자'입니다. 회복에 시간이 걸립니다.",
        "0-1-0-1": "오래 쉬면서도 안정된 루틴을 찾는'정착형 휴식가'입니다. 변화를 싫어합니다.",
        "0-1-1-0": "잠과 공유를 통해 스트레스를 푸는'공유형 수면가'입니다. 잠이든 대화든 풀고 봐야 합니다.",
        "0-1-1-1": "느긋하게 쉬면서 혼자만의 안정된 루틴을 지키는'완전 충전형'입니다. 간섭받기 싫어합니다.",
        "1-0-0-0": "먹고 바로 활동하는'쾌락형 활동가'입니다. 스트레스를 먹는 것으로 대체하려는 경향이 강합니다.",
        "1-0-0-1": "먹고 나서 안정된 일상으로 돌아가는'균형 잡힌 복귀형'입니다. 일상으로의 복귀가 빠릅니다.",
        "1-0-1-0": "먹고 공유하는'음식 공유형'입니다. 스트레스를 주변 사람들과 함께 해소합니다.",
        "1-0-1-1": "먹고 혼자 해결하는'단독 해결형'입니다. 자기만의 방식으로 빠르게 해소합니다.",
        "1-1-0-0": "먹은 후 충분히 쉬는'긴급 충전형'입니다. 먹는 행위와 휴식이 동시에 필요합니다.",
        "1-1-0-1": "오래 쉬면서도 안정된 루틴을 고집하는'고집 센 회복형'입니다. 변화를 싫어합니다.",
        "1-1-1-0": "먹고 오래 쉬며 공유하는'전천후 위로형'입니다. 모든 자원을 동원해 스트레스를 해소합니다.",
        "1-1-1-1": "먹고 충분히 쉬면서 새로운 자극을 찾는'변화 추구형'입니다. 해소 후 여행을 즐깁니다.",
      },
      "answer_result": "당신의 스트레스 관리 스타일 분석 결과입니다.",
    }
    );
    // 5. 당신의 소비 패턴 분석(4단계 질문)
    _testRef.push().set({
      "title": "당신의 숨겨진 소비 패턴 테스트",
      "type": "sequential_final",
      "questions": [
        {
          "id": "Q1",
          "question": "지출을 결정할 때 가장 중요하게 생각하는 것은?",
          "selects": ["가격 대비 성능(가성비)", "브랜드 및 디자인(가심비)"]
        },
        {
          "id": "Q2",
          "question": "할인 정보를 발견했을 때 당신의 행동은?",
          "selects": ["필요하지 않아도 일단 구매한다", "필요할 때만 구매한다"]
        },
        {
          "id": "Q3",
          "question": "미래의 나를 위한 소비는?",
          "selects": ["적극적으로 투자한다(자기 계발)", "현재의 만족에 집중한다(취미 생활)"]
        },
        {
          "id": "Q4",
          "question": "계획에 없던 지출이 생겼을 때 당신의 기분은?",
          "selects": ["죄책감을 느낀다", "어쩔 수 없다고 생각하고 넘어간다"]
        },
      ],
      "answers": {
        "0-0-0-0": "당신은'계획형 절약가': 가성비를 추구하며 충동구매 후에는 큰 죄책감을 느끼는FM 절약파입니다.",
        "0-0-0-1": "당신은'합리적 회피자': 가성비가 좋으면 충동구매도 하지만, 지출 후 쉽게 잊고 넘어갑니다.",
        "0-0-1-0": "당신은'효율적 현재파': 가성비 위주로 소비하며 현재 만족을 위해 돈을 쓰고, 죄책감을 느낍니다.",
        "0-0-1-1": "당신은'유동적 소비가': 가성비가 좋으면 충동적으로 구매하고, 현재 만족에 집중하며 지출 후 미련이 없습니다.",
        "0-1-0-0": "당신은'미래 지향적 투자자': 필요할 때만 사며, 미래 투자에 집중하고 지출 시 신중합니다.",
        "0-1-0-1": "당신은'현실주의자': 필요할 때만 소비하며 미래 계획에 투자하지만, 지출에 대한 스트레스가 적습니다.",
        "0-1-1-0": "당신은'꼼꼼한 실용주의자': 필요할 때만 가성비를 따져 소비하고, 현재 만족이 주를 이루며 죄책감을 느낍니다.",
        "0-1-1-1": "당신은'자유로운 실속파': 필요할 때만 소비하며, 현재 만족에 집중하고 지출에 쿨하게 넘어갑니다.",
        "1-0-0-0": "당신은'브랜드 집착형': 가심비를 위해 충동구매를 하며, 미래 투자에 집중하나 충동 지출에 죄책감을 느낍니다.",
        "1-0-0-1": "당신은'지름신 영접형': 가심비가 좋으면 일단 사고 보는 충동파입니다. 지출 후 스트레스는 적습니다.",
        "1-0-1-0": "당신은'나를 위한 탕진형': 가심비를 추구하며 현재 만족을 위해 아낌없이 지출하고 죄책감을 느낍니다.",
        "1-0-1-1": "당신은'오늘이 마지막형': 감성적 소비 후 현재 만족에 집중하며, 지출에 대한 죄책감 없이 사는YOLO형입니다.",
        "1-1-0-0": "당신은'계획적 컬렉터': 꼭 필요할 때만 가심비를 따져 구매하며, 미래 투자에 집중하고 지출을 후회합니다.",
        "1-1-0-1": "당신은'현명한 자기애형': 필요할 때 가심비를 추구하며 미래에 투자하지만, 지출에 얽매이지 않습니다.",
        "1-1-1-0": "당신은'가심비 밸런스형': 필요할 때 구매하며 현재 만족을 누리지만, 지출에 대해 되돌아보는 타입입니다.",
        "1-1-1-1": "당신은'완벽한 만족 추구자': 필요할 때 가심비를 충족시키며 현재를 즐기고, 지출 후 후회가 전혀 없습니다.",
      }
    }
    );
      final data = await loadAsset();
      _loadRecentResults();
      return data;
  }
  // Firebase Database에서 데이터 읽기
  Future<List<String>> loadAsset() async {
    try {
      final snapshot = await _testRef.get();
      testList.clear();
      for (var element in snapshot.children) {
        final value = element.value;
        if (value != null) {
          testList.add(jsonEncode(value));
        }
      }
      return testList;
    } catch (e) {
      print('Failed to load data: $e');
      return [];
    }
  }
  // 최근 테스트 결과 로드
  void _loadRecentResults() async {
    if (currentUser == null) return;
    try {
      final snapshot = await _userRef.child('results').get();
      if (snapshot.exists && snapshot.value is Map) {
        Map<dynamic, dynamic> resultsMap = snapshot.value as Map<dynamic, dynamic>;
        List<MapEntry<dynamic, dynamic>> sortedEntries = resultsMap.entries.toList();

        // 시간순 정렬 (최신 결과가 위로 오도록)
        sortedEntries.sort((a, b) => (b.value['timestamp'] as int).compareTo(a.value['timestamp'] as int));

        recentResults.clear();
        int count = 0;

        for (var entry in sortedEntries) {
          if (count >= 3) break;
          final resultData = entry.value as Map<dynamic, dynamic>;
          final timestamp = resultData['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

          final dateString = DateFormat('yy/MM/dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(timestamp));

          recentResults.add(
            // TestResult 생성자 호출 시 오류가 나지 않도록 파라미터 확인
            TestResult(
              title: resultData['testTitle'] ?? '알 수 없는 테스트',
              result: resultData['result'] ?? '결과 없음',
              date: dateString,
            ),
          );
          count++;
        }
        setState(() {});
      }
    } catch (e) {
      print('Failed to load recent results: $e');
    }
  }
  // 목록 타일을 빌드하는 함수
  Widget buildTestTile(Map<String, dynamic> item) {
    final String title = item['title'].toString();
    IconData iconData;
    Color iconColor;

    if (title.contains('MBTI')) {
      iconData = Icons.psychology_alt; // 심리학/MBTI (기존 유지)
      iconColor = Colors.deepPurple.shade400;
    }
    //동물 성향 테스트
    else if (title.contains('동물') || title.contains('숨겨진 애완동물')) {
      iconData = Icons.pets;
      iconColor = Colors.brown.shade400;
    }
    // 스트레스 관리 테스트
    else if (title.contains('스트레스')) {
      iconData = Icons.psychology;
      iconColor = Colors.red.shade400;
    }
    // 소비 패턴 테스트
    else if (title.contains('소비 패턴')) {
      iconData = Icons.attach_money;
      iconColor = Colors.green.shade600;
    }
    // 연애 성향 테스트
    else if (title.contains('사랑') || title.contains('연애')) {
      iconData = Icons.favorite;
      iconColor = Colors.pink;
    }
    else {
      iconData = Icons.assignment;
      iconColor = Colors.blueGrey;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),

      child: InkWell(
        onTap: () async {
          try {
            await FirebaseAnalytics.instance.logEvent(
              name: 'test_click',
              parameters: {'test_name': title},
            );
            final bool? shouldRefresh = await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => QuestionPage(questionData: item),
            ));

            if (shouldRefresh == true) {
              setState(() {
                _loadRecentResults();
              });
            }
          } catch (e) {
            print('Analtyics log failed: $e');
          }
        },
        child: ListTile(
          leading: Icon(iconData, color: iconColor, size: 30),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(
              Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 8.0, horizontal: 16.0),
        ),
      ),
    );
  }


  // 슬라이딩 메뉴 (Drawer) 구현 위젯
  Widget _buildDrawer() {
    double drawerWidth = MediaQuery.of(context).size.width * 0.7;

    return Drawer(
      width: drawerWidth,
      child: Column(
        children: <Widget>[
          // 1. 계정 정보 영역
          Container(
            padding: const EdgeInsets.only(top: 40, left: 20, right: 10, bottom: 20),
            color: Colors.deepPurple,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 닉네임
                  Text(
                    widget.nickname,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // 이메일
                  Text(
                    widget.email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 2. 앱/계정 설정 박스
          ListTile(
            title: const Text('앱 및 계정 설정', style: TextStyle(fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.settings, color: Colors.deepPurple),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AccountSettingsPage()),
              );
            },
          ),
          const Divider(height: 0),

          // 3. 전체 기록 보기 박스
          ListTile(
            title: const Text('결과 기록한 테스트 내역', style: TextStyle(fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.history, color: Colors.blueGrey),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MyHistoryPage()),
              );
            },
          ),
          const Divider(height: 0),

          const Spacer(),
          // 5. 로그아웃 버튼 영역 (기존 유지)
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('로그아웃', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text(widget.remoteConfig
            .getString('welcome')
            .isEmpty
            ? '심리 테스트 목록'
            : widget.remoteConfig.getString('welcome')),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          // 1. 목록
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final List<String> items = snapshot.data!;
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> item = jsonDecode(items[index]);
                      return buildTestTile(item);
                    },
                  );
                } else {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('No Data', style: TextStyle(fontSize: 24,
                            color: Colors.grey)),
                        Text(
                            '오른쪽 아래 + 버튼을 눌러 테스트 목록을 추가해주세요.', style: TextStyle(
                            color: Colors.grey)),
                      ],
                    ),
                  );
                }
              },
            ),
          ),

          // 2. 광고 배너 표시
          if (_isAdLoaded && _bannerAd != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Colors.grey, width: 0.5)),
                ),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}