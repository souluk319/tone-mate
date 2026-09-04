# ToneMate 모바일 앱 기술검증 계획 v1

- 문서 버전: 1.4
- 작성일: 2026-09-02
- ToneMate 정본 편입일: 2026-09-04
- 상태: 실행 계획
- 검증 대상: [제품 명세 v1](./product-spec-v1.md)
- 근거: [딥리서치](../research/deep-research-2026-09-02.md)
- 병행 공급망 검증: [ChainShield #1470 E2E 명세](./chainshield-1470-e2e-spec-v1.md)
- 요구사항 연결: [제품·QA 추적성 명세](./product-qa-traceability-v1.md)

## 0. 검증의 목적

이 계획은 `앱이 빌드된다`가 아니라 다음 네 가지를 실제 iOS·Android 기기에서 증명하기 위한 것이다.

1. 초보자의 단선율 음성을 제품에 필요한 정확도와 지연으로 측정할 수 있는가?
2. 측정할 수 없는 환경에서 틀린 점수를 만드는 대신 신뢰도 낮음을 판정할 수 있는가?
3. Flutter UI, 네이티브 오디오와 온디바이스 DSP를 배터리·발열·안정성 문제 없이 결합할 수 있는가?
4. guided·unguided·retention을 분리한 제품 흐름이 사용자가 이해할 수 있고 실제로 반복 가능한가?
5. 고정 commit의 정식 패키지 좌표와 lockfile로 격리된 원격 소비·앱 build를 재현할 수 있는가?

검증 결과는 알고리즘을 자랑하기 위한 최고 점수가 아니라 **MVP 범위와 지원 조건을 결정하는 근거**가 된다.

## 1. 검증 결과의 종류

- **PASS:** 사전 정의한 필수 기준을 충족하고 결과를 재현할 수 있다.
- **CONDITIONAL PASS:** 특정 기기·음역·오디오 경로를 제외하면 충족한다. 제외 조건을 제품 명세와 UI에 반영해야 한다.
- **FAIL:** 필수 기준을 충족하지 못한다. 해당 구조·알고리즘·제품 약속을 사용하지 않는다.
- **INCONCLUSIVE:** 데이터·표본·장비가 부족해 판단할 수 없다. PASS로 취급하지 않는다.

수치를 보고 난 뒤 합격선을 낮추지 않는다. 기준을 바꿔야 한다면 변경 이유, 영향과 이전 결과를 함께 남기고 새 버전으로 다시 실행한다.

## 2. 검증 범위

### 포함

- iOS·Android 물리 기기의 마이크 입력
- Flutter UI와 Swift·Kotlin 오디오 계층
- YIN, streaming pYIN, 경량 CREPE 또는 동등한 경량 모델 비교
- 공유 C/C++ DSP와 플랫폼별 구현 비교
- F0 정확도, 음성 검출, 옥타브 오류, onset, 신뢰도
- 입력→피치 관측→화면 표시 지연
- 오디오 경로 변경, interruption, 권한, Bluetooth 제한
- 배터리, CPU, 메모리, 발열, 장시간 안정성
- 원음 비저장·네트워크 비전송 검증
- 첫 진단, 피드백 페이딩, 무피드백 재검사의 사용성
- 의존성 고정, 라이선스, 재현 가능한 물리 기기 빌드

### 제외

- 상용곡에서 보컬 분리와 멜로디 추출
- 다성 음악의 주선율 추정
- 음색·호흡·공명·성대 건강 분석
- 임상 진단 정확도
- 클라우드 추론
- 앱스토어 과금·계정·백엔드 동기화
- 장기 교육 효과의 확정. 이는 제품 알파 이후 별도 연구 대상이다.

## 3. 검증 전 결정과 검증으로 결정할 것

### 이미 결정

- Flutter가 UI·세션·로컬 데이터의 제품 셸을 담당한다.
- PCM 수집과 오디오 route/interruption은 Swift·Kotlin 네이티브 계층이 담당한다.
- 핵심 분석은 온디바이스에서 수행한다.
- 연속 PCM을 Dart platform channel로 보내지 않는다.
- 원음은 기본 저장·전송하지 않는다.
- iOS·Android에서 같은 원시 지표 계약을 사용한다.
- `pitch_core`는 제품의 정식 Conan 2 내부 패키지로 배포한다. 외부 C/C++ 의존성 사용 여부는 별도로 결정한다.
- SwiftPM을 iOS 주 통합으로, CocoaPods를 같은 코드의 지원 대상 호환 통합으로 사용한다.
- `tonemate_pitch`는 실제 앱이 workspace에서 소비하는 Flutter plugin이다. Pub registry 검증은 #1470 범위가 아니다.

### 검증으로 결정

| 결정 ID | 질문 | 후보 |
|---|---|---|
| D01 | 실시간 기본 F0 추정기는 무엇인가? | C++ YIN, native YIN, streaming pYIN, 경량 CREPE |
| D02 | scoring과 live feedback을 같은 추정기로 처리하는가? | 단일 경로, YIN live + 정밀 post-pass |
| D03 | 공유 DSP를 쓸 것인가? | C++20 공유 코어, Swift·Kotlin 별도 구현 |
| D04 | Dart 연결은 무엇인가? | FFI snapshot, EventChannel summary |
| D05 | 기본 frame/hop은 무엇인가? | 2048/256, 2048/512, 저음용 4096 adaptive |
| D06 | 지원 음역은 어디까지인가? | 목표 65–1047Hz, 통과 구간만 제품 지원 |
| D07 | Bluetooth 입력을 지원하는가? | 지원, 조건부, MVP 미지원 |
| D08 | ML 모델을 포함할 가치가 있는가? | 정확도 이득 대비 크기·배터리·복잡도 평가 |
| D09 | C/C++ 외부 의존성이 필요한가? | 없음, 검증된 실제 필요 패키지만 추가; 내부 `pitch_core` Conan 배포는 유지 |

## 4. 목표 아키텍처와 비교안

### A안 — 권장 기준안

```text
AVAudioEngine / Android native input
            ↓ PCM ring buffer
       C++20 pitch_core
   noise + VAD + YIN + segment
            ↓ 20Hz snapshot
       Dart FFI / Flutter UI
```

장점은 두 플랫폼의 산식과 버전을 맞추기 쉽고, Flutter 공식 문서가 설명하는 것처럼 고빈도 네이티브 호출에 [Dart FFI](https://docs.flutter.dev/platform-integration/bind-native-code)를 사용할 수 있다는 점이다. 단점은 iOS·Android cross-build, ABI, 메모리 소유권과 실시간 thread 안전을 직접 관리해야 한다는 점이다.

### B안 — 플랫폼 구현안

```text
iOS Swift DSP ── summary ──┐
                            ├─ platform channel ─ Flutter UI
Android Kotlin/NDK DSP ────┘
```

초기 구현은 빠를 수 있지만 동일 PCM에 대한 결과 일치, 중복 버그 수정과 장기 유지비가 위험이다.

### C안 — 이중 추정안

```text
low-latency YIN → 실시간 피드백
        same buffered PCM
pYIN / light model → trial 종료 후 scoring
```

실시간 반응성과 최종 정확도를 분리할 수 있지만 사용자에게 보인 피치와 종료 후 점수가 다를 수 있다. 두 결과의 중앙 차이가 15c를 넘는 trial이 5% 이상이면 사용하지 않는다.

### 플랫폼 기준 자료

- iOS 입력은 [AVAudioEngine inputNode](https://developer.apple.com/documentation/avfaudio/avaudioengine/inputnode)의 실제 hardware format과 recording tap을 사용해 검증한다.
- Android는 [Oboe/AAudio 저지연 지침](https://developer.android.com/games/sdk/oboe/low-latency-audio)을 기준으로 low-latency mode와 callback을 검증한다.
- Flutter 네이티브 제어는 [platform channel](https://docs.flutter.dev/platform-integration/platform-channels), 고빈도 C ABI 데이터는 FFI를 비교한다.
- iOS 의존성은 [Flutter SwiftPM 통합](https://docs.flutter.dev/packages-and-plugins/swift-package-manager)을 주 경로로 사용한다. CocoaPods는 같은 iOS 기능 소스를 사용하는 지원 대상 호환 build lane으로 따로 시험한다.
- `pitch_core`의 패키징·모바일 binary 소비는 [Conan 2 cross-build](https://docs.conan.io/2/tutorial/consuming_packages/cross_building_with_conan.html)를 별도 게이트로 검증한다. 외부 Conan 의존성은 실제 필요가 확정된 경우에만 추가한다.

## 5. 검증 저장소 산출 구조

실제 제품은 ChainShield와 분리한 새 저장소에서 시작한다. 기술검증 브랜치도 제품 저장소 안에 둔다.

```text
tonemate/
  AGENTS.md                    프로젝트 작업·검증·안전 규칙
  DESIGN.md                    모듈·런타임·패키지 아키텍처 정본
  apps/tonemate/
    lib/                       Flutter UI·세션·로컬 데이터
    ios/                       SwiftPM 주 통합·CocoaPods 호환 통합
    android/                   Kotlin·NDK 호스트
  packages/pitch_core/
    include/ src/ tests/       C++20 DSP·C ABI
    conanfile.py               실제 Conan 배포 recipe
  packages/apple_audio/
    Package.swift              AVAudioEngine 연결 Swift package
    Sources/ Tests/
  packages/tonemate_pitch/
    pubspec.yaml               실제 Flutter plugin manifest
    lib/ ios/ android/ test/
  distribution/cocoapods/
    ToneMatePitch.podspec.json
    package-source.sh          같은 commit의 iOS 소스만 패키징
  bench/
    corpus-manifest.jsonl
    generators/ runner/ reference/
    thresholds-v1.json
  docs/validation/tech-v1/
    plan.md environment.md results.json decision-log.md report.md
    plots/ device-runs/ privacy/
  docs/specs/                 승인된 제품·기술·QA 명세
  docs/adr/                   주요 설계 선택·대안·결과
  qa/chainshield/
    AGENTS.md                 해당 하위 트리에만 적용되는 증적 규칙
    README.md
    run/                       포맷별 실행 진입점
    consumers/                 모노레포 밖 격리 consumer 원본
    fixtures/negative/         손상·정책 차단 전용, 제품 graph에 미포함
    schemas/                   run·evidence JSON schema
```

민감한 실제 음성은 Git에 넣지 않는다. 저장소에는 동의 범위가 명확한 공개·합성 자료 또는 비가역 manifest와 SHA-256만 둔다.

### 프로젝트 규범 문서 계약

#### 루트 `AGENTS.md`

루트 `AGENTS.md`는 다음을 MUST로 규정한다.

- 제품 사용자 가치가 본체이고 ChainShield #1470은 병행 검증이라는 범위
- ChainShield 소스를 이 저장소에 복사하거나 앱 코드를 ChainShield 저장소에 섞지 않는 경계
- `DESIGN.md`, `docs/specs/`, `docs/adr/`의 역할과 구조 변경 시 동시 갱신 규칙
- Flutter→plugin→platform audio→`pitch_core` 의 일방향 의존성과 허용된 예외
- audio callback에서 할당·lock·I/O·로깅·Dart channel 전송을 하지 않는 실시간 안전 규칙
- 원음 기본 비저장·비전송, 민감 음성·credential·개인정보 Git 저장 금지
- Conan·SwiftPM·CocoaPods 정식 좌표와 제품 Dart/Flutter lockfile·license·digest 유지 규칙
- Android, iOS SwiftPM, iOS CocoaPods가 별도 build lane이며 SwiftPM·CocoaPods를 한 target에 중복 link하지 않는 규칙
- 포맷 테스트를 위한 불필요한 제품 의존성 추가 금지
- 변경 범위의 focused test·build·물리 기기 게이트와 전체 suite 실행 권한 구분
- 사용자의 기존 dirty change를 보존하고 파괴적 명령을 금지하는 작업 규칙
- 코드 완료, 제품 검증, #1470 증적 완료를 서로 다른 상태로 보고하는 판정 규칙

#### `qa/chainshield/AGENTS.md`

하위 `AGENTS.md`는 `qa/chainshield/**`에만 적용하며 루트 규칙을 약화하지 않는다.

- clean·pushed full product SHA와 `source_dirty=false` 필수
- workspace·`path`·`git`·이전 cache 우회를 #1470 증적으로 인정하지 않음
- run별 임시 home·cache·evidence directory 격리와 전역 cache 삭제 금지
- credential을 CLI 인자·stdout·screenshot·manifest에 기록하지 않음
- 정상 경로는 실제 제품 package·app build, 손상·차단은 격리 fixture로만 수행
- ChainShield 운영 배포·DB 변경·서비스 재구성 금지
- `run_id`·양쪽 SHA·coordinate·digest·manifest·audit·Group member 상관관계 필수
- 결함 수정을 #1470 실행 중 섞지 않고 근본원인별 이슈·PR로 분리

#### 루트 `DESIGN.md`

`DESIGN.md`는 구현 현황과 일치하는 living document로 다음 섹션을 갖는다.

1. 제품 목표·비목표·시스템 context
2. 모듈 그래프·의존 방향·소유권
3. PCM 입력→ring buffer→DSP→snapshot→Flutter UI 데이터 흐름
4. audio thread·worker thread·Dart isolate 동시성·메모리 소유권·backpressure 계약
5. `pitch_core` C ABI, Dart FFI, platform control API의 안정 경계
6. 신호 유효성·confidence·구간화·scoring 버전 계약
7. Android, iOS SwiftPM, iOS CocoaPods build lane과 패키지 좌표·lockfile 흐름
8. 로컬 데이터·원음·삭제·분석 event의 개인정보·보안 경계
9. 권한·route change·interruption·저신뢰도·native 오류의 실패·복구 전이
10. 지연·결정성·배터리·메모리·오프라인 같은 품질 속성과 검증 연결
11. 채택된 선택·기각한 대안·오픈 결정을 연결한 ADR 색인
12. 아키텍처 다이어그램, 알려진 제한, 변경 이력

`DESIGN.md`에는 미확정 내용을 현재 설계로 단정하지 않는다. YIN/pYIN/경량 CREPE 선택, frame/hop, 지원 음역·Bluetooth·외부 의존성은 실험 전에 `Open decision`으로 표시하고 검증 후 ADR로 확정한다.

#### 동기화 규칙

- 모듈 소유권·API·thread·데이터 흐름·build lane을 바꾸면 코드와 `DESIGN.md`를 같은 commit에서 갱신한다.
- 주요 선택·기각·호환성 변경은 `docs/adr/`에 새 ADR을 남긴다.
- 작업·보안·검증 방법이 바뀌면 루트 또는 하위 `AGENTS.md`를 같은 변경에서 갱신한다.
- 제품 약속·수용 기준이 바뀌면 `docs/specs/`와 추적성 표를 같이 갱신한다.
- 문서와 구현이 다르면 구현을 무조건 정답으로 간주하지 않고 차이를 결함 또는 의도된 설계 변경으로 분류한 뒤 함께 수정한다.

## 6. 도구·버전·재현성

### 고정할 항목

- Flutter·Dart SDK 정확한 버전
- Xcode·Swift, iOS deployment target
- Android Gradle Plugin·Gradle·Kotlin·NDK·CMake
- C++ standard와 compiler flags
- 모델 파일·음원·corpus manifest digest
- 알고리즘·threshold·scoring version
- 모든 Dart/Flutter, SwiftPM, Gradle, Conan lockfile
- CocoaPods 호환 경로의 `Podfile.lock`과 제품 archive SHA-256
- 포맷별 정식 좌표·산출물 digest·소스 commit을 결속한 `package-manifest.json`

현재 문서가 가리키는 Flutter 공식 자료는 2026년 Flutter 3.44 계열을 반영하지만, 실제 저장소 생성일의 stable 버전을 기록하고 중간 자동 업그레이드를 금지한다.

### 재현성 기준

- 깨끗한 macOS 개발기 또는 CI runner에서 lockfile만으로 Android debug·release build 성공
- 같은 조건에서 iOS simulator build와 서명 가능한 device archive 성공
- 지원하는 두 ABI 이상의 Android native library 생성
- iOS device와 simulator slice 생성
- 같은 PCM·설정·알고리즘 버전에서 raw metrics가 허용 오차 안에서 동일
- SBOM 또는 동등한 dependency inventory와 라이선스 보고서 생성
- 모노레포 밖 격리 consumer에서 workspace·path·git 우회 없이 정식 원격 좌표로 같은 build 재현

## 7. 검증 코퍼스

### 7.1 합성 정확도 세트

정확한 ground truth를 가진 PCM을 코드로 생성한다.

- 음역: 65–1047Hz 안의 반음 단위 target
- 파형: sine, harmonic-rich, band-limited saw, formant-filtered synthetic vowel
- 발성 형태: straight, attack glide, downward drift, regular vibrato, irregular vibrato
- 진폭: -36, -24, -12dBFS
- SNR: clean, 30dB, 20dB, 10dB
- 소음: white, pink, 실내 HVAC, 원거리 대화
- 오류: octave mixture, clipping, silence, unvoiced fricative
- sample rate: 48kHz 기준, 44.1kHz route 변환 케이스 추가

최소 3,000개 clip을 결정론적으로 생성하고 seed와 generator version을 기록한다.

### 7.2 실제 음성 세트

기술 알파에서는 성인 12명 이상을 모집한다.

- 서로 다른 편안한 음역과 음색
- target 12개, 모음 `/a/`, `/i/`, `/u/`, 각 2회
- straight tone, 자연 비브라토, target 아래·위에서 접근
- built-in mic와 외부 reference mic 동시 녹음
- 조용한 환경과 20dB SNR 재생 환경

예상 최소 864개 유효 발성 clip을 확보한다. 참여자 4명 이상을 알고리즘 선택에 쓰지 않는 holdout으로 둔다.

실제 음성의 기준 f0는 고품질 reference mic, Praat 계열 분석, spectrogram 수동 검사 중 둘 이상이 일치한 구간만 사용한다. 심사자가 합의하지 못한 frame은 정확도 평가에서 제외하고 강건성 평가에는 남긴다.

### 7.3 부정·거부 세트

점수를 내면 안 되는 300개 이상의 clip을 만든다.

- 말하기, 속삭임, 파열음, 마찰음
- 박수, 책상 타격, TV, 반주, 두 사람 목소리
- 매우 작은 신호, clipping, 마이크 문지름
- 600ms 미만 음성, 심한 route 변환, Bluetooth 저품질 입력

부정 세트는 `신뢰도 낮음`과 trial 무효화의 정확도를 평가한다.

### 7.4 개인정보

- 참여 동의서에 목적, 보관 기간, 접근자, 삭제, 상업 제품 재사용 여부를 분리한다.
- 이름 대신 무작위 participant ID를 쓴다.
- 원음은 접근 통제 저장소에 암호화하고 Git·일반 클라우드 폴더에 복사하지 않는다.
- 기술검증 종료 후 보관·삭제를 동의 범위에 따라 실행한다.
- 제품 학습용 데이터로 재사용하려면 별도 명시 동의를 받는다.

## 8. 기기·오디오 조건 매트릭스

### 물리 기기 최소 구성

| 구분 | 수량 | 조건 |
|---|---:|---|
| iOS 저사양 | 1 | 지원 최소 OS와 가까운 기기, 작은 메모리 |
| iOS 중간 | 1 | 일반 사용 비중이 높은 세대 |
| iOS 최신급 | 1 | 최신 칩·OS |
| Android 저사양 | 2 | API 29–31, 서로 다른 SoC·OEM, RAM 4GB급 |
| Android 중간 | 2 | Samsung·Pixel 또는 동등한 서로 다른 OEM |
| Android 최신급 | 1 | 최신 API·64bit flagship |

최소 8대다. 에뮬레이터·시뮬레이터는 빌드와 UI 자동화에만 사용하고 오디오 성능 PASS 근거로 사용하지 않는다.

### 오디오 조건

- built-in speaker + built-in mic
- wired 이어폰 출력 + built-in/inline mic
- USB-C/Lightning 오디오 입력 1종
- Bluetooth 출력
- Bluetooth HFP 입력
- silent mode, volume 20/50/80%
- 다른 오디오 앱 재생·정지
- 이어폰 연결·해제
- 전화·알림·음성비서 interruption
- 화면 잠금·백그라운드 전환

MVP 필수 지원은 built-in mic와 검증된 유선 입력이다. Bluetooth HFP가 accuracy 또는 latency gate를 통과하지 못하면 제품이 해당 route를 감지하고 assessment 전에 연결 해제를 안내해야 한다.

## 9. 알고리즘 후보와 선택 규칙

### 후보

| 후보 | 역할 | 예상 장점 | 주요 위험 |
|---|---|---|---|
| YIN | live·scoring 기준선 | 결정론적, 작음, 낮은 지연 | 약음·잡음·옥타브 오류 |
| pYIN streaming | scoring 후보 | 후보 확률·시간 연속성 | fixed-lag 지연·복잡도 |
| 경량 CREPE | scoring 또는 hybrid | 잡음 강건성 가능성 | 모델 크기·배터리·라이선스·기기 편차 |
| YIN + post-pass | hybrid | live 반응성과 scoring 분리 | 결과 불일치·코드 경로 2개 |

### 하드 게이트

후보가 다음 중 하나를 실패하면 가중치 평가에서 제외한다.

- clean 정확도 gate
- p95 input-to-UI 120ms gate를 live 역할에서 충족
- 부정 세트 false-valid gate
- 지원 최저 기기에서 20분 thermal warning 없음
- 상업 사용 가능한 라이선스와 재배포 조건 확인
- 완전 온디바이스 동작

### 통과 후보 점수

| 항목 | 가중치 |
|---|---:|
| holdout 실제 음성 정확도·octave error | 40% |
| 지연과 callback 안정성 | 25% |
| CPU·배터리·발열 | 15% |
| binary/model 크기 | 10% |
| 구현·디버깅·업데이트 복잡도 | 10% |

최고 점수와 5점 이내면 더 단순하고 결정론적인 후보를 선택한다. ML 후보의 작은 정확도 이득만으로 모델·런타임을 추가하지 않는다.

## 10. 측정 기준

### F0 정확도

| 데이터 | 필수 기준 |
|---|---|
| 합성 clean voiced | 중앙 절대 오차 ≤5c, p95 ≤15c, octave error 0.2% 미만 |
| 합성 20dB SNR | 중앙 ≤15c, p95 ≤35c, octave error 1% 미만 |
| 실제 clean holdout | 기준 분석 대비 중앙 ≤15c, p95 ≤35c, octave error 1% 미만 |
| 실제 20dB SNR | 중앙 ≤25c, p95 ≤50c, octave error 2% 미만 |

음역 전체 평균만으로 통과시키지 않는다. 65–110, 110–220, 220–440, 440–1047Hz 구간을 각각 보고하고 한 구간이라도 기준을 넘으면 지원 음역 축소 또는 FAIL이다.

### 음성 검출·거부

| 항목 | 필수 기준 |
|---|---:|
| clean 유효 발성 true-valid | 90% 이상 |
| 20dB SNR 유효 발성 true-valid | 80% 이상 |
| 부정 세트 false-valid | 5% 미만 |
| clipping·무음 명시적 무효화 | 99% 이상 |
| confidence <0.60 결과 억제 | 100% |

### onset·구간

- 수동 기준 대비 voice onset 중앙 오차 ≤40ms, p95 ≤100ms
- stable segment 시작·끝 중앙 오차 ≤80ms
- 600ms 미만 음성을 안정 점수로 오인하는 비율 <2%
- 규칙적 비브라토를 octave error로 오인하는 비율 <1%

### 지연

| 구간 | 필수 기준 |
|---|---:|
| audio callback 수신 → native pitch observation | p95 ≤60ms |
| observation → Flutter visible update | p95 ≤30ms |
| 외부 음 변화 → 화면 반응 end-to-end | 중앙 ≤80ms, p95 ≤120ms |
| UI update rate | 15–20Hz, 프레임 드롭 없이 |

소프트웨어 지연과 실제 acoustic-to-display 지연을 별도로 측정한다.

### 자원

| 항목 | 필수 기준 |
|---|---:|
| 20분 callback deadline miss | 0.1% 미만 |
| 20분 메모리 증가 | 10MB 미만 |
| 앱 RSS | 지원 저사양에서 200MB 이하 목표 |
| 배터리 | 화면 켠 20분에 8%p 이하 소모 목표 |
| 발열 | OS thermal warning·강제 throttling 0회 |
| 크래시·hang | 반복 100세션에서 0회 |

배터리·RSS는 OS와 기기별 기준 차이가 있으므로 절대값과 동일 기기의 idle/recorder baseline 대비 값을 함께 기록한다.

## 11. 세부 검증 항목

| ID | 검증 | 방법 | PASS |
|---|---|---|---|
| TV-001 | 권한 전 마이크 접근 없음 | 첫 실행 OS privacy log | 접근 0건 |
| TV-002 | 실제 input format 처리 | 44.1/48k, mono/stereo route | crash 없이 resample 또는 명시적 거부 |
| TV-003 | YIN baseline 정확도 | 합성·실제 corpus offline | §10 정확도 기준 |
| TV-004 | pYIN fixed-lag | 동일 corpus·실시간 replay | hard gate + YIN 대비 실질 이득 |
| TV-005 | 경량 CREPE | quantized/native runtime | hard gate·라이선스 통과 |
| TV-006 | octave 오류 | 저음·배음·vibrato corpus | 구간별 기준 충족 |
| TV-007 | confidence 거부 | 부정 세트 | false-valid <5% |
| TV-008 | onset·stable segment | 수동 라벨 corpus | §10 기준 |
| TV-009 | FFI overhead | 20Hz snapshot, 20분 | observation→UI p95 ≤30ms |
| TV-010 | PCM 소유권 | sanitizer·stress test | use-after-free·race 0건 |
| TV-011 | acoustic latency | pitch transition+고속 촬영 | 중앙 ≤80ms, p95 ≤120ms |
| TV-012 | callback 안정성 | 저사양 20분 | miss <0.1% |
| TV-013 | route change | 연결·해제·전화 | trial 무효·재검사 100% |
| TV-014 | Bluetooth HFP | 전체 accuracy·latency | 통과 또는 사전 차단 |
| TV-015 | 배터리·발열 | 기기별 20분 반복 | §10 기준 |
| TV-016 | deterministic replay | 동일 PCM 100회 | ≤1c 또는 1 frame 차이 |
| TV-017 | 원음 디스크 미저장 | filesystem snapshot | opt-in 전 파일 0개 |
| TV-018 | 원음 네트워크 미전송 | offline·proxy·packet capture | audio payload 0건 |
| TV-019 | 데이터 삭제 | 저장→삭제→forensic check | DB·cache·file 잔존 0건 |
| TV-020 | background mic | lifecycle·OS indicator | background capture 0건 |
| TV-021 | iOS clean build | lockfile·새 runner | device archive 성공 |
| TV-022 | Android clean build | lockfile·새 runner | release APK/AAB 성공 |
| TV-023 | native ABI | arm64 device/simulator | symbol·ABI test 통과 |
| TV-024 | dependency inventory | SBOM·license scan | 미식별 의존성 0개 |
| TV-025 | scoring versioning | 원시 지표 재계산 | 과거 raw 보존·재현 |
| TV-026 | 낮은 신뢰도 UI | noise/input cases | 점수 미노출 100% |
| TV-027 | guided/unguided 분리 | E2E session | 저장·그래프 혼합 0건 |
| TV-028 | 접근성 | VoiceOver·TalkBack·200% text | 핵심 흐름 완료 |
| TV-029 | 안전 중단 | 5개 증상·세션 중 | 한 탭 종료·마이크 해제 |
| TV-030 | 오프라인 첫 진단 | airplane mode·fresh install | S01–S13 완료 |

## 12. 지연 측정 방법

### 소프트웨어 지연

각 audio buffer에 native monotonic timestamp를 붙이고 다음 시점을 기록한다.

```text
t0 buffer callback
t1 DSP observation ready
t2 Dart snapshot received
t3 Flutter frame scheduled
t4 frame presented estimate
```

- release build에서 10분 이상 측정한다.
- 로그 기록 자체가 callback을 방해하지 않도록 lock-free counter와 batch flush를 사용한다.
- debug build 수치는 참고만 하고 PASS 근거로 쓰지 않는다.

### acoustic-to-display 지연

1. 외부 오디오 인터페이스가 정확한 시점에 220→330Hz로 전환한다.
2. 같은 trigger로 LED를 켠다.
3. 240fps 이상 카메라로 LED와 앱 피치선 변화를 함께 촬영한다.
4. LED onset부터 화면 반응까지 frame 수를 잰다.
5. 기기·route별 30회 반복해 중앙과 p95를 보고한다.

고속 카메라가 없으면 오실로스코프·screen capture 조합을 사용할 수 있지만 추정 오차를 결과에 명시한다.

## 13. 실제 사용자 기술·사용성 검증

### 참가자

- 8–12명, 핵심 타깃인 노래 초보자·취미 보컬
- iOS·Android 사용자 모두 포함
- 서로 다른 성별 정체성보다 실제 편안한 음역·기기·경험을 기준으로 다양화
- 현재 통증·심한 쉰 목소리·의료적 음성 문제는 발성 테스트에서 제외

### 과제

1. 설명 없이 첫 진단 시작
2. 환경 실패를 한 번 경험하고 복구
3. 지각·단음·패턴 테스트 완료
4. 프로필 의미를 자기 말로 설명
5. 획득→감쇠→회상 루틴 완료
6. guided와 unguided 차이를 설명
7. 원음 저장 설정과 전체 삭제 찾기
8. `불편해요`로 안전 중단

### 수용 기준

- 80% 이상이 `듣기와 부르기가 별도 결과인 이유`를 설명
- 80% 이상이 다음 연습 행동을 추가 설명 없이 선택
- 80% 이상이 guided와 unguided 결과를 구분
- 90% 이상이 통증 시 중단해야 한다고 이해
- 첫 프로필 중앙 8분 이하
- 일일 루틴 중앙 6분 이하
- 치명적 접근성·권한·데이터 삭제 실패 0건

관찰자는 음정 실력을 평가하지 않고 지시 이해, 중단, 혼동과 피로도를 기록한다.

## 14. 단계별 실행

### Phase 0 — 저장소·재현성

산출물:

- 별도 제품 저장소
- 프로젝트 한정 루트 `AGENTS.md`와 `qa/chainshield/AGENTS.md`
- 구현과 일치하는 루트 `DESIGN.md`, 초기 ADR 색인과 `docs/specs/`
- pinned toolchain manifest
- iOS·Android physical-device hello audio build
- dependency lock과 라이선스 inventory
- 검증 결과 스키마
- Conan·Swift·CocoaPods 정식 패키지 좌표와 공통 `package-manifest.json`; Flutter workspace package manifest
- workspace·path 우회가 없는 격리 consumer 생성·검증 스크립트

종료 조건: TV-021–024 PASS, 정식 좌표 증적 manifest 생성, 격리 consumer의 local bypass 0건, `AGENTS.md`·`DESIGN.md`·초기 ADR·승인 명세의 상호 링크·구현 일치 리뷰 완료.

### Phase 1 — 계측 가능한 오디오 셸

산출물:

- 권한·route·interruption 처리
- PCM ring buffer
- timestamp와 debug meter
- 원음 저장 없는 instrumented recorder

종료 조건: TV-001–002, TV-010, TV-013, TV-020 PASS.

### Phase 2 — corpus·offline harness

산출물:

- 합성 generator와 3,000+ corpus
- 실제 음성 수집 프로토콜
- negative corpus
- 알고리즘 공통 input/output adapter
- raw metrics JSON과 비교 plot

종료 조건: corpus manifest와 ground-truth review가 완료되고 runner가 같은 결과를 재현.

### Phase 3 — 알고리즘 선택

산출물:

- YIN/pYIN/경량 CREPE 비교표
- 음역·SNR·발성 형태별 error distribution
- octave·false-valid 분석
- D01–D06 decision record

종료 조건: 하나 이상의 후보가 정확도·거부 hard gate를 PASS. 없으면 지원 범위 축소 또는 알고리즘 재탐색.

### Phase 4 — Flutter 실시간 통합

산출물:

- FFI 또는 summary bridge
- 15–20Hz 피치 레인
- guided·unguided session state
- 실시간·post-pass 일치 보고서

종료 조건: TV-009–012, TV-016, TV-027 PASS.

### Phase 5 — 기기·route·자원

산출물:

- 8대 device matrix 결과
- route별 지원표
- 배터리·CPU·메모리·thermal 보고서
- Android OEM별 known issue

종료 조건: TV-014–015와 §10 자원 기준 PASS 또는 제품에 반영된 CONDITIONAL PASS.

### Phase 6 — 개인정보·안전·접근성

산출물:

- 파일시스템 diff
- packet capture 보고서
- 삭제 증거
- VoiceOver·TalkBack 체크
- 안전 중단 시나리오 결과

종료 조건: TV-017–020, TV-028–030 PASS.

### Phase 7 — 사용자 알파

산출물:

- 8–12명 세션 기록
- 프로필 이해·완료시간·이탈 원인
- 카피와 흐름 수정
- MVP 수용 시나리오 최종 결과

종료 조건: §13 수용 기준 충족.

## 15. 검증 증거 형식

각 device run은 다음 JSON을 남긴다.

```json
{
  "run_id": "uuid",
  "source_commit": "full-git-sha",
  "app_version": "0.1.0-tech",
  "algorithm": "yin-cpp",
  "algorithm_version": "sha256-or-semver",
  "threshold_version": "v1",
  "device_alias": "android-low-01",
  "os_version": "recorded-at-run",
  "input_route": "built_in_mic",
  "corpus_manifest_sha256": "...",
  "started_at": "ISO-8601",
  "metrics": {},
  "gate_results": [],
  "artifacts": []
}
```

### 증거 규칙

- 모든 결과를 정확한 Git SHA, toolchain, device alias와 묶는다.
- 평균만 쓰지 않고 중앙, p95, 최악 음역과 실패 샘플을 남긴다.
- FAIL 샘플을 삭제하거나 임의로 outlier 처리하지 않는다. 제외 규칙은 실행 전에 정의한다.
- 실제 음성 파일은 보고서에 첨부하지 않고 participant·clip ID만 기록한다.
- benchmark script와 threshold JSON은 제품 저장소에 commit한다.
- 최종 보고서는 PASS뿐 아니라 known limitations와 미지원 route를 포함한다.

## 16. 자동화

### commit마다

- DSP 단위 테스트
- 센트·MIDI·전조·구간화 property test
- 합성 smoke corpus
- 동일 PCM 결정성 테스트
- Flutter widget·state test
- iOS simulator·Android emulator build
- dependency lock drift와 라이선스 검사

### nightly 또는 물리 기기 lab

- 전체 합성 corpus
- 실제 음성 holdout replay
- 20분 stability·memory
- 배터리·thermal 표본
- Android OEM·iOS device matrix

### release candidate마다

- acoustic-to-display latency
- route·interruption 전 조합
- 파일시스템·network privacy 검사
- 데이터 삭제
- 접근성 핵심 흐름
- guided·unguided·retention E2E

## 17. 실패 시 대응

| 실패 | 우선 대응 | 금지 대응 |
|---|---|---|
| 저음 octave 오류 | adaptive window·candidate continuity, 지원 하한 검토 | modulo로 오류 숨기기 |
| 잡음 false-valid | VAD·SNR·confidence 거부 강화 | 낮은 신뢰 점수 표시 |
| live 지연 | YIN live, 정밀 post-pass 분리 | UI를 선행 예측해 가짜 표시 |
| Android callback miss | Oboe low-latency·buffer·thread 점검 | 오디오 thread에서 로그·할당 |
| Flutter bridge 병목 | C ABI snapshot·batching | PCM frame을 MethodChannel 전송 |
| ML 발열·크기 | quantization 또는 YIN 선택 | 최저 기기 제외를 숨기기 |
| Bluetooth 품질 실패 | assessment 전 차단·기기 mic 안내 | 경로를 모른 채 점수 생성 |
| 사용자 점수 혼동 | 원시 행동 언어·축 축소 | 더 큰 총점 배지 추가 |
| 음성 피로·불편 | 음역·반복 감소·중단 | streak 때문에 계속 유도 |

## 18. Go/No-Go 게이트

### 기술 알파 GO

다음을 모두 만족해야 제품 UI 전체 구현으로 이동한다.

1. YIN baseline 또는 대안이 clean·20dB 정확도와 false-valid 기준을 충족한다.
2. iOS·Android 최저 지원 기기에서 live p95 120ms 이하이다.
3. built-in mic 경로가 20분 동안 callback·발열 기준을 통과한다.
4. confidence <0.60에서 점수가 항상 억제된다.
5. lockfile 기반 clean physical-device build가 재현된다.

### MVP 알파 GO

1. TV-001–030 중 해당 MVP 필수 항목이 PASS다.
2. 8대 device matrix에서 built-in mic 경로가 PASS다.
3. 조건부 지원·미지원 route가 UI와 문서에 반영됐다.
4. 사용자 8–12명 수용 기준을 충족한다.
5. 원음 비동의 저장·전송 0건과 데이터 삭제 100%를 증명했다.
6. 제품 명세의 AC-01–07이 실제 기기 또는 AC-07에 정의된 격리 clean build에서 통과한다.

### 공개 베타 NO-GO 조건

- 실제 음성 holdout에서 octave error가 2% 이상
- 기기군 하나에서 invalid rate 20% 이상인데 원인을 설명하지 못함
- 낮은 confidence에서 능력 점수를 표시하는 경로 존재
- background mic, 비동의 원음 저장·전송, 삭제 잔존 중 하나라도 발생
- 통증·쉰 목소리에서 연습 지속을 유도하는 문구 존재
- guided 결과를 학습 효과로 오인하게 하는 UI 존재
- 의존성 라이선스 또는 음원 권리가 미확인

## 19. ChainShield #1470 병행 실사용 E2E

제품은 ChainShield 저장소 안에 넣지 않고 독립 `tonemate` 모노레포에서 개발한다. 다만 패키지 경계가 build 가능해지는 순서대로 #1470 실행을 병행한다. 전체 제품이 완성될 때까지 기다리지 않으며, 각 run마다 실행 대상을 clean 고정 commit으로 동결한다.

### 병행 원칙

- 제품 commit과 패키지 source commit은 같아야 한다.
- Conan·Swift·CocoaPods 배포물은 같은 소스를 포맷별로 패키징하며 테스트용 구현을 따로 만들지 않는다.
- 일반 개발의 workspace·path 해석은 허용하되 #1470 증적 consumer는 모노레포 밖으로 격리한다.
- 정상 경로는 실제 제품 package·app build로 검증한다. 손상 archive, 정책 차단과 예외 상태만 `qa/chainshield/fixtures/negative` 안의 격리 fixture를 사용한다.
- Proxy는 고정 commit에 실제로 있는 외부 의존성만 사용한다. 해당 포맷 외부 좌표가 없으면 패키지를 추가하지 않고 `N/A — 실제 외부 의존성 없음`을 기록한다.
- 제품 기술 게이트와 ChainShield E2E 판정을 별도로 남긴다. 한쪽의 PASS가 다른 한쪽을 대체하지 않는다.

### 포맷별 제품 연결

| 포맷 | 실제 제품 산출물 | 실사용 build 게이트 |
|---|---|---|
| Conan | `pitch_core` recipe·platform binary revision | `--build=never` 격리 install 후 CMake smoke·Flutter native build |
| Swift | `apple_audio` source package | clean SwiftPM resolve/build 후 iOS app build |
| CocoaPods | `ToneMatePitch` 호환 source archive·podspec | clean `pod install` 후 `.xcworkspace` app build |

Flutter app과 `tonemate_pitch`는 제품 기준선과 세 native package consumer build에 계속 사용하지만 Pub 저장소 자체는 #1470에서 검증하지 않는다.

실행 절차·정책·cache·UI·증적·판정 계약은 별도 [ChainShield #1470 E2E 명세](./chainshield-1470-e2e-spec-v1.md)를 따른다.

## 20. 첫 실행 순서

1. 별도 제품 저장소와 pinned toolchain manifest를 만든다.
2. 양 플랫폼에서 PCM timestamp만 출력하는 instrumented recorder를 물리 기기에 설치한다.
3. 합성 corpus generator와 offline benchmark runner를 먼저 만든다.
4. C++ YIN을 기준선으로 구현해 정확도·지연·거부 기준을 측정한다.
5. 기준선이 약한 구간에만 pYIN·경량 CREPE를 비교한다.
6. 알고리즘을 결정한 뒤 Flutter 피치 레인과 세션 상태를 연결한다.
7. 8대 기기·route·배터리·privacy 검증을 통과시킨다.
8. 첫 진단과 5분 루틴을 완성해 8–12명 사용자 알파를 진행한다.
9. 패키지 경계가 안정되는 순서대로 clean commit을 고정하고 #1470 단독 기준선을 병행 실행한다.
10. PASS/CONDITIONAL PASS 범위만 제품 명세에 반영하고 MVP 구현 범위를 고정한다.

## 21. 제품 요구사항 추적표

| 제품 명세 범위 | 주 검증 | 보조 증거 |
|---|---|---|
| ONB-01–04 | TV-001, TV-030 | 사용자 알파 권한·완료 관찰 |
| ENV-01–05 | TV-002, TV-013, TV-014 | device/route matrix |
| SAF-01–02 | TV-029 | 안전 카피 리뷰·사용자 알파 |
| RNG-01–03 | 콘텐츠 생성기 property test | 사용자 음역별 target snapshot |
| PER-01–05 | 문항 생성 단위·state test | 사용자 알파 지시 이해 |
| PRD-01–06 | TV-003–008, TV-026 | corpus·physical-device E2E |
| TRN-01–08 | TV-011, TV-012, TV-027 | 세션 event trace·완료시간 |
| RES-01–06 | TV-025–027 | profile golden test·사용자 설명 |
| HIS-01–02 | TV-016, TV-025 | 재실행·주간 aggregate test |
| DAT-01–03 | TV-017–019 | filesystem diff·export test |
| PRV-01–08 | TV-001, TV-017–020, TV-030 | packet capture·OS privacy log |
| NFR-01–12 | TV-009–016, TV-021–024, TV-030 | benchmark·SBOM·clean build·#1470 package manifest |
| AC-01–07 | 실제 기기 product E2E·격리 package build | 화면 녹화·event trace·파일 검사·원격 archive digest |

제품 요구사항이 추가되면 이 표와 해당 자동·수동 검증을 같은 변경에서 갱신한다. 검증이 연결되지 않은 MUST 요구사항은 구현 완료로 표시할 수 없다.
