# ToneMate 개발·이슈 운영 계획

- 버전: 1.1
- 기준일: 2026-09-04
- 상태: 실행 기준선
- ChainShield 실행 이슈: [#1470](https://github.com/cywell-rnd-team/chainshield/issues/1470)
- 현재 #1470 형식: Conan, Swift, CocoaPods
- 포맷별 상세 착수 순서: [#1470 착수 계획](./issue-1470-kickoff-plan.md)
- 다중 저장소 작업 규칙: [ToneMate·ChainShield 작업공간 계약](./multi-repo-workspace.md)

## 1. 운영 원칙

ToneMate 개발과 ChainShield 검증을 동시에 진행하되 일을 다음 세 트랙으로 분리한다.

```text
ToneMate 제품 이슈
  → 구현·제품 검증
  → clean product commit
  → 적용 가능한 #1470 포맷 실행
      ├─ PASS: #1470에 run 증적 추가
      ├─ ToneMate 결함: ToneMate 이슈에서 수정
      ├─ QA 하네스 결함: ToneMate QA 이슈에서 수정
      └─ ChainShield 결함: ChainShield 별도 이슈·PR·배포 후 재실행
```

핵심은 앱을 만들다가 만나는 모든 오류를 ChainShield 이슈로 만들지 않는 것이다. 제품 수용 기준을 위반하는 재현 가능한 문제만 이슈화하고, 첫 실패 경계와 소유 저장소를 확인한 뒤 등록한다.

## 2. 이슈의 소유권

| 대상 | 기록 위치 | 포함 내용 | 포함하지 않는 내용 |
|---|---|---|---|
| ToneMate 제품 기능 | ToneMate 저장소 이슈 | 사용자 흐름, DSP, 앱, native integration, package 산출물 | ChainShield 내부 수정 |
| ToneMate 기술검증 | ToneMate 저장소 이슈 | 알고리즘 비교, device·latency·privacy gate | 제품과 무관한 실험 |
| ToneMate QA 하네스 | ToneMate 저장소 이슈 | 격리 consumer, run manifest, evidence 자동화 | ChainShield 제품 결함 |
| #1470 실행 | ChainShield #1470 댓글 | 고정 SHA의 H/P/G 실행 결과, 판정, 증적 링크 | 앱 개발 체크리스트와 수정 코드 |
| ChainShield 결함 | ChainShield 별도 이슈 | 재현 가능한 제품 차단, endpoint·상태 전이·근본원인 | ToneMate 자체 결함 |

#1470은 작업 보드가 아니라 실행 장부다. 제품 진행률은 ToneMate 이슈에서 관리하고 #1470에는 실제 run만 남긴다.

## 3. WIP 제한

- 동시에 진행하는 제품 구현 이슈는 1개로 제한한다.
- 같은 시점에 조사 중인 ChainShield 결함도 1개만 둔다.
- 아직 필요하지 않은 포맷용 구조를 미리 구현하지 않는다.
- 제품 기능이 실제 consumer가 된 뒤 해당 포맷의 #1470 run을 연다.
- 실패를 고치기 전 다음 포맷으로 무작정 넘어가지 않는다. 단, 서로 독립임이 확인되면 BLOCKED 사유를 남기고 다음 제품 단계는 진행할 수 있다.

## 4. 한 작업 단위의 수명주기

### P0 — 제품 이슈 생성

ToneMate 이슈는 다음을 갖는다.

- 해결할 사용자 또는 기술 문제
- 포함·제외 범위
- 제품 수용 기준
- 영향 모듈과 예상 build lane
- 관련 제품 명세·기술검증 ID
- #1470 관련 형식 또는 `N/A`

단순 구현 방법을 제목으로 쓰지 않는다. 예를 들어 `YIN 클래스 작성`보다 `합성 단음에서 결정론적 F0 기준선 확보`가 이슈 경계에 적합하다.

### P1 — 구현과 focused 검증

- 이슈 하나에 대응하는 branch와 변경 범위를 유지한다.
- 관련 unit·integration·benchmark·build만 실행한다.
- 설계 경계가 바뀌면 `DESIGN.md`와 ADR을 같은 변경에서 갱신한다.
- 원음·credential·개인정보가 Git이나 로그에 들어가지 않는지 확인한다.

### P2 — 일반 제품 기준선

ChainShield를 사용하지 않는 정상 제품 경로를 먼저 검증한다.

- 같은 source commit에서 package/archive를 생성한다.
- 일반 upstream 또는 정상 로컬 제품 build로 기능을 검증한다.
- 제품 기준선이 실패하면 #1470을 실행하지 않고 ToneMate 결함으로 처리한다.
- 제품 PASS는 아직 ChainShield PASS가 아니다.

### P3 — 실행 commit 동결

#1470 대상이 되는 시점에는 다음을 모두 만족한다.

- working tree clean
- remote에 push된 full SHA
- toolchain과 lockfile 고정
- package coordinate·version·digest manifest 생성
- 일반 제품 기준선 PASS
- 앱 consumer와 package source가 같은 commit에 결속

현재 ToneMate 저장소에는 remote가 없으므로 이 단계 전까지 원격 저장소를 먼저 확정해야 한다.

### P4 — #1470 단독 포맷 실행

실제 제품 경계가 준비된 순서대로 Conan, Swift, CocoaPods를 각각 실행한다.

1. ChainShield 배포 SHA·버전·schema·health를 읽기 전용으로 확인한다.
2. Hosted 게시·두 격리 client 다운로드·실제 consumer build를 확인한다.
3. 실제 외부 의존성이 있을 때만 Proxy cold·warm·purge·recold·rewarm을 확인한다.
4. Hosted-first·Proxy-second Group endpoint만 사용해 실제 consumer build를 수행한다.
5. Scan·Policy·재스캔·예외·감사·digest·selected member를 같은 run으로 연결한다.
6. PASS, FAIL, BLOCKED 또는 사유 있는 N/A를 #1470 댓글에 기록한다.

### P5 — 실패 분류

첫 실패 지점까지 성공한 경계를 기록한 뒤 아래 표로 소유권을 정한다.

| 관찰 | 분류 | 다음 행동 |
|---|---|---|
| 일반 build와 ChainShield build가 동일하게 실패 | ToneMate 제품·패키징 결함 | ToneMate 이슈 수정, 새 SHA로 P2부터 재실행 |
| 일반 build는 성공하고 ChainShield 경로에서만 실패 | ChainShield 또는 QA 하네스 | 격리·요청·응답·로그로 둘을 분리 |
| 잘못된 coordinate, cache 또는 assertion | ToneMate QA 하네스 결함 | QA 이슈 수정, 제품 commit과 하네스 commit 관계 기록 |
| 실제 API·Gateway·Worker 동작이 계약을 위반 | ChainShield 결함 | 기존 이슈 검색 후 동일 근본원인에 증적 추가 또는 새 이슈 생성 |
| 배포 SHA·schema·health 불일치 | 실행 환경 BLOCKED | 제품이나 ChainShield 코드 수정 없이 환경 정상화 후 재시도 |
| 실제 외부 의존성이 없음 | 해당 Proxy 조합 N/A | 테스트용 의존성을 추가하지 않고 사유 기록 |
| 정책이 제어 artifact를 예상대로 차단 | 기대된 차단 PASS | 검사 판정과 실제 요청 결과를 분리해 증적 |

### P6 — ChainShield 결함 처리

새 ChainShield 이슈는 다음 조건을 모두 만족할 때만 만든다.

- 최신 배포와 clean ToneMate commit에서 재현됨
- 일반 제품 기준선은 PASS
- endpoint, 요청, 응답, 상태 전이와 최초 실패 경계가 특정됨
- OPEN/CLOSED 이슈를 검색해 같은 근본원인이 없음
- 등록 시 before screenshot 또는 관찰 가능한 API·로그 증거가 있음
- 원래 #1470 완료 조건을 직접 위반함

수정은 ChainShield 저장소의 별도 branch·PR로 수행한다. #1470 실행 도중 수정 코드를 섞지 않는다. 수정 후에는 ChainShield의 로컬 검증, 승인된 배포와 같은 ToneMate run 조건의 재검증을 거쳐 after screenshot을 남긴다.

### P7 — 완료와 연결

- ToneMate 제품 이슈는 제품 수용 기준과 관련 test/build가 통과하면 닫는다.
- ChainShield 결함은 배포 후 같은 재현 조건에서 해결된 증적이 있어야 닫는다.
- #1470 포맷 행은 H/P/G, Scan·Policy, 실제 build와 관련 결함 재검증이 끝난 뒤에만 PASS로 바꾼다.
- 제품 구현 완료, 제품 검증 완료와 #1470 완료를 서로 대체하지 않는다.

## 5. 권장 개발 순서

| 단계 | 제품 산출물 | 제품 게이트 | #1470 연결 |
|---:|---|---|---|
| 0 | 저장소 remote, toolchain manifest, CI, run schema | clean hello builds | 아직 실행하지 않음 |
| 1 | 합성 corpus·C++ `pitch_core`·Flutter 최소 vertical slice | 결정성·F0 정확도·Android/iOS 일반 build | 아직 실행하지 않음 |
| 2 | 실제 `pitch_core` Conan package와 Flutter native link | 일반 Conan consumer·실제 app build | Conan 첫 run |
| 3 | `apple_audio` Swift package와 iOS SwiftPM lane | route·interruption·실기기 build | Swift 첫 run |
| 4 | 같은 iOS 소스의 CocoaPods 호환 배포 | pod lint·clean workspace build | CocoaPods 첫 run |
| 5 | 듣기·단음 재현·C 메이저 5분 루틴 | AC-01–07과 기기 기술 게이트 | 세 포맷을 같은 RC commit으로 통합 run |

Conan부터 시작하는 이유는 공유 피치 코어가 실제 제품 핵심이면서 Android·iOS 양쪽 consumer를 만들기 때문이다. 다만 CMake fixture만으로 #1470을 PASS 처리하지 않고 Flutter 앱이 실제 package를 link한 뒤 첫 run을 연다. Swift와 CocoaPods는 iOS 오디오 경계가 제품에서 실제로 사용 가능해진 뒤 진행한다.

## 6. 첫 ToneMate 이슈 백로그

원격 저장소를 만든 뒤 처음에는 아래 이슈만 생성한다. 뒤 단계는 앞 단계 결과가 나온 뒤 구체화한다.

1. `BOOT-001: 모바일·네이티브 toolchain과 재현 가능한 hello build 고정`
2. `DSP-001: 합성 단음 corpus와 pitch_core F0 기준선 구현`
3. `APP-001: Flutter 목표음→PCM 분석→pitch 표시 vertical slice 구현`
4. `PKG-001: 실제 pitch_core Conan package와 앱 consumer 구현`
5. `IOS-001: apple_audio SwiftPM package와 iOS app lane 구현`
6. `IOS-002: ToneMatePitch CocoaPods 호환 lane 구현`
7. `QA-001: #1470 포맷별 run·evidence 자동화`

처음부터 전체 MVP 이슈를 수십 개 만들지 않는다. 1–3번을 먼저 발행하고 Phase 0 결과를 본 뒤 4–7번의 수용 기준과 toolchain 값을 확정한다.

## 7. 이슈 본문 최소 형식

```markdown
## 목적

## 사용자·기술 문제

## 포함 / 제외

## 수용 기준
- [ ] ...

## 영향 경계
- 모듈:
- build lane:
- 제품 명세·검증 ID:
- #1470 포맷: Conan / Swift / CocoaPods / N/A

## 검증
- focused test/build:
- 실제 기기 또는 corpus:
- 개인정보·비밀 확인:

## 완료 증적
- commit:
- 결과:
- screenshot/log/manifest:
```

## 8. 당장 할 일

1. ToneMate GitHub 저장소의 소유 조직과 공개 범위를 정하고 현재 `main`을 push한다.
2. 위 백로그의 1–3번만 생성한다.
3. 첫 이슈에서 SDK·compiler·build tool 버전을 확인하고 고정한다.
4. 문서 구조가 아닌 실제 `pitch_core` build가 생길 때 첫 제품 기능 branch를 시작한다.
5. Conan package가 일반 consumer에서 PASS하기 전에는 #1470 실행 댓글을 만들지 않는다.

이 방식이면 제품 개발을 멈추지 않으면서도 ChainShield 문제만 정확한 시점에 별도 이슈로 분리할 수 있다.

## 9. 이슈 번호와 작업장

- 이슈를 먼저 발행해 번호를 확보하고 해당 저장소의 `.worktrees/issue_<번호>`를 만든다.
- ToneMate와 ChainShield의 같은 숫자 이슈는 서로 다른 저장소 경로와 `ToneMate#번호`·`ChainShield#번호` 표기로 구분한다.
- #1470은 실행 장부이므로 `issue_1470` 작업장을 만들지 않는다.
- ChainShield 결함은 별도 이슈 번호의 `fix/<번호>-<범위>` branch와 worktree에서만 수정한다.
- 생성·추가·작업·검증·정리의 전체 절차는 [다중 저장소 작업공간 계약](./multi-repo-workspace.md)을 따른다.
