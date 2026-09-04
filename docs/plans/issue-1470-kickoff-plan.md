# ChainShield #1470 착수 계획

- 버전: 1.0
- 기준일: 2026-09-04
- 기준 이슈: [ChainShield #1470](https://github.com/cywell-rnd-team/chainshield/issues/1470)
- 확인한 이슈 갱신 시각: 2026-09-04T00:38:50Z
- 담당 포맷: Conan, Swift, CocoaPods
- 상태: Phase 0 착수 가능, 포맷 실행 전

## 1. 결론

#1470은 포맷 fixture 시험을 한 번 더 실행하는 일이 아니다. ToneMate의 실제 고정 commit에서 만든 패키지를 ChainShield Hosted·Proxy·Group으로 소비하고, 그 결과를 실제 모바일 build와 UI·Scan·Policy·감사·digest에 결속하는 일이다.

작업은 다음 순서로 진행한다.

```text
개발 환경·원격 저장소 고정
  → ToneMate 일반 제품 build
  → 실제 패키지와 앱 consumer 완성
  → clean commit push
  → 포맷별 #1470 run
  → 실패 소유권 판정
  → ChainShield 결함이면 별도 이슈·PR·배포
  → 같은 ToneMate commit으로 재검증
```

Pub Hosted·Proxy·Group은 #1470 범위가 아니다. Flutter/Dart의 `pubspec`과 내부 `tonemate_pitch` workspace package는 제품 개발에 계속 사용하지만 #1470 실행표·판정·증적에는 포함하지 않는다.

## 2. 이슈 본문 필수 검증 매핑

아래 항목은 Conan·Swift·CocoaPods 각 행에 적용한다. 한 포맷의 일부 결과를 다른 포맷의 PASS로 대신하지 않는다.

| #1470 필수 항목 | 실행 방법 | 완료 증적 |
|---|---|---|
| 배포 SHA·버전·DB schema와 native client 버전 | run 시작 직전 ChainShield 배포 상태를 읽기 전용으로 확인하고 실제 client 버전을 기록 | `environment.json`, preflight log, health·schema screenshot |
| 실제 프로젝트의 고정 commit 또는 모노레포 경로 | remote에 push된 clean ToneMate full SHA만 선택 | `run.json`, `git status`, remote commit URL |
| Hosted 업로드·게시·native 다운로드·동일 요청 재시도 | 같은 좌표·같은 bytes를 게시하고 두 격리 client가 소비한다. 같은 digest 재시도는 저장된 성공 결과와 일치해야 한다 | publish response, 두 client log, 원본·다운로드 SHA-256, UI package detail |
| Proxy cold·Scan/정책·warm cache | 실제 lockfile의 외부 좌표를 client A가 cold 요청하고, scan·정책 결과 뒤 client B가 같은 bytes를 warm 요청 | upstream·cold·warm digest, cache 상태, request·audit ID |
| Proxy purge·재cold·재warm | UI package detail에서 정확한 cache 항목만 삭제하고 새 client C·D로 재수집과 재warm을 수행 | 삭제 screenshot, 새 manifest ID, C·D log와 digest |
| Group 우선순위·선택 member·provenance | UI에서 Hosted 1순위·Proxy 2순위를 저장하고 단일 Group endpoint만 consumer에 설정 | member 설정 screenshot, selected member ID, member order, provenance |
| 정상 허용·위험 차단 비교 | 정식 제품 version은 정상 허용하고, 제품 graph 밖의 무해한 QA prerelease/fixture만 차단 대상으로 사용 | artifact 판정, 실제 `요청 허용`·`요청 차단`, policy·audit ID |
| 재스캔 요청·진행·완료·실패 | 정상 artifact로 요청→진행→완료를 확인하고, 실패 상태는 지원되는 결정적 제어 조건으로만 확인 | 상태 전이 시각, request ID, UI/API screenshot·log |
| 예외 요청·승인·거절·회수 | exact artifact 경계에서 가능한 수명주기만 수행한다. 포맷·배포가 지원하지 않으면 근거 있는 N/A로 남긴다 | 요청·승인·거절·회수 audit, 적용 전후 실제 요청 결과 |
| 목록·상세·Scan·정책·감사·digest·native 대조 | `run_id + 양쪽 SHA + format + repo + coordinate + version + digest + manifest`를 공통 subject로 사용 | evidence index와 상호 링크된 screenshot·log·manifest |
| 미지원 조합 차단 또는 N/A | 미구현을 N/A로 숨기지 않는다. 프로토콜상 불가하거나 실제 제품 의존성이 없는 경우만 사유를 기록 | `N/A — <구체적 사유>` 또는 명시적 거부 응답 |

재스캔 실패를 만들기 위해 운영 scanner를 고의로 망가뜨리거나 실제 악성코드를 사용하지 않는다. 배포가 제공하는 안전한 결정적 제어 경로가 없으면 해당 run을 `BLOCKED`로 두고 계약 위반 여부를 별도 판단한다.

## 3. 포맷별 실제 제품 경계

### 3.1 Conan — 첫 실행 포맷

실제 제품 경계:

- `packages/pitch_core`
- C++20 F0·confidence·VAD 코어와 공개 C ABI
- 실제 소비자: CMake smoke, Flutter Android·iOS native link
- 기준 client: Conan CLI 2.31.1

제품 진입 조건:

- 합성 PCM corpus에서 `pitch_core`의 결정론적 결과와 focused test가 PASS다.
- 실제 Android·iOS 대상 package ID/ABI가 `conan create`로 만들어진다.
- `conan.lock`, 좌표, recipe revision, package revision과 archive digest를 기록한다.
- ChainShield를 사용하지 않는 격리 consumer가 먼저 PASS한다.

#1470 실행:

1. Hosted는 `conan upload`로 recipe/package revision graph 전체를 게시한다. Conan의 UI 단일 파일 upload는 포맷 구조상 N/A이며, UI에는 native 게시 안내와 게시 결과의 package/detail이 보여야 한다.
2. 두 개의 새 Conan home에서 `--build=never`로 exact revision을 설치하고 CMake smoke와 실제 앱 native build를 수행한다.
3. 제품에 실제 외부 Conan 좌표가 있을 때만 Proxy cold·warm·purge·재cold·재warm을 수행한다. 없다면 Proxy 조합만 `N/A — 실제 외부 Conan 의존성 없음`으로 둔다.
4. Group endpoint만 설정한 새 home에서 Hosted package와 적용 가능한 Proxy dependency를 해석하고 selected recipe/package member를 확인한다.
5. 정책 차단은 exact recipe/package revision의 무해한 QA version으로 수행하고 뒤 member로 fallback하지 않는지 확인한다.

최초 Conan run은 실제 Flutter 앱이 `pitch_core`를 link한 뒤 수행한다. CMake fixture만 성공한 상태는 준비 증거일 뿐 #1470 `실사용 Build` 최종 PASS가 아니다.

### 3.2 Swift — iOS 주 경로

실제 제품 경계:

- `packages/apple_audio`
- AVAudioSession·AVAudioEngine, route/interruption과 PCM ring-buffer 연결
- 실제 소비자: 격리 Swift consumer와 Flutter iOS SwiftPM lane
- 기준 client: SwiftPM 6.1

제품 진입 조건:

- `swift build`·focused test가 일반 registry 또는 local baseline에서 PASS다.
- 실제 iOS app target이 SwiftPM package를 link하고 서명 없는 compile을 통과한다.
- `Package.resolved`, source archive checksum과 `Package.swift` identity가 고정된다.
- 물리 기기 route/interruption 검증은 최종 포맷 PASS 전에 최소 한 번 수행한다.

#1470 실행:

1. 고정 commit의 source archive를 지원되는 Hosted publish/UI 흐름으로 게시한다.
2. 두 격리 SwiftPM cache에서 exact release를 resolve하고 source checksum·module import·build를 확인한다.
3. 실제 `Package.resolved` 외부 좌표가 있을 때만 Proxy를 실행한다. 테스트만을 위한 Swift dependency는 추가하지 않는다.
4. UI에서 구성한 Group registry 하나로 Hosted package와 적용 가능한 Proxy dependency를 resolve하고 iOS app을 build한다.
5. 선택 release의 policy failure가 뒤 member로 우회되지 않고 source archive 전달 전에 차단되는지 확인한다.

macOS의 앱 build는 설치된 Xcode toolchain을 사용하고, registry protocol 기준 확인은 고정된 Swift 6.1 client를 별도로 사용한다. 두 결과의 compiler·OS 차이를 `environment.json`에 기록한다.

### 3.3 CocoaPods — iOS 호환 경로

실제 제품 경계:

- `distribution/cocoapods/ToneMatePitch.podspec.json`
- SwiftPM 경로와 같은 iOS source commit의 source ZIP
- 실제 소비자: Flutter iOS CocoaPods compatibility `.xcworkspace`
- 기준 client: CocoaPods 1.16.2

제품 진입 조건:

- podspec name/version/source와 ZIP checksum이 같은 release identity를 가리킨다.
- 일반 CDN/local baseline의 두 clean cache에서 `pod install`이 PASS다.
- `Podfile.lock`과 `.xcworkspace` compile이 PASS다.
- SwiftPM과 CocoaPods를 같은 target에 동시에 link하지 않는다.

#1470 실행:

1. podspec JSON을 포함한 실제 source ZIP을 Hosted UI file input으로 게시한다.
2. 두 격리 CocoaPods home/cache에서 CDN metadata와 source ZIP을 resolve하고 동일 checksum을 확인한다.
3. 실제 `Podfile.lock`의 외부 pod가 있을 때만 Proxy cold·warm·purge·재cold·재warm을 수행한다.
4. Group CDN source 하나만 사용한 `pod install`과 실제 `.xcworkspace` build에서 선택 member·source URL·provenance를 확인한다.
5. invalid podspec/source와 policy 차단이 다른 member로 우회되지 않는지 확인한다.

CocoaPods lane은 #1470을 위한 가짜 샘플이 아니라 ToneMate가 실제 지원하는 iOS 호환 build여야 한다. 제품에서 이 경로를 지원하지 않기로 결정하면 테스트 코드만 남기지 말고 #1470 범위 자체를 다시 협의한다.

## 4. 단계별 착수 순서

### Phase 0 — 저장소·도구·증적 기반

산출물:

- ToneMate GitHub remote와 push된 `main`
- 고정할 Flutter, Dart, Xcode·Swift, Android SDK·NDK, CMake, Conan, CocoaPods 버전 manifest
- Android·iOS hello build와 C++ hello test
- `qa/chainshield/run`, `schemas`, `consumers`, ignored evidence 경계
- `run.json`, `environment.json`, `package-manifest.json` schema
- secret redaction과 run별 cache/home 격리 검사

종료 조건:

- remote의 clean commit에서 Android와 iOS hello build가 재현된다.
- 포맷별 client 버전과 cache 격리 방법이 고정된다.
- 아직 #1470 포맷 행을 PASS로 바꾸지 않는다.

### Phase 1 — 최소 실제 제품 vertical slice

산출물:

- 합성 단음 corpus와 `pitch_core` 기준 구현
- Flutter 앱 셸과 `tonemate_pitch` FFI 경계
- C 메이저 목표음 하나를 생성하고 PCM 분석 결과를 화면에 표시하는 최소 흐름
- Android·iOS 일반 제품 build

종료 조건:

- ChainShield 없이 같은 commit의 corpus test·CMake consumer·Flutter build가 PASS다.
- 앱과 package source가 같은 commit에 결속된다.

### Phase 2 — Conan 단독 run

- `pitch_core` Conan package와 실제 Flutter consumer를 완성한다.
- 일반 Conan baseline을 통과한 clean commit을 push한다.
- #1470의 Conan Hosted·적용 가능한 Proxy·Group·Scan/Policy·실사용 Build를 한 run으로 수행한다.
- 발견 결함을 분류·수정·재검증한 뒤에만 Conan 행을 최종 판정한다.

### Phase 3 — Swift 단독 run

- `apple_audio`와 iOS SwiftPM app lane을 완성한다.
- 일반 SwiftPM baseline과 실제 iOS compile·기기 smoke를 통과한다.
- 같은 방식으로 Swift 행을 수행하고 판정한다.

### Phase 4 — CocoaPods 단독 run

- 같은 iOS source의 CocoaPods 호환 archive와 별도 app lane을 완성한다.
- 일반 `pod install`·`.xcworkspace` build를 통과한다.
- CocoaPods 행을 수행하고 판정한다.

### Phase 5 — 제품 RC 통합 run

- 세 패키지가 같은 ToneMate RC full SHA를 가리키게 한다.
- Android, iOS SwiftPM, iOS CocoaPods clean build를 다시 결속한다.
- #1464가 요구하는 동시 native 요청이 있다면 단독 기준선과 별도로 수행한다.
- 세 행의 PASS·기대된 차단·사유 있는 N/A와 파생 결함 재검증을 확인한다.

## 5. 첫 이슈 발행 순서

원격 저장소를 만든 직후 아래 세 개만 먼저 발행한다.

1. `BOOT-001: 모바일·네이티브 툴체인과 clean hello build 고정`
2. `DSP-001: 합성 단음 corpus와 pitch_core F0 기준선 구현`
3. `APP-001: Flutter에서 목표음 생성→PCM 분석→pitch 표시 vertical slice 구현`

이후 앞 단계 결과를 근거로 순서대로 연다.

4. `PKG-001: pitch_core Conan package와 실제 앱 consumer 구성`
5. `IOS-001: apple_audio SwiftPM package와 iOS app lane 구성`
6. `IOS-002: ToneMatePitch CocoaPods 호환 lane 구성`
7. `QA-001: #1470 포맷별 run·evidence 자동화`

`QA-001`은 제품 패키지 계약을 새로 만들지 않고, 각 제품 이슈에서 확정된 command와 산출물을 실행·수집한다.

## 6. 결함 이슈 전환 기준

다음이 모두 참일 때만 ChainShield 결함 이슈를 만든다.

1. 같은 ToneMate clean commit이 일반 제품 경로에서는 PASS다.
2. 최신 확인 배포의 ChainShield 경로에서만 재현된다.
3. 최초 실패 endpoint·request ID·응답·상태 전이·artifact digest를 특정했다.
4. 기존 OPEN/CLOSED 이슈에서 같은 오류 문구·source path·근본원인을 찾지 못했다.
5. #1470의 원 완료 조건을 직접 위반한다.
6. before screenshot 또는 동일 역할의 API·native·log 증거가 있다.

결함 수정은 ChainShield 저장소의 별도 branch·PR에서 수행한다. 배포 후 같은 ToneMate commit·좌표·run 조건으로 재검증하고 after screenshot을 연결한다.

## 7. 2026-09-04 로컬 준비 상태

| 도구·환경 | 현재 확인 | 착수 조치 |
|---|---|---|
| Git / GitHub CLI | 설치됨 | ToneMate remote·visibility 결정 후 push |
| Flutter | 없음 | 공식 stable 버전을 선정·설치하고 pin |
| Dart | 3.13.2 | Flutter가 제공하는 Dart와 최종 정합 확인 |
| Android SDK / adb | 현재 PATH·환경변수에 없음 | SDK·platform·build-tools·NDK 설치·고정 |
| Conan | 없음 | ChainShield baseline 2.31.1과 제품 pin을 맞춰 설치 |
| CMake | 4.4.2 | compiler·generator와 함께 manifest에 기록 |
| Ninja | 없음 | 재현 가능한 native build generator로 설치·고정 |
| Swift | Apple Swift 6.0.3 | protocol 검증용 SwiftPM 6.1과 앱 compiler 차이를 명시 |
| CocoaPods | 1.16.2 | ChainShield baseline과 일치 |
| Xcode | active developer directory가 CommandLineTools이며 `/Applications/Xcode.app` 없음 | 전체 Xcode 설치·선택 후 iOS simulator/device 확인 |
| Docker | client 29.7.2 | 고정 Linux native client 실행 가능 여부 확인 |

따라서 지금 즉시 가능한 것은 Phase 0의 remote·manifest·툴체인 설치와 C++ 준비다. Android·iOS 실제 build와 #1470 포맷 실행은 필요한 SDK와 전체 Xcode를 갖춘 뒤 시작한다.

## 8. 바로 다음 행동

1. ToneMate GitHub 저장소의 owner와 public/private를 결정한다.
2. 현재 문서 기준선 commit을 remote에 push한다.
3. `BOOT-001`을 열고 툴체인을 설치·고정한다.
4. `DSP-001`, `APP-001`을 열되 WIP는 한 개로 유지한다.
5. Phase 1 일반 제품 build가 PASS하기 전에는 #1470 실행 댓글을 만들지 않는다.
6. 첫 #1470 run은 Conan으로 시작하고 Swift, CocoaPods 순으로 확장한다.
