import 'package:firebase_database/firebase_database.dart';
import '../test_model.dart';
import 'main/mainlist_page.dart';

// 1. Firebase에서 목록 데이터를 읽기 위한 모델
class TestModel {
  final String key;
  final String title;
  final String description;
  final String type;
  final List<dynamic> questions;
  final String answerResult;

  TestModel.fromSnapshot(DataSnapshot snapshot)
      : assert(snapshot.value != null),
        key = snapshot.key!,
        title = (snapshot.value as Map)['title'] ?? '제목 없음',
        description = (snapshot.value as Map)['description'] ?? '소개 멘트가 없습니다.',
        type = (snapshot.value as Map)['type'] ?? 'sequential',
        questions = (snapshot.value as Map)['questions'] is List
            ? (snapshot.value as Map)['questions'] as List<dynamic>
            : [],
        answerResult = (snapshot.value as Map)['answerResult'] ??
            (snapshot.value as Map)['answer_result'] ?? '';
}

// 2. 최근 테스트 결과를 저장하기 위한 모델
class TestResult {
  final String title;
  final String result;
  final String date;

  TestResult({required this.title, required this.result, required this.date});
}