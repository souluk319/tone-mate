# ToneMate 개발 저장소 연결

개발용 소비 주소는 아래 Group이다. 문제를 분리할 때 같은 패키지를 Hosted에서
직접 받아 비교한다. 저장소 설정과 업로드는 관리자가 수행한다.

| Client | Endpoint | 내부 패키지 |
|---|---|---|
| Conan 2.31.1 | `https://chainshield.cywell.co.kr/conan/tm1470-conan-group` | `tonemate-pitch-core/0.1.0-alpha.1@tonemate/stable` |
| Apple Swift 6.0.3 | `https://chainshield.cywell.co.kr/swift/tm1470-swift-group` | `tonemate.apple-audio@0.1.0-alpha.1` |
| CocoaPods 1.16.2 | `https://chainshield.cywell.co.kr/cocoapods/tm1470-cocoapods-group` | `ToneMatePitch@0.1.0-alpha.1` |

Node의 `--env-file`로 기존 `.env`를 읽으며 키를 인자에 복사하지 않는다.
현재 작업은 `.worktrees/issue_1`에서 실행한다. 아래 `.env`는 기준 checkout의
기존 파일이다. Conan 실행 파일은 `TONEMATE_CONAN`으로 지정할 수 있으며 기본은
`~/.local/share/chainshield-tools/conan-2.31.1/bin/conan`이다.

```sh
node --env-file=../../.env scripts/connect-chainshield.mjs inspect
node --env-file=../../.env scripts/connect-chainshield.mjs conan
node --env-file=../../.env scripts/connect-chainshield.mjs swift
node --env-file=../../.env scripts/connect-chainshield.mjs cocoapods
# Hosted 비교: 마지막 인자로 hosted 추가
node --env-file=../../.env scripts/connect-chainshield.mjs swift hosted
```

스크립트는 매번 저장소 밖의 새 임시 디렉터리에 consumer, 인증 파일과 캐시를
만들고 결과 경로를 출력한다. 인증 파일은 0600이며 로그에서 키를 제거한다.
Conan은 binary를 내려받아 C ABI를 링크·실행하고, Swift는 registry package를
resolve해 모듈을 실행하며, CocoaPods는 설치 후 iOS Simulator용 pod를 컴파일한다.
실제 앱 lane이 생기기 전의 연결 확인이므로 #1470의 실사용 Build PASS가 아니다.

게시된 버전은 재생성하거나 덮어쓰지 않는다. 서버의 revision/digest와 해당 게시
당시 source commit을 확인한다. 연결 실패 시 Hosted와 Group의 최초 실패 지점을
비교하고, 기존 OPEN/CLOSED 이슈 검색 후 확인된 ChainShield 결함을 별도 이슈로
등록한다. 요청 ID와 native 로그를 남기며 인증 실패·정책 차단을 서버 결함으로
단정하지 않는다.
