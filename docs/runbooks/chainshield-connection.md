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

## 2026-09-08 연결 결과

Production `1.0.1`, 배포 SHA `7d97c3239d9b7fa99b1e069fe6df06c7839643c1`,
시스템 화면 schema `192 (192..192)`에서 확인했다. 9개 저장소는 active이며
세 Hosted에 alpha.1 패키지가 게시되어 있다.

| 경로 | 결과 |
|---|---|
| Conan Group | 인증, recipe/binary 다운로드, C++ 링크·A4=440 Hz 실행 성공 |
| CocoaPods Group | `pod install` 및 iOS Simulator pod build 성공 |
| Swift Hosted | `--netrc` 적용 후 resolve, 다운로드, module import·실행 성공 |
| Swift Group | 인증 후 `Package.swift`에서 502; 연결 미완료 |

- [#1734](https://github.com/cywell-rnd-team/chainshield/issues/1734): macOS Swift
  Private 안내에 `--netrc` 누락. 현재 연결 스크립트에는 옵션을 반영했다.
- [#1735](https://github.com/cywell-rnd-team/chainshield/issues/1735): Swift Proxy의
  upstream 404가 502로 바뀌어 뒤 Hosted로 진행하지 못함.
- Swift Group은 현재 Proxy 1순위, Hosted 2순위다. 두 continue 옵션 모두 true인
  상태에서 재현했으며 서버 설정은 변경하지 않았다.
- Swift 개발 준비는 `swift hosted` 명령으로 확인 가능하다. Group 재검증은
  #1735 수정 배포 후 동일 설정과 좌표로 수행한다.
- 이 결과는 초기 내부 패키지 연결 확인이다. Flutter 앱과 실제 오디오 capture는
  아직 없으며, 다음 제품 작업은 #1의 Flutter 앱 골격 및 Android/iOS hello build다.
