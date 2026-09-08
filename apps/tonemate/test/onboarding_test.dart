import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonemate/main.dart';

void main() {
  testWidgets('시작 안내에서 안전 범위를 확인하고 돌아온다', (tester) async {
    await tester.pumpWidget(const ToneMateApp());
    expect(find.text('ToneMate'), findsOneWidget);
    expect(find.textContaining('저장하거나 전송하지 않아요'), findsOneWidget);
    await tester.tap(find.text('시작 전 안내'));
    await tester.pumpAndSettle();
    expect(find.textContaining('의료 진단이나 치료를 제공하지 않아요'), findsOneWidget);
    expect(find.textContaining('아직 마이크를 사용하거나'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('시작 전 안내'), findsOneWidget);
  });

  testWidgets('작은 화면의 200% 글자 크기에서도 안내를 연다', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ToneMateApp());
    await tester.scrollUntilVisible(find.text('시작 전 안내'), 200);
    await tester.tap(find.text('시작 전 안내'));
    await tester.pumpAndSettle();
    expect(find.text('편안하게 시작해요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
