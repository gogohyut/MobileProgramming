import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../test_model.dart';

class MyHistoryPage extends StatefulWidget {
  const MyHistoryPage({super.key});

  @override
  State<MyHistoryPage> createState() => _MyHistoryPageState();
}

class _MyHistoryPageState extends State<MyHistoryPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late DatabaseReference _userRef;
  List<TestResult> _allResults = [];
  bool _isLoading = true;

  void _deleteAllResults() async {
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 전체 삭제'),
        content: const Text('모든 테스트 기록을 영구적으로 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 🚨 [핵심] Firebase DB에서 해당 사용자 UID의 'results' 경로 전체를 삭제
        await _userRef.remove();

        // UI 업데이트
        setState(() {
          _allResults.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 기록이 삭제되었습니다.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 삭제에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _userRef = FirebaseDatabase.instance.ref('users').child(currentUser!.uid).child('results');
      _loadAllResults();
    } else {
      _isLoading = false;
    }
  }

  void _loadAllResults() async {
    try {
      final snapshot = await _userRef.get();
      if (snapshot.exists && snapshot.value is Map) {
        Map<dynamic, dynamic> resultsMap = snapshot.value as Map<dynamic, dynamic>;

        List<TestResult> loadedResults = [];

        resultsMap.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final timestamp = value['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
            final dateString = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(timestamp));

            loadedResults.add(
              TestResult(
                title: value['testTitle'] ?? '알 수 없음',
                result: value['result'] ?? '결과 없음',
                date: dateString,
              ),
            );
          }
        });

        // 가장 최근 결과를 위로 오도록 정렬
        loadedResults.sort((a, b) => b.date.compareTo(a.date));

        setState(() {
          _allResults = loadedResults;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to load all results: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결과 기록한 테스트 내역'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,

        actions: [
          if (_allResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _deleteAllResults,
              tooltip: '전체 기록 삭제',
              color: Colors.white,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allResults.isEmpty
          ? const Center(child: Text('❌ 기록된 테스트 결과가 없습니다.'))
          : ListView.builder(
        itemCount: _allResults.length,
        itemBuilder: (context, index) {
          final result = _allResults[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListTile(
              title: Text(result.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('결과: ${result.result}\n날짜: ${result.date}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}