# ToneMate

> Pitch maketh tone.

ToneMate는 노래 초보자가 음정을 못 맞히는 원인을 듣기, 목표음 진입, 음 유지, 음정 이동으로 나눠 이해하고 개인 음역의 짧은 훈련 뒤 화면 도움 없이 개선을 확인하는 iOS·Android 모바일 코치다.

## 현재 상태

이 저장소는 2026-09-04에 문서 우선 모노레포로 시작했다. 현재 제품 코드와 패키지 산출물은 없으며, 제품·기술검증·ChainShield #1470 실행 계약만 정본화되어 있다.

`ToneMate`는 개발 작업명이다. 공개 출시명으로 확정하기 전 상표, 앱스토어, 도메인과 유사 서비스 충돌을 별도로 검토한다.

## 정본 문서

1. [제품 명세](docs/specs/product-spec-v1.md) — 사용자 가치, MVP, 안전·개인정보, 수용 기준
2. [기술검증 계획](docs/specs/technical-validation-plan-v1.md) — 오디오·피치 검출·성능·기기 검증 게이트
3. [제품·QA 추적성](docs/specs/product-qa-traceability-v1.md) — 요구사항에서 코드·시험·증적까지의 연결
4. [ChainShield #1470 E2E 명세](docs/specs/chainshield-1470-e2e-spec-v1.md) — Conan·Swift·CocoaPods 실사용 검증
5. [현재 설계](DESIGN.md) — 구현 상태와 일치해야 하는 아키텍처 정본
6. [개발·이슈 운영 계획](docs/plans/development-workflow.md) — 제품 구현, #1470 실행과 결함 수정의 분리 절차
7. [#1470 착수 계획](docs/plans/issue-1470-kickoff-plan.md) — 이슈 본문 필수 검증을 포맷별 제품 산출물과 실행 단계에 매핑

문서의 역할과 우선순위는 [명세 인덱스](docs/specs/README.md)를 따른다. 조사 자료는 [연구 인덱스](docs/research/README.md)에 분리되어 있으며 정본 요구사항을 직접 변경하지 않는다.

## 계획된 제품 경계

```text
apps/tonemate/                 Flutter iOS·Android 앱
packages/pitch_core/           C++20 피치 분석 코어·Conan recipe
packages/apple_audio/          iOS AVAudioEngine·Swift package
packages/tonemate_pitch/       앱 내부 Flutter plugin·Dart package
distribution/cocoapods/        같은 iOS 코드의 CocoaPods 호환 배포
bench/                         DSP corpus·benchmark
qa/chainshield/                #1470 실행·증적 하네스
```

제품은 실제 사용자 가치를 위해 개발한다. ChainShield #1470은 고정된 제품 commit의 Conan·Swift·CocoaPods 게시·소비·빌드 과정을 검증하는 병행 QA이며 제품 구조를 지배하지 않는다. Flutter/Dart의 Pub 도구 사용은 제품 build 경로로 유지하지만 #1470의 Pub 저장소 검증에는 포함하지 않는다.

## 다음 구현 단계

1. 도구 버전과 지원 기기 기준선을 확정한다.
2. Flutter 앱 셸과 C++ `pitch_core`의 최소 빌드 경계를 만든다.
3. 합성 신호 benchmark로 YIN 기준 구현을 검증한다.
4. iOS·Android 실제 마이크 입력과 지연·신뢰도 게이트를 검증한다.
5. 제품에 필요한 패키지 경계가 빌드 가능해지는 순서대로 #1470 실행을 병행한다.

저장소 작업 규칙은 [AGENTS.md](AGENTS.md)를 따른다.
