# ToneMate ChainShield #1470 실사용 E2E 명세 v1

- 문서 버전: 1.3
- 작성일: 2026-09-02
- ToneMate 정본 편입일: 2026-09-04
- 상태: 실행 전 명세, 제품 기준선 commit·ChainShield 배포 확인 후 실행 가능
- 실행 이슈: [ChainShield #1470](https://github.com/cywell-rnd-team/chainshield/issues/1470)
- 상위 이슈: [ChainShield #1464](https://github.com/cywell-rnd-team/chainshield/issues/1464)
- 제품 기준: [제품 명세 v1](./product-spec-v1.md)
- 기술 기준: [기술검증 계획 v1](./technical-validation-plan-v1.md)
- 연결 기준: [제품·QA 추적성 명세](./product-qa-traceability-v1.md)

이 문서는 앱 개발 명세가 아니라, 실제 앱 개발 과정을 ChainShield Native·Mobile 실사용 E2E로 어떻게 연결하고 증명할지 정의한다. 2026-09-04 확인한 #1470 본문의 실행 범위는 `Conan, Swift, CocoaPods`다.

## 0. 핵심 실행 결정

1. 실제 모바일 제품은 별도 `tonemate` 모노레포에서 개발한다.
2. #1470은 코드 개발 이슈가 아니라 고정 commit을 소비하는 실행·증적 이슈로 유지한다.
3. Conan·Swift·CocoaPods는 모두 실제 제품 모듈의 배포·소비 경로로 사용한다.
4. Flutter/Dart의 Pub 도구와 `tonemate_pitch` workspace package는 제품 구현에 사용하지만 Pub Hosted·Proxy·Group은 #1470에서 검증하지 않는다.
5. 정상 경로는 실제 제품 archive와 실제 앱 build로 검증한다.
6. 손상·좌표 불일치·정책 차단·예외 상태는 제품 dependency graph와 분리된 제어 fixture로만 검증한다.
7. 한 실행의 제품 판정과 ChainShield 판정은 별도다. 하나의 PASS로 다른 하나를 대체하지 않는다.

## 1. 목적

이 E2E는 다음을 한 번의 상관된 run으로 증명한다.

- 고정된 제품 commit에서 생성한 패키지가 ChainShield Hosted에 정상 게시된다.
- 실제 공식 native client가 빈 cache에서 같은 좌표·버전·digest를 내려받는다.
- 제품의 실제 외부 의존성이 ChainShield Proxy에 처음 유입되고, 다른 빈 cache client가 같은 bytes를 warm hit로 받는다.
- UI에서 설정한 Hosted-first·Proxy-second Group의 단일 endpoint로 실제 패키지와 외부 의존성을 해석한다.
- 패키지 소비 결과가 실제 C++ smoke, Swift build, Xcode workspace build, Flutter Android·iOS build로 이어진다.
- Scan·Policy·재스캔·예외·감사·digest·Group provenance가 native 결과와 일치한다.
- 제품 결함, ChainShield 결함, 실행 하네스 결함과 사유 있는 N/A를 구분할 수 있다.

## 2. 범위와 비범위

### 포함

- Conan 2, Swift Package Registry, CocoaPods CDN
- Hosted·Proxy·Group, Private 인증, native install/build
- Proxy cold·warm·exact package purge·재수집·재warm
- Group member 우선순위·selected member·provenance·fail-closed
- 정상 허용·정책 차단·재스캔·적용 가능한 예외 수명주기
- 패키지 목록·상세·Scan·정책·감사·digest·native 결과 대조
- 제품 고정 commit의 실제 Android·iOS build

### 비범위

- ChainShield 소스 수정, 배포·DB migration, 운영 환경 재구성
- ToneMate 음정 알고리즘·학습 효과의 합격 판정
- 제품에 필요하지 않은 외부 라이브러리 추가
- 실제 악성코드 실행. 위험 검증은 비실행성·결정적 fixture로 한정한다.
- #1470에서 발견한 결함의 즉시 수정. 수정은 근본원인별 분리 이슈·분리 PR로 진행한다.
- Pub Hosted·Proxy·Group과 Pub 저장소 형식의 정책·캐시·감사 검증. Flutter/Dart build 도구 사용 자체는 제품 범위에 유지한다.

## 3. 권위 기준과 버전

| 포맷 | ChainShield 규약 기준 | 현재 기준 client | 실행 요구 |
|---|---|---|---|
| Conan | Conan 2 revisions model | Conan CLI 2.31.1 baseline | 실제 버전·OS·arch를 run에 기록 |
| Swift | Swift Package Registry API v1 / SE-0292 | SwiftPM 6.1 baseline | registry·cache를 격리하고 `resolve/build` |
| CocoaPods | Specs/CDN model | CocoaPods 1.16.2 | 실제 macOS·Xcode project에서 `pod install` |

위 버전은 ChainShield 저장소 규약의 검증 baseline이다. 제품이 더 새로운 공식 client를 고정하면 그 버전을 우선해 실행하되, baseline과의 차이를 명시한다. 실행 시점의 ChainShield 소스 SHA, 배포 SHA·버전·DB schema를 반드시 다시 확인한다.

## 4. 제품 모노레포 계약

```text
tonemate/
  AGENTS.md                          제품 전체 작업 규칙
  DESIGN.md                          아키텍처·패키지 경계 정본
  apps/tonemate/                    실제 Flutter app consumer
  packages/pitch_core/              C++20 core + Conan recipe
  packages/apple_audio/             Swift package
  packages/tonemate_pitch/          앱 내부 Flutter plugin + Dart package
  distribution/cocoapods/           CocoaPods compatibility artifact
  bench/                             제품 기술 검증
  qa/chainshield/
    AGENTS.md                        clean SHA·격리·증적·비밀 규칙
    run/                             포맷별 진입점
    consumers/                       격리 consumer 원본
    fixtures/negative/               손상·차단 전용
    schemas/                         manifest schema
    evidence/.gitkeep               실제 증적은 보안·용량 정책에 따라 보관
```

### 패키지 정체성

| 포맷 | 소스 경계 | 초기 정식 좌표 | 실제 소비자 |
|---|---|---|---|
| Conan | `packages/pitch_core` | `tonemate-pitch-core/0.1.0@tonemate/stable` | CMake smoke, Flutter iOS·Android native link |
| Swift | `packages/apple_audio` | `tonemate.apple-audio@0.1.0` | Swift consumer, Flutter iOS SwiftPM lane |
| CocoaPods | `distribution/cocoapods` + 공유 iOS source | `ToneMatePitch@0.1.0` | Flutter iOS CocoaPods compatibility lane |

좌표는 첫 게시 전 상표·namespace·클라이언트 제약을 검토해 확정한다. 확정 후 명세 변경 없이 임의 좌표로 대체하지 않는다.

### 최종 앱 build lane

| lane | 필수 패키지 경로 | 산출물 |
|---|---|---|
| Android | 적용 가능한 Conan Group | release APK/AAB·물리 기기 smoke |
| iOS 주 경로 | Swift Group + 적용 가능한 Conan Group | no-sign compile·device archive·물리 기기 smoke |
| iOS 호환 경로 | CocoaPods Group + 적용 가능한 Conan Group | `.xcworkspace` compile·호환 스모크 |

여기서 `Group`은 포맷별 단일 endpoint를 뜻한다. 여러 생태계를 하나의 범용 endpoint로 합치지 않는다. SwiftPM과 CocoaPods lane은 같은 iOS target에 동시 링크하지 않고, 같은 product commit·기능 소스를 서로 다른 clean build 구성으로 검증한다. `tonemate_pitch`는 같은 product commit의 workspace package로 소비하되 Pub ChainShield 증적으로 계산하지 않는다. plugin의 iOS 연결은 각 lane에서 `apple_audio` 또는 `ToneMatePitch` 중 하나만 소비해 중복 symbol·이중 패키징을 방지한다.

### 소스–산출물 결속

모든 배포 산출물은 다음 필드를 갖는 `package-manifest.json`을 공유한다.

```json
{
  "source_commit": "<FULL_PRODUCT_SHA>",
  "source_dirty": false,
  "product_version": "0.1.0",
  "format": "conan",
  "coordinate": "tonemate-pitch-core/0.1.0@tonemate/stable",
  "version": "0.1.0",
  "artifact_file": "<ARTIFACT_FILE>",
  "artifact_sha256": "<SHA256>",
  "toolchain": {},
  "lockfiles": [],
  "created_at": "<ISO-8601>"
}
```

- `source_dirty` 가 `true`이면 게시·E2E를 시작하지 않는다.
- 산출물 생성 후 소스를 변경하면 새 commit·새 run으로 시작한다.
- 다른 포맷의 같은 제품 버전은 같은 `source_commit`을 가리켜야 한다.

## 5. 실행 환경과 전제조건

### ChainShield 전제조건

- 2026-09-03 대상 배포가 확인되어야 한다.
- 배포 full SHA, 제품 버전, DB schema version과 dirty=false를 기록한다.
- API·Worker·Web·DB 건강 상태가 정상이어야 한다.
- #1470 실행은 배포가 아니며 ChainShield 운영 구성을 변경하지 않는다.
- `test-slot` 관련 내용·변경·증적은 제외한다.

### 제품 전제조건

- 대상 commit이 remote에 push되어 있고 clean checkout이 가능해야 한다.
- 루트 `AGENTS.md`, `DESIGN.md`, `qa/chainshield/AGENTS.md`가 해당 commit에 존재하고 실제 모듈·build lane·증적 규칙과 일치해야 한다.
- 같은 commit의 일반 제품 build 기준선을 먼저 수행해 제품 자체 결함을 분리한다.
- 포맷별 lockfile, package manifest, license inventory가 있어야 한다.
- iOS는 서명 없는 compile 증적과 최소 1회의 물리 기기 실행 증적을 구분한다.
- Android는 release artifact build와 최소 1회의 물리 기기 실행 증적을 남긴다.

### 실행 계정과 비밀

- 저장소 생성·구성·읽기·쓰기·삭제·예외에 필요한 권한만 사용한다.
- API key·token·upstream credential을 command log, screenshot, manifest에 남기지 않는다.
- 비밀은 환경변수·안전한 credential store로 주입하고 실행 전·후 redaction을 확인한다.

## 6. 저장소 구성

포맷별로 아래 세 저장소를 UI에서 생성한다. 실제 key는 실행 시점에 확정하고 run manifest에 기록한다.

| 포맷 | Hosted key 예시 | Proxy key 예시 | Group key 예시 |
|---|---|---|---|
| Conan | `tonemate-conan-h-1470` | `tonemate-conan-p-1470` | `tonemate-conan-g-1470` |
| Swift | `tonemate-swift-h-1470` | `tonemate-swift-p-1470` | `tonemate-swift-g-1470` |
| CocoaPods | `tonemate-pods-h-1470` | `tonemate-pods-p-1470` | `tonemate-pods-g-1470` |

- key는 1–64자 영문 소문자·숫자·`.`·`_`·`-`만 사용하고 첫·끝 문자는 영문 소문자 또는 숫자로 한다.
- 정상 실행은 Private 저장소를 기준으로 하고 익명·잘못된 credential 거부를 따로 확인한다.
- Group member order는 Hosted 1순위, Proxy 2순위로 한다.
- Group은 단일 endpoint만 consumer에 노출하며 member endpoint를 직접 fallback으로 사용하지 않는다.

## 7. 판정과 실행 상태

### 이슈 판정

- `PASS`: 정의된 제품·ChainShield 수용 기준을 모두 충족하고 증적이 완전하다.
- `FAIL`: 수용 기준을 재현 가능하게 위반한다.
- `BLOCKED`: 배포·권한·upstream·runner 등 외부 전제조건이 없어 실행 자체를 완료할 수 없다.
- `N/A — 사유`: 실제 제품 graph에 외부 좌표가 없거나 포맷 구조상 제공하지 않는 조합이다.

### 내부 분류

| 기준선 | ChainShield | 분류 |
|---|---|---|
| PASS | PASS | 정상 |
| PASS | FAIL | ChainShield 또는 실행 하네스 결함; 재현 분리 필요 |
| FAIL | FAIL | 제품·패키징 결함 우선 |
| FAIL | PASS 불가 | 제품 기준선 수정 후 새 commit으로 재실행 |
| PASS | BLOCKED | 외부 차단 사유 해결 후 같은 commit으로 새 run |

## 8. 공통 실행 순서

### E0 — 고정 commit 선정

1. 제품 remote의 정확한 full SHA를 선정한다.
2. clean checkout을 만들고 `source_dirty=false`를 증명한다.
3. `AGENTS.md`·`DESIGN.md`·적용되는 하위 `AGENTS.md`를 읽고 실제 구조와 일치하는지 확인한다.
4. 동일 SHA의 일반 제품 build를 수행한다.
5. 패키지 좌표·버전·digest·lockfile을 결속한다.

### E1 — 저장소·정책 생성

1. UI로 Hosted·Proxy·Group을 생성한다.
2. Proxy upstream·credential을 저장하고 reachability 결과를 기록한다.
3. Group member·우선순위를 저장한 뒤 화면 재진입으로 유지를 확인한다.
4. 정상 패키지 허용과 격리 제어 버전 차단을 위한 정책을 준비한다.

### E2 — Hosted

1. 고정 commit의 정식 archive를 게시한다.
2. 제품의 정식 배포 흐름이 native publish를 지원하면 해당 native client로 게시한다. UI–native cross-surface가 필요한 포맷은 같은 product commit의 run-scoped QA prerelease archive를 실제 UI file input으로 게시한 뒤 fresh native client가 같은 digest를 소비하게 한다. QA prerelease는 정식 app lockfile에 넣지 않는다.
3. Conan은 multi-file revision graph라 UI 단일 파일 upload을 `N/A — 포맷 구조상 native upload`로 기록하고 `conan upload`로 게시한다.
4. 다른 빈 client home/cache에서 정확한 버전을 설치한다.
5. 설치 bytes SHA-256과 Hosted manifest digest를 대조한다.
6. 실제 consumer build·smoke를 수행한다.

### E3 — Proxy cold·warm·purge

1. 제품 lockfile의 실제 upstream 좌표 하나를 확정한다.
2. 빈 client A가 Proxy endpoint로 요청해 cold fetch를 발생시킨다. UI prefetch로 대체하지 않는다.
3. 다른 빈 client B가 같은 좌표를 요청해 warm cache를 증명한다.
4. upstream·cold·warm digest와 audit request ID를 대조한다.
5. UI package detail에서 해당 Proxy 좌표만 삭제한다.
6. 새 client C로 같은 좌표를 요청해 재수집 cold, 새 client D로 재warm을 확인한다.

### E4 — Group

1. consumer에 단일 Group endpoint만 설정한다.
2. Hosted 내부 패키지와 Proxy 외부 의존성을 한 번의 native resolve/build에서 소비한다.
3. selected member, member order, provenance, manifest ID를 확인한다.
4. 선택 후 손상·정책 실패를 뒤 member로 우회하지 않는지 검증한다.
5. Group package detail에서 member 소유 artifact를 Group 자체가 삭제하는 UI를 노출하지 않는지 확인한다.

### E5 — Scan·Policy·예외

1. 정상 제품 버전의 scan 완료·정책 허용·native 성공을 연결한다.
2. 격리된 QA prerelease 또는 비실행성 제어 fixture에만 차단 정책을 적용한다.
3. 정책 위반 판정과 실제 `요청 차단` 감사 event를 구분한다.
4. 재스캔 요청·진행·완료·실패 상태를 확인한다.
5. 포맷에 적용 가능한 예외이면 요청·승인·적용·거절·회수를 검증한다. 적용할 수 없는 조합은 사유를 기록한다.
6. 예외가 있어도 아티팩트 판정 `정책 위반`을 `정상`으로 바꾸지 않고 실제 요청 결과만 `허용 · 예외 적용`으로 기록한다.

### E6 — 포맷 단독 기준선과 동시 실행

1. 담당자 단독 run으로 포맷별 기준선을 먼저 확보한다.
2. #1464의 다른 포맷 담당자와 시간을 맞춰 native 요청을 동시 실행한다.
3. Gateway·BlobStore·Worker 공용 경계의 지연·오류·상태 전이를 단독 run과 비교한다.
4. 동시 실행이 단독 기준선을 대체하지 않는다.

## 9. Conan 실행 명세

### 제품 산출물

- recipe: `packages/pitch_core/conanfile.py`
- 좌표: `tonemate-pitch-core/<version>@tonemate/stable`
- 원본: C++20 source, public C ABI header, CMake config, tests
- binary variants: 실제 제품이 소비하는 Android ABI와 iOS device/simulator target

### 필수 시나리오

| ID | 시나리오 | 통과 조건 |
|---|---|---|
| CN-H-01 | clean `conan create` 후 Hosted native upload | recipe/package revision graph가 완전하게 게시 |
| CN-H-02 | 두 개의 격리 Conan home에서 `--build=never` install | exact revision·package ID·files digest 일치 |
| CN-H-03 | 설치 결과로 CMake smoke executable build·run | 예상된 pitch-core API 결과 |
| CN-P-01 | 실제 외부 Conan 의존성 cold·warm | upstream·cold·warm revision/digest 일치 |
| CN-P-02 | exact Proxy package 삭제 후 재cold·재warm | 새 manifest, 같은 authoritative bytes |
| CN-G-01 | Group만 설정한 새 home에서 install | selected member·revision provenance 일치 |
| CN-S-01 | 정책 차단 좌표를 Group에서 install | 다음 member 우회 없이 요청 거부 |

Conan Proxy 대상은 제품이 실제로 사용하는 외부 Conan 좌표로 한정한다. `pitch_core`가 표준 라이브러리만 사용하여 외부 Conan 의존성이 없으면 CN-P-01·02는 불필요한 의존성을 추가하지 않고 `N/A`로 판정한다.

## 10. Swift Package Registry 실행 명세

### 제품 산출물

- package: `packages/apple_audio`
- 좌표: `tonemate.apple-audio@<version>`
- 내용: AVAudioSession·AVAudioEngine 구성, route/interruption, PCM ring-buffer 연결
- 소비자: 실제 iOS 호스트와 격리 Swift consumer

### 필수 시나리오

| ID | 시나리오 | 통과 조건 |
|---|---|---|
| SW-H-01 | 고정 commit source archive를 `swift package-registry publish` 또는 정의된 UI cross-surface 경로로 Hosted에 게시 | scope·name·version·checksum 일치 |
| SW-H-02 | 두 개의 격리 SwiftPM cache에서 resolve | resolved version·archive checksum 일치 |
| SW-H-03 | 격리 consumer `swift build`/`swift test` | 실제 module import·compile 성공 |
| SW-P-01 | 실제 외부 Swift dependency cold·warm | upstream·cache checksum 일치 |
| SW-P-02 | exact cache 삭제 후 재resolve | 재cold·재warm·audit 일치 |
| SW-G-01 | Group registry만 설정한 consumer build | Hosted package·Proxy dependency 동시 해석 |
| SW-G-02 | Flutter iOS SwiftPM lane compile | 실제 app target이 원격 package를 link |
| SW-S-01 | 선택된 release 정책 차단 | 뒤 member 우회 없이 native 거부 |

Package.swift·plugin·macro를 ChainShield 서버에서 실행하지 않는 것은 정상이다. 실행 가능성은 신뢰된 격리 consumer build에서만 확인한다.

## 11. CocoaPods 실행 명세

### 제품 산출물

- pod: `ToneMatePitch@<version>`
- 원본: `distribution/cocoapods/ToneMatePitch.podspec.json`과 같은 commit의 iOS source archive
- 소비자: 실제 Flutter iOS CocoaPods compatibility lane
- 원칙: SwiftPM과 기능 코드를 복제하지 않고 패키징·연결 방식만 다르게 한다.

### 필수 시나리오

| ID | 시나리오 | 통과 조건 |
|---|---|---|
| CP-H-01 | podspec JSON을 포함한 source ZIP을 지원 publish 또는 UI file input으로 Hosted upload | name·version·source·archive digest 일치 |
| CP-H-02 | 두 개의 격리 CocoaPods cache에서 `pod install` | CDN metadata·resolved version·source checksum 일치 |
| CP-H-03 | 생성된 `.xcworkspace` app build | 실제 app target·pod link 성공 |
| CP-P-01 | 실제 외부 pod cold·warm | upstream·cold·warm source digest 일치 |
| CP-P-02 | exact Proxy pod 삭제 후 재install | 재cold·재warm·CDN metadata 정합 |
| CP-G-01 | Group CDN source만 설정한 `pod install` | member 우선순위·source URL·provenance 일치 |
| CP-S-01 | 선택된 pod 정책 차단 | source archive 전달 전 거부, 뒤 member 우회 없음 |

CocoaPods는 단순 QA 포맷이 아니라 지원하는 iOS 호환 경로다. 단, 실제 pinned Flutter·Xcode 조합에서 이 경로를 지원하지 않기로 제품 결정을 바꾸면, CocoaPods를 테스트용으로 존치하지 않고 #1470에 영향·사유를 기록한다.

## 12. Proxy 대상 선정 게이트

각 포맷의 Proxy 좌표는 실행 전 dependency inventory에서 다음 기준으로 선정한다.

1. 제품 코드·build·런타임에 실제로 필요하다.
2. 고정 commit의 manifest·lockfile에 존재한다.
3. 상업적 사용·재배포가 허용된다.
4. 공식·신뢰 가능한 upstream에서 좌표·checksum을 확인할 수 있다.
5. 테스트를 위해 새로 추가한 의존성이 아니다.

실행 표의 Proxy coordinate는 첫 run 전까지 `TBD — Phase 0 dependency inventory`로 둔다. 기준을 통과한 좌표가 없으면 포맷 행 전체가 아니라 Proxy 조합만 사유가 있는 N/A로 기록한다.

## 13. 정책·손상 제어 fixture

### 정책 차단

- 정상 제품 version은 허용 상태로 유지한다.
- 차단 검증은 같은 고정 commit에서 만든 `0.1.0-qa-blocked.<run>` 같은 식별 가능한 prerelease 또는 해당 포맷의 무해한 제어 좌표로 수행한다.
- 제어 version은 앱의 정식 lockfile·배포 manifest에 넣지 않는다.
- 정책 조건·예상 위반·요청 결과를 실행 전에 고정한다.

### 손상·불일치

- archive magic 오류
- traversal·symlink·special entry
- 경로·파일명·내부 metadata의 name/version 불일치
- checksum 불일치
- 필수 manifest 누락·중복

이 fixture는 UI preflight와 native/API 게시 모두에서 거부되어야 하며 package, version, manifest, servable blob reference를 남기면 안 된다. 정상 제품 archive를 손상한 복사본을 사용하되 정상 archive와 보관 경로를 분리한다.

## 14. 캐시·삭제 계약

- client cache 삭제와 ChainShield Proxy artifact cache 삭제를 구분한다.
- warm 검증은 cold client home/cache를 재사용하지 않고 다른 빈 client로 수행한다.
- Hosted exact package 삭제 후 fresh native 요청은 not-found여야 한다.
- Proxy exact package 삭제 후 fresh native 요청은 upstream에서 재수집되어야 한다.
- Group은 member 원본을 소유하지 않으므로 개별 삭제를 제공하지 않고 member·우선순위·provenance를 보존해야 한다.
- 한 포맷 검증을 위해 전역 cache·다른 포맷·다른 저장소를 삭제하지 않는다.

## 15. UI–native–audit 상관관계

각 포맷·저장소 유형 결과는 다음 canonical subject로 연결한다.

```text
run_id + chainshield_commit + product_commit + contract_version +
format + repository_type + repository_id + repository_key +
coordinate + version + variant + artifact_key + digest + manifest_id +
selected_member_repository_id + member_order
```

필수 대조:

- Hosted product archive SHA-256 = ChainShield manifest digest = fresh native downloaded digest
- Proxy upstream digest = cold digest = warm digest = purge 후 재cold·재warm digest
- Group native result의 selected member ID·member order = UI에 저장된 구성
- browser request ID·native request ID·audit event ID는 각각 실제 event를 가리키되 같은 run subject에 연결
- 스크린샷은 화면 상태 증거이며 digest·native build 증거를 대체하지 않음

## 16. 증적 명세

### 디렉터리

```text
qa/chainshield/evidence/<run-id>/
  run.json
  environment.json
  package-manifests/
  hosted/
  proxy/
  group/
  policy/
  ui/screenshots/
  ui/network/
  native/<format>/<client-id>/
  audit/
  build/android/
  build/ios/
  result.json
  redaction-report.md
```

raw 실행 증적은 용량·보안 정책에 따라 제품 저장소의 ignored evidence directory 또는 CI artifact에 보관할 수 있다. #1470에 공개할 sanitized manifest·screenshot·요약 log는 다음 중 하나로 고정한다.

- ChainShield 저장소의 `docs/verification/issue-1470/<run-id>/`에 증적만 commit하고 immutable commit-SHA `?raw=1` URL로 연결
- 리뷰어가 접근 가능한 GitHub-uploaded attachment로 연결

ChainShield 증적 경로에 모바일 앱 개발 코드를 복사하지 않는다. 반대로 제품 저장소의 배포·기능 코드에 #1470 보고 전용 스크린샷을 산재시키지 않는다.

### `run.json` 필수 필드

```json
{
  "run_id": "1470-<yyyymmdd>-<nn>",
  "started_at": "<ISO-8601>",
  "chainshield": {
    "source_commit": "<FULL_SHA>",
    "deployed_commit": "<FULL_SHA>",
    "version": "<VERSION>",
    "db_schema": "<VERSION>:false"
  },
  "product": {
    "repository": "tonemate",
    "commit": "<FULL_SHA>",
    "dirty": false,
    "version": "0.1.0"
  },
  "clients": {},
  "formats": {},
  "redacted": true
}
```

### 필수 증거

- 실행 command, client version, OS·arch, exit code, sanitized stdout·stderr
- 저장소 ID·key·type·endpoint의 비밀 제거본
- package coordinate·version·variant·artifact key·SHA-256·manifest ID
- cold·warm·purge·재cold·재warm 요청과 cache hit 상태
- Scan·Policy·재스캔·예외 상태 전이
- Group member order·selected member·provenance
- Android·iOS 실제 build 산출물 digest와 최소 smoke 결과
- 화면 상태별 screenshot과 관련 request/audit ID
- 가려지 않은 비밀·개인정보가 없음을 확인한 redaction report

### 필수 스크린샷

1. 포맷별 Hosted·Proxy·Group 구성과 key
2. Hosted 정상 패키지 상세·digest·Scan 결과
3. Proxy cold 후 package detail과 warm·삭제·재수집 관련 감사 흐름
4. Group member order·selected member·provenance
5. 정책 위반 아티팩트와 실제 `요청 차단` 결과
6. 예외가 적용되면 `허용 · 예외 적용` 요청 결과와 원래 `정책 위반` 판정
7. 실제 앱 build·실행 성공 화면 또는 터미널 결과

## 17. 실행 자동화 계약

`qa/chainshield/run` 진입점은 포맷별로 다음 공통 인자를 받는다.

```text
--run-id
--product-ref
--chainshield-base-url
--hosted-key
--proxy-key
--group-key
--evidence-dir
--mode baseline|hosted|proxy|group|policy|all
```

- credential은 CLI 인자로 받지 않고 포맷별 표준 credential store 또는 환경변수로 주입한다.
- 스크립트는 임의 전역 cache를 삭제하지 않고 run용 임시 디렉터리만 생성·정리한다.
- 실패 시 증적을 보존하고 exit non-zero로 종료한다.
- retry는 같은 run 결과를 덮어쓰지 않고 attempt ID를 늘린다.
- `not_run`, `skipped`, timeout, cancel, stale commit, dirty source는 PASS로 승격하지 않는다.

## 18. 결함 분류·등록

FAIL은 다음 순서로 분류한다.

1. 일반 원격·로컬 기준선에서 같은 product commit·client·lockfile로 재현한다.
2. 제품 archive·manifest·좌표·빌드 하네스 결함을 먼저 제거한다.
3. ChainShield endpoint, request ID, 상태 전이, digest, selected member를 고정해 재현한다.
4. GitHub의 OPEN·CLOSED 이슈에서 오류 문구·endpoint·source path·근본원인을 검색한다.
5. 동일 근본원인은 포맷별 이슈로 복제하지 않고 기존 이슈에 영향 포맷·증거를 추가한다.
6. #1470 완료 조건을 직접 위반하는 재현 가능한 결함만 `1.0.1` 마일스톤으로 등록한다.
7. UI, Core, Runner 수정은 분리 이슈·분리 PR로 처리한다.

결함 이슈에는 실패 상태 screenshot을 반드시 첨부하고, 닫기 전에 같은 조건의 개선 screenshot·재검증 run·관련 PR을 연결한다.

## 19. 실행 중단 조건

다음은 즉시 실행을 중단하고 `BLOCKED` 또는 배포 무효 가능성을 공유한다.

- 기록한 배포 SHA와 실제 서비스 SHA 불일치
- DB schema dirty 또는 예상 버전 불일치
- API·Worker·DB 비정상으로 Scan·Policy 결과를 신뢰할 수 없음
- product commit dirty, 미push, package manifest·archive digest 불일치
- credential·개인정보·민감한 음성이 증적에 노출됨
- Group이 아닌 member endpoint를 우회해야만 build가 성공함
- 실제 앱 dependency가 아닌 임의 패키지를 제품에 추가해야만 Proxy가 성립함

## 20. 완료 조건

포맷 행은 다음을 모두 만족해야 완료다.

1. 정확한 ChainShield 배포 SHA·버전·DB schema·실행 시각을 기록했다.
2. 정확한 product repository·full commit·dirty=false를 기록했다.
3. Hosted·Proxy·Group의 각 조합이 PASS, 기대된 차단 또는 사유가 있는 N/A다.
4. 정상 경로의 실제 native install·build·smoke가 있다.
5. UI·native·audit·digest·manifest·Group provenance가 하나의 run subject로 연결됐다.
6. Proxy cold·warm·purge·재cold·재warm을 다른 client cache로 검증했다.
7. 정상 허용과 격리된 정책 차단을 비교했다.
8. 적용 가능한 재스캔·예외 수명주기 결과가 있다.
9. FAIL은 근본원인 기준 이슈와 연결되었고 screenshot 증거가 있다.
10. secret·개인정보·민감한 음성이 공개 증적에 없다.

#1470 전체는 Conan·Swift·CocoaPods 세 행이 모두 위 조건을 만족하고, 파생 결함이 재검증되어야 완료다.

## 21. #1470 실행 댓글 템플릿

```markdown
## <포맷> / Run <YYYYMMDD-NN>

- ChainShield 배포 SHA·버전·DB schema:
- 제품 repository·commit·dirty:
- 제품 기준선 결과:
- Native client·version·OS/arch:
- Hosted / Proxy / Group 저장소 ID·key:
- package / version / variant / artifact key / digest:
- Proxy 실제 upstream 의존성 또는 N/A 사유:
- Group member order·selected member·provenance:
- 정상·위험·실패·재시도 조건:
- 실제 consumer build·smoke:
- Scan·Policy·재스캔·예외:
- 기대 결과:
- 실제 결과:
- 판정: PASS / FAIL / BLOCKED / N/A — 사유
- screenshot·log·manifest·audit 증적:
- 관련 결함:
- 비밀·개인정보 redaction 확인:
```

## 22. 첫 실행 순서

1. `tonemate` 저장소와 포맷별 실제 모듈 경계를 생성한다.
2. 루트·QA `AGENTS.md`, `DESIGN.md`, 승인 명세·초기 ADR을 작성하고 상호 연결한다.
3. 툴체인·좌표·버전·lockfile·package manifest를 고정한다.
4. 일반 원격을 사용한 제품 기준선과 격리 consumer를 완성한다.
5. `pitch_core`가 실제 제품에서 build 가능한 첫 clean commit부터 Conan 단독 run을 검증한다.
6. `apple_audio`와 CocoaPods 호환 lane이 실제 build 가능해지는 순서대로 Swift·CocoaPods 단독 run을 검증한다.
7. Android, iOS SwiftPM, iOS CocoaPods 세 clean lane을 적용 가능한 native 포맷 Group endpoint로 build하고 같은 product commit에 결속한다.
8. #1464 일정에 맞춰 동시 native 요청 run을 수행한다.
9. 포맷별 판정·증적·파생 결함을 #1470에 연결한다.
