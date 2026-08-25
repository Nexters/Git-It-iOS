# UI·Domain 경계 계약: 온보딩 흐름

## Root 입력과 출력

- App은 launch 시 production graph를 한 번 만들고 root에 Domain UseCase protocol을 명시 주입한다.
- root는 launch당 `RestoreSessionUseCase`를 자동 1회 호출한다.
- App root는 `restoring`, `onboarding`, `mainShell`만 소유한다. 복구 가능한 실패는 onboarding 내부
  `restoreError`로 가며 retry 입력만 추가 복구 1회를 허용한다.
- 인증 결과 뒤 `FetchMemberProfileUseCase`를 호출한다. 계약된 404는 세션 정리 후 신규 가입,
  nullable profile은 curation, 완성 profile은 MainShell로 연결한다.

## Feature initializer 계약

Onboarding Feature는 다음 역할의 protocol을 initializer에서 받는다.

- session restore
- Apple sign-in
- 명시적 sign-out/local authentication cleanup
- member profile fetch
- whole curation completion
- 현재 정책 manifest 조회
- 설치 단위 정책 consent 조회·저장
- bundle version 표시 값 또는 이를 제공하는 공급자 중립 값

View는 위 계약을 직접 호출하지 않고 Feature action만 전송한다.

## 인증 액션 결과 타입

`AuthenticationOutcome`은 `ObserveAuthenticationOutcomesUseCase` 전용 상태 조회 타입
(`authenticated`/`unauthenticated`/`recoverableFailure`)으로 유지한다. session restore, Apple
sign-in, 명시적 sign-out은 액션이므로 이 타입을 재사용하지 않고 각각 전용 결과 타입
(`RestoreSessionResult`, `SignInResult`, `SignOutResult`)을 반환한다. 케이스와 근거는
[data-model.md의 "인증 액션 결과 타입"](../data-model.md)을 따른다. `SignInResult.cancelled`은
Apple 인증 취소에서만 발생하며 `retryableFailure`와 구분된다.

## Phase 계약

```text
splash
  ├─ unauthenticated ─> tutorial(page: 1)
  ├─ recoverable failure ─> restoreError ── retry ─> splash
  └─ authenticated ─> profile lookup
       ├─ complete ─> MainShell delegate
       ├─ nullable field ─> position ─> career ─> completing ─> MainShell delegate
       └─ member 404 ─> local cleanup ─> tutorial(page: 1)

tutorial(page: 3) ─> valid consent ? signIn : legalAgreement
legalAgreement ── accept all/continue ─> signIn
  └─ signIn success + needsCuration=true  ─> position ─> career ─> completing ─> MainShell delegate
  └─ signIn success + needsCuration=false ─> MainShell delegate (profile 조회 없이 이동)
position ── back/signOut success ─> tutorial(page: 3)
career ── back ─> position (selection preserved)
```

동시에 둘 이상의 phase를 표시하지 않는다. 각 비동기 요청은 identity를 가지며 현재 phase/request와
다른 늦은 응답은 상태를 바꾸지 않는다.

**로그인 직후 curation 판정**: `LoginResponse.needsCuration` (서버 schema에 명시됨)으로 판정한다.
`true`이면 curation, `false`이면 별도 profile 조회 없이 MainShell로 이동한다.
**세션 복구 경로 curation 판정**: `FetchMemberProfileUseCase`의 `position`/`careerLevel` null 여부로
판정한다. login 응답이 없으므로 `needsCuration`을 사용할 수 없다.

## Career 표시 계약

| Domain | 제목 | 설명 |
|---|---|---|
| `entry` | 입문 | 프로젝트 코드를 처음 살펴봐요. |
| `junior` | 주니어 | 작은 기능 단위로 코드를 이해할 수 있어요. |
| `midLevel` | 미들 | 프로젝트 구조와 흐름을 함께 살펴봐요. |
| `senior` | 시니어 | 설계 의도와 변경 영향을 분석할 수 있어요. |

현재 미커밋 tree의 `beginner`는 Domain 단계에서 최종 공개 이름 `entry`로 변경한다.
`CareerLevel.unknown`은 정의하거나 지원하지 않는다.

## 정책 계약

- 개인정보 처리방침과 서비스 이용 약관은 각각 별도 필수 항목이다.
- 문서 ID·version 일치가 유효성의 유일한 기준이며 외부 브라우저 열기 성공은 조건이 아니다.
- manifest는 개인정보 처리방침 `privacy-policy`/`1`, 서비스 이용 약관
  `terms-of-service`/`1`을 제공한다.
- 외부 브라우저 열기 요청 실패는 문서별 오류와 retry action을 제공하되 선택 상태·continue·sign-in
  조건을 바꾸지 않는다. 브라우저가 열린 뒤의 page load 결과는 앱이 추적하지 않는다.
- sheet 취소/닫기는 consent를 저장하거나 sign-in을 호출하지 않는다.
- 저장 자료는 회원/Apple 계정 식별자를 포함하지 않고 로그아웃 뒤에도 유지한다.

## 중복 요청과 오류 계약

- restore, sign-in, sign-out, curation은 각각 진행 중 동일 action을 무시한다.
- restore와 sign-in은 request identity가 현재 phase/request와 다르면 늦은 응답을 무시한다.
- sign-in은 `SignInResult`의 `success`, `cancelled`, `retryableFailure`를 구분한다.
- restore는 `RestoreSessionResult`의 `authenticated`, `unauthenticated`, `recoverableFailure`를
  구분한다.
- sign-out은 `SignOutResult`의 `success`, `retryableFailure`를 구분하며 실패 시 인증 상태를
  불명확하게 바꾸지 않는다.
- curation 실패는 두 선택을 보존한다.
- 404 cleanup 실패는 신규 가입이나 Apple sign-in으로 진행하지 않고 retryable error를 표시한다.
- policy 외부 브라우저 열기 요청 실패는 인증 failure로 변환하지 않는다.

## Preview·접근성 계약

- 각 기능 대상 View 파일 하단 Preview는 `iPhone 17 Pro Max` frame과 deterministic dependency를 쓴다.
- Figma 대응 이름에는 node ID, 그 외에는 idle/selected/loading/error 상태 ID를 포함한다.
- interactive control은 최소 44×44pt이고 selection/page/error는 label/value/trait로도 전달한다.
- 작은 화면과 Dynamic Type에는 ScrollView 등 접근 가능한 탐색을 제공한다.
- Reduce Motion에서는 장식 transition만 축소하고 정보·action 순서를 유지한다.
- 필수 Figma 비교는 tutorial `779:33450`·`779:33529`·`779:33564`, 약관 전체 선택 `786:38332`,
  분야 선택 `737:10367`, Career `737:10358`·`737:10349`를 사용한다. Figma의 Google 로그인 표현,
  개인정보 관련 명칭, 분야 화면 닫기 표현과 360×800 frame은 명세 우선의 승인된 차이다.

## API 서버 raw value 계약 (Data 레이어 책임)

`POST /api/v1/auth/login/apple` 및 `POST /api/v1/members/me/curation`의 `CurationRequest`가
사용하는 서버 raw value는 아래 표와 같다. Domain 공개 이름과 다르면 Data DTO 레이어에서 명시 변환한다.

| Domain | 서버 raw value | 비고 |
|---|---|---|
| `MemberPosition.backend` | `BACKEND` | — |
| `MemberPosition.frontend` | `FRONTEND` | — |
| `MemberPosition.ios` | `IOS` | — |
| `MemberPosition.android` | `ANDROID` | — |
| `CareerLevel.entry` | `ENTRY` | — |
| `CareerLevel.junior` | `JUNIOR` | — |
| `CareerLevel.midLevel` | `MIDDLE` | **이름 불일치 — 명시 변환 필수** |
| `CareerLevel.senior` | `SENIOR` | — |

위 목록에 없는 non-null raw value는 decoding 오류로 처리한다. `MemberPosition.web`·`.unknown`은
서버 API에 없다. `GET /api/v1/members/me` 응답의 `position`·`careerLevel`에는 공식 schema null
선언이 없으나 명세 계약에 따라 Data DTO를 `String?`으로 선언한다.
