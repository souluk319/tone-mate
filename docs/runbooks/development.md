# ToneMate 개발 시작

도구 버전은 루트 `toolchain.json`, Dart 의존성은 workspace 루트 `pubspec.lock`에 고정한다.
Flutter 공식 `3.47.2` 태그를 사용하며 SDK를 자동 업그레이드하지 않는다.

현재 Mac의 도구 위치를 아래처럼 지정한다. 다른 개발기는 설치 위치만 맞춘다.
셸 전체 설정이나 기존 `.env`를 수정할 필요는 없다.

```sh
export PATH="$HOME/.local/share/tonemate-tools/flutter-3.47.2/bin:$PATH"
export DEVELOPER_DIR=/Applications/Xcode-16.2.app/Contents/Developer
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME="$HOME/Library/Android/sdk"

# ToneMate 작업장 루트
flutter pub get --enforce-lockfile
flutter analyze
flutter test apps/tonemate/test
cmake -S packages/pitch_core -B build/bootstrap/pitch-core -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build/bootstrap/pitch-core
ctest --test-dir build/bootstrap/pitch-core --output-on-failure

cd apps/tonemate
flutter build ios --simulator --debug --no-codesign
flutter build apk --debug
flutter run -d <device-id>
```

현재 앱은 시작·안전 안내까지만 구현했다. 마이크, DSP 연결, 진단·훈련은 미구현이다.
이 단계의 앱 빌드는 ChainShield 패키지를 아직 링크하지 않으므로 #1470 실사용 Build PASS가 아니다.
실제 저장소 소비와 문제 비교는 [연결 명령](chainshield-connection.md)을 사용한다.

Android release는 공식 템플릿의 debug signing 상태이므로 배포용 서명이 아니다.
물리 기기 오디오·성능·오프라인 전체 진단 검증도 이후 구현 단계에서 수행한다.
