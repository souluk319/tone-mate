# ToneMate Repository Instructions

## Scope

이 문서는 저장소 전체에 적용한다. 더 하위의 `AGENTS.md`는 해당 하위 트리에 추가 제약을 둘 수 있지만 이 문서의 제품·안전·개인정보 경계를 약화할 수 없다.

## Mission

- ToneMate는 실제 iOS·Android 음정 감각·발성 훈련 제품이다.
- 사용자가 음정을 못 맞히는 원인을 듣기, 목표음 진입, 유지, 이동과 타이밍으로 나누고 개인 음역에 맞는 훈련과 무피드백 재검사를 제공한다.
- ChainShield #1470은 실제 제품 개발에서 만들어지는 Conan·Swift·CocoaPods 패키지를 검증하는 병행 QA다. 테스트를 위해 제품에 필요 없는 기능이나 의존성을 넣지 않는다.
- ChainShield 소스를 이 저장소에 복사하지 않고 ToneMate 코드를 ChainShield 저장소에 섞지 않는다.

## Source of truth

다음 문서를 역할에 맞게 사용한다.

1. `docs/specs/product-spec-v1.md`: 사용자 가치, 제품 요구사항, MVP와 수용 기준
2. `docs/specs/technical-validation-plan-v1.md`: 알고리즘·기기·성능·개인정보 검증 게이트
3. `DESIGN.md`: 현재 구현의 모듈·데이터·스레드·빌드 경계
4. `docs/specs/product-qa-traceability-v1.md`: 요구사항과 구현·시험·증적의 연결
5. `docs/specs/chainshield-1470-e2e-spec-v1.md`: 고정 commit을 소비하는 공급망 검증 계약
6. `docs/plans/development-workflow.md`: 제품 개발, #1470 실행과 결함 수정의 이슈 운영 절차
7. `docs/plans/issue-1470-kickoff-plan.md`: live 이슈 체크리스트를 포맷별 제품 산출물·run·증적에 매핑한 착수 순서
8. `docs/adr/`: 채택하거나 기각한 주요 설계 선택

연구 문서는 결정 근거이며 정본 요구사항이 아니다. 문서끼리 충돌하면 조용히 한쪽을 선택하지 말고 역할에 따라 분류한 뒤 관련 정본과 추적성 문서를 함께 갱신한다.

## Product and architecture boundaries

- Flutter는 UI, 내비게이션, 세션 상태와 로컬 데이터를 담당한다.
- Swift·Kotlin 계층은 권한, 오디오 세션, 입력 경로, interruption과 PCM 수집을 담당한다.
- 고빈도 PCM을 Dart 메시지 채널로 연속 전송하지 않는다.
- 공유 DSP를 채택하면 `pitch_core` C ABI와 Dart FFI를 안정 경계로 사용한다.
- 의존 방향은 앱 → Flutter plugin → 플랫폼 오디오 → `pitch_core`로 유지한다.
- SwiftPM과 CocoaPods는 같은 iOS target에 동시에 링크하지 않는다. 별도의 clean build lane으로 검증한다.
- Flutter/Dart의 `pubspec`과 workspace package는 제품 build 도구다. Pub Hosted·Proxy·Group은 현재 #1470 범위가 아니며 그 결과를 #1470 PASS로 기록하지 않는다.
- 서버는 MVP 핵심 경로의 필수 조건이 아니다. 오프라인 첫 진단과 훈련을 유지한다.

## Real-time audio safety

오디오 callback에서는 다음을 금지한다.

- 동적 메모리 할당과 예측 불가능한 해제
- blocking lock, 파일·네트워크 I/O와 로깅
- Dart channel 직접 전송
- 모델 로딩, 데이터베이스 접근과 UI 상태 변경

callback은 사전 할당된 buffer에 bounded write만 수행한다. 분석과 UI snapshot 생성은 별도 worker에서 처리하고 backpressure와 drop 정책을 `DESIGN.md`에 기록한다.

## Specifications and decisions

- `DESIGN.md`는 실제 구현 상태를 서술한다. 아직 구현되지 않은 구조는 `Planned`, 실험 전 선택은 `Open decision`으로 표시한다.
- 모듈 소유권, API, 스레드, 데이터 흐름 또는 build lane을 바꾸면 코드와 `DESIGN.md`를 같은 변경에서 갱신한다.
- 주요 선택·기각·호환성 변경은 `docs/adr/`에 ADR로 남긴다.
- 제품 약속이나 수용 기준이 바뀌면 제품 명세와 추적성 문서를 함께 갱신한다.
- 측정 수치와 합격선은 결과를 본 뒤 소급해 낮추지 않는다. 변경 시 이유와 이전 결과의 영향을 기록한다.

## Dependency and build discipline

- Flutter·Dart, Xcode·Swift, Android Gradle·Kotlin·NDK·CMake와 Conan 버전을 고정한다.
- 제품의 `pubspec.lock`, `Package.resolved`, `Podfile.lock`, Gradle dependency lock과 `conan.lock`을 해당 lane이 생기는 시점부터 버전 관리한다.
- 공개한 패키지 버전은 같은 byte와 digest에만 결속한다. 내용이 달라지면 새 버전을 발행한다.
- 패키지 포맷 테스트만을 위한 불필요한 제품 의존성은 추가하지 않는다.
- 변경 범위의 focused test와 build를 기본으로 실행한다. 전체 기기·통합 matrix는 명세에 정의된 phase/release gate에서 수행한다.

## Voice data, privacy, and safety

- 원음은 기본적으로 저장하거나 네트워크로 전송하지 않는다.
- 사용자가 명시적으로 저장을 선택한 경우에만 보존 범위와 삭제 방법을 제공한다.
- 실제 사용자 음성, credential, token, 개인 정보와 비공개 corpus를 Git에 넣지 않는다.
- 저장소에는 사용 조건이 명확한 공개·합성 음원 또는 비가역 manifest와 digest만 둔다.
- ToneMate는 의학적 음치·성대 질환을 진단하지 않는다. 통증, 쉰 목소리 또는 피로가 있으면 발성 세션을 중단한다.

## ChainShield #1470 boundary

`qa/chainshield/**`에는 해당 하위 트리의 `AGENTS.md`가 추가 적용된다.

- 제품 PASS와 ChainShield PASS를 별도로 판정한다.
- #1470 증적은 clean하고 remote에 push된 full product SHA에 결속한다.
- workspace, local path, Git dependency 또는 이전 cache로 해석된 소비 결과를 ChainShield E2E PASS로 인정하지 않는다.
- 정상 경로는 실제 제품 package와 앱 build를 사용한다. 손상·차단 조건은 제품 dependency graph와 분리된 결정적 fixture로만 검증한다.
- #1470에서 발견한 ChainShield 결함 수정은 별도 ChainShield 이슈·브랜치·PR로 진행한다.

## Git and workspace safety

- 사용자가 만든 변경을 보존하고 관련 없는 파일을 수정하지 않는다.
- 파괴적인 Git 명령과 광범위한 삭제를 사용하지 않는다.
- 생성 산출물, cache, secret과 개인 음성은 커밋하지 않는다.
- 상태를 보고할 때 문서 완료, 코드 완료, 제품 검증과 #1470 증적 완료를 구분한다.

## Completion

작업 완료를 주장하려면 변경 범위에 맞는 문서 링크, test/build 결과와 남은 open decision을 보고한다. 코드가 없는 문서 기준선은 제품 구현 완료로 표현하지 않는다.
