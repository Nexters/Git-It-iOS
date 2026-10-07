# 지침 5.1.1(v) 이의제기 문안

Submission ID `723df8fb-ed8b-4eb9-8caa-e4ee5f9e14a4` (1.0.0 build 7)에 대한 App Store Connect
회신용 문안입니다. 앱이 계정 기반으로만 동작한다는 사실을 근거로 지침 5.1.1(v) 적용 재검토를
요청합니다.

## 주장의 근거 (코드 사실)

| 주장 | 근거 |
| --- | --- |
| 모든 콘텐츠가 계정 귀속 서버 데이터다 | `LearningProjectHTTPExecutor`가 project·set·answer·bookmark 전 요청에 `AuthorizedRequestHeaders` 부착 |
| 편집자 콘텐츠·공개 카탈로그가 없다 | 조회 가능한 목록은 `FetchLearningProjectsUseCase` 결과뿐이며 사용자가 등록한 저장소에서만 생성 |
| 퀴즈는 사용자별로 생성된다 | `CreateLearningProjectUseCase` → 서버 생성 → `ObserveGenerationOutcomesUseCase`로 해당 계정에만 전달 |
| 추가 개인정보 입력 폼이 없다 | 로그인은 `com.apple.developer.applesignin` 전용, 아이디/비밀번호 폼 없음 |
| 계정 삭제가 앱 안에 있다 | `SettingsScreen+AccountDeletionView` — 확인 즉시 삭제 |

## 붙여넣을 회신 (영문)

```text
Hello,

Thank you for the review. We would like to provide additional context regarding
Guideline 5.1.1(v), as we believe every feature in Git It is account-based.

WHY THE ACCOUNT IS REQUIRED FOR ALL FEATURES

Git It has no catalog, no editorial content, and no browsable public library. There is
no content in the app that exists independently of a user account. Specifically:

1. All quiz content is generated per user, on demand.
   The app does not ship or download any pre-made quizzes. A quiz set exists only after
   a signed-in user registers one of their own repositories, at which point our server
   generates a set of questions for that user. There is nothing to display to a user who
   has not created any.

2. All content is stored server-side against the account.
   Every content endpoint in the app (projects, quiz sets, submitted answers, bookmarks,
   and profile statistics) is an authorized request bound to the signed-in member. There
   is no unauthenticated content endpoint that could populate a browsing experience.

3. The features are inherently personal.
   The core value of the app is reviewing code the user has personally written. Answer
   history, correctness statistics, weekly progress, and bookmarked questions are all
   per-account records. Without an identity, these features have no meaning — there is no
   anonymous equivalent of "your progress on your repository".

In other words, a signed-out mode would show empty screens only. We are not withholding
non-account features behind a login; there are no non-account features to withhold.

MINIMAL DATA COLLECTION

The app uses Sign in with Apple exclusively. There is no registration form, and users may
use Hide My Email. We collect only the email address and name that Sign in with Apple
provides, plus a device push token used solely to notify the user that their quiz set has
finished generating. There is no tracking, no advertising identifier, and no third-party
data sharing.

ACCOUNT DELETION

Account deletion is available in the app at the "마이" (My) tab > "계정 삭제" (Delete
Account). Deletion is immediate and removes the account together with all generated
content, as required by Guideline 5.1.1(v).

HOW TO REVIEW

    Public repository URL: <<공개 저장소 URL>>

Please note that quiz generation is server-side and intentionally rate-limited: the
progress screen remains visible for a minimum of five minutes. This is expected behavior,
not a hang. A local notification is delivered when the set is ready.

We would be grateful if you could reconsider the app under this context. If you still
consider a signed-out entry point necessary, we would appreciate specific guidance on
which feature you regard as not account-based, so that we can address it precisely.

Thank you for your time.
```

## 회신 전 확인 목록

- [ ] `<<공개 저장소 URL>>`을 실제 값으로 교체했다
- [ ] [app-store-review-notes.md](app-store-review-notes.md)의 "HOW TO REVIEW" 1번이
      "Sign in with Apple, ..."으로 시작하지 않도록 고쳤다 (로그인이 전제라고 먼저
      선언하는 문장은 5.1.1(v) 지적을 스스로 확인해 주는 셈이다)
- [ ] 온보딩의 직군·연차 선택을 건너뛸 수 있게 할지 결정했다 —
      `PositionSelectionFeature.nextTapped`가 선택 없이는 진행을 막고 있으며, 이는
      "기능하기 위한 개인정보 입력 요구"로 해석될 수 있어 이의제기의 가장 약한 지점이다

## 이의제기가 기각될 경우

계정 기반이라는 주장 자체는 유지하되, 다음 순서로 양보 범위를 넓힙니다.

1. 직군·연차 선택을 건너뛰기 가능하게 변경 (개인정보 입력 요구 제거)
2. 로그인 전 튜토리얼에 샘플 문항 미리보기 추가 (콘텐츠 성격을 심사자가 확인 가능)
3. 비로그인 진입 + 번들 샘플 세트 풀이 허용 (`AppEntryFeature.Destination` 확장 필요)
