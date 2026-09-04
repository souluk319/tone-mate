# ToneMate Hosted 웹 업로드

- 게시 주체: Kugnus Lab
- 게시 목적: ToneMate 내부 prerelease 패키지의 Private Hosted 유통
- 초기 버전: `0.1.0-alpha.1`
- 실제 업로드 담당: 저장소 관리자
- 비밀 원칙: API 키는 파일·명령 인자·스크린샷에 기록하지 않는다.

`scripts/build-hosted-upload-artifacts.sh`를 실행하면 Git에서 제외되는
`dist/hosted-upload/`에 세 파일, 포맷별 manifest와 `SHA256SUMS`가 생성된다.
스크립트는 dirty worktree에서는 실행을 거부한다. 같은 버전은 같은 bytes에만
결속하며 내용이 달라지면 새 prerelease 버전을 사용한다.

## Conan

- 저장소: `tm1470-conan-hosted`
- 파일: `tonemate-pitch-core-0.1.0-alpha.1.tgz`
- 좌표: `tonemate-pitch-core/0.1.0-alpha.1@tonemate/stable`

Hosted의 `업로드` 탭에서 Conan 캐시 아카이브를 선택한다. 패키지명, 버전,
사용자, 채널, recipe revision과 binary package revision이 자동 분석된 뒤에만
업로드한다.

## Swift

- 저장소: `tm1470-swift-hosted`
- 파일: `tonemate.apple-audio-0.1.0-alpha.1.zip`
- 패키지: `tonemate.apple-audio`
- 버전: `0.1.0-alpha.1`
- ZIP 구조: 최상위 디렉터리는 파일명과 동일한
  `tonemate.apple-audio-0.1.0-alpha.1/`이며, 그 바로 아래에
  `Package.swift`가 있어야 한다. 이 구조가 ChainShield 웹 업로드의
  Swift 좌표 자동 인식 계약이다.
- 아티팩트 경로: 비워 둔다.

Hosted의 `업로드` 탭에서 ZIP을 선택한다. UI가 패키지와 버전을 자동으로
채운 것을 확인한 뒤 업로드하며, 자동 인식되지 않은 파일은 수동 좌표로
우회하지 않는다. ZIP에는 단일 package root 바로 아래의 `Package.swift`와
실제 Swift source가 포함된다.

## CocoaPods

- 저장소: `tm1470-cocoapods-hosted`
- 파일: `ToneMatePitch-0.1.0-alpha.1.zip`
- 패키지: `ToneMatePitch`
- 버전: `0.1.0-alpha.1`
- 아티팩트 경로: `hosted/ToneMatePitch/0.1.0-alpha.1/ToneMatePitch-0.1.0-alpha.1.zip`

Hosted의 `업로드` 탭에서 ZIP을 선택한다. ZIP에는 실제 공유 Swift source와
정확히 하나의 `ToneMatePitch.podspec.json`이 포함되며 podspec의 `source.http`는
위 canonical Hosted 경로를 가리킨다.

## 업로드 직전 확인

1. 현재 ToneMate source commit이 clean하고 remote에 push되어 있는지 확인한다.
2. `(cd dist/hosted-upload && shasum -a 256 -c SHA256SUMS)`가 모두 성공해야 한다.
3. 세 파일의 버전과 UI 입력 버전이 정확히 일치해야 한다.
4. 업로드 성공 화면과 package detail에는 API 키가 보이지 않아야 한다.
5. 업로드 후 표시되는 digest를 `SHA256SUMS`와 대조한다.
