import 'package:flutter/material.dart';

void main() {
  runApp(const ToneMateApp());
}

class ToneMateApp extends StatelessWidget {
  const ToneMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToneMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF356859)),
        useMaterial3: true,
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ToneMate')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '귀로 듣고, 내 목소리로.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              '듣기·음 찾기·음 유지·음 이동을 나눠 살펴보고, '
              '편안한 음역에서 연습해요.',
            ),
            const SizedBox(height: 24),
            const Text('계정 없이 시작해요. 원음은 기본적으로 저장하거나 전송하지 않아요.'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const SafetyPage()),
              ),
              child: const Text('시작 전 안내'),
            ),
          ],
        ),
      ),
    );
  }
}

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('편안하게 시작해요')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            Text('ToneMate는 음정 연습을 돕는 교육 도구예요. 의료 진단이나 치료를 제공하지 않아요.'),
            SizedBox(height: 16),
            Text('통증·쉰 목소리·피로가 있다면 오늘 발성 연습은 쉬어 주세요.'),
            SizedBox(height: 24),
            Text('개발 중인 첫 버전입니다. 아직 마이크를 사용하거나 음정을 측정하지 않아요.'),
          ],
        ),
      ),
    );
  }
}
