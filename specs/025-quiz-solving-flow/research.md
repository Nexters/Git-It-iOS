# 조사: Task 3 문제 풀이 흐름 구현

**기능 브랜치**: `feature/quiz-solving-flow`

**날짜**: 2026-09-03

**명세**: [spec.md](./spec.md)

이 문서는 계획 단계에서 해소한 설계 결정을 기록한다. 각 항목은 `결정 · 근거 · 검토한 대안`으로
구성하며, 근거의 코드·문서 위치는 저장소 상대 경로로 적는다. 명세가 확정한 사항(FR·SC)은
반복하지 않고 그 위에서 결정한 내용만 적는다. Figma 노드 근거는
`private/task3-quiz-flow-spec.md`(이하 "조사 문서") §3·§8을 인용한다.

## R-01. Reducer 분해 단위 — 화면 8종을 책임 단위 7개 + 조합 3개로 나눈다

**결정**: 다음과 같이 나눈다. 괄호는 Figma 화면.

| Reducer | 책임 | 화면 |
| --- | --- | --- |
| `ProjectDetailFeature` (기존 확장) | 프로젝트 상세 조회·재조회, 세트 선택·바로 시작 의도 출력 | S1 |
| `LearningSetIntroFeature` (신설) | 세트 라벨·제목 즉시 표시, 설명 로드 상태 표시, 시작 의도 출력 | S2 |
| `ChoiceQuestionFeature` (신설) | 객관식 한 문제의 선택 → 제출 → 결과(펼침·접힘) 수명 | S3 · S5 |
| `EssayQuestionFeature` (신설) | 서술형 한 문제의 입력(400자) → 제출 → 결과 수명 | S6 · S7 |
| `QuestionBookmarkFeature` (신설, Child) | 현재 문제의 북마크 mutation | S3·S5·S6·S7 툴바 |
| `QuestionSourceFeature` (신설, Destination) | 출처 시트 표시와 외부 링크 열기 | S4 |
| `LearningCompletionFeature` (신설) | 완료 요약 표시, 나가기 의도 출력 | S8 |
| `QuizSessionFeature` (신설, 비화면 Child) | 세트·북마크 목록 조회, 진행 위치, 세션 제출 결과 보존, 완료 집계 | — |
| `QuizExitFeature` (신설, 조건부) | Router가 상위로 나가야 하는지 판단 | — |
| `QuizRouterFeature` (신설, Router) | S2~S8 조합, 활성 화면 전환, 이동 이벤트 기록 | S2~S8 |

**근거**:

- FR-024는 "화면을 책임지는 독립 Reducer"를 요구하고, 사용자 원문은 "각각의 TCA-Feature를
  책임단위로 명확히 정의해 조합"이다. `docs/conventions/tca/feature.md` §2는 Feature를
  "디자인 프레임 수가 아니라 논리적인 상태 소유자"로 나누고, 같은 논리 화면의 상태 변형은 하나의
  Feature가 소유하도록 한다.
- S3→S5, S6→S7은 화면 이동이 아니라 **같은 문제의 상태 전이**다(조사 문서 §3 S5: "헤더·툴바 구조는
  S3와 같고", CTA만 `정답 확인`→`다음`으로 바뀜). S5의 결과는 S3의 선택 값에 의존하므로 둘을 나누면
  부모가 선택 값과 결과를 복사해 넘겨야 해 FR-024의 "다른 화면의 상태를 직접 변경하지 않는다"를 오히려
  어긴다. 따라서 문제 형식별 Feature 하나가 `phase`(`answering`/`result`)를 소유한다.
- SC-002 "8종 각각의 상태 전이 테스트"는 Feature 수가 아니라 테스트 대상 전이로 충족한다.
  `data-model.md` §7의 전이표가 S1~S8 각각을 어느 테스트가 검증하는지 고정한다.
- 세트 수준 상태(세트 조회, 현재 문제 index, 세션 제출 결과, 북마크 목록)는 어느 화면에도 속하지
  않지만 독립 Effect·재시도·불변식을 가지므로 `feature.md` §3의 Child 분리 기준을 모두 만족한다
  → `QuizSessionFeature`(R-02).

**검토한 대안**:

- 기존 `QuizFeature` 하나를 확장(S3~S8 전부 소유): FR-024 위반. 기각.
- S3와 S5를 별개 Reducer로 분리: 위의 복사 문제와 재제출 흐름(결과 화면에서 다시 풀이 화면으로)
  때문에 기각.
- S2가 세트를 직접 조회하고 문제 Feature에 넘김: 홈 이어 풀기·바로 시작 경로에서는 S2가 없으므로
  조회 경로가 둘이 된다. 기각.

## R-02. 세트 풀이 세션의 소유자 — `QuizSessionFeature`(비화면 Child)

**결정**: `QuizRouterFeature`의 Child로 `QuizSessionFeature`를 두고 `FetchLearningSet`과
`FetchBookmarkedQuestions`를 이 Feature에만 주입한다. 세션은 `LearningSet`, 북마크 ID 집합,
진행 위치(`position`), 이번 세션 제출 결과(`sessionOutcomes`)를 소유하고, 문제 Feature에 넘길
`QuestionPresentation`과 완료 시 `LearningCompletionSummary`를 delegate로 출력한다.

**근거**: `docs/conventions/tca/navigation.md` §2.3은 Router를 "조합과 전환만" 책임지는 상위
Feature로 정의한다. 세트 조회 Effect와 실패·재시도 상태를 Router에 두면 이 경계를 넘는다.
반대로 문제 Feature에 두면 문제마다 세트를 다시 조회하거나 부모가 세트를 복사해야 한다.
`feature.md` §3 "독립적인 비동기 Effect와 cancellation 수명", "자체 오류·재시도 상태",
"부모가 하위 상태의 불변식을 계속 대신 관리해야 합니다"에 모두 해당한다.

**검토한 대안**: Router State에 세트와 index를 직접 두고 Router `Reduce`에서 Effect 실행 —
`OnboardingRouterFeature`는 Effect가 없어 선례가 되지 않으며 Router 테스트가 조회 Mock까지
준비해야 해 SC-006에 불리하다. 기각.

## R-03. Router 구성 — navigation.md §2.3 적용과 문제 화면 State의 예외

**결정**: `QuizRouterFeature`는 `ActiveScreen` 계층형 enum, `ScreenTransitionEvent` 기록,
`Scope` 조합, 조건부 `QuizExitFeature`를 `OnboardingRouterFeature`와 같은 형태로 갖춘다. 단
화면 Feature의 State(`LearningSetIntroFeature.State`, `ChoiceQuestionFeature.State`,
`EssayQuestionFeature.State`, `LearningCompletionFeature.State`)는 **optional**로 보유하고 `ifLet`으로
조합한다. `QuizSessionFeature.State`와 `QuizExitFeature.State`는 항상 보유한다.

**근거**: §2.3의 "항상 함께 보유" 규칙은 인자 없이 만들 수 있는 화면 State를 전제한다
(`OnboardingGuideFeature.State(bundleVersion:)`, `CurationFeature.State()`). 문제 화면 State는 세트
조회가 끝나야 존재하는 `Question`을 정본으로 가지고, 세트 시작 화면 State는 `LearningSet`에 없는
세트 라벨(`LearningProjectSetProgress.label`)을 필요로 해 직접 진입에서는 만들 수 없다. 미리 만들려면
자리표시자를 넣어야 하고 이는 `docs/conventions/tca/state.md` §2(정본만 소유)에 어긋난다. `state.md` §3은 "Child 수명은
optional child State … 처럼 생성과 제거가 드러나는 상태로 표현"을 허용한다. 활성 화면 enum에는
"완료·이탈" case를 두지 않고, 이탈 판단은 `QuizExitFeature`가 한다(§2.3 준수). 이 예외는
`docs/conventions/tca/navigation.md`를 바꾸지 않고 계획에만 기록한다 — 문서 개정은 별도 결정이다.

**검토한 대안**: 문제 Feature State에 `question: Question?`를 두고 항상 보유 — 모든 액션에
`guard let` 이 생기고 테스트가 반쪽 상태를 다뤄야 한다. 기각.

## R-04. 북마크는 Child Feature 하나를 두 문제 Feature가 재사용한다

**결정**: `QuestionBookmarkFeature`(State: `projectID`, `questionID`, `isBookmarked`, `mutation`)를
`ChoiceQuestionFeature`와 `EssayQuestionFeature`가 `Scope`로 조합한다. `SetQuestionBookmark`는 이
Child에만 주입한다. 성공 응답의 `BookmarkState.bookmarked`로만 표시를 바꾸고(FR-015a), `committing`
중 탭은 무시하며, 실패는 이전 표시를 유지하고 `failed`로 남겨 재시도를 허용한다.

**근거**: `feature.md` §3 "여러 화면에서 동일한 제품 동작 단위로 재사용됩니다" + 자체 mutation·실패
복구. 두 Feature에 같은 로직을 복제하면 SC-006의 독립 테스트가 중복된다.

**검토한 대안**: `QuizSessionFeature`가 북마크 mutation까지 소유 — 문제 화면이 세션 delegate를
거쳐 표시를 갱신해야 해 Router 중계가 늘어난다. 기각. 세션은 성공 결과만 `bookmarkRecorded`로
전달받아 북마크 집합을 최신으로 유지한다(재진입 시 화면 생성에 사용).

## R-05. 출처 시트 — Router의 Destination, 인앱 오버레이, 외부 링크는 closure 주입

**결정**:

- `QuizRouterFeature.State`에 `@Presents var source: QuestionSourceFeature.State?`를 두고 문제
  Feature의 `delegate(.sourceRequested)`를 받아 현재 문제의 `sources`로 생성한다. 닫기는
  `delegate(.closeRequested)` → `source = nil`.
- 화면은 `.sheet` 대신 `ModalOverlay` + `SheetSurface`로 현재 화면 위에 겹친다. 조사 문서 §3 S4는
  시트 프레임이 배경 화면 전체를 그대로 포함해 노출한다고 기록한다.
- 외부 링크 열기는 `openExternalLink: @MainActor @Sendable (URL) async -> Void`를 생성자 주입한다.
  선례: `ProjectRegistrationFeature.openNotificationSettings`
  (`sources/Projects/Feature/ProjectRegistration/Reducers/ProjectRegistrationFeature.swift:17`),
  App 연결은 `sources/Projects/App/GitIt/GitItApp.swift:65`.
- `referenceURL`이 `URL`로 파싱되지 않으면 링크 버튼을 비활성화한다. `sources`가 비어 있으면 문제
  화면이 출처 트리거를 노출하지 않는다(명세 경계 사례).

**근거**: `navigation.md` §2.1 "현재 Feature 수명 안에서 완결되는 sheet … Destination으로 소유".
두 문제 Feature가 각각 시트를 소유하면 `openExternalLink`를 둘 다 받아야 하고 상태가 중복된다.

**검토한 대안**: `@Environment(\.openURL)`을 View에서 직접 호출 — View가 Effect를 실행해
`navigation.md` §2.2(View는 View Action만 보냄)에 어긋난다. 기각.

## R-06. 기존 답변(`PreviousAnswer`)의 복원 범위 — 결과 화면이 아니라 풀이 화면에 선반영

**결정**: 세션 진행 중 이미 답변된 문제를 만나면(순차 진행이 건너뛰지 않으므로) 그 문제를 **풀이
단계**로 열되, 객관식은 `previousAnswer.selectedIndex`를 선택 상태로, 서술형은 `previousAnswer.text`를
입력값으로 미리 채운다. 사용자는 그대로 `정답 확인`을 눌러 재제출하고 완전한 결과를 받는다.

**근거**: `MyAnswerResponseDTO`(`sources/Projects/Data/LearningProject/DTOs/LearningSet/MyAnswerResponseDTO.swift`)
는 `selectedIndex`·`text`·`correct`만 제공한다. 정답 index와 해설이 없어 S5·S7을 온전히 복원할 수
없고, 반쪽 결과 화면(해설 없음, 오답인데 정답 표시 없음)은 FR-010을 만족하지 못한다. FR-002a의
"재풀이" 의미와도 맞는다. 재제출 결과는 세션 결과가 기존 답변보다 우선한다(FR-014c 집계).

**검토한 대안**: 기존 답변이 있으면 결과 화면으로 복원 — 위 데이터 부재로 기각. 답변된 문제를
자동으로 건너뛰기 — 조사 문서 A-11 "이미 답변된 문제도 건너뛰지 않음"과 충돌. 기각.

## R-07. 시작 문제 index 규칙은 Domain이 소유한다

**결정**: `LearningSet`에 `resumeQuestionIndex(additionallyAnswered: Set<String> = []) -> Int`를 추가한다.
"`previousAnswer == nil`이고 `additionallyAnswered`에 없는 첫 문제, 없으면 0". `LearningProjectDetail`에
`firstIncompleteSet: LearningProjectSetProgress?`("`completedCount < problemCount`인 첫 세트, 없으면
`nil`")를 추가한다. 기존 `nextSet`(첫 미완료 ?? 첫 세트)은 홈이 쓰므로 유지한다.

**근거**: FR-002a는 유스케이스 명세 006 FR-025의 Domain 규칙이다. `docs/package-rules/feature.md`는
"Domain의 비즈니스 규칙을 Feature에 다시 구현해서는 안 됩니다"라 한다. 기존 `QuizFeature.resumeIndex`
(`sources/Projects/Feature/Quiz/Reducers/QuizFeature.swift:326`)는 전부 답변 시 `count - 1`을 반환해
FR-002a와 다르므로 그 규칙을 Domain으로 옮기면서 바로잡는다. `additionallyAnswered`는 S2로 돌아갔다
다시 시작할 때 이번 세션 제출분을 반영하기 위한 인자다(R-10). FR-006a "미완료 세트 없으면 액션
미제공"은 `firstIncompleteSet == nil`로 판정한다.

**검토한 대안**: Feature에서 계산 — 규칙 중복. 기각.

## R-08. 학습 완료 카운터 산식과 메시지

**결정**: `QuizSessionFeature`가 완료 시 `LearningCompletionSummary(choiceQuestionCount:, correctChoiceCount:)`를
계산한다. 분모 = `format == .multipleChoice`인 문제 수. 분자 = 그중 (이번 세션 결과가 있으면
`ChoiceAnswerResult.correct`, 없으면 `previousAnswer?.correct == true`)인 문제 수. 분모가 0이면
`LearningCompletionFeature`가 카운터를 숨기고 메시지만 표시한다(FR-014d). 메시지는 분모 > 0이고
분자 == 분모이면 Figma 문구 `세트의 모든 문제를 다 맞췄어요!`, 그 밖에는 `세트의 모든 문제를 풀었어요!`
(잠정 — Figma에는 전부 정답 프레임만 있음, 조사 문서 Q-13).

**근거**: FR-014b·c·d. 정답 판정 값은 서버 응답만 사용한다(FR-017, SC-003) — 클라이언트는 `Bool`을
세기만 한다.

**검토한 대안**: 이번 세션 제출분만 집계 — FR-014c가 세트 전체 기준을 확정. 기각.

## R-09. App 내비게이션 — `NavigationStack` + `StackState`, 수동 목적지 Reducer

**결정**:

- `AppRootFeature.State`에 `mainStack: StackState<MainStackDestinationFeature.State>`를 추가하고
  `AppRootView`가 `MainShellScreen`을 루트로 하는 `NavigationStack(path:)`로 감싼다. 시스템 내비게이션
  바는 숨긴다(화면이 `ScreenHeader`를 그린다).
- `MainStackDestinationFeature`는 `enum State { projectDetail(ProjectDetailFeature.State); quiz(QuizRouterFeature.State) }`
  와 대응 `Action`을 **수동으로** 작성하고 `body`에서 `Scope`로 생성자 주입된 Reducer를 조합한다.
  TCA `@Reducer enum` 매크로는 각 case의 Reducer를 인자 없는 `init()`으로 생성하므로 이 프로젝트의
  생성자 주입 원칙(`docs/conventions/tca/README.md`)과 맞지 않는다.
- 전환 정책: `mainShell.delegate(.projectDetailRequested)` → `.projectDetail` push ·
  `mainShell.delegate(.learningRequested)` → `.quiz(entry: .direct(startingQuestionID:))` push ·
  `projectDetail.delegate(.setSelected)` → `.quiz(entry: .setIntro(label:title:))` push ·
  `projectDetail.delegate(.quickStartRequested)` → `.quiz(entry: .direct(startingQuestionID: nil))` push ·
  `projectDetail.delegate(.backRequested)` → pop · `quiz.delegate(.exited(projectID:reason:))` → quiz pop 후
  스택에 같은 `projectID`의 상세가 있으면 `input(.reloadRequested)` 전송, 없고 `reason == .completed`이면
  상세를 새로 push(FR-014a), 그 밖에는 홈 재표시이므로 `mainShell.home(.input(.learningProjectsReloadRequested))`
  전송(FR-023). 시스템 pop(`.popFrom(id:)`)도 같은 갱신 규칙을 적용한다.
- `AppRootFeature` 생성자에 `fetchLearningProjectDetail`, `fetchLearningSet`, `submitChoiceAnswer`,
  `submitEssayAnswer`, `setQuestionBookmark`, `openExternalLink`를 추가한다(`fetchBookmarkedQuestions`는
  이미 있음). `AppComposition`은 여섯 UseCase를 이미 공개하므로 Composition 변경은 없다.

**근거**: `docs/package-rules/app.md` "Feature가 외부 화면 흐름 변경을 요청하면 App이 목적지와 전환
방식을 결정". 현재 `AppRootFeature.swift:257-259`는 세 delegate를 `.none`으로 버린다. 문제 풀이 화면은
탭 바 없이 전체 화면이므로 `TabShell` 바깥의 스택 push가 Figma와 맞는다. `.fullScreenCover`(등록 흐름
선례)는 S1→S2→S3의 뒤로가기 계층을 표현하지 못한다.

**검토한 대안**: `MainShellFeature` 안에 스택을 두기 — MainShell은 탭 소유자이며 다른 최상위 Feature의
목적지 생성은 App 책임이다(`feature.md` §4). 기각.

## R-10. 뒤로가기 정책 — 세트 시작 화면을 거친 진입은 S2로 복귀, 그 밖에는 이탈

**결정**: 문제 화면(S3~S7)의 뒤로가기는 `entry == .setIntro`이면 Router 내부에서 S2로 돌아가고 문제
State를 제거한다. 세션은 유지되며 `시작하기`를 다시 누르면 `resumeQuestionIndex(additionallyAnswered:
sessionOutcomes.keys)`로 다음 미답변 문제부터 시작한다. `entry == .direct`이거나 S2·로딩·실패·빈
세트 화면에서의 뒤로가기는 `QuizExitFeature`를 거쳐 `delegate(.exited(reason: .abandoned))`로 이탈한다.
S8의 `X`·`다음`은 `.completed`로 이탈한다. 어느 경우도 확인 절차 없이 즉시 수행하고 미제출 입력은
버린다(FR-005a).

**근거**: FR-005 "이전 화면으로 돌아가는 수단". S2를 거쳐 들어온 사용자의 이전 화면은 S2다. 직접
진입은 이전 화면이 홈 또는 상세이므로 Router 밖이다.

**검토한 대안**: 모든 뒤로가기를 이탈로 처리 — 단순하지만 S1→S2→S3 경로에서 S2를 건너뛰어 "이전
화면"이 아니다. 기각.

## R-11. 로딩·실패·제출 중 표현 — 기존 표현 재사용

**결정**: Figma에 프레임이 없는 상태(조사 문서 Q-12)는 다음으로 통일한다.

| 상태 | 표현 |
| --- | --- |
| 조회 중(S1·S2 설명·세션) | `ResourceAnimation(asset: .generalLoading)` 중앙 배치. S2는 라벨·제목을 먼저 그리고 설명 자리에 표시 |
| 조회 실패 | `EmptyState(title:message:)` + `ActionButton.secondary("다시 시도")`. 뒤로가기 유지 |
| 빈 세트 | `EmptyState(title: "문제가 없는 세트예요", message: …)`. 하단 툴바 없음, 뒤로가기만 |
| 제출 중 | CTA `isEnabled: false`(`ActionButton` Disabled variant, 조사 문서 Q-04 해소). 선택·입력 잠금 |
| 제출 실패 | 선택·입력 유지, CTA 재활성, CTA 위에 `StyledText.caption1` 실패 안내 1줄 |
| 북마크 실패 | 표시 변화 없음, 재탭 허용(FR-015a) |

**근거**: 명세 가정 "로딩·실패·제출 중 상태는 … 기존 상태 표현 방식을 재사용". 컴포넌트는
`sources/Projects/UI/Component/Indicators/EmptyState/`, `Displays/ResourceAnimation.swift`,
`Controls/ActionButton*`에 존재한다.

## R-12. UI 컴포넌트 정합 — `LearningSetRow` 재구성, `ChoiceResultRow.Judgement.neutral` 추가

**결정**:

- `LearningSetRow`를 Figma `학습세트 List-item`(조사 문서 §3 S1)에 맞춰
  `init(label:title:questionCount:completedCount:onTap:)`로 바꾸고 내부 진행 표시를
  `ContinuousProgressBar(progress:)`에서 `ProgressSegments(completed:total:)`로 교체한다. `Set N` 라벨·재생
  아이콘을 추가하고 Figma에 없는 `완료` 배지·`문제 N개` 캡션은 제거한다. 완료 세그먼트 색은
  `ProgressSegments`가 이미 `blue100`/`grey500`을 쓰므로 그대로 둔다(Q-01 해소값과 일치).
- `ChoiceResultRow.Judgement`에 `.neutral`(배경 `grey600`, 접근성 접미사 없음)을 추가한다. FR-010a가
  중립 표현을 확정했고 Figma에는 variant가 없으므로(Q-08) 색은 S3 카드 배경과 같은 `grey600`을 쓴다.
- `ProgressSegments`, `LabeledProgressBar`(전체 진행률, 트랙 `progressTrack = grey500`), `BookmarkButton`,
  `ChoiceAnswerOption`, `ScreenHeader`, `BottomActionBar`, `ScreenEdgeScrim`, `SheetSurface`,
  `ModalOverlay`, `EmptyState`, `ResourceAnimation`, `TagBadge`, `ActionButton`은 변경 없이 사용한다.
  조사 문서 Q-16(전체 진행률 트랙 색)은 기존 의미 토큰을 유지하는 것으로 닫는다.
- `docs/conventions/ui-component.md` §3.4 목록은 컴포넌트 추가·삭제가 없으므로 바꾸지 않는다.

**근거**: FR-007·FR-030. 두 컴포넌트의 사용처는 UI 패키지 안(테스트 포함)뿐이라
(`grep` 결과: `LearningSetRowTests.swift`, `AccessibilityContractTests.swift`, `ChoiceResultRowTests.swift`)
UI 단위만으로 compile이 닫힌다.

**검토한 대안**: `LearningSetRow` 대신 Feature에서 조립 — 재사용 컴포넌트를 Feature가 소유하게 되어
`feature.md` 제약 위반. 기각.

## R-13. S2 배경 그라데이션(`#141414 → #A5C4F0`) — 토큰 추가는 승인 지점

**결정**: `GradientToken`에 세트 시작 배경 항목을 추가하는 것을 기본안으로 두되 **구현 전 승인을
받는다**(⛔). 승인되지 않으면 장식 그라데이션을 생략하고 `grey700` 단색 배경으로 구현하며 PR에
미반영 항목으로 남긴다.

**근거**: 조사 문서 Q-17 — 종료색 `#A5C4F0`이 토큰 표에 없다. FR-028은 화면 코드의 색 직접 기입을
금지하고 `docs/package-rules/feature.md`는 DesignSystem 밖 시각 어휘 정의를 금지하므로 Feature에서
`LinearGradient`를 조립하는 우회는 쓰지 않는다. 한편 FR-030은 UI 변경을 데이터·컴포넌트 정합으로
한정하므로 토큰 추가는 범위 확장이며 Constitution 원칙 7의 "새로운 제품 결정"에 해당한다.

## R-14. CTA 문구·텍스트 스타일 매핑

**결정**:

- CTA: S3·S6 `정답 확인`, S5·S7 `다음`(Primary), S8 `다음`(Secondary), S2 `시작하기`, S4 `닫기`.
  조사 문서 Q-06·Q-11의 혼재를 서술형 기준으로 통일한다.
- 텍스트 스타일: Figma 크기·굵기에 가장 가까운 기존 `TextStyleToken`을 쓰고 새 토큰을 만들지 않는다.
  Q-20이 지적한 18 Bold(학습 세트 제목)·16 Bold(`Set N`)·22 Bold(S8 카운터)는 구현 시 토큰 카탈로그에서
  고르고 선택 근거를 PR 본문에 남긴다. S7 제목의 `Pretendard`는 디자인 시스템에 없으므로 `body` 계열로
  대체한다(Q-11).
- S7 본문 부분 강조(색만 다름)는 대응 데이터가 없어 단색으로 표시한다.

## R-15. 범위 밖 확인 — rubric 미표시, 트로피 애니메이션은 기존 자산

**결정**: `EssayAnswerResult.rubric`은 화면에 쓰지 않는다(명세 범위 밖, Q-10). `RubricView`는 손대지
않는다. S8 그래픽은 `ResourceAnimation(asset: .complete, isLooping: false)`를 쓴다(Q-19 — 이미 번들된
자산이 있어 외부 파일 확인이 필요 없다).

## R-16. 서술형 400자 상한은 Reducer가 강제한다

**결정**: `EssayQuestionFeature`가 `answerCharacterLimit = 400`을 공개 상수로 갖고
`view(.essayTextChanged)`에서 `prefix(400)`으로 잘라 State에 저장한다. 제출 guard는 "공백 제외 1자
이상"과 "400자 이하"를 함께 검사한다. `AnswerEditor`는 카운터 표시(`n / 400`)만 담당한다.

**근거**: FR-011a "상한을 넘긴 답안이 제출되는 경로가 존재해서는 안 된다". View의 `TextField`만으로는
붙여넣기·IME 조합을 막을 수 없다.

## R-17. 기존 `QuizFeature` 처리 — 대체 후 삭제(승인 지점)

**결정**: `sources/Projects/Feature/Quiz/Reducers/QuizFeature.swift`는 새 Reducer군이 들어가는 실행
단위에서 삭제한다(⛔ 삭제 전 승인). 그 전 단계(Domain 모델 변경)에서는 `myAnswer` 참조 1줄만
`previousAnswer`로 바꿔 compile을 유지한다. `Quiz/Views/QuestionPrompt.swift`·`AnswerEditor.swift`는
Figma 규격에 맞춰 재작성해 계속 쓴다.

**근거**: `QuizFeature`는 App·다른 Feature에서 참조되지 않는다(`grep` 결과 자기 파일뿐). 삭제는
되돌리기 어려운 작업이라 Constitution 원칙 7의 승인 대상이다.

## R-18. Domain 모델 변경으로 깨지는 기존 테스트·호출부

| 파일 | 영향 | 처리 단위 |
| --- | --- | --- |
| `sources/Projects/Domain/Tests/LearningProject/UseCases/FetchLearningSetTests.swift` | `Question(…source:myAnswer:)`·`LearningSet(setID:title:questions:)` 생성자, `myAnswer` 검증 | 단위 1 |
| `sources/Projects/Composition/Adapter/Adapters/LearningSetRepositoryAdapter.swift` | `question(from:)` 매핑 | 단위 1 |
| `sources/Projects/Composition/Adapter/Adapters/LearningProjectRepositoryAdapter.swift` | `problemCount: 0, completedCount: 0` 상수 | 단위 1 |
| `sources/Projects/Composition/Tests/Adapter/Adapters/LearningSetRepositoryAdapterTests.swift` | 매핑 기대값 | 단위 1 |
| `sources/Projects/Composition/Tests/Adapter/Adapters/LearningProjectRepositoryAdapterTests.swift` | 문제 수·완료 수 기대값 추가 | 단위 1 |
| `sources/Projects/Feature/Quiz/Reducers/QuizFeature.swift:326` | `myAnswer` 참조 | 단위 1(1줄), 단위 3(삭제) |
| `sources/Projects/UI/Tests/Component/Unit/CollectionItems/LearningSetRowTests.swift` | 생성자 | 단위 2 |
| `sources/Projects/UI/Tests/Component/Unit/Controls/AccessibilityContractTests.swift` | `LearningSetRow` 생성자 | 단위 2 |
| `sources/Projects/UI/Tests/Component/Unit/CollectionItems/ChoiceResultRowTests.swift` | `Judgement` 추가 case | 단위 2 |
| `sources/Projects/App/Tests/GitIt/Reducers/AppRootFeatureTests.swift:249-273` | delegate가 `.none`이라는 기대 | 단위 6 |
| `sources/Projects/App/Tests/GitIt/TestDoubles/AppRootTestSupport.swift` | 생성자 인자 추가 | 단위 6 |
| `sources/Projects/App/GitIt/Screens/AppRootView.swift` `AppRootPreviewSupport` | 생성자 인자 추가 | 단위 6 |

`LearningProjectLifecycleTests.swift`·`LearningProjectRepositoryContractTests.swift`·`LearningProjectDetailTests.swift`는
`LearningProjectDetail`·`LearningProjectSetProgress` 생성자를 쓰며 이 생성자는 바꾸지 않으므로 영향이
없다(`firstIncompleteSet`은 computed property 추가).

## R-19. 작업 트리에 남아 있는 미커밋 변경 100건

**결정**: 현재 브랜치 작업 트리에는 이전 기능(`feature/ui-design-spec-alignment`)에서 넘어온 수정 90건·
미추적 10건이 있다(`git status --porcelain | wc -l` = 100). `/speckit-implement`는 이 파일들을 이 기능의
커밋에 섞지 않는다. 구현 시작 전 사용자가 이 변경을 커밋·stash·폐기 중 하나로 정리하는 것을
권장하며, 정리되지 않으면 각 커밋 단위에서 이 기능이 바꾼 파일만 정확히 stage한다.

**근거**: Constitution 원칙 7 "무관한 변경을 포함하지 않는다". 원칙 3의 검증 결과가 이전 기능의
미커밋 변경에 오염되지 않아야 한다.

## R-20. 실행 단위와 의존성 위상 순서

**결정**: 적용 패키지는 Domain · UI · Composition · Feature · App이며 위상 순서는
Domain → UI → Composition → Feature → App이다(`docs/architecture.md` 의존성 표: Composition→Domain,
Feature→Domain·UI, App→Feature·Composition·Domain; Domain·UI는 서로 독립). 단위 구성과 분리 불가
근거는 [plan.md](./plan.md) "실행 단위"가 정본이다. Tuist manifest 변경은 없다 — `Feature`·`FeatureTests`,
`GitIt`·`GitItTests`, `UIComponent`·`UIComponentTests`, `DomainLearningProject`·`DomainLearningProjectTests`,
`CompositionAdapter`·`CompositionAdapterTests` target이 모두 존재하고 test source root가 `Tests/`라 새
폴더가 자동 포함된다.
