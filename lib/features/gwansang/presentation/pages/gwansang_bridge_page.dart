import 'package:flutter/material.dart';

/// 관상 브릿지 페이지 -- 사주 결과 -> 관상 유도 화면
///
/// placeholder (Task G7에서 구현 예정)
class GwansangBridgePage extends StatelessWidget {
  const GwansangBridgePage({super.key, this.sajuResult});

  /// 사주 분석 결과 (GoRouter extra)
  final dynamic sajuResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관상 브릿지 - 구현 예정')),
      body: const Center(child: Text('구현 예정')),
    );
  }
}
