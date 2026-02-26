import 'package:flutter/material.dart';

/// 관상 결과 페이지 -- 동물상 리빌 + 분석 결과 화면
///
/// placeholder (Task G10에서 구현 예정)
class GwansangResultPage extends StatelessWidget {
  const GwansangResultPage({super.key, this.result});

  /// 관상 분석 결과 (GoRouter extra)
  final dynamic result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관상 결과 - 구현 예정')),
      body: const Center(child: Text('구현 예정')),
    );
  }
}
