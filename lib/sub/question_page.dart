import 'package:flutter/material.dart';
import '../detail/detail_page.dart';

class QuestionPage extends StatefulWidget {
  final Map<String, dynamic> questionData;
  const QuestionPage({super.key, required this.questionData});

  @override
  State<QuestionPage> createState() {
    return _QuestionPage();
  }
}

class _QuestionPage extends State<QuestionPage> {
  int selectNumber = -1;


  // 💡 1. 다단계 질문 관리를 위한 변수
  int currentQuestionIndex = 0; // 현재 진행 중인 질문의 인덱스
  List<dynamic> questionsList = []; // MBTI/심화 테스트의 질문 목록

  // 💡 2. 답변을 저장할 리스트들
  Map<String, int> mbtiResult = { // MBTI (E/I, S/N, T/F, J/P) 점수 저장
    'E': 0, 'I': 0, 'S': 0, 'N': 0, 'T': 0, 'F': 0, 'J': 0, 'P': 0
  };
  List<int> finalAnswers = []; // 4단계 심화 테스트의 답변 인덱스 저장 (0 또는 1)

  @override
  void initState() {
    super.initState();
    // 질문 목록 초기화
    if (widget.questionData.containsKey('questions')) {
      questionsList = widget.questionData['questions'] as List<dynamic>;
    }

    // 4단계 심화 테스트를 위해 답변 리스트를 질문 개수만큼 -1로 초기화
    finalAnswers = List.generate(questionsList.length, (index) => -1);
  }

  // 💡 3. 다음 질문으로 이동하거나 최종 결과를 표시하는 함수
  void goToNextQuestion() {
    if (selectNumber == -1) return; // 선택하지 않았다면 진행 중단

    // 현재 답변 인덱스를 finalAnswers 리스트에 저장 (심화 테스트 결과 조합용)
    finalAnswers[currentQuestionIndex] = selectNumber;

    if (widget.questionData['type'] == 'sequential') {
      // MBTI 점수 계산 (E/I, S/N, T/F, J/P)
      Map<String, dynamic> currentQuestion = questionsList[currentQuestionIndex];
      String dimensionId = currentQuestion['id'] as String;

      String firstType = dimensionId.substring(0, 1);
      String secondType = dimensionId.substring(2, 3);

      if (selectNumber == 0) {
        mbtiResult[firstType] = (mbtiResult[firstType] ?? 0) + 1;
      } else if (selectNumber == 1) {
        mbtiResult[secondType] = (mbtiResult[secondType] ?? 0) + 1;
      }
    }


    if (currentQuestionIndex < questionsList.length - 1) {
      // 다음 질문이 남았을 경우
      setState(() {
        currentQuestionIndex++; // 인덱스 증가
        selectNumber = -1; // 선택 초기화
      });
    } else {
      // 모든 질문이 끝났을 경우, 결과 페이지로 이동
      String finalResult;

      if (widget.questionData['type'] == 'sequential') {
        finalResult = calculateMbtiType(); // MBTI 최종 유형 로직
      } else if (widget.questionData['type'] == 'sequential_final') {
        // 💡 4단계 심화 테스트: 답변 인덱스(0-1-0-1)를 조합하여 결과 키 생성
        String resultKey = finalAnswers.map((e) => e.toString()).join('-');

        Map<String, dynamic> answersMap = widget.questionData['answers'] as Map<String, dynamic>;

        // 결과 찾기
        finalResult = answersMap[resultKey] ?? '결과를 찾을 수 없습니다. (조합: $resultKey)';
      } else {
        finalResult = '알 수 없는 테스트 유형입니다.';
      }

      // 결과 페이지로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            return DetailPage(
              answer: finalResult,
              question: widget.questionData['title'] ?? '테스트 결과',
            );
          },
        ),
      );
    }
  }

  // 💡 4. MBTI 최종 유형을 계산하는 함수
  String calculateMbtiType() {
    String mbti = '';

    mbti += (mbtiResult['E'] ?? 0) > (mbtiResult['I'] ?? 0) ? 'E' : 'I';
    mbti += (mbtiResult['S'] ?? 0) > (mbtiResult['N'] ?? 0) ? 'S' : 'N';
    mbti += (mbtiResult['T'] ?? 0) > (mbtiResult['F'] ?? 0) ? 'T' : 'F';
    mbti += (mbtiResult['J'] ?? 0) > (mbtiResult['P'] ?? 0) ? 'J' : 'P';

    return "당신의 MBTI 유형은 **$mbti** 입니다!";
  }


  @override
  Widget build(BuildContext context) {

    // 🚨 다단계 MBTI/심화 테스트 처리 로직
    if (widget.questionData['type'] == 'sequential' || widget.questionData['type'] == 'sequential_final') {

      if (questionsList.isEmpty) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      Map<String, dynamic> currentQuestion = questionsList[currentQuestionIndex];
      // 💡 selects가 List가 아닐 경우 빈 리스트로 안전하게 처리
      final List<dynamic> selects = (currentQuestion['selects'] is List)
          ? currentQuestion['selects'] as List<dynamic>
          : [];

      return Scaffold(
        appBar: AppBar(
          title: Text(currentQuestion['title']?.toString() ?? "테스트"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // 1. 질문 텍스트 표시
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                currentQuestion['question']?.toString() ?? '질문 없음', // 💡 null 체크 추가
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                textAlign: TextAlign.center,
              ),
            ),

            // 2. 선택지 목록
            Expanded(
              child: ListView.builder(
                itemCount: selects.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(
                          color: selectNumber == index ? Colors.deepPurple : Colors.grey.shade300,
                          width: selectNumber == index ? 2.0 : 1.0,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectNumber = index;
                          });
                        },
                        // 💡 [수정] Padding 위젯의 필수 인수를 복구하여 문법 오류 해결
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Row(
                            children: [
                              Radio(
                                value: index,
                                groupValue: selectNumber,
                                onChanged: (value) {
                                  setState(() {
                                    selectNumber = index;
                                  });
                                },
                              ),
                              Expanded(
                                child: Text(
                                  selects[index].toString(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. 다음 질문/결과 보기 버튼
            selectNumber == -1
                ? Container()
                : Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                onPressed: goToNextQuestion, // 💡 다음 질문 이동/결과 처리 함수
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30)
                ),
                child: Text(
                  currentQuestionIndex < questionsList.length - 1 ? '다음 질문' : '결과 보기',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      );

    } else {
      // 🚨 단일 질문 처리 로직 (기존 레거시 테스트 처리)

      final Map<String, dynamic> questions = widget.questionData;
      final String title = questions['title']?.toString() ?? '테스트';

      // selects가 List가 아닐 경우 빈 리스트로 안전하게 처리
      final List<dynamic> selects = (questions['selects'] is List)
          ? questions['selects'] as List<dynamic>
          : [];

      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            // 질문 텍스트
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                questions['question']?.toString() ?? '질문 없음', // 💡 null 체크 추가
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                textAlign: TextAlign.center,
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: selects.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(
                          color: selectNumber == index ? Colors.deepPurple : Colors.grey.shade300,
                          width: selectNumber == index ? 2.0 : 1.0,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectNumber = index;
                          });
                        },
                        child: Padding( // Padding 위젯 복구
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Row(
                            children: [
                              Radio(
                                value: index,
                                groupValue: selectNumber,
                                onChanged: (value) {
                                  setState(() {
                                    selectNumber = index;
                                  });
                                },
                              ),
                              Expanded(
                                child: Text(
                                  selects[index].toString(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            selectNumber == -1
                ? Container()
                : Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  // 결과 페이지 이동 로직 (안전하게 answer 접근)
                  final List<dynamic> answers = questions['answer'] is List
                      ? questions['answer'] as List<dynamic>
                      : [];

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) {
                        return DetailPage(
                          answer: answers.isNotEmpty && selectNumber < answers.length
                              ? answers[selectNumber].toString()
                              : '결과를 찾을 수 없습니다.',
                          question: questions['question']?.toString() ?? '테스트 질문',
                        );
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30)
                ),
                child: const Text('결과 보기', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      );
    }
  }
}