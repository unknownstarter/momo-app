import 'package:flutter/material.dart';

/// 관상 분석 페이지 -- 분석 중 로딩 애니메이션 화면
///
/// placeholder (Task G9에서 구현 예정)
class GwansangAnalysisPage extends StatelessWidget {
  const GwansangAnalysisPage({super.key, this.analysisData});

  /// 분석에 필요한 데이터 (GoRouter extra)
  final Map<String, dynamic>? analysisData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관상 분석 중 - 구현 예정')),
      body: const Center(child: Text('구현 예정')),
    );
  }
}
