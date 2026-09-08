# ToneMate Design

- 상태: Specification baseline
- 기준일: 2026-09-04
- 구현 상태: 패키지 기반 계약 구현 시작
- 제품 작업명: ToneMate
- 브랜드 문구 후보: `Pitch maketh tone.`

이 문서는 현재 구현과 계획된 경계를 구분하는 living document다. 상세 요구사항과 검증 수치는 `docs/specs/`를 따르며, 여기서는 시스템 구조와 변경 시 지켜야 할 경계를 설명한다.

## 1. Product context

ToneMate는 기준음을 듣고 구별하는 능력과 그 음을 목소리로 재현·유지·이동하는 능력을 분리해 측정하는 모바일 훈련 제품이다. 사용자의 편안한 음역으로 과제를 배치하고, 실시간 피드백을 점차 줄인 뒤 무피드백 재검사로 변화를 확인한다.

MVP는 계정과 서버 없이 첫 진단과 일일 훈련을 완료할 수 있어야 한다. 원음은 기본적으로 기기를 떠나지 않는다.

## 2. Current repository state

현재 저장소에는 정본 명세와 함께 `pitch_core`의 C ABI·음정 단위 변환 기반,
`apple_audio`의 callback 외부 구성·타이밍 계약, 같은 Swift source를 배포하는
CocoaPods prerelease 구성이 구현되어 있다. `apps/tonemate`에는 Flutter workspace의
시작·안전 안내 화면과 Android/iOS 기본 host가 있다. 실제 F0 추정, PCM capture,
native package의 앱 연결과 진단·훈련 흐름은 아직 `Planned`다.

`scripts/connect-chainshield.mjs`와 `qa/chainshield/consumers`는 게시된 내부
패키지를 네이티브 클라이언트로 받아 사용하는 연결 확인을 제공한다.
독립 임시 consumer를 사용하며 실제 앱 build lane은 아직 `Planned`다.

```text
apps/tonemate/                 Flutter UI·세션·로컬 데이터
packages/pitch_core/           C++20 DSP 기반·C ABI·Conan recipe (부분 구현)
packages/apple_audio/          iOS 오디오 계약 Swift package (부분 구현)
packages/tonemate_pitch/       앱 내부 Flutter plugin·Dart package
distribution/cocoapods/        동일 iOS 소스의 CocoaPods 배포 (alpha 구성)
bench/                         결정론적 corpus·benchmark
qa/chainshield/                #1470 실행·증적 하네스
```

구현이 시작되면 존재하지 않는 모듈을 현재형으로 표현하지 않도록 이 절을 먼저 갱신한다.

## 3. Planned system graph

```text
ToneMate Flutter UI
        │ control + bounded observations
        ▼
tonemate_pitch Flutter plugin
        │
        ├── iOS: Swift / AVAudioEngine
        └── Android: Kotlin / native audio
                       │ PCM ring buffer
                       ▼
              C++20 pitch_core
        noise gate → VAD → F0 → segment → score inputs
                       │ bounded snapshot
                       ▼
                Flutter session state
```

의존성은 위에서 아래로 단방향이다. 플랫폼 오디오와 DSP는 Flutter 화면 구조를 알지 못하고, `pitch_core`는 플랫폼 API에 의존하지 않는다.

## 4. Module ownership

| 모듈 | 책임 | 책임지지 않는 것 |
|---|---|---|
| `apps/tonemate` | 화면, 내비게이션, 세션 상태, 훈련 콘텐츠, 로컬 기록 | PCM 실시간 처리 |
| `tonemate_pitch` | Dart API, platform control, FFI snapshot, 오류 정규화 | 교육 점수 임의 변경 |
| `apple_audio` | iOS 권한, route, interruption, PCM capture | Flutter UI, 최종 점수 |
| Android host | Android 권한, lifecycle, route, 저지연 PCM capture | Flutter UI, 최종 점수 |
| `pitch_core` | 신호 gate, VAD, F0, confidence, segment observation | 의료 판단, 사용자 처방 |
| `bench` | 동일 입력의 알고리즘·플랫폼 비교와 threshold 검증 | 제품 런타임 의존성 |
| `qa/chainshield` | 고정 commit 패키지 게시·소비·증적 | 제품 기능 구현, ChainShield 수정 |

## 5. Audio and observation flow

1. Flutter가 세션과 trial을 시작한다.
2. platform control API가 권한·route·오디오 session을 준비한다.
3. native callback이 PCM을 사전 할당 ring buffer에 기록한다.
4. DSP worker가 bounded chunk를 읽어 signal gate, VAD와 F0 추정을 수행한다.
5. worker가 원시 PCM이 아닌 제한된 관측 snapshot을 생성한다.
6. Flutter는 snapshot으로 실시간 피드백을 표시하고 trial 종료 시 안정 구간을 평가한다.
7. 낮은 신뢰도·소음·클리핑·입력 부재는 점수 대신 명시적 무효 사유가 된다.
8. 동의하지 않은 원음은 세션 종료 후 폐기한다.

실시간 표시값과 종료 후 점수가 다른 추정기를 사용할지는 open decision이다. 두 경로를 채택하면 사용자에게 보인 값과 최종 점수의 허용 차이를 기술검증으로 제한한다.

## 6. Concurrency and memory contract

- audio callback은 allocation, blocking lock, I/O, logging과 Dart 호출을 수행하지 않는다.
- PCM buffer의 생산자와 소비자, overwrite/drop 정책과 timestamp clock을 구현 전에 ADR로 확정한다.
- UI 갱신은 기본 20Hz bounded snapshot을 기준 후보로 하며 실제 frame/hop과 함께 검증한다.
- route 변경, interruption과 background 전환 시 현재 trial을 무효화하고 새 환경 검사 없이는 이어 붙이지 않는다.
- 모델·corpus·파일 I/O는 audio callback 밖에서 수행한다.

## 7. Build and package lanes

| Lane | 실제 제품 경로 | ChainShield #1470 형식 |
|---|---|---|
| Android | Flutter app + `tonemate_pitch` + `pitch_core` | 적용 가능한 Conan |
| iOS SwiftPM | Flutter app + `tonemate_pitch` + `apple_audio` + `pitch_core` | Swift + 적용 가능한 Conan |
| iOS CocoaPods | Flutter app + `tonemate_pitch` + `ToneMatePitch` + `pitch_core` | CocoaPods + 적용 가능한 Conan |

SwiftPM과 CocoaPods lane은 같은 기능 소스와 product commit을 사용하지만 같은 target에 동시에 링크하지 않는다. 모든 정식 패키지는 lockfile, coordinate, version, source commit과 artifact digest를 기록한다.

초기 좌표는 제품 명세의 제안이며 첫 게시 전 검토한다. 한번 게시한 버전의 byte를 교체하지 않는다.

## 8. ChainShield integration boundary

ChainShield는 제품 런타임 기능이 아니다. `qa/chainshield`가 다음을 외부 관점에서 검증한다.

- Conan, Swift, CocoaPods Hosted 게시와 native 소비
- Proxy cold·warm·exact purge·재수집
- Hosted-first, Proxy-second Group의 실제 선택 member와 provenance
- Scan·Policy·재스캔·예외·감사·digest의 native 결과 상관관계
- 격리된 consumer의 실제 Android·iOS build

각 실행은 clean하고 push된 ToneMate full SHA와 ChainShield 배포 full SHA를 동시에 기록한다. 로컬 workspace 우회는 제품 개발에는 사용할 수 있지만 #1470 증적에는 사용할 수 없다.

Flutter/Dart의 Pub 도구와 `tonemate_pitch` workspace package는 제품 내부 build 경로로 유지한다. Pub 저장소의 Hosted·Proxy·Group은 현재 #1470 범위가 아니므로 해당 경로를 위한 원격 게시·격리 consumer 증적을 만들지 않는다.

## 9. Data and privacy boundary

- 기본 저장 데이터는 trial 관측치, 점수, confidence, 설정과 진행 기록이다.
- 원음 저장은 명시적 opt-in 기능이 구현된 경우에만 허용한다.
- 분석·크래시 event에 원시 음성, API key와 개인 식별 정보를 넣지 않는다.
- 삭제 기능은 로컬 진행 기록과 opt-in 원음을 구분해 설명하고 실제 삭제를 검증한다.
- 공개·합성 corpus의 라이선스와 digest를 manifest로 관리한다. 비공개 실제 음성은 Git에 저장하지 않는다.

## 10. Failure and recovery states

- 마이크 거부: 듣기 데모만 허용하고 발성 프로필은 만들지 않는다.
- 높은 소음·클리핑·입력 없음: 점수를 생성하지 않고 재측정 원인을 안내한다.
- Bluetooth 품질 미달: 기기 마이크 또는 유선 입력을 안내하고 현재 trial을 무효화한다.
- route 변경·전화·background: trial을 중단하고 환경 검사 후 재시작한다.
- native/DSP 오류: 조용히 0점으로 변환하지 않고 오류 코드와 안전한 재시도 경로를 제공한다.
- 통증·쉰 목소리·피로: 세션을 종료하고 의료 진단이 아닌 안전 안내를 제공한다.

## 11. Open decisions

| ID | 결정 | 현재 후보 | 결정 근거 |
|---|---|---|---|
| D01 | 실시간 F0 추정기 | C++ YIN, native YIN, streaming pYIN, 경량 CREPE | 정확도·옥타브 오류·지연·전력 |
| D02 | live/scoring 추정기 분리 | 단일 경로, YIN live + 정밀 post-pass | 표시값·점수 일치 |
| D03 | DSP 공유 방식 | C++20 공통 코어, 플랫폼별 구현 | 동일 입력 결정성·유지비 |
| D04 | Dart 연결 | FFI snapshot, EventChannel summary | 지연·안정성·복잡도 |
| D05 | frame/hop | 2048/256, 2048/512, 저음 adaptive | 음역·onset·CPU |
| D06 | 지원 음역 | 목표 65–1047Hz 중 검증 통과 구간 | 기기·성별·발성 조건 |
| D07 | Bluetooth 입력 | 지원, 조건부, MVP 미지원 | route별 품질·지연 |
| D08 | ML 모델 포함 | 미포함, 경량 모델 | 정확도 이득 대비 크기·전력 |
| D09 | 외부 C/C++ 의존성 | 없음, 검증된 필요 패키지 | 제품 필요·라이선스·공급망 |
| D10 | 공개 제품명 | ToneMate 유지, 별도 이름 채택 | 상표·스토어·도메인 충돌 |

결정 전에는 후보를 현재 설계로 단정하지 않는다. 결정 결과는 ADR과 기술검증 보고서에 기록하고 이 문서를 함께 갱신한다.

## 12. Change discipline

- 모듈 경계·API·thread·데이터 흐름·build lane 변경은 코드와 이 문서에서 함께 이루어진다.
- 제품 요구사항 변경은 제품 명세와 추적성 문서를 함께 갱신한다.
- 실험 수치와 threshold 변경은 관찰 결과, 이유와 이전 결과 영향을 남긴다.
- 제품 구현, 제품 검증과 ChainShield #1470 증적 상태는 별도로 보고한다.
