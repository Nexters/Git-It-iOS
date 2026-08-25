# 빠른 검증 가이드: 온보딩·로그인·튜토리얼 App 통합

## 사전 조건

- 저장소 루트에서 실행한다.
- `iPhone 17 Pro Max` Simulator가 설치되어 있어야 한다. 없다면 설치된 iOS 26 기기의 UUID를
  `GIT_IT_TEST_DESTINATION`에 지정한다.
- `make tuist` 후 FeatureTests와 AppTests가 shared scheme Test Action에 포함됐는지 확인한다.
- 상태 계약은 [data-model.md](./data-model.md), 흐름 계약은
  [contracts/onboarding-flow.md](./contracts/onboarding-flow.md)를 기준으로 한다.

```sh
xcrun simctl list devices available | rg 'iPhone 17 Pro Max'
make tuist
```

## 자동 검증

project build runner는 action 하나만 받으며 scheme 이름을 추가 인자로 받지 않는다. 전체 검증은
동일 DerivedData를 공유하므로 다음 순서를 유지한다.

```sh
project_build_runner=$(./tools/repository-paths/bin/repository-paths.sh GIT_IT_PROJECT_BUILD_RUNNER)
GIT_IT_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro Max' "$project_build_runner" build
GIT_IT_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro Max' "$project_build_runner" compile
GIT_IT_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro Max' "$project_build_runner" test
```

필요하면 전체 unit/UI 묶음을 각각 다음처럼 분리해 진단한다.

```sh
GIT_IT_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro Max' "$project_build_runner" compile-unit
GIT_IT_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro Max' "$project_build_runner" test-unit
GIT_IT_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro Max' "$project_build_runner" compile-ui
GIT_IT_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro Max' "$project_build_runner" test-ui
```

예상 결과는 모든 명령 exit 0, production build 전체 성공, 모든 test scheme build-for-testing 및
test-without-building 성공이다. 실제 실행하지 않은 항목은 PR 검증 목록에 표시하지 않는다.

## 필수 자동 시나리오

1. 미인증, restore failure, member 404, profile partial null 두 조합, complete profile을 fake로 주입해
   root와 호출 횟수를 검증한다.
2. legal 미동의/취소/부분 선택/유효 저장 consent/버전 mismatch/외부 브라우저 열기 요청 실패
   조건에서 sign-in 호출 횟수와 sheet 상태를 검증하고, sign-in 단계 이탈 뒤 stale 응답의 route
   변경이 0회인지 확인한다.
3. position/career 선택, career back 보존, position back sign-out, 반복 submit, 실패 retry, 성공
   MainShell delegate를 검증한다.
4. DTO null, unknown non-null raw, MEMBER-001 404, transport, 5xx, decoding을 각각 계약 테스트한다.
5. logout 전후 consent 동일성, 문서별 version 변경, 저장 자료의 계정 식별자 부재를 검증한다.
6. App composition 생성 횟수와 `Hello, world!`/sample root 부재를 검증한다.

## Preview와 Figma 비교

각 기능 View의 파일 하단 Preview를 열고 `iPhone 17 Pro Max`에서 idle, selected, loading, error를
독립 재현한다. Figma 비교는 section이 아니라 지정 개별 node를 사용한다.

- Tutorial 1페이지: `779:33450`
- Tutorial 2페이지: `779:33529`
- Tutorial 3페이지: `779:33564`
- 약관 전체 선택/활성 계속하기: `786:38332`
- 분야 선택/활성 다음 버튼: `737:10367`
- Career 미선택: `737:10358`
- Career 첫 카드 선택/활성 다음 버튼: `737:10349`

각 비교 결과는 일치, 수정 완료, 승인된 차이 중 하나로 기록한다. 승인된 차이는 이유와 영향을
PR에 남긴다. Figma의 Google 로그인 표현, 개인정보 관련 명칭, 분야 화면 닫기 표현과 360×800
frame은 각각 명세의 Apple 로그인, `개인정보 처리방침`, sign-out 복귀 동작, `iPhone 17 Pro Max`
기준을 우선하는 승인된 차이로 기록한다.

## 수동 접근성 검증

1. 작은 지원 iPhone과 가장 큰 접근성 Dynamic Type에서 tutorial·legal·curation의 문구와 CTA에
   스크롤로 접근 가능한지 확인한다.
2. VoiceOver로 page indicator의 현재 페이지, 카드의 선택 상태, link 오류와 retry action이 색상
   없이 전달되는지 확인한다.
3. Reduce Motion을 켜고 splash 및 page 전환에서 장식 motion만 축소되고 순서와 기능이 유지되는지
   확인한다.
4. link 미열람 및 외부 브라우저 열기 요청 실패 상태에서도 필수 선택 후 continue와 Apple sign-in이
   가능한지 확인한다. 브라우저가 열린 뒤의 page load 결과는 앱 검증 항목에 포함하지 않는다.

수동 결과에는 기기/OS, 설정, Preview 또는 화면 상태, 결과와 증거 경로를 기록한다.
