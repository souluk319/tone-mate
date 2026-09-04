# ToneMate 제품·기술·ChainShield #1470 추적성 명세 v1

- 문서 버전: 1.2
- 작성일: 2026-09-02
- ToneMate 정본 편입일: 2026-09-04
- 상태: 실행 전 기준선
- 제품 명세: [ToneMate 제품 명세 v1](./product-spec-v1.md)
- 기술 검증: [ToneMate 기술검증 계획 v1](./technical-validation-plan-v1.md)
- 공급망 E2E: [ChainShield #1470 E2E 명세 v1](./chainshield-1470-e2e-spec-v1.md)

## 0. 목적

이 문서는 제품 요구사항, 실제 코드·패키지 경계, 제품 기술 검증과 ChainShield #1470 증적을 연결한다. 목표는 다음 네 가지다.

1. ChainShield 테스트를 위해 제품에 불필요한 구조를 추가하지 않는다.
2. 제품 기능에 필요한 패키지가 어떤 Hosted·Proxy·Group 시나리오를 자연스럽게 증명하는지 보여준다.
3. 제품 PASS와 ChainShield PASS를 서로 대체하지 않는다.
4. 요구사항·구현·테스트·증적 중 하나가 비어 있는 상태를 완료로 표시하지 않는다.

## 1. 상태 용어

| 상태 | 의미 |
|---|---|
| `NOT RUN` | 실행 전이거나 전제조건 미충족으로 실행 증적이 없음 |
| `SPECIFIED` | 요구사항과 수용 기준만 작성됨 |
| `IMPLEMENTED` | 고정 commit에 구현됨, 검증 미완료 |
| `PRODUCT_VERIFIED` | 제품 기술 게이트를 통과함 |
| `CHAINSHIELD_VERIFIED` | #1470 결합 실행과 증적이 PASS |
| `COMPLETE` | 필요한 제품·ChainShield 게이트가 모두 PASS |
| `N/A — 사유` | 실제 제품 graph에 해당 조합이 없거나 지원 불가 |

이 문서 작성 시점의 모든 실행 항목은 `SPECIFIED`이다. 실행 증적 없이 `VERIFIED`나 `COMPLETE`로 바꾸지 않는다.

## 2. 경계 원칙

### 제품 본체

- 사용자 기능, 오디오 수집, 음정 분석, 세션, 데이터와 안전 요구사항
- 정식 패키지·호환 경로·lockfile·라이선스·재현 가능한 build
- 제품 포맷의 후보가 ChainShield 없이도 정상 build·실행되는지 판정

### ChainShield 병행 QA

- 같은 고정 commit의 패키지를 Hosted·Proxy·Group으로 유통
- native manager·실제 consumer build·UI·Scan·Policy·audit·digest의 상관관계
- ChainShield 결함은 #1470이 아닌 근본원인별 이슈·PR로 분리

### 격리 fixture

- 정상 제품에 포함할 수 없는 손상 archive·좌표 불일치·정책 차단·예외 검증
- `qa/chainshield/fixtures/negative` 아래에만 존재
- 정식 app manifest·lockfile·release artifact에 미포함

## 3. 핵심 모듈 추적표

| 모듈 | 제품 필요 | 배포 포맷 | 정식 consumer | 제품 검증 | #1470 주 검증 |
|---|---|---|---|---|---|
| `pitch_core` | iOS·Android 공유 F0·VAD·segment 산식 | Conan | native host·CMake smoke | TV-003–012, 016, 023 | CN-H/P/G/S |
| `apple_audio` | iOS route·interruption·PCM 수집 | Swift Registry | iOS app SwiftPM lane | TV-001–02, 010, 013, 021 | SW-H/P/G/S |
| `ToneMatePitch` | SwiftPM 미사용 iOS 호환 경로 | CocoaPods | iOS app `.xcworkspace` lane | TV-021, 023–024 | CP-H/P/G/S |
| `tonemate_pitch` | Flutter–native 제어·관측 API | Pub | `apps/tonemate` | TV-009–013, 016, 021–022, 027 | PB-H/P/G/S |
| `apps/tonemate` | 실제 음정 테스트·훈련 UX | Pub + lane별 native packages | 최종 앱 | AC-01–07, TV-021–030 | Android / iOS SwiftPM / iOS CocoaPods 별도 Group build |

## 4. 제품 요구사항–기술–공급망 추적표

| 제품 요구사항 | 주 구현 경계 | 제품 검증 | ChainShield 연결 | 증적 완료 조건 |
|---|---|---|---|---|
| ONB-01 오프라인 첫 진단 | Flutter app·로컬 assets | TV-030 | Pub Group의 clean app build | 원격 plugin 포함 build + airplane mode AC-01 |
| ENV-01 실제 input format | `apple_audio`·Android host | TV-002 | Swift/CocoaPods Hosted·Group | 원격 package를 link한 실기기 route run |
| ENV-04 route/interruption | `apple_audio`·Android host | TV-013 | Swift/CocoaPods Group | 실제 app AC-04 + package provenance |
| PRD-01–06 음정 산출 | `pitch_core` | TV-003–008, 026 | Conan Hosted·Group | exact revision 소비 + corpus gate |
| TRN-03 실시간 피치 | `pitch_core`→`tonemate_pitch`→Flutter | TV-009–012 | Conan + Pub Group | p95 latency + Android/iOS build |
| TRN-04–06 feedback fading | Flutter session state | TV-027 | Pub Group | 원격 plugin consumer의 AC-03 |
| TRN-07 retention | Flutter·local DB | product E2E | Pub Group | clean app build에서 retention state 재현 |
| DAT-01–03 데이터 | Flutter·platform storage | TV-017–019 | 공급망 보조 | 원격 빌드에서 파일·삭제 검사 |
| PRV-01–08 개인정보 | 전 앱·plugin | TV-017–020, 030 | 공급망 보조 | 원격 빌드의 packet·filesystem 검사 |
| NFR-03 입력→UI 지연 | 전 native–Flutter 경로 | TV-009–012 | Conan·Swift·Pub Group | 원격 package build와 latency run 같은 SHA |
| NFR-08 결정성 | `pitch_core` | TV-016 | Conan exact revision | 같은 PCM·package digest 100회 replay |
| NFR-11 의존성 inventory | 전 패키지 | TV-024 | 네 포맷 H/P/G | lockfile·SBOM·manifest·digest 일치 |
| NFR-12 공급망 재현성 | 전 패키지·app | AC-07 | CN/SW/CP/PB Group | local bypass 0 + clean Android·iOS build |
| AC-04 오디오 경로 변경 | Swift/CocoaPods native + Flutter | TV-013 | SW-G-02, CP-H-03, PB-G-03 | 같은 app SHA의 두 iOS 배포 lane |
| AC-07 clean package build | 전 모듈 | Phase 0 reproducibility | #1470 네 포맷 필수 | source·coordinate·digest·build 상관관계 |

공급망 검증이 `보조`인 항목은 ChainShield PASS만으로 제품 기능 PASS를 주장할 수 없다. 반대로 제품 기능 PASS는 패키지 저장소 계약의 PASS를 주장할 수 없다.

## 5. #1470 시나리오 ID 색인

| ID 범위 | 포맷 | 성공 경로 | 부정·정책 경로 |
|---|---|---|---|
| CN-H/P/G/S | Conan | recipe·binary revision·CMake/app link | incomplete graph·digest·정책 차단 |
| SW-H/P/G/S | Swift | registry publish/resolve/build·iOS link | archive/identity·selected-release 차단 |
| CP-H/P/G/S | CocoaPods | CDN metadata·pod install·workspace build | podspec/source 불일치·정책 차단 |
| PB-H/P/G/S | Pub | package get·Flutter Android/iOS build | archive/pubspec 불일치·정책 차단 |

## 6. 저장소 유형별 추적표

| 유형 | 제품 입력 | ChainShield 행위 | 실제 consumer 증거 | UI·audit 증거 |
|---|---|---|---|---|
| Hosted | 고정 commit의 내부 package | 게시·scan·manifest 생성 | fresh client exact version·digest·build | package/detail·download·delete·request ID |
| Proxy | lockfile의 실제 외부 package | cold acquisition·scan·cache·purge | A cold, B warm, C recold, D rewarm | cache 상태·manifest·audit |
| Group | 내부 package + 실제 외부 package | Hosted-first/Proxy-second 선택 | Group endpoint만으로 resolve·app build | member order·selected member·provenance |
| Policy | 격리 QA prerelease/fixture | scan·정책·예외·회수 | allow·block·waived request 결과 | 정책 판정과 실제 요청 결과 분리 |
| Delete | exact package coordinate | Hosted 삭제·Proxy cache 삭제·Group read-only | not-found·재수집·member 보존 | 삭제 확인·audit |

## 7. Proxy 적용성 추적

포맷별 Proxy 대상은 아래 표에 첫 실행 전 확정한다.

| 포맷 | 고정 commit의 실제 외부 좌표 | lockfile/manifest 근거 | 판정 | 사유 |
|---|---|---|---|---|
| Conan | `TBD` | `conan.lock` | `SPECIFIED` | Phase 0 inventory 후 확정 |
| Swift | `TBD` | `Package.resolved` | `SPECIFIED` | Phase 0 inventory 후 확정 |
| CocoaPods | `TBD` | `Podfile.lock` | `SPECIFIED` | Phase 0 inventory 후 확정 |
| Pub | `TBD` | `pubspec.lock` | `SPECIFIED` | Phase 0 inventory 후 확정 |

확정 규칙:

- 해당 commit의 build에 실제로 필요해야 한다.
- 포맷 E2E만을 위해 의존성을 추가하지 않는다.
- 실제 좌표가 없으면 해당 Proxy 조합만 `N/A — 실제 외부 의존성 없음`으로 남긴다.
- 이 판정은 의존성이 추가·제거되는 commit마다 다시 수행한다.

## 8. 판정 분리 매트릭스

| 상황 | 제품 판정 | #1470 판정 | 다음 행동 |
|---|---|---|---|
| 일반·ChainShield 모두 build 성공 | PASS | PASS | 증적 결속 |
| 일반 build 성공, ChainShield에서만 실패 | PASS | FAIL/BLOCKED | ChainShield·harness 원인 분리 |
| 일반·ChainShield 모두 같은 package 오류 | FAIL | 재판정 대기 | 제품·패키징 수정, 새 SHA |
| native get 성공, 실제 app compile 실패 | FAIL | FAIL 가능 | link/source 원인 분리 |
| local workspace로만 build 성공 | 개발 참고 | NOT RUN | 격리 consumer로 재실행 |
| 실제 Proxy dependency 없음 | PASS 가능 | N/A 가능 | 불필요한 package 추가 금지 |
| 정책이 제어 version을 예상대로 차단 | 영향 없음 | 기대된 차단 PASS | 판정·요청 결과 증적 |

## 9. 변경 영향 규칙

| 변경 | 갱신할 문서·검증 |
|---|---|
| 제품 패키지 경계·좌표 | 제품 §18, 기술 §5·19, #1470 §4, 본 문서 §3–07 |
| 외부 의존성 추가·제거 | lockfile, SBOM, Proxy 적용성 표, P/G 시나리오 |
| Flutter·Dart 버전 | 툴체인 manifest, Pub client 증적, Android·iOS build |
| SwiftPM⇄CocoaPods 지원 범위 | 제품 지원 정책, SW/CP 시나리오, #1470 N/A 영향 |
| DSP 공유 C++ 제거 | Conan 적용성과 CN 시나리오 전체 재판정 |
| 정책·scan profile | 제어 fixture, 기대 판정, 예외 수명주기 |
| ChainShield 배포 SHA·schema | 기존 run 재사용 금지, 새 run manifest |

요구사항을 변경하는 commit은 구현만 바꾸지 않고 이 추적표와 관련 자동·수동 검증을 같은 변경에서 갱신한다.

## 10. 증적 완전성 체크

요구사항 하나를 `COMPLETE`로 바꾸기 전에 다음을 확인한다.

- [ ] 요구사항 ID와 수용 기준이 있다.
- [ ] 구현 모듈·패키지 경계가 있다.
- [ ] 정확한 clean product commit이 있다.
- [ ] 제품 기술 검증 ID와 PASS 증적이 있다.
- [ ] ChainShield가 필요한 항목은 #1470 시나리오 ID·run·PASS 증적이 있다.
- [ ] source commit·coordinate·version·archive digest·manifest ID·native digest가 연결됐다.
- [ ] 실제 Android·iOS consumer build 중 적용 가능한 결과가 있다.
- [ ] screenshot·log·audit가 실행 상태를 증명하고 비밀·개인정보를 포함하지 않는다.
- [ ] FAIL·N/A·BLOCKED가 있으면 근본원인·사유·다음 행동이 있다.

## 11. 현재 커버리지

| 범위 | 상태 | 근거 | 다음 게이트 |
|---|---|---|---|
| 제품 기능 명세 | `SPECIFIED` | 제품 명세 v1.3 | 모노레포 구현 |
| 음정 기술 검증 | `SPECIFIED` | 기술검증 계획 v1.3 | Phase 0–3 실행 |
| Conan #1470 | `SPECIFIED` | CN-H/P/G/S | 제품 package·consumer 구현 |
| Swift #1470 | `SPECIFIED` | SW-H/P/G/S | 제품 package·consumer 구현 |
| CocoaPods #1470 | `SPECIFIED` | CP-H/P/G/S | 호환 lane 구현·지원 확정 |
| Pub #1470 | `SPECIFIED` | PB-H/P/G/S | 실제 Flutter plugin·격리 app build |
| #1470 실행 | `NOT RUN` | 2026-09-03 배포 후 시작 | 배포 preflight·고정 product SHA |

## 12. 첫 구현 백로그 연결

| 순서 | 제품 산출물 | 제품 검증 | #1470 결합 산출물 |
|---:|---|---|---|
| 1 | 루트 `AGENTS.md`·`DESIGN.md`·QA `AGENTS.md`·`docs/specs`·초기 ADR | 문서–구조 일치 리뷰 | clean SHA·격리·증적 규칙 확정 |
| 2 | 모노레포·툴체인·manifest schema | clean hello builds | run schema·consumer isolation check |
| 3 | `pitch_core` C++ baseline | corpus·determinism·ABI | Conan Hosted·Group |
| 4 | `tonemate_pitch` Flutter plugin | Dart API·FFI·widget smoke | Pub Hosted·Group + Android build |
| 5 | `apple_audio` Swift package | route·interruption·iOS compile | Swift Hosted·Group + iOS build |
| 6 | CocoaPods compatibility archive | Pod lint·workspace compile | CocoaPods Hosted·Group |
| 7 | 실제 외부 dependency 고정 | lock·license·SBOM | 적용 가능한 Proxy cold·warm·purge |
| 8 | 정책 제어 fixture | 정식 graph 미포함 확인 | 차단·재스캔·예외 |
| 9 | 고정 product RC commit | AC-01–07·TV gates | 네 포맷 단독·동시 run |

이 순서는 제품 완성 후에만 #1470을 시작하는 방식이 아니다. 각 package·consumer가 실제 build 가능해지면 그 commit을 고정해 포맷 단독 기준선을 바로 축적한다. 최종 RC에서 네 포맷을 한 commit으로 다시 결속한다.
