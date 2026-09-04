# ToneMate·ChainShield 다중 저장소 작업공간 계약

- 버전: 1.0
- 기준일: 2026-09-04
- 상태: 실행 기준선
- workspace 파일: `/Users/souluk/kugnus-idea/ToneMate-ChainShield.code-workspace`
- 관련 실행 이슈: [ChainShield #1470](https://github.com/cywell-rnd-team/chainshield/issues/1470)

## 1. 목적과 경계

ToneMate 제품을 개발하면서 발견한 ChainShield 결함을 별도 이슈로 등록·수정·배포·재검증하되, 두 저장소의 코드와 Git 이력을 섞지 않는다.

multi-root workspace는 두 저장소를 한 화면에서 탐색하는 로컬 편의 수단이다. 다음을 의미하지 않는다.

- 하나의 Git monorepo
- Git submodule 또는 subtree
- ToneMate에서 ChainShield source를 참조하는 path·Git dependency
- 두 저장소를 묶는 하나의 commit·branch·PR
- #1470 안에서 앱 코드나 ChainShield 수정 코드를 함께 개발하는 작업장

매 작업은 정확히 하나의 쓰기 대상 worktree를 가진다. 같은 workspace에 열린 다른 repository root는 읽기 전용 참고 대상으로 취급한다.

## 2. 저장소·이슈·작업장 식별

| 용도 | 기준 checkout | issue 표기 | worktree 경로 | branch 예시 |
|---|---|---|---|---|
| ToneMate 제품 기능 | `/Users/souluk/kugnus-idea/tonemate` | `ToneMate#<번호>` | `tonemate/.worktrees/issue_<번호>` | `feat/<번호>-<범위>` |
| ToneMate 결함·QA | `/Users/souluk/kugnus-idea/tonemate` | `ToneMate#<번호>` | `tonemate/.worktrees/issue_<번호>` | `fix/<번호>-<범위>` 또는 `test/<번호>-<범위>` |
| ChainShield 결함 | `/Users/souluk/kugnus-idea/Cywell/chainshield` | `ChainShield#<번호>` | `Cywell/chainshield/.worktrees/issue_<번호>` | `fix/<번호>-<범위>` |
| #1470 실행 | worktree 없음 | `ChainShield#1470` | 생성 금지 | 생성 금지 |

같은 숫자의 이슈가 두 저장소에 있어도 repository prefix와 서로 다른 `.worktrees` 부모 경로로 구분한다. 문서·commit·PR·run manifest에서 bare `#123`만 쓰지 않고 저장소가 문맥상 자명하지 않으면 `ToneMate#123`, `ChainShield#123`처럼 적는다.

#1470은 고정 제품 commit의 실행·증적 장부이므로 `issue_1470` worktree나 `fix/1470-*` branch를 만들지 않는다. 실행에서 실제 ChainShield 결함이 확인되면 먼저 별도 ChainShield 이슈 번호를 확보하고 그 번호로 작업장을 만든다.

## 3. 이슈 발행 전 분류

### ToneMate 이슈

- 일반 제품 build에서도 같은 문제가 발생한다.
- 앱 UX, DSP, native integration, packaging 또는 ToneMate QA 하네스가 원인이다.
- ToneMate 수용 기준이나 기술검증 gate를 위반한다.

### ChainShield 결함 후보

아래 조건을 모두 확인한다.

1. 같은 clean ToneMate commit의 일반 제품 경로는 PASS다.
2. 확인된 ChainShield 배포에서만 실패한다.
3. 최초 실패 endpoint·request ID·응답·상태 전이·digest를 특정했다.
4. OPEN/CLOSED 이슈에서 오류 문구·endpoint·source path·근본원인을 검색했다.
5. #1470 완료 조건을 직접 위반한다.
6. 문제 상태 screenshot 또는 동일 역할의 실제 API·native·log 증거가 있다.

이 조건 전에는 ChainShield worktree를 만들지 않고 ToneMate run evidence에 조사 상태로 남긴다.

## 4. 작업장 생성 절차

### 4.1 공통 사전 확인

이슈 번호를 확보한 뒤 기준 checkout에서 다음을 읽기 전용으로 확인한다.

```bash
git status --short --branch
git worktree list --porcelain
git branch --list '<branch-name>'
git check-ignore -v '.worktrees/issue_<이슈번호>'
test ! -e '.worktrees/issue_<이슈번호>'
```

- 같은 issue path·branch·worktree가 있으면 새로 만들지 않고 기존 작업을 확인한다.
- 기준 checkout의 사용자 변경을 stash, reset, clean 또는 checkout하지 않는다.
- `.worktrees/`는 추적 `.gitignore`가 아니라 각 저장소의 `.git/info/exclude`에만 등록한다.
- worktree 생성은 현재 편집기나 Codex의 cwd를 자동으로 바꾸지 않는다.

### 4.2 ToneMate 제품 worktree

ToneMate remote가 생긴 뒤 `origin/main`을 기준으로 만든다.

```bash
git -C /Users/souluk/kugnus-idea/tonemate fetch origin main

git -C /Users/souluk/kugnus-idea/tonemate worktree add \
  -b 'feat/<이슈번호>-<범위>' \
  '/Users/souluk/kugnus-idea/tonemate/.worktrees/issue_<이슈번호>' \
  origin/main
```

결함이면 `feat/` 대신 `fix/`, QA 하네스면 `test/`를 사용한다. 하나의 이슈에 branch prefix가 달라져도 worktree는 하나만 둔다.

### 4.3 ChainShield 결함 worktree

기존 ChainShield 가이드와 같이 최신 `origin/dev`를 기준으로 만든다.

```bash
git -C /Users/souluk/kugnus-idea/Cywell/chainshield fetch origin dev

git -C /Users/souluk/kugnus-idea/Cywell/chainshield worktree add \
  -b 'fix/<이슈번호>-<범위>' \
  '/Users/souluk/kugnus-idea/Cywell/chainshield/.worktrees/issue_<이슈번호>' \
  origin/dev
```

기준 `dev` checkout에서 `pull`, branch 전환, reset, clean 또는 stash를 실행하지 않는다. 기준 checkout이 dirty여도 사용자 변경을 보존한 채 fetch한 원격 ref에서 새 worktree를 만든다.

### 4.4 생성 직후 확인

```bash
git -C '<issue-worktree>' rev-parse --show-toplevel
git -C '<issue-worktree>' status --short --branch
git -C '<base-repository>' worktree list --porcelain
```

구현을 시작할 Codex/terminal의 cwd가 정확한 issue worktree인지 확인하고 그 worktree의 `AGENTS.md`를 다시 읽는다.

## 5. Workspace 사용 규칙

기본 workspace에는 다음 기준 checkout만 상시 등록한다.

- `ToneMate · main baseline`
- `ChainShield · dev baseline`

issue worktree를 만든 뒤 현재 작업장 하나만 workspace에 추가한다.

```json
{
  "name": "ChainShield #<이슈번호> · fix",
  "path": "Cywell/chainshield/.worktrees/issue_<이슈번호>"
}
```

ToneMate 작업장은 `ToneMate #<이슈번호> · feat|fix|test`로 표시한다. 종료된 worktree folder는 workspace에서 제거하되, 이 동작을 실제 Git worktree 삭제로 오해하지 않는다.

multi-root workspace를 열었다는 사실만으로 작업 대상을 선택한 것이 아니다. 매 세션 시작 시 다음을 확인한다.

```bash
pwd
git rev-parse --show-toplevel
git branch --show-current
git status --short --branch
```

한 agent·terminal은 한 worktree에서만 쓰기 작업을 한다. 다른 agent가 필요하면 서로 다른 worktree와 branch를 사용하며 같은 build directory, dependency install 또는 포트를 공유하지 않는다.

## 6. 교차 저장소 수정 흐름

```text
ToneMate issue worktree에서 제품 구현
  → 일반 제품 경로 PASS
  → clean ToneMate commit push
  → #1470 run
  → ChainShield 결함 후보 재현·기존 이슈 검색
  → ChainShield 결함 이슈 발행·번호 확보
  → ChainShield issue worktree 생성
  → isolated local DB에서 focused fix·검증
  → ChainShield PR·리뷰·머지·승인된 배포
  → 원래 ToneMate commit으로 #1470 재실행
  → after evidence와 PR을 결함 이슈·#1470에 연결
```

두 저장소를 동시에 바꿔야 해도 cross-repository atomic commit은 만들지 않는다.

- ToneMate 변경과 ChainShield 변경은 각각 독립 이슈·branch·commit·PR을 갖는다.
- 각 PR 본문에 상대 repository의 고정 commit 또는 issue URL을 의존성으로 기록한다.
- ChainShield PR은 결함 이슈만 `Closes`하고 #1470은 `Refs`로 연결한다.
- ChainShield 수정 전후 비교는 같은 ToneMate full SHA, package coordinate와 digest를 사용한다.
- ToneMate product fix 때문에 source SHA나 bytes가 달라지면 새 #1470 run으로 시작한다.

## 7. 실행·환경 격리

- #1470 실제 판정은 배포된 ChainShield와 clean·push된 ToneMate commit을 사용한다.
- ChainShield code fix의 로컬 검증은 issue worktree와 전용 isolated PostgreSQL을 사용한다.
- 로컬 ChainShield API/Worker를 A40 PostgreSQL에 연결하지 않는다.
- 기준 checkout, issue worktree와 #1470 consumer의 cache/home/build/evidence 디렉터리를 분리한다.
- 포트는 run 또는 issue 단위로 예약하고 기존 사용자 프로세스를 종료하지 않는다.
- credential·token·개인정보·음성 원본은 workspace 설정, Git, log와 screenshot에 넣지 않는다.

## 8. WIP와 충돌 방지

- 동시에 쓰기 작업 중인 ToneMate 제품 worktree는 1개다.
- 동시에 조사·수정 중인 ChainShield 결함 worktree는 1개다.
- #1470 run 도중 발견한 주변 개선은 현재 결함 worktree에 섞지 않는다.
- 동일 근본원인은 포맷별 이슈·worktree로 복제하지 않는다.
- 한 결함이 여러 포맷에 영향을 주면 하나의 ChainShield 이슈·worktree에서 영향 포맷을 기록한다.
- Epic이 하나의 PR·배포·롤백 단위를 명시한 경우에만 Epic 번호 worktree 하나를 사용하며 하위 이슈 worktree를 추가하지 않는다.

## 9. 작업 완료와 정리

worktree 정리는 다음이 모두 참일 때만 수행한다.

1. 변경이 commit·push되어 있고 PR 상태가 확인됐다.
2. 필요한 focused test·build와 screenshot evidence가 연결됐다.
3. `git status --short`가 clean이다.
4. 미푸시 commit과 보존할 사용자 파일이 없다.
5. ChainShield 결함이면 배포 후 #1470 재검증이 끝났다.

그 뒤 workspace에서 issue folder를 제거하고 기준 저장소에서 `git worktree remove`, merge가 확인된 local branch에는 `git branch -d`, 마지막으로 `git worktree prune`을 사용한다. `--force`나 폴더 직접 삭제는 보존할 변경이 없음을 별도 확인하지 않는 한 사용하지 않는다.
