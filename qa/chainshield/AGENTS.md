# ToneMate ChainShield QA Instructions

## Scope

이 문서는 `qa/chainshield/**`에만 적용하며 루트 `AGENTS.md`의 제품·안전·개인정보 규칙을 강화한다.

## Evidence identity

- 각 run은 clean하고 remote에 push된 ToneMate full SHA를 사용한다.
- ChainShield 배포 full SHA, 제품 버전, DB schema version·dirty flag와 native client 버전을 함께 기록한다.
- 모든 artifact는 format, coordinate, version, source commit, file digest와 ChainShield manifest/digest에 결속한다.
- `source_dirty=true`, 짧은 SHA 또는 remote에서 재현할 수 없는 commit은 실행 대상이 아니다.

## Consumer isolation

- #1470 소비자는 모노레포 밖의 run별 임시 디렉터리로 export한다.
- run별 home, cache, credential store와 evidence directory를 분리한다.
- workspace, local path, Git dependency와 이전 cache로 제품 package가 해석되지 않음을 검증한다.
- 전역 package cache를 삭제하지 않는다. 이 run이 만든 임시 경로만 정리한다.

## Real product path

- 정상 Hosted·Proxy·Group 검증에는 같은 제품 commit의 실제 package와 실제 앱 build를 사용한다.
- ChainShield 테스트를 위해 제품에 필요 없는 외부 의존성을 추가하지 않는다.
- 손상 archive, checksum mismatch, 위험 패턴과 정책 차단은 제품 graph 밖의 결정적 negative fixture에서만 사용한다.
- 실제 악성코드는 실행하지 않는다.

## Secrets and publish safety

- API key, token과 upstream credential을 CLI 인자, stdout, screenshot, manifest 또는 Git에 기록하지 않는다.
- 비밀은 환경변수나 안전한 credential store로 주입하고 evidence 게시 전에 redaction을 확인한다.
- 한 번 게시한 coordinate/version의 byte를 교체하지 않는다. 변경은 새 버전으로 발행한다.

## Execution boundary

- 이 하네스는 ChainShield 운영 배포, DB migration, 서비스 재구성을 수행하지 않는다.
- Hosted, Proxy cold·warm·purge·rewarm, Group, Scan·Policy, 재스캔, 예외와 감사 결과를 별도 단계로 기록한다.
- 제품 PASS와 ChainShield PASS를 독립적으로 판정한다.
- FAIL은 기존 이슈의 endpoint, 상태 전이, source path와 근본원인을 먼저 검색한다.
- 같은 근본원인은 새 포맷 이슈를 만들지 않고 기존 이슈에 영향과 증적을 추가한다.
- ChainShield 수정은 ChainShield 저장소의 별도 이슈·브랜치·PR에서 수행한다.

## Evidence publication

- run manifest에는 `run_id`, 양쪽 full SHA, coordinate, digest, native 결과, 선택 Group member와 관련 audit ID를 포함한다.
- screenshot은 실제 UI/API/native 결과와 같은 run에 결속하고 비밀·개인정보를 제거한다.
- PASS, FAIL, BLOCKED와 사유 있는 N/A를 구분한다.
- 문서·하네스 완료를 #1470 실행 완료로 보고하지 않는다.
