# 계약: Feature Reducer와 UseCase 주입

**기능 브랜치**: `feature/quiz-solving-flow` · **날짜**: 2026-09-03

이 문서는 FR-027·SC-007의 정본이다. 구현된 각 Reducer의 생성자 인자는 §1 표와 정확히 일치해야 한다.
State 필드는 [data-model.md](../data-model.md) §3을, Router 전환 규칙은
[screen-flow.md](./screen-flow.md)를 참조한다. Action 분류·이름은
`docs/conventions/tca/action.md`(`view`·`input`·`effect`·`delegate`)를 따른다.

## 1. Reducer별 주입 UseCase와 사용 지점 (FR-027)

| Reducer | 생성자 인자 | 사용 지점 |
| --- | --- | --- |
| `ProjectDetailFeature` | `fetchLearningProjectDetail: any FetchLearningProjectDetailUseCase` | `view(.task)`, `view(.retryTapped)`, `input(.reloadRequested)` → `.run`에서 `fetchLearningProjectDetail(projectID:)` |
| `LearningSetIntroFeature` | 없음 | — (설명은 Router가 세션 결과로 `input`) |
| `QuizSessionFeature` | `fetchLearningSet: any FetchLearningSetUseCase`, `fetchBookmarkedQuestions: any FetchBookmarkedQuestionsUseCase` | `input(.loadRequested)`, `input(.retryRequested)` → 두 UseCase를 각각 `.run`으로 병행 호출(`fetchLearningSet(projectID:setID:)`, `fetchBookmarkedQuestions(projectID:)`) |
| `ChoiceQuestionFeature` | `submitChoiceAnswer: any SubmitChoiceAnswerUseCase`, `setQuestionBookmark: any SetQuestionBookmarkUseCase` | `view(.submitTapped)` → `submitChoiceAnswer(projectID:questionID:selectedIndex:)`. `setQuestionBookmark`는 사용하지 않고 `QuestionBookmarkFeature`에 그대로 전달 |
| `EssayQuestionFeature` | `submitEssayAnswer: any SubmitEssayAnswerUseCase`, `setQuestionBookmark: any SetQuestionBookmarkUseCase` | `view(.submitTapped)` → `submitEssayAnswer(projectID:questionID:text:)`. `setQuestionBookmark`는 `QuestionBookmarkFeature`에 전달 |
| `QuestionBookmarkFeature` | `setQuestionBookmark: any SetQuestionBookmarkUseCase` | `view(.toggleTapped)` → `setQuestionBookmark(projectID:questionID:bookmarked: !isBookmarked)` |
| `QuestionSourceFeature` | `openExternalLink: @MainActor @Sendable (URL) async -> Void` | `view(.linkTapped(index:))` → `.run`에서 호출(UseCase 아님) |
| `LearningCompletionFeature` | 없음 | — |
| `QuizExitFeature` | 없음 | — |
| `QuizRouterFeature` | `fetchLearningSet`, `fetchBookmarkedQuestions`, `submitChoiceAnswer`, `submitEssayAnswer`, `setQuestionBookmark`, `openExternalLink` | 직접 사용하지 않고 `body`의 `Scope`/`ifLet`에서 각 Child 생성자에 전달 |
| `MainStackDestinationFeature` (App) | `fetchLearningProjectDetail` + Router와 같은 6개 | `Scope`에서 `ProjectDetailFeature`·`QuizRouterFeature` 생성 |
| `AppRootFeature` (App, 기존 확장) | 기존 인자 + `fetchLearningProjectDetail`, `fetchLearningSet`, `submitChoiceAnswer`, `submitEssayAnswer`, `setQuestionBookmark`, `openExternalLink` (`fetchBookmarkedQuestions`는 기존) | `.forEach(\.mainStack)`에서 `MainStackDestinationFeature` 생성 |

Router가 Child 생성자에 전달하기 위해 받는 인자는 "자신이 사용하는 UseCase"(FR-026)의 예외가
아니라 조합 책임의 일부다 — `OnboardingRouterFeature`가 `signIn`·`signOut`을 받아 Child에 넘기는
선례와 같다. `ChoiceQuestionFeature`·`EssayQuestionFeature`가 `setQuestionBookmark`를 받는 것도
Child 조합을 위한 전달이다.

UseCase 6종은 `AppComposition`이 이미 공개한다
(`sources/Projects/Composition/Adapter/Assemblies/AppComposition.swift:149-156`). Composition 공개
표면은 바뀌지 않는다.

## 2. Reducer 계약

각 Reducer는 `@Reducer public struct … : Sendable`, `@ObservableState public struct State: Equatable, Sendable`,
`public enum Action: ViewAction, Sendable, Equatable`을 갖는다. `View`·`Input`·`Effect`·`Delegate`는
`@CasePathable` 중첩 enum이다.

### 2.1 `ProjectDetailFeature` — S1 (기존 파일 확장)

경로: `sources/Projects/Feature/ProjectDetail/Reducers/ProjectDetailFeature.swift`

| 분류 | Action | 규칙 |
| --- | --- | --- |
| view | `task` | `loadStatus == .idle`일 때만 조회 시작 |
| view | `retryTapped` | `failed`에서 재조회 |
| view | `setRowTapped(setID:)` | `detail.sets`에서 찾은 `LearningProjectSetProgress`를 delegate로 |
| view | `quickStartTapped` | `quickStartSet == nil`이면 무시(FR-006a) |
| view | `backTapped` | → `delegate(.backRequested)` |
| input | `reloadRequested` | `requestID` 증가 후 재조회. 표시 중인 `detail`은 유지(깜빡임 없음) |
| effect | `detailLoadFinished(requestID:result:)` | `requestID` 불일치 시 무시 |
| delegate | `setSelected(projectID:set: LearningProjectSetProgress)` | 기존 `setSelected(projectID:setID:)`의 payload 확장(S2가 라벨·제목을 즉시 표시) |
| delegate | `quickStartRequested(projectID:setID:)` | App이 `QuizEntry.direct(startingQuestionID: nil)`로 해석 |
| delegate | `backRequested` | App이 pop |

Cancellation ID: `detailLoad`(`cancelInFlight: true`).

### 2.2 `LearningSetIntroFeature` — S2

경로: `sources/Projects/Feature/Quiz/Reducers/LearningSetIntroFeature.swift`

| 분류 | Action | 규칙 |
| --- | --- | --- |
| view | `startTapped` | `isStartEnabled`일 때만 → `delegate(.startRequested)` |
| view | `retryTapped` | `description == .failed`에서만 → `delegate(.retryRequested)` |
| view | `backTapped` | → `delegate(.backRequested)` |
| input | `descriptionLoadChanged(DescriptionLoad)` | Router가 세션 결과를 전달 |
| delegate | `startRequested`, `retryRequested`, `backRequested` | |

State 생성: `init(label:title:)` → `description = .loading`.

### 2.3 `QuizSessionFeature` — 세트 풀이 세션 (비화면)

경로: `sources/Projects/Feature/Quiz/Reducers/QuizSessionFeature.swift`

| 분류 | Action | 규칙 |
| --- | --- | --- |
| input | `loadRequested` | `setLoad == .idle`일 때만. `loadRequestID += 1`, `setLoad = .loading`, `bookmarkLoad = .loading`, 두 Effect 시작 |
| input | `retryRequested` | `failed`에서 위와 동일 |
| input | `startRequested` | `setLoad == .loaded(set)`·`!set.questions.isEmpty`일 때만. index = `startingQuestionID`의 위치 ?? `set.resumeQuestionIndex(additionallyAnswered: Set(sessionOutcomes.keys))`. `position = .question(index)`, → `delegate(.questionPresented(presentation(at: index)))` |
| input | `answerRecorded(questionID:outcome:)` | `sessionOutcomes[questionID] = outcome` |
| input | `bookmarkRecorded(questionID:isBookmarked:)` | `bookmarkLoad`의 집합 갱신(실패 상태였으면 `.loaded`로 승격) |
| input | `advanceRequested` | `position == .question(i)`일 때만. `i + 1 < count` → `.question(i + 1)` + `questionPresented`; 아니면 `.completed` + `delegate(.setCompleted(completionSummary))` |
| effect | `setLoadFinished(requestID:result:)` | `requestID == loadRequestID`만 반영. 성공: `.loaded(set)` → 빈 세트면 `delegate(.setEmpty)`, 아니면 `delegate(.setLoaded(set))`. 실패: `.failed(e)` → `delegate(.setLoadFailed(e))` |
| effect | `bookmarksLoadFinished(requestID:result:)` | 성공: `.loaded(ids)`. 실패: `.failed(e)` — 세션 진행은 막지 않음 |
| delegate | `setLoaded(LearningSet)`, `setLoadFailed(LearningProjectError)`, `setEmpty`, `questionPresented(QuestionPresentation)`, `setCompleted(LearningCompletionSummary)` | |

Cancellation ID: `setLoad`, `bookmarkLoad`(둘 다 `cancelInFlight: true`). `presentation(at:)`은
`isBookmarked = bookmarkedQuestionIDs.contains(questionID)`를 채운다.

### 2.4 `ChoiceQuestionFeature` — S3·S5

경로: `sources/Projects/Feature/Quiz/Reducers/ChoiceQuestionFeature.swift`

| 분류 | Action | 규칙 |
| --- | --- | --- |
| view | `choiceTapped(index:)` | `phase == .answering`·`submission != .committing`일 때만 `selectedIndex = index`(교체) |
| view | `submitTapped` | `canSubmit`일 때만 `submission = .committing` + Effect |
| view | `resultRowTapped(index:)` | `phase == .result`에서 `expandedChoiceIndices` 토글 |
| view | `nextTapped` | `phase == .result`에서만 → `delegate(.nextRequested)` |
| view | `sourceTapped` | `hasSources`일 때만 → `delegate(.sourceRequested)` |
| view | `backTapped` | → `delegate(.backRequested)` |
| effect | `submissionFinished(questionID:result: Result<ChoiceAnswerResult, LearningProjectError>)` | `questionID` 일치만 반영. 성공: `result = r`, `submission = .idle`, `expandedChoiceIndices = [r.answerIndex] ∪ (오답이면 `[selectedIndex]`)`(Figma 초기 펼침), → `delegate(.answerSubmitted(questionID:outcome: .choice(r)))`. 실패: `submission = .failed(e)`, 선택 유지 |
| child | `bookmark(QuestionBookmarkFeature.Action)` | `.delegate(.bookmarkChanged)`를 자신의 delegate로 재전송 |
| delegate | `answerSubmitted(questionID:outcome: AnswerOutcome)`, `nextRequested`, `sourceRequested`, `backRequested`, `bookmarkChanged(questionID:isBookmarked:)` | |

Cancellation ID: `submission`. mutation이므로 `cancelInFlight` 없이 State 전이로 중복을 차단한다.
State 생성: `init(projectID:presentation:)`.

### 2.5 `EssayQuestionFeature` — S6·S7

경로: `sources/Projects/Feature/Quiz/Reducers/EssayQuestionFeature.swift`

| 분류 | Action | 규칙 |
| --- | --- | --- |
| view | `essayTextChanged(String)` | `phase == .answering`·committing 아님일 때 `draftText = String(text.prefix(answerCharacterLimit))` |
| view | `submitTapped` | `canSubmit`일 때만 `submittedText = draftText`, `submission = .committing` + Effect |
| view | `nextTapped`, `sourceTapped`, `backTapped` | 2.4와 동일 |
| effect | `submissionFinished(questionID:result: Result<EssayAnswerResult, LearningProjectError>)` | 성공: `result = r`, `submission = .idle`, → `delegate(.answerSubmitted(questionID:outcome: .essay(r)))`. 실패: `submission = .failed(e)`, `draftText` 유지, `submittedText = nil` |
| child | `bookmark` | 2.4와 동일 |
| delegate | 2.4와 동일 | |

`public static let answerCharacterLimit = 400`.

### 2.6 `QuestionBookmarkFeature`

경로: `sources/Projects/Feature/Quiz/Reducers/QuestionBookmarkFeature.swift`

| 분류 | Action | 규칙 |
| --- | --- | --- |
| view | `toggleTapped` | `mutation == .committing`이면 무시. 아니면 `.committing` + `setQuestionBookmark(…, bookmarked: !isBookmarked)` |
| effect | `mutationFinished(questionID:result: Result<BookmarkState, LearningProjectError>)` | 성공: `isBookmarked = state.bookmarked`, `.idle`, → `delegate(.bookmarkChanged)`. 실패: `.failed(e)`, 표시 유지 |
| delegate | `bookmarkChanged(questionID:isBookmarked:)` | |

Cancellation ID: `bookmarkMutation`.

### 2.7 `QuestionSourceFeature` — S4

경로: `sources/Projects/Feature/Quiz/Reducers/QuestionSourceFeature.swift`

| 분류 | Action | 규칙 |
| --- | --- | --- |
| view | `linkTapped(index:)` | `link(at: index)`가 `nil`이면 무시. 아니면 `.run { await openExternalLink(url) }` |
| view | `closeTapped` | → `delegate(.closeRequested)` |
| delegate | `closeRequested` | |

### 2.8 `LearningCompletionFeature` — S8

경로: `sources/Projects/Feature/Quiz/Reducers/LearningCompletionFeature.swift`

| 분류 | Action | 규칙 |
| --- | --- | --- |
| view | `nextTapped`, `closeTapped` | 둘 다 → `delegate(.finished)` |
| delegate | `finished` | |

### 2.9 `QuizExitFeature` — 이탈 판단

경로: `sources/Projects/Feature/Quiz/Reducers/QuizExitFeature.swift`

| 분류 | Action | 규칙 |
| --- | --- | --- |
| input | `completionFinished` | → `delegate(.shouldExit(.completed))` |
| input | `backRequestedAtEntry` | → `delegate(.shouldExit(.abandoned))` |
| delegate | `shouldExit(QuizExitReason)` | |

`OnboardingExitFeature`와 같은 형태(`ViewAction` 아님, `input`·`delegate`만).

### 2.10 `QuizRouterFeature` — 조합

경로: `sources/Projects/Feature/Quiz/Reducers/QuizRouterFeature.swift`

| 분류 | Action | 규칙 |
| --- | --- | --- |
| view | `task` | 최초 1회 → `session(.input(.loadRequested))` |
| view | `retryTapped` | `activeScreen == .sessionFailed` → `session(.input(.retryRequested))`, `activeScreen = .sessionLoading` |
| view | `backTapped` | `sessionLoading`·`sessionFailed`·`setEmpty` 화면의 뒤로가기 → `exit(.input(.backRequestedAtEntry))` |
| child | `session`, `setIntro`, `choiceQuestion`, `essayQuestion`, `completion`, `exit`, `source(PresentationAction<…>)` | 해석 규칙은 [screen-flow.md](./screen-flow.md) §2 |
| delegate | `exited(projectID: String, reason: QuizExitReason)` | 상위에 알리는 유일한 delegate |

State 생성: `init(projectID:setID:entry:)`. `.setIntro(label:title:)` → `setIntro = .init(label:title:)`,
`activeScreen = .setIntro`. `.direct(startingQuestionID:)` → `activeScreen = .sessionLoading`,
`session.startingQuestionID` 설정.

## 3. 화면(Screen) 계약

모든 화면은 `@ViewAction(for:)`, `init(store:)`, `View` Action만 전송(`docs/conventions/view.md` §3.4,
`navigation.md` §2.2).

| 화면 | 경로 | Store |
| --- | --- | --- |
| `ProjectDetailScreen` | `sources/Projects/Feature/ProjectDetail/Screens/ProjectDetailScreen.swift` | `StoreOf<ProjectDetailFeature>` |
| `QuizScreen` | `sources/Projects/Feature/Quiz/Screens/QuizScreen.swift` | `StoreOf<QuizRouterFeature>` — `activeScreen`으로 분기, `source` 오버레이 |
| `LearningSetIntroScreen` | `sources/Projects/Feature/Quiz/Screens/LearningSetIntroScreen.swift` | `StoreOf<LearningSetIntroFeature>` |
| `ChoiceQuestionScreen` | `sources/Projects/Feature/Quiz/Screens/ChoiceQuestionScreen.swift` | `StoreOf<ChoiceQuestionFeature>` |
| `EssayQuestionScreen` | `sources/Projects/Feature/Quiz/Screens/EssayQuestionScreen.swift` | `StoreOf<EssayQuestionFeature>` |
| `QuestionSourceScreen` | `sources/Projects/Feature/Quiz/Screens/QuestionSourceScreen.swift` | `StoreOf<QuestionSourceFeature>` — 시트 내용 |
| `LearningCompletionScreen` | `sources/Projects/Feature/Quiz/Screens/LearningCompletionScreen.swift` | `StoreOf<LearningCompletionFeature>` |

`QuizScreen`이 `sessionLoading`·`sessionFailed`·`setEmpty`를 그릴 때는 Store 없는 Feature 로컬 View
(`sources/Projects/Feature/Quiz/Views/QuizSessionStatusView.swift`)를 쓰고 콜백을 `retryTapped`·
`backTapped`로 해석한다. 사용 컴포넌트는 [ui-component-api.md](./ui-component-api.md) §3.

## 4. 테스트 Double 계약

경로: `sources/Projects/Feature/Tests/Quiz/TestDoubles/`, `sources/Projects/Feature/Tests/ProjectDetail/TestDoubles/`.
기존 Feature 테스트(`Home`·`Saved`)에 같은 Protocol의 Mock이 이미 있으면 재사용하고 새로 만들지
않는다(구현 시 `grep "UseCaseMock" sources/Projects/Feature/Tests`로 확인).

| Double | Protocol | 형태 |
| --- | --- | --- |
| `FetchLearningSetUseCaseMock` | `FetchLearningSetUseCase` | `actor`, `results: [Result<LearningSet, LearningProjectError>]`, `snapshot()` 호출 기록 |
| `FetchBookmarkedQuestionsUseCaseMock` | `FetchBookmarkedQuestionsUseCase` | 위와 동일 |
| `SubmitChoiceAnswerUseCaseMock` | `SubmitChoiceAnswerUseCase` | 위와 동일, 인자 `(projectID, questionID, selectedIndex)` 기록 |
| `SubmitEssayAnswerUseCaseMock` | `SubmitEssayAnswerUseCase` | 위와 동일 |
| `SetQuestionBookmarkUseCaseMock` | `SetQuestionBookmarkUseCase` | 위와 동일 |
| `FetchLearningProjectDetailUseCaseMock` | `FetchLearningProjectDetailUseCase` | 위와 동일 |
| `QuizTestFixture` | — | 객관식 2·서술형 1 혼합 세트, 서술형만 세트, 빈 세트, 기존 답변 있는 세트, 출처 없는 문제 |
| `ProjectDetailTestFixture` | — | 미완료 세트 있는 상세, 전부 완료된 상세 |

App 테스트 Double(`sources/Projects/App/Tests/GitIt/TestDoubles/`): `NoopFetchLearningProjectDetailUseCase`,
`NoopFetchLearningSetUseCase`, `NoopSubmitChoiceAnswerUseCase`, `NoopSubmitEssayAnswerUseCase`,
`NoopSetQuestionBookmarkUseCase` — 기존 `NoopFetchBookmarkedQuestionsUseCase` 형태.
